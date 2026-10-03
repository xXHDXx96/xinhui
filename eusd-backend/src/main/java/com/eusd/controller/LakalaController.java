package com.eusd.controller;

import com.eusd.entity.DepositOrder;
import com.eusd.repository.DepositOrderRepository;
import com.eusd.service.DepositService;
import com.eusd.service.LakalaService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/lakala")
@RequiredArgsConstructor
public class LakalaController {

    private final LakalaService lakalaService;
    private final DepositOrderRepository depositRepo;
    private final DepositService depositService;

    @PostMapping("/create")
    public Map<String, Object> create(@RequestParam String userId,
                                       @RequestParam String channel,
                                       @RequestParam String amount,
                                       @RequestParam(defaultValue = "JPY") String currency) {
        Map<String, Object> result = new HashMap<>();
        try {
            UUID uid = UUID.fromString(userId);
            long amountMinor = new BigDecimal(amount).longValue();

            String orderId = "XH_" + System.currentTimeMillis()
                + "_" + uid.toString().substring(0, 8);

            Map<String, Object> lk = lakalaService.createQrOrder(
                orderId, amountMinor, currency, channel);

            if (!Boolean.TRUE.equals(lk.get("success"))) {
                result.put("success", false);
                result.put("message", lk.get("message"));
                return result;
            }

            DepositOrder order = DepositOrder.builder()
                .userId(uid)
                .orderNo(orderId)
                .channel(channel)
                .amountCny(new BigDecimal(amount))
                .status("CREATED")
                .build();
            depositRepo.save(order);

            result.put("success", true);
            result.put("orderNo", orderId);
            result.put("codeUrl", lk.get("codeUrl"));
            result.put("qrcodeImg", lk.get("qrcodeImg"));
            result.put("payUrl", lk.get("payUrl"));
            result.put("channel", channel);
            result.put("amount", amount);
        } catch (Exception e) {
            log.error("创建 Lakala 订单失败", e);
            result.put("success", false);
            result.put("message", e.getMessage());
        }
        return result;
    }

    @GetMapping("/status/{orderId}")
    public Map<String, Object> status(@PathVariable String orderId) {
        Map<String, Object> result = new HashMap<>();
        try {
            Map<String, Object> lk = lakalaService.queryOrder(orderId);
            result.put("success", true);
            result.put("resultCode", lk.get("resultCode"));
            result.put("paid", "PAY_SUCCESS".equals(lk.get("resultCode")));
            result.put("channelOrderId", lk.get("channelOrderId"));
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", e.getMessage());
        }
        return result;
    }

    @PostMapping("/notify")
    public String notify(@RequestParam Map<String, String> params) {
        log.info("Lakala 支付回调: {}", params);

        if (!lakalaService.verifyNotify(params)) {
            log.warn("Lakala 回调验签失败");
            return "FAIL";
        }

        String partnerOrderId = params.get("partner_order_id");
        String resultCode = params.get("result_code");
        String channelOrderId = params.get("channel_order_id");
        String totalFee = params.get("total_fee");

        if (!"PAY_SUCCESS".equals(resultCode)) {
            return "SUCCESS";
        }

        try {
            depositService.onLakalaPaid(partnerOrderId, channelOrderId, totalFee);
            return "SUCCESS";
        } catch (Exception e) {
            log.error("Lakala 回调处理失败: orderNo={}", partnerOrderId, e);
            return "FAIL";
        }
    }
}
