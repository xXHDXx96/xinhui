package com.eusd.controller;

import com.eusd.entity.VirtualCard;
import com.eusd.repository.VirtualCardRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/admin/cards")
@RequiredArgsConstructor
public class AdminCardController {

    private final VirtualCardRepository cardRepo;

    @GetMapping("/list")
    public Map<String, Object> list() {
        Map<String, Object> r = new HashMap<>();
        try {
            List<VirtualCard> all = cardRepo.findAll();
            r.put("success", true);
            r.put("items", all);
        } catch (Exception e) {
            r.put("success", false);
            r.put("message", e.getMessage());
        }
        return r;
    }

    @GetMapping("/detail/{id}")
    public Map<String, Object> detail(@PathVariable String id) {
        Map<String, Object> r = new HashMap<>();
        try {
            VirtualCard c = cardRepo.findById(UUID.fromString(id)).orElse(null);
            if (c == null) {
                r.put("success", false);
                r.put("message", "卡片不存在");
                return r;
            }
            r.put("success", true);
            r.put("item", c);
        } catch (Exception e) {
            r.put("success", false);
            r.put("message", e.getMessage());
        }
        return r;
    }

    @PostMapping("/status/{id}")
    public Map<String, Object> updateStatus(@PathVariable String id,
                                             @RequestParam String status) {
        Map<String, Object> r = new HashMap<>();
        try {
            VirtualCard c = cardRepo.findById(UUID.fromString(id)).orElse(null);
            if (c == null) {
                r.put("success", false);
                r.put("message", "卡片不存在");
                return r;
            }
            c.setStatus(status);
            cardRepo.save(c);
            r.put("success", true);
            r.put("message", "已更新");
        } catch (Exception e) {
            r.put("success", false);
            r.put("message", e.getMessage());
        }
        return r;
    }
}
