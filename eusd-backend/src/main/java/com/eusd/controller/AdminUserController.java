package com.eusd.controller;

import com.eusd.entity.User;
import com.eusd.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
public class AdminUserController {

    private final UserRepository userRepo;

    @GetMapping("/list")
    public Map<String, Object> list(@RequestParam(required = false) String keyword) {
        Map<String, Object> r = new HashMap<>();
        try {
            List<User> all = userRepo.findAll();
            if (keyword != null && !keyword.isEmpty()) {
                String k = keyword.toLowerCase();
                all = all.stream()
                    .filter(u -> (u.getEmail() != null && u.getEmail().toLowerCase().contains(k))
                              || (u.getNickname() != null && u.getNickname().toLowerCase().contains(k))
                              || (u.getPhone() != null && u.getPhone().contains(k)))
                    .toList();
            }
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
            User u = userRepo.findById(UUID.fromString(id)).orElse(null);
            if (u == null) {
                r.put("success", false);
                r.put("message", "用户不存在");
                return r;
            }
            r.put("success", true);
            r.put("item", u);
        } catch (Exception e) {
            r.put("success", false);
            r.put("message", e.getMessage());
        }
        return r;
    }

    @PostMapping("/ban/{id}")
    public Map<String, Object> ban(@PathVariable String id) {
        Map<String, Object> r = new HashMap<>();
        try {
            User u = userRepo.findById(UUID.fromString(id)).orElse(null);
            if (u == null) {
                r.put("success", false);
                r.put("message", "用户不存在");
                return r;
            }
            u.setKycStatus("BANNED");
            userRepo.save(u);
            r.put("success", true);
            r.put("message", "已封禁");
        } catch (Exception e) {
            r.put("success", false);
            r.put("message", e.getMessage());
        }
        return r;
    }

    @PostMapping("/unban/{id}")
    public Map<String, Object> unban(@PathVariable String id) {
        Map<String, Object> r = new HashMap<>();
        try {
            User u = userRepo.findById(UUID.fromString(id)).orElse(null);
            if (u == null) {
                r.put("success", false);
                r.put("message", "用户不存在");
                return r;
            }
            u.setKycStatus("UNVERIFIED");
            userRepo.save(u);
            r.put("success", true);
            r.put("message", "已解封");
        } catch (Exception e) {
            r.put("success", false);
            r.put("message", e.getMessage());
        }
        return r;
    }

    @PostMapping("/kyc/{id}")
    public Map<String, Object> updateKyc(@PathVariable String id,
                                          @RequestParam String status,
                                          @RequestParam(required = false) String level) {
        Map<String, Object> r = new HashMap<>();
        try {
            User u = userRepo.findById(UUID.fromString(id)).orElse(null);
            if (u == null) {
                r.put("success", false);
                r.put("message", "用户不存在");
                return r;
            }
            u.setKycStatus(status);
            if (level != null && !level.isEmpty()) u.setKycLevel(level);
            userRepo.save(u);
            r.put("success", true);
            r.put("message", "已更新");
        } catch (Exception e) {
            r.put("success", false);
            r.put("message", e.getMessage());
        }
        return r;
    }
}
