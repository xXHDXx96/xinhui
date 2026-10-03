package com.eusd.service;

import com.eusd.entity.User;
import com.eusd.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Pattern;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;

    /** 内存 token 存储（生产应改 Redis/JWT） */
    private final Map<String, Map<String, Object>> tokenStore = new ConcurrentHashMap<>();
    private static final long TOKEN_TTL_MS = 7 * 24 * 60 * 60 * 1000L;
    private static final Pattern EMAIL_PATTERN =
        Pattern.compile("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");

    /**
     * 用户注册
     */
    @Transactional
    public Map<String, Object> register(String email, String password, String nickname) {
        if (email == null || !EMAIL_PATTERN.matcher(email).matches()) {
            return error("邮箱格式不正确");
        }
        if (password == null || password.length() < 6) {
            return error("密码至少 6 位");
        }
        if (userRepository.existsByEmail(email)) {
            return error("该邮箱已注册");
        }

        User user = User.builder()
            .email(email)
            .passwordHash(sha256(password))
            .nickname(nickname != null && !nickname.isEmpty() ? nickname : email.split("@")[0])
            .kycStatus("UNVERIFIED")
            .kycLevel("NONE")
            .build();

        userRepository.save(user);
        log.info("用户注册成功: email={}, userId={}", email, user.getId());

        return buildLoginResult(user);
    }

    /**
     * 用户登录
     */
    public Map<String, Object> login(String email, String password) {
        if (email == null || password == null) return error("参数不能为空");

        User user = userRepository.findByEmail(email).orElse(null);
        if (user == null) return error("邮箱或密码错误");

        if (!sha256(password).equals(user.getPasswordHash())) {
            return error("邮箱或密码错误");
        }

        log.info("用户登录成功: email={}, userId={}", email, user.getId());
        return buildLoginResult(user);
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
     * 获取当前用户信息
     */
    public Map<String, Object> getUserInfo(UUID userId) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) return error("用户不存在");

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("id", user.getId());
        result.put("email", user.getEmail());
        result.put("nickname", user.getNickname());
        result.put("kycStatus", user.getKycStatus());
        result.put("kycLevel", user.getKycLevel());
        result.put("avatarUrl", user.getAvatarUrl());
        result.put("createdAt", user.getCreatedAt());
        return result;
    }

    /**
     * 退出登录
     */
    public void logout(String token) {
        if (token != null) tokenStore.remove(token);
    }

    /**
     * 更新用户资料
     */
    @Transactional
    public Map<String, Object> updateProfile(UUID userId, String nickname, String avatarUrl) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) return error("用户不存在");

        if (nickname != null) user.setNickname(nickname);
        if (avatarUrl != null) user.setAvatarUrl(avatarUrl);
        userRepository.save(user);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("message", "资料已更新");
        return result;
    }

    /**
     * 修改密码
     */
    @Transactional
    public Map<String, Object> changePassword(UUID userId, String oldPwd, String newPwd) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) return error("用户不存在");

        if (!sha256(oldPwd).equals(user.getPasswordHash())) {
            return error("原密码错误");
        }
        if (newPwd == null || newPwd.length() < 6) {
            return error("新密码至少 6 位");
        }
        user.setPasswordHash(sha256(newPwd));
        userRepository.save(user);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("message", "密码已修改");
        return result;
    }

    // ===== 内部方法 =====

    private Map<String, Object> buildLoginResult(User user) {
        String token = generateToken();
        long expireAt = System.currentTimeMillis() + TOKEN_TTL_MS;

        Map<String, Object> session = new ConcurrentHashMap<>();
        session.put("userId", user.getId().toString());
        session.put("email", user.getEmail());
        session.put("expireAt", expireAt);
        tokenStore.put(token, session);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("token", token);
        result.put("expireAt", expireAt);

        Map<String, Object> userInfo = new HashMap<>();
        userInfo.put("id", user.getId().toString());
        userInfo.put("email", user.getEmail());
        userInfo.put("nickname", user.getNickname());
        userInfo.put("kycStatus", user.getKycStatus());
        userInfo.put("kycLevel", user.getKycLevel());
        result.put("user", userInfo);
        return result;
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
