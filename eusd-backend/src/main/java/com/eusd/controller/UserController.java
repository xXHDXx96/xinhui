package com.eusd.controller;

import com.eusd.entity.User;
import com.eusd.repository.UserRepository;
import com.eusd.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;
    private final UserRepository userRepository;

    @PostMapping("/register")
    public Map<String, Object> register(@RequestBody Map<String, String> body) {
        String email = body.get("email");
        String password = body.get("password");
        String nickname = body.get("nickname");
        if (email == null || password == null) {
            Map<String, Object> r = new HashMap<>();
            r.put("success", false);
            r.put("message", "邮箱和密码不能为空");
            return r;
        }
        return userService.register(email, password, nickname);
    }

    @PostMapping("/login")
    public Map<String, Object> login(@RequestBody Map<String, String> body) {
        String email = body.get("email");
        String password = body.get("password");
        if (email == null || password == null) {
            Map<String, Object> r = new HashMap<>();
            r.put("success", false);
            r.put("message", "邮箱和密码不能为空");
            return r;
        }
        return userService.login(email, password);
    }

    @GetMapping("/verify")
    public Map<String, Object> verify(
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        Map<String, Object> result = new HashMap<>();
        String token = extractToken(authHeader);
        Map<String, Object> session = userService.verifyToken(token);
        if (session == null) {
            result.put("success", false);
            result.put("message", "token 无效或已过期");
            return result;
        }
        result.put("success", true);
        result.put("userId", session.get("userId"));
        result.put("email", session.get("email"));
        return result;
    }

    @GetMapping("/info/{userId}")
    public Map<String, Object> getUserInfo(@PathVariable String userId) {
        try {
            return userService.getUserInfo(UUID.fromString(userId));
        } catch (Exception e) {
            Map<String, Object> r = new HashMap<>();
            r.put("success", false);
            r.put("message", "无效的用户ID");
            return r;
        }
    }

    @PostMapping("/update")
    public Map<String, Object> updateProfile(@RequestParam String userId,
                                              @RequestParam(required = false) String nickname,
                                              @RequestParam(required = false) String avatarUrl) {
        try {
            return userService.updateProfile(UUID.fromString(userId), nickname, avatarUrl);
        } catch (Exception e) {
            Map<String, Object> r = new HashMap<>();
            r.put("success", false);
            r.put("message", e.getMessage());
            return r;
        }
    }

    @PostMapping("/change-password")
    public Map<String, Object> changePassword(@RequestParam String userId,
                                               @RequestParam String oldPassword,
                                               @RequestParam String newPassword) {
        try {
            return userService.changePassword(
                UUID.fromString(userId), oldPassword, newPassword);
        } catch (Exception e) {
            Map<String, Object> r = new HashMap<>();
            r.put("success", false);
            r.put("message", e.getMessage());
            return r;
        }
    }

    @PostMapping("/realname")
    public Map<String, Object> submitRealname(@RequestParam String userId,
                                               @RequestParam String realName,
                                               @RequestParam String idNumber,
                                               @RequestParam(required = false) String phone) {
        Map<String, Object> r = new HashMap<>();
        try {
            if (realName == null || realName.trim().isEmpty()) {
                r.put("success", false);
                r.put("message", "请填写真实姓名");
                return r;
            }
            if (idNumber == null || idNumber.trim().length() != 18) {
                r.put("success", false);
                r.put("message", "身份证号应为 18 位");
                return r;
            }
            UUID uid = UUID.fromString(userId);
            User u = userRepository.findById(uid).orElse(null);
            if (u == null) {
                r.put("success", false);
                r.put("message", "用户不存在");
                return r;
            }
            if ("VERIFIED".equals(u.getKycStatus())) {
                r.put("success", false);
                r.put("message", "已实名，无需重复提交");
                return r;
            }
            if ("PENDING".equals(u.getKycStatus())) {
                r.put("success", false);
                r.put("message", "审核中，请耐心等待");
                return r;
            }
            u.setRealName(realName.trim());
            u.setIdNumber(idNumber.trim());
            if (phone != null && !phone.trim().isEmpty()) {
                u.setPhone(phone.trim());
            }
            u.setKycStatus("PENDING");
            u.setRealnameSubmittedAt(LocalDateTime.now());
            userRepository.save(u);
            log.info("实名认证已提交: userId={}, name={}", uid, realName);
            r.put("success", true);
            r.put("message", "已提交，等待审核");
            r.put("kycStatus", "PENDING");
        } catch (Exception e) {
            log.error("实名认证提交失败", e);
            r.put("success", false);
            r.put("message", e.getMessage());
        }
        return r;
    }

    @PostMapping("/logout")
    public Map<String, Object> logout(
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        String token = extractToken(authHeader);
        userService.logout(token);
        Map<String, Object> r = new HashMap<>();
        r.put("success", true);
        r.put("message", "已退出登录");
        return r;
    }

    private String extractToken(String authHeader) {
        if (authHeader == null || authHeader.isEmpty()) return null;
        if (authHeader.startsWith("Bearer ")) return authHeader.substring(7);
        return authHeader;
    }
}
