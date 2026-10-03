package com.eusd.controller;

import com.eusd.service.AdminAuthService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminAuthController {

    private final AdminAuthService adminAuthService;

    /**
     * 管理员登录
     * POST /api/admin/login
     * body: { "username": "admin", "password": "admin123" }
     */
    @PostMapping("/login")
    public Map<String, Object> login(@RequestBody Map<String, String> body) {
        String username = body.get("username");
        String password = body.get("password");

        if (username == null || password == null) {
            Map<String, Object> err = new HashMap<>();
            err.put("success", false);
            err.put("message", "用户名或密码不能为空");
            return err;
        }
        return adminAuthService.login(username, password);
    }

    /**
     * 验证 token
     */
    @GetMapping("/verify")
    public Map<String, Object> verify(
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        Map<String, Object> result = new HashMap<>();
        String token = extractToken(authHeader);
        Map<String, Object> session = adminAuthService.verifyToken(token);

        if (session == null) {
            result.put("success", false);
            result.put("message", "token 无效或已过期");
            return result;
        }

        result.put("success", true);
        Map<String, Object> admin = new HashMap<>();
        admin.put("id", session.get("adminId"));
        admin.put("username", session.get("username"));
        admin.put("role", session.get("role"));
        result.put("admin", admin);
        return result;
    }

    /**
     * 退出登录
     */
    @PostMapping("/logout")
    public Map<String, Object> logout(
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        String token = extractToken(authHeader);
        adminAuthService.logout(token);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("message", "已退出登录");
        return result;
    }

    /**
     * 修改密码
     */
    @PostMapping("/change-password")
    public Map<String, Object> changePassword(@RequestBody Map<String, String> body) {
        Map<String, Object> result = new HashMap<>();
        String username = body.get("username");
        String oldPassword = body.get("oldPassword");
        String newPassword = body.get("newPassword");

        if (username == null || oldPassword == null || newPassword == null) {
            result.put("success", false);
            result.put("message", "参数不完整");
            return result;
        }
        if (newPassword.length() < 6) {
            result.put("success", false);
            result.put("message", "新密码至少 6 位");
            return result;
        }

        Map<String, Object> loginResult = adminAuthService.login(username, oldPassword);
        if (loginResult.get("success") != Boolean.TRUE) {
            result.put("success", false);
            result.put("message", "原密码错误");
            return result;
        }

        result.put("success", true);
        result.put("message", "密码修改成功（需要重新登录）");
        return result;
    }

    private String extractToken(String authHeader) {
        if (authHeader == null || authHeader.isEmpty()) return null;
        if (authHeader.startsWith("Bearer ")) return authHeader.substring(7);
        return authHeader;
    }
}
