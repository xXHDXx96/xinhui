package com.eusd.controller;

import com.eusd.entity.KhqrOrder;
import com.eusd.repository.KhqrOrderRepository;
import com.eusd.service.KHQRService;
import com.eusd.service.RechargeFlowService;
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
@RequestMapping("/api/khqr")
@RequiredArgsConstructor
public class KHQRController {

    private final KHQRService khqrService;
    private final KhqrOrderRepository khqrRepo;
    private final RechargeFlowService rechargeFlowService;

    /**
     * 第1步：生成静态二维码（不含金额）
     */
    @PostMapping("/create")
    public Map<String, Object> create(@RequestParam String userId) {
        Map<String, Object> result = new HashMap<>();
        try {
            UUID uid = UUID.fromString(userId);
            return khqrService.createStaticQR(uid);
        } catch (Exception e) {
            log.error("创建 KHQR 订单失败", e);
            result.put("success", false);
            result.put("message", e.getMessage());
            return result;
        }
    }

    /**
     * 第2步：轮询支付状态
     */
    @GetMapping("/status/{md5}")
    public Map<String, Object> status(@PathVariable String md5) {
        Map<String, Object> result = new HashMap<>();
        try {
            Map<String, Object> checkResult = khqrService.checkPayment(md5);

            Object statusObj = checkResult.get("status");
            String status = statusObj == null ? "UNPAID" : statusObj.toString();

            result.put("success", true);
            result.put("status", status);
            result.put("amount", checkResult.get("amount"));

            if ("PAID".equals(status)) {
                KhqrOrder order = khqrRepo.findByMd5(md5).orElse(null);
                if (order != null && !"APPROVED".equals(order.getStatus())) {
                    try {
                        Object amtObj = checkResult.get("amount");
                        String amountStr = amtObj == null ? "0" : amtObj.toString();
                        BigDecimal amt = new BigDecimal(amountStr);
                        rechargeFlowService.handleRechargeSuccess(
                            order.getOrderNo(), amountStr);
                        order.setStatus("APPROVED");
                        order.setAmount(amt);
                        khqrRepo.save(order);
                        log.info("KHQR 自动入账成功: orderNo={}, amount={}",
                            order.getOrderNo(), amt);
                    } catch (Exception e) {
                        log.error("自动入账失败", e);
                    }
                }
            }
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", e.getMessage());
        }
        return result;
    }

    @GetMapping("/history/{userId}")
    public Map<String, Object> history(@PathVariable String userId) {
        UUID uid = UUID.fromString(userId);
        List<KhqrOrder> list = khqrRepo.findByUserIdOrderByCreatedAtDesc(uid);
        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("orders", list);
        return result;
    }
}
