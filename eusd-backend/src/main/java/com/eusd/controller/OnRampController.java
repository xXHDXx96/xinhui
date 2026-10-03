package com.eusd.controller;

import com.eusd.service.AlchemyPayService;
import com.eusd.service.RechargeFlowService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/onramp")
@RequiredArgsConstructor
public class OnRampController {

    private final AlchemyPayService alchemyPayService;
    private final RechargeFlowService rechargeFlowService;

    /**
     * 创建 On-Ramp 订单
     * App 调用 → 返回 qrCode / payUrl → App 显示二维码
     */
    @PostMapping("/create")
    public Map<String, Object> create(@RequestParam String userId,
                                       @RequestParam String amount,
                                       @RequestParam(defaultValue = "USD") String fiatCurrency) {
        UUID uid = UUID.fromString(userId);
        BigDecimal amt = new BigDecimal(amount);

        String merchantOrderNo = "OR_" + System.currentTimeMillis()
            + "_" + uid.toString().substring(0, 8);

        Map<String, Object> r = alchemyPayService.createOrder(
            merchantOrderNo, amt, fiatCurrency);

        if (Boolean.TRUE.equals(r.get("success"))) {
            r.put("merchantOrderNo", merchantOrderNo);
            r.put("userId", uid);
        }
        return r;
    }

    /**
     * 查询订单状态
     */
    @GetMapping("/status/{orderId}")
    public Map<String, Object> status(@PathVariable String orderId) {
        return alchemyPayService.queryOrder(orderId);
    }

    /**
     * Webhook 回调（Alchemy Pay 服务器调用）
     * 收到 crypto 到账通知 → 给用户账户加 USDT
     */
    @PostMapping("/webhook")
    public Map<String, Object> webhook(
            @RequestHeader Map<String, String> headers,
            @RequestBody String body) {

        log.info("收到 AlchemyPay Webhook: {}", body);

        if (!alchemyPayService.verifyWebhook(headers, body)) {
            log.warn("Webhook 验签失败");
            return Map.of("success", false, "message", "invalid signature");
        }

        try {
            Map<String, Object> r = new HashMap<>();
            // 解析 body（根据 Alchemy Pay 实际回调格式调整）
            // 常见字段: merchantOrderNo, cryptoAmount, txHash, status
            // 此处为示例结构，需对照官方文档调整

            // 假设解析出:
            // String merchantOrderNo = ...
            // String cryptoAmount = ...
            // String txHash = ...
            // String status = ...

            // if ("SUCCESS".equals(status)) {
            //     // 根据 merchantOrderNo 找到用户，加 USDT 余额
            //     rechargeFlowService.addCryptoBalance(userId, "USDT", new BigDecimal(cryptoAmount));
            // }

            r.put("success", true);
            return r;
        } catch (Exception e) {
            log.error("处理 Webhook 异常", e);
            return Map.of("success", false, "message", e.getMessage());
        }
    }
}
