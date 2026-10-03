package com.eusd.controller;

import com.eusd.entity.PaymentQrCode;
import com.eusd.repository.PaymentQrCodeRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/admin/qr-codes")
@RequiredArgsConstructor
public class QrCodeController {

    private final PaymentQrCodeRepository qrRepo;

    @GetMapping("/list")
    public Map<String, Object> list() {
        Map<String, Object> r = new HashMap<>();
        List<PaymentQrCode> list = qrRepo.findAllByOrderByCreatedAtDesc();
        r.put("success", true);
        r.put("items", list);
        return r;
    }

    @PostMapping("/add")
    public Map<String, Object> add(@RequestParam String channel,
                                    @RequestParam String qrContent,
                                    @RequestParam(required = false, defaultValue = "TEXT") String qrType,
                                    @RequestParam(required = false) String merchantName,
                                    @RequestParam(required = false) String remark) {
        Map<String, Object> r = new HashMap<>();
        try {
            PaymentQrCode qr = PaymentQrCode.builder()
                .channel(channel.toUpperCase())
                .qrContent(qrContent)
                .qrType(qrType)
                .merchantName(merchantName)
                .remark(remark)
                .enabled(true)
                .usedCount(0L)
                .build();
            qrRepo.save(qr);
            r.put("success", true);
            r.put("message", "已添加");
            r.put("id", qr.getId());
        } catch (Exception e) {
            r.put("success", false);
            r.put("message", e.getMessage());
        }
        return r;
    }

    @PostMapping("/delete/{id}")
    public Map<String, Object> delete(@PathVariable String id) {
        Map<String, Object> r = new HashMap<>();
        try {
            qrRepo.deleteById(UUID.fromString(id));
            r.put("success", true);
        } catch (Exception e) {
            r.put("success", false);
            r.put("message", e.getMessage());
        }
        return r;
    }

    @PostMapping("/toggle/{id}")
    public Map<String, Object> toggle(@PathVariable String id) {
        Map<String, Object> r = new HashMap<>();
        try {
            PaymentQrCode qr = qrRepo.findById(UUID.fromString(id)).orElse(null);
            if (qr == null) {
                r.put("success", false);
                r.put("message", "不存在");
                return r;
            }
            qr.setEnabled(!Boolean.TRUE.equals(qr.getEnabled()));
            qrRepo.save(qr);
            r.put("success", true);
            r.put("enabled", qr.getEnabled());
        } catch (Exception e) {
            r.put("success", false);
            r.put("message", e.getMessage());
        }
        return r;
    }
}
