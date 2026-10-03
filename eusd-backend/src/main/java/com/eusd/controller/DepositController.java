package com.eusd.controller;

import com.eusd.entity.DepositOrder;
import com.eusd.entity.PaymentQrCode;
import com.eusd.repository.PaymentQrCodeRepository;
import com.eusd.service.DepositService;
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
@RequestMapping("/api/deposit")
@RequiredArgsConstructor
public class DepositController {

    private final DepositService depositService;
    private final PaymentQrCodeRepository qrRepo;

    @PostMapping("/create")
    public Map<String, Object> create(@RequestParam String userId,
                                       @RequestParam String channel) {
        Map<String, Object> result = new HashMap<>();
        try {
            UUID uid = UUID.fromString(userId);
            DepositOrder order = depositService.createDeposit(uid, channel);

            String qrContent = null;
            String qrType = "TEXT";
            if (order.getQrCodeId() != null) {
                PaymentQrCode qr = qrRepo.findById(order.getQrCodeId()).orElse(null);
                if (qr != null) {
                    qrContent = qr.getQrContent();
                    qrType = qr.getQrType();
                }
            }

            result.put("success", true);
            result.put("orderNo", order.getOrderNo());
            result.put("channel", channel);
            result.put("qrContent", qrContent);
            result.put("qrType", qrType);
            result.put("merchantName", order.getQrMerchantName());
        } catch (Exception e) {
            log.error("创建订单失败", e);
            result.put("success", false);
            result.put("message", e.getMessage());
        }
        return result;
    }

    @PostMapping("/submit")
    public Map<String, Object> submit(@RequestParam String orderNo,
                                       @RequestParam String amount,
                                       @RequestParam String paymentTxid,
                                       @RequestParam(required = false) String screenshot) {
        Map<String, Object> result = new HashMap<>();
        try {
            BigDecimal amt = new BigDecimal(amount);
            DepositOrder order = depositService.submitDeposit(orderNo, amt, paymentTxid);
            if (screenshot != null && !screenshot.isEmpty()) {
                order.setPaymentScreenshot(screenshot);
                depositService.updateOrder(order);
            }
            result.put("success", true);
            result.put("message", "已提交，客服将尽快审核");
            result.put("status", order.getStatus());
        } catch (Exception e) {
            log.error("提交失败", e);
            result.put("success", false);
            result.put("message", e.getMessage());
        }
        return result;
    }

    @GetMapping("/status/{orderNo}")
    public Map<String, Object> status(@PathVariable String orderNo) {
        Map<String, Object> result = new HashMap<>();
        try {
            DepositOrder order = depositService.getByOrderNo(orderNo);
            result.put("success", true);
            result.put("status", order.getStatus());
            result.put("orderNo", order.getOrderNo());
            result.put("amountCny", order.getAmountCny());
            result.put("amountUsdt", order.getAmountUsdt());
            result.put("adminRemark", order.getAdminRemark());
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", e.getMessage());
        }
        return result;
    }

    @GetMapping("/history/{userId}")
    public Map<String, Object> history(@PathVariable String userId) {
        Map<String, Object> result = new HashMap<>();
        try {
            UUID uid = UUID.fromString(userId);
            List<DepositOrder> list = depositService.listByUser(uid);
            result.put("success", true);
            result.put("orders", list);
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", e.getMessage());
        }
        return result;
    }
}
