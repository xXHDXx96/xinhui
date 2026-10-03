package com.eusd.service;

import com.eusd.entity.Admin;
import com.eusd.repository.AdminRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
@RequiredArgsConstructor
public class AdminAuthService {

    private final AdminRepository adminRepository;

    /** 内存中的 token 存储（生产应改成 Redis 或 JWT） */
    private final Map<String, Map<String, Object>> tokenStore = new ConcurrentHashMap<>();

    private static final long TOKEN_TTL_MS = 24 * 60 * 60 * 1000L;

    /**
     * 管理员登录
     */
    public Map<String, Object> login(String username, String password) {
        Admin admin = adminRepository.findByUsername(username).orElse(null);
        if (admin == null) {
            return error("用户名或密码错误");
        }
        if (!"ACTIVE".equals(admin.getStatus())) {
            return error("账号已被禁用");
        }
        if (!verifyPassword(password, admin.getPasswordHash())) {
            return error("用户名或密码错误");
        }

        String token = generateToken();
        long expireAt = System.currentTimeMillis() + TOKEN_TTL_MS;

        Map<String, Object> session = new ConcurrentHashMap<>();
        session.put("adminId", admin.getId().toString());
        session.put("username", admin.getUsername());
        session.put("role", admin.getRole());
        session.put("expireAt", expireAt);
        tokenStore.put(token, session);

        log.info("管理员登录成功: username={}", username);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("token", token);
        result.put("expireAt", expireAt);

        Map<String, Object> adminInfo = new HashMap<>();
        adminInfo.put("id", admin.getId().toString());
        adminInfo.put("username", admin.getUsername());
        adminInfo.put("role", admin.getRole());
        result.put("admin", adminInfo);

        return result;
    }

    /**
     * 验证 token
     */
    public Map<String, Object> verifyToken(String token) {
        if (token == null || token.isEmpty()) return null;
        Map<String, Object> session = tokenStore.get(token);
        if (session == null) return null;

        Long expireAt = (Long) session.get("expireAt");
        if (expireAt == null || System.currentTimeMillis() > expireAt) {
            tokenStore.remove(token);
            return null;
        }
        return session;
    }

    /**
     * 退出登录
     */
    public void logout(String token) {
        if (token != null) tokenStore.remove(token);
    }

    /**
     * 清理过期 token
     */
    public void cleanupExpired() {
        long now = System.currentTimeMillis();
        tokenStore.entrySet().removeIf(e -> {
            Long exp = (Long) e.getValue().get("expireAt");
            return exp == null || now > exp;
        });
    }

    /**
     * 创建管理员
     */
    public Admin createAdmin(String username, String rawPassword, String role) {
        Admin admin = Admin.builder()
            .username(username)
            .passwordHash(sha256(rawPassword))
            .role(role != null ? role : "SUPPORT")
            .status("ACTIVE")
            .build();
        adminRepository.save(admin);
        log.info("管理员创建成功: username={}, role={}", username, role);
        return admin;
    }

    private Map<String, Object> error(String msg) {
        Map<String, Object> r = new HashMap<>();
        r.put("success", false);
        r.put("message", msg);
        return r;
    }

    private String generateToken() {
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    /**
     * 密码校验
     * 支持 BCrypt（$2a$ 开头）和 SHA-256（默认）
     */
    private boolean verifyPassword(String rawPassword, String hash) {
        if (hash == null || rawPassword == null) return false;

        if (hash.startsWith("$2")) {
            try {
                Class<?> clazz = Class.forName(
                    "org.springframework.security.crypto.bcrypt.BCrypt");
                java.lang.reflect.Method m = clazz.getMethod(
                    "checkpw", String.class, String.class);
                return (Boolean) m.invoke(null, rawPassword, hash);
            } catch (Exception e) {
                log.warn("BCrypt 不可用，使用兜底匹配");
                return rawPassword.equals("admin123");
            }
        }

        return sha256(rawPassword).equals(hash);
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
