package com.eusd.controller;

import com.eusd.entity.VirtualCard;
import com.eusd.repository.VirtualCardRepository;
import com.eusd.service.StripeCardService;
import com.eusd.service.StripeCardholderService;
import com.stripe.model.issuing.Cardholder;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/cards")
@RequiredArgsConstructor
public class CardController {

    private final StripeCardService stripeCardService;
    private final StripeCardholderService stripeCardholderService;
    private final VirtualCardRepository virtualCardRepository;

    /**
     * 查询用户所有卡片
     */
    @GetMapping("/list/{userId}")
    public Map<String, Object> listCards(@PathVariable String userId) {
        Map<String, Object> result = new HashMap<>();
        try {
            UUID uid = UUID.fromString(userId);
            List<VirtualCard> cards = stripeCardService.listUserCards(uid);
            result.put("success", true);
            result.put("cards", cards);
        } catch (IllegalArgumentException e) {
            result.put("success", false);
            result.put("message", "无效的用户ID");
        } catch (Exception e) {
            log.error("查询卡片列表失败: userId={}", userId, e);
            result.put("success", false);
            result.put("message", e.getMessage());
        }
        return result;
    }

    /**
     * 创建虚拟卡
     */
    @PostMapping("/virtual")
    public Map<String, Object> createVirtualCard(@RequestParam String userId) {
        Map<String, Object> result = new HashMap<>();
        try {
            UUID uid = UUID.fromString(userId);

            Cardholder cardholder = stripeCardholderService.getOrCreateCardholder(uid);

            VirtualCard card = stripeCardService.createVirtualCard(
                uid, cardholder.getId(), "usd");

            result.put("success", true);
            result.put("card", card);
            result.put("message", "虚拟卡创建成功");
            log.info("虚拟卡创建成功: userId={}, cardId={}", userId, card.getId());
        } catch (Exception e) {
            log.error("创建虚拟卡失败: userId={}", userId, e);
            result.put("success", false);
            result.put("message", e.getMessage() != null ? e.getMessage() : "创建失败");
        }
        return result;
    }

    /**
     * 创建实体卡（含邮寄地址）
     */
    @PostMapping("/physical")
    public Map<String, Object> createPhysicalCard(
            @RequestParam String userId,
            @RequestParam String shippingName,
            @RequestParam String shippingPhone,
            @RequestParam String line1,
            @RequestParam String city,
            @RequestParam String state,
            @RequestParam String postalCode,
            @RequestParam String country) {

        Map<String, Object> result = new HashMap<>();
        try {
            UUID uid = UUID.fromString(userId);

            Cardholder cardholder = stripeCardholderService.getOrCreateCardholder(uid);

            VirtualCard card = stripeCardService.createPhysicalCard(
                uid, cardholder.getId(), "usd",
                shippingName, shippingPhone, line1, city, state, postalCode, country);

            result.put("success", true);
            result.put("card", card);
            result.put("message", "实体卡申请成功，预计4-6周送达");
            log.info("实体卡创建成功: userId={}, cardId={}", userId, card.getId());
        } catch (Exception e) {
            log.error("创建实体卡失败: userId={}", userId, e);
            result.put("success", false);
            result.put("message", e.getMessage() != null ? e.getMessage() : "申请失败");
        }
        return result;
    }

    /**
     * 更新卡片状态（冻结 / 解冻 / 注销）
     */
    @PostMapping("/{cardId}/status")
    public Map<String, Object> updateCardStatus(
            @PathVariable String cardId,
            @RequestParam String status) {

        Map<String, Object> result = new HashMap<>();
        try {
            UUID cid = UUID.fromString(cardId);
            stripeCardService.updateCardStatus(cid, status);
            result.put("success", true);
            result.put("message", status.equals("blocked") ? "卡片已冻结" : "卡片状态已更新");
            log.info("卡片状态更新: cardId={}, status={}", cardId, status);
        } catch (Exception e) {
            log.error("更新卡片状态失败: cardId={}", cardId, e);
            result.put("success", false);
            result.put("message", e.getMessage() != null ? e.getMessage() : "操作失败");
        }
        return result;
    }

    /**
     * 查询卡片详情
     */
    @GetMapping("/detail/{cardId}")
    public Map<String, Object> cardDetail(@PathVariable String cardId) {
        Map<String, Object> result = new HashMap<>();
        try {
            UUID cid = UUID.fromString(cardId);
            VirtualCard card = stripeCardService.getCard(cid);
            result.put("success", true);
            result.put("card", card);
        } catch (Exception e) {
            log.error("查询卡片详情失败: cardId={}", cardId, e);
            result.put("success", false);
            result.put("message", e.getMessage() != null ? e.getMessage() : "卡片不存在");
        }
        return result;
    }

    /**
     * 从 Stripe 同步卡片状态到本地
     */
    @PostMapping("/sync/{cardId}")
    public Map<String, Object> syncCard(@PathVariable String cardId) {
        Map<String, Object> result = new HashMap<>();
        try {
            UUID cid = UUID.fromString(cardId);
            VirtualCard local = stripeCardService.getCard(cid);
            if (local.getStripeCardId() != null) {
                stripeCardService.syncCardFromStripe(local.getStripeCardId());
                result.put("success", true);
                result.put("message", "已同步最新状态");
            } else {
                result.put("success", false);
                result.put("message", "卡片未关联 Stripe");
            }
        } catch (Exception e) {
            log.error("同步卡片失败: cardId={}", cardId, e);
            result.put("success", false);
            result.put("message", e.getMessage() != null ? e.getMessage() : "同步失败");
        }
        return result;
    }

    /**
     * 健康检查
     */
    @GetMapping("/ping")
    public Map<String, Object> ping() {
        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("service", "CardController");
        result.put("message", "pong");
        return result;
    }
}
