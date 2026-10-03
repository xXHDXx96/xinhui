package com.eusd.controller;

import com.eusd.entity.VirtualCard;
import com.eusd.service.RechargeFlowService;
import com.eusd.service.StripeCardService;
import com.stripe.model.Event;
import com.stripe.model.issuing.Authorization;
import com.stripe.model.issuing.Card;
import com.stripe.model.issuing.Transaction;
import com.stripe.net.Webhook;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.math.RoundingMode;

@Slf4j
@RestController
@RequestMapping("/api/stripe")
@RequiredArgsConstructor
public class StripeWebhookController {

    private final StripeCardService stripeCardService;
    private final RechargeFlowService rechargeFlowService;

    @Value("${stripe.webhook-secret}")
    private String webhookSecret;

    /**
     * Stripe Webhook 总入口
     * 关键：issuing_authorization.request 必须在 2 秒内返回决策
     */
    @PostMapping("/webhook")
    public ResponseEntity<String> handleWebhook(@RequestBody String payload,
                                                 @RequestHeader("Stripe-Signature") String sigHeader) {
        Event event;
        try {
            event = Webhook.constructEvent(payload, sigHeader, webhookSecret);
        } catch (Exception e) {
            log.warn("Stripe Webhook 签名验证失败: {}", e.getMessage());
            return ResponseEntity.badRequest().body("{\"error\":\"invalid_signature\"}");
        }

        long start = System.currentTimeMillis();
        try {
            switch (event.getType()) {
                case "issuing_authorization.request":
                    return handleAuthorizationRequest(event);
                case "issuing_authorization.created":
                    handleAuthorizationCreated(event);
                    break;
                case "issuing_transaction.created":
                    handleTransactionCreated(event);
                    break;
                case "issuing_card.created":
                    handleCardCreated(event);
                    break;
                case "issuing_card.updated":
                    handleCardUpdated(event);
                    break;
                case "issuing_cardholder.created":
                    log.info("Cardholder created 事件");
                    break;
                default:
                    log.debug("未处理的 Stripe 事件: {}", event.getType());
            }
            return ResponseEntity.ok("{\"received\":true}");
        } catch (Exception e) {
            log.error("处理 Stripe Webhook 异常: {}", event.getType(), e);
            return ResponseEntity.ok("{\"received\":true}");
        } finally {
            long elapsed = System.currentTimeMillis() - start;
            log.info("Stripe Webhook 处理耗时: {}ms, type={}", elapsed, event.getType());
        }
    }

    /**
     * 实时授权请求 — 必须在 2 秒内返回
     */
    private ResponseEntity<String> handleAuthorizationRequest(Event event) {
        Authorization auth = (Authorization) event.getDataObjectDeserializer()
            .getObject().orElse(null);

        if (auth == null) {
            return ResponseEntity.ok("{\"approved\":false,\"reason\":\"unknown\"}");
        }

        String stripeCardId = auth.getCard() != null ? auth.getCard().getId() : null;
        long amountMinor = auth.getAmount();
        BigDecimal amount = BigDecimal.valueOf(amountMinor)
            .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);

        String merchantCategory = null;
        if (auth.getMerchantData() != null) {
            merchantCategory = auth.getMerchantData().getCategory();
        }

        log.info("收到授权请求: cardId={}, amount={} USD, mcc={}",
            stripeCardId, amount, merchantCategory);

        if (stripeCardId == null) {
            return ResponseEntity.ok("{\"approved\":false,\"reason\":\"card_not_found\"}");
        }

        VirtualCard card = stripeCardService.getByStripeCardId(stripeCardId);
        if (card == null) {
            log.warn("授权拒绝：本地无此卡片记录 {}", stripeCardId);
            return ResponseEntity.ok("{\"approved\":false,\"reason\":\"card_not_found\"}");
        }

        if (!"active".equals(card.getStatus())) {
            log.warn("授权拒绝：卡片状态非 active: {}", card.getStatus());
            return ResponseEntity.ok("{\"approved\":false,\"reason\":\"card_inactive\"}");
        }

        BigDecimal balance = rechargeFlowService.getCryptoBalance(card.getUserId(), "USD");
        if (balance.compareTo(amount) < 0) {
            log.warn("授权拒绝：余额不足 userId={}, balance={}, required={}",
                card.getUserId(), balance, amount);
            return ResponseEntity.ok("{\"approved\":false,\"reason\":\"insufficient_funds\"}");
        }

        if (!checkSpendingControls(merchantCategory, amount)) {
            return ResponseEntity.ok("{\"approved\":false,\"reason\":\"spending_controls\"}");
        }

        log.info("授权批准: cardId={}, amount={}", stripeCardId, amount);
        return ResponseEntity.ok("{\"approved\":true}");
    }

    /**
     * 授权已创建（异步事件，仅记录）
     */
    private void handleAuthorizationCreated(Event event) {
        Authorization auth = (Authorization) event.getDataObjectDeserializer()
            .getObject().orElse(null);
        if (auth == null) return;
        String cardId = auth.getCard() != null ? auth.getCard().getId() : "unknown";
        log.info("授权已创建: id={}, cardId={}, amount={}, status={}",
            auth.getId(), cardId, auth.getAmount(), auth.getStatus());
    }

    /**
     * 交易完成（清算扣款）
     */
    private void handleTransactionCreated(Event event) {
        Transaction txn = (Transaction) event.getDataObjectDeserializer()
            .getObject().orElse(null);
        if (txn == null) return;

        String stripeCardId = txn.getCard();
        long amountMinor = txn.getAmount();
        BigDecimal amount = BigDecimal.valueOf(amountMinor)
            .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);

        log.info("交易完成: txnId={}, cardId={}, amount={} USD",
            txn.getId(), stripeCardId, amount);

        if (stripeCardId == null) return;

        VirtualCard card = stripeCardService.getByStripeCardId(stripeCardId);
        if (card == null) {
            log.warn("交易关联的本地卡片不存在: {}", stripeCardId);
            return;
        }

        try {
            rechargeFlowService.deductCryptoBalance(card.getUserId(), "USD", amount);
            log.info("已扣款: userId={}, amount={} USD", card.getUserId(), amount);
        } catch (Exception e) {
            log.error("扣款失败: userId={}, amount={}", card.getUserId(), amount, e);
        }
    }

    /**
     * 卡片创建事件
     */
    private void handleCardCreated(Event event) {
        Card card = (Card) event.getDataObjectDeserializer().getObject().orElse(null);
        if (card != null) {
            log.info("Stripe 卡片已创建: id={}, last4={}", card.getId(), card.getLast4());
        }
    }

    /**
     * 卡片更新事件（同步状态到本地）
     */
    private void handleCardUpdated(Event event) {
        Card card = (Card) event.getDataObjectDeserializer().getObject().orElse(null);
        if (card != null) {
            stripeCardService.handleCardWebhook(card.getId(), card.getStatus());
        }
    }

    /**
     * 支出控制检查（简化版：MCC 黑名单）
     */
    private boolean checkSpendingControls(String mcc, BigDecimal amount) {
        if ("7995".equals(mcc)) {
            log.debug("拒绝：赌博类商户");
            return false;
        }
        if ("6012".equals(mcc)) {
            log.debug("拒绝：现金预付类商户");
            return false;
        }
        return true;
    }
}
