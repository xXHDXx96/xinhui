package com.eusd.controller;

import com.eusd.entity.Admin;
import com.eusd.repository.AdminRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.security.MessageDigest;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/admin/accounts")
@RequiredArgsConstructor
public class AdminAccountController {

    private final AdminRepository adminRepo;

    @GetMapping("/list")
    public Map<String, Object> list() {
        Map<String, Object> r = new HashMap<>();
        try {
            List<Admin> all = adminRepo.findAll();
            r.put("success", true);
            r.put("items", all);
        } catch (Exception e) {
            r.put("success", false);
            r.put("message", e.getMessage());
        }
        return r;
    }

    @PostMapping("/add")
    public Map<String, Object> add(@RequestParam String username,
                                    @RequestParam String password,
                                    @RequestParam(required = false, defaultValue = "SUPPORT") String role) {
        Map<String, Object> r = new HashMap<>();
        try {
            if (username == null || username.isEmpty() || password == null || password.isEmpty()) {
                r.put("success", false);
                r.put("message", "用户名和密码不能为空");
                return r;
            }
            if (adminRepo.findByUsername(username).isPresent()) {
                r.put("success", false);
                r.put("message", "用户名已存在");
                return r;
            }
            Admin a = Admin.builder()
                .username(username)
                .passwordHash(sha256(password))
                .role(role)
                .status("ACTIVE")
                .build();
            adminRepo.save(a);
            r.put("success", true);
            r.put("message", "已添加");
            r.put("id", a.getId());
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
            adminRepo.deleteById(UUID.fromString(id));
            r.put("success", true);
            r.put("message", "已删除");
        } catch (Exception e) {
            r.put("success", false);
            r.put("message", e.getMessage());
        }
        return r;
    }

    private String sha256(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(input.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : digest) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
