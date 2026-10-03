package com.eusd.controller;

import com.eusd.entity.RechargeOrder;
import com.eusd.entity.UserCryptoAccount;
import com.eusd.entity.UserFiatAccount;
import com.eusd.repository.RechargeOrderRepository;
import com.eusd.service.ExchangeRateService;
import com.eusd.service.RechargeFlowService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/recharge")
@RequiredArgsConstructor
public class RechargeController {

    private final RechargeFlowService rechargeFlowService;
    private final ExchangeRateService exchangeRateService;
    private final RechargeOrderRepository rechargeOrderRepository;

    @PersistenceContext
    private EntityManager em;

    /**
     * 创建充值订单
     */
    @PostMapping("/create")
    public Map<String, Object> create(@RequestParam String userId,
                                       @RequestParam String channel,
                                       @RequestParam String amount,
                                       @RequestParam(defaultValue = "USD") String targetAsset) {
        UUID uid = UUID.fromString(userId);
        BigDecimal amt = new BigDecimal(amount);

        RechargeOrder order = rechargeFlowService.createOrder(
            uid, channel.toUpperCase(), amt, targetAsset);

        ExchangeRateService.ExchangeQuote quote =
            exchangeRateService.quote("CNY", targetAsset, amt);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("outTradeNo", order.getOutTradeNo());
        result.put("fiatAmount", amt);
        result.put("fiatCurrency", "CNY");
        result.put("targetAsset", targetAsset);
        result.put("estimatedAmount", quote.getToAmount());
        result.put("exchangeRate", quote.getRate());
        result.put("fee", quote.getFee());
        return result;
    }

    /**
     * 查询订单状态（前端轮询）
     */
    @GetMapping("/status/{outTradeNo}")
    public Map<String, Object> status(@PathVariable String outTradeNo) {
        RechargeOrder order = rechargeOrderRepository.findByOutTradeNo(outTradeNo)
            .orElse(null);

        Map<String, Object> result = new HashMap<>();
        if (order == null) {
            result.put("success", false);
            result.put("message", "订单不存在");
            return result;
        }

        result.put("success", true);
        result.put("status", order.getStatus());
        result.put("outTradeNo", order.getOutTradeNo());
        result.put("fiatAmount", order.getFiatAmount());
        result.put("targetAmount", order.getTargetAmount());
        result.put("targetAsset", order.getTargetAsset());
        result.put("completedAt", order.getCompletedAt());
        return result;
    }

    /**
     * 获取汇率报价（不创建订单）
     */
    @GetMapping("/quote")
    public Map<String, Object> quote(@RequestParam String fromAsset,
                                      @RequestParam String toAsset,
                                      @RequestParam String amount) {
        BigDecimal amt = new BigDecimal(amount);
        ExchangeRateService.ExchangeQuote quote =
            exchangeRateService.quote(fromAsset, toAsset, amt);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("fromAsset", quote.getFromAsset());
        result.put("toAsset", quote.getToAsset());
        result.put("fromAmount", quote.getFromAmount());
        result.put("toAmount", quote.getToAmount());
        result.put("rate", quote.getRate());
        result.put("fee", quote.getFee());
        return result;
    }

    /**
     * 查询用户所有余额（法币 + 加密资产）
     */
    @GetMapping("/balance/{userId}")
    public Map<String, Object> balance(@PathVariable String userId) {
        UUID uid = UUID.fromString(userId);

        List<UserFiatAccount> fiatAccounts = em.createQuery(
            "SELECT a FROM UserFiatAccount a WHERE a.userId = :uid", UserFiatAccount.class)
            .setParameter("uid", uid)
            .getResultList();

        List<UserCryptoAccount> cryptoAccounts = em.createQuery(
            "SELECT a FROM UserCryptoAccount a WHERE a.userId = :uid", UserCryptoAccount.class)
            .setParameter("uid", uid)
            .getResultList();

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);

        Map<String, Object> fiat = new HashMap<>();
        for (UserFiatAccount a : fiatAccounts) {
            fiat.put(a.getCurrency(), a.getBalance());
        }
        result.put("fiat", fiat);

        Map<String, Object> crypto = new HashMap<>();
        for (UserCryptoAccount a : cryptoAccounts) {
            crypto.put(a.getAsset(), a.getBalance());
        }
        result.put("crypto", crypto);

        return result;
    }

    /**
     * 用户充值历史
     */
    @GetMapping("/history/{userId}")
    public Map<String, Object> history(@PathVariable String userId) {
        UUID uid = UUID.fromString(userId);
        List<RechargeOrder> orders = rechargeOrderRepository.findByUserId(uid);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("orders", orders);
        return result;
    }

    /**
     * 手动兑换（用户主动把 CNY 兑换成 USD/USDT 等）
     */
    @PostMapping("/exchange")
    public Map<String, Object> exchange(@RequestParam String userId,
                                         @RequestParam String fromAsset,
                                         @RequestParam String toAsset,
                                         @RequestParam String amount) {
        UUID uid = UUID.fromString(userId);
        BigDecimal amt = new BigDecimal(amount);

        Map<String, Object> result = new HashMap<>();
        try {
            if ("CNY".equals(fromAsset)) {
                rechargeFlowService.deductFiatBalance(uid, fromAsset, amt);
            } else {
                rechargeFlowService.deductCryptoBalance(uid, fromAsset, amt);
            }

            ExchangeRateService.ExchangeQuote quote =
                exchangeRateService.quote(fromAsset, toAsset, amt);

            if ("CNY".equals(toAsset)) {
                rechargeFlowService.addFiatBalance(uid, toAsset, quote.getToAmount());
            } else {
                rechargeFlowService.addCryptoBalance(uid, toAsset, quote.getToAmount());
            }

            result.put("success", true);
            result.put("fromAmount", amt);
            result.put("toAmount", quote.getToAmount());
            result.put("rate", quote.getRate());
            result.put("fee", quote.getFee());
            log.info("兑换成功: userId={}, {} {} → {} {}",
                uid, amt, fromAsset, quote.getToAmount(), toAsset);
        } catch (Exception e) {
            log.error("兑换失败: userId={}", uid, e);
            result.put("success", false);
            result.put("message", e.getMessage());
        }
        return result;
    }
}
