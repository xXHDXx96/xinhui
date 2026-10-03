package com.eusd.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.math.BigDecimal;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class AlchemyPayService {

    private final SystemConfigService cfg;
    private final ObjectMapper om = new ObjectMapper();

    // ===== 每次调用从数据库缓存读，App 后台改完立即生效 =====
    private boolean enabled() {
        return "true".equalsIgnoreCase(cfg.getCached("ALCHEMY", "enabled", "false"));
    }
    private String appId() {
        return cfg.getCached("ALCHEMY", "app-id", "");
    }
    private String secret() {
        return cfg.getCached("ALCHEMY", "secret", "");
    }
    private String baseUrl() {
        return cfg.getCached("ALCHEMY", "base-url", "https://openapi.alchemypay.org");
    }
    private String callbackUrl() {
        return cfg.getCached("ALCHEMY", "callback-url", "");
    }
    private String settleAddress() {
        return cfg.getCached("ALCHEMY", "settle-address", "");
    }
    private String settleNetwork() {
        return cfg.getCached("ALCHEMY", "settle-network", "TRX");
    }
    private String settleCrypto() {
        return cfg.getCached("ALCHEMY", "settle-crypto", "USDT");
    }

    public boolean isEnabled() { return enabled(); }

    /**
     * 创建 On-Ramp 订单
     */
    public Map<String, Object> createOrder(String merchantOrderNo,
                                            BigDecimal fiatAmount,
                                            String fiatCurrency) {
        if (!enabled()) {
            throw new RuntimeException("Alchemy Pay 未启用，请在后台系统配置中开启");
        }

        String appId = appId();
        String secret = secret();
        String baseUrl = baseUrl();
        String settleAddress = settleAddress();

        if (appId.isEmpty() || secret.isEmpty()) {
            throw new RuntimeException("Alchemy Pay 未配置 App ID 或 Secret，请在后台系统配置中填写");
        }
        if (settleAddress.isEmpty()) {
            throw new RuntimeException("未配置 USDT 收款地址，请在后台系统配置中填写");
        }

        try {
            long timestamp = System.currentTimeMillis();
            String nonce = generateNonce();

            String signString = "appId=" + appId + "&nonce=" + nonce + "&timestamp=" + timestamp;
            String signature = sha256(signString + secret);

            Map<String, Object> body = new HashMap<>();
            body.put("crypto", settleCrypto());
            body.put("network", settleNetwork());
            body.put("fiat", fiatCurrency);
            body.put("fiatAmount", fiatAmount.toPlainString());
            body.put("walletAddress", settleAddress);
            body.put("callbackUrl", callbackUrl());
            body.put("merchantOrderNo", merchantOrderNo);

            String json = om.writeValueAsString(body);
            String url = baseUrl + "/open/api/v4/merchant/order/create";

            HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
            conn.setRequestMethod("POST");
            conn.setDoOutput(true);
            conn.setConnectTimeout(15000);
            conn.setReadTimeout(30000);
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setRequestProperty("appId", appId);
            conn.setRequestProperty("timestamp", String.valueOf(timestamp));
            conn.setRequestProperty("nonce", nonce);
            conn.setRequestProperty("sign", signature);

            try (OutputStream os = conn.getOutputStream()) {
                os.write(json.getBytes(StandardCharsets.UTF_8));
            }

            int code = conn.getResponseCode();
            StringBuilder resp = new StringBuilder();
            try (BufferedReader br = new BufferedReader(
                    new InputStreamReader(code >= 200 && code < 300
                        ? conn.getInputStream() : conn.getErrorStream(),
                        StandardCharsets.UTF_8))) {
                String line;
                while ((line = br.readLine()) != null) resp.append(line);
            }

            log.info("AlchemyPay 创建订单返回: code={}, body={}", code, resp);

            JsonNode root = om.readTree(resp.toString());
            Map<String, Object> result = new HashMap<>();
            result.put("success", root.path("success").asBoolean(false));
            result.put("orderId", root.path("data").path("orderId").asText(""));
            result.put("payUrl", root.path("data").path("payUrl").asText(""));
            result.put("qrCode", root.path("data").path("qrCode").asText(""));
            result.put("expireTime", root.path("data").path("expireTime").asLong(0));
            if (!root.path("success").asBoolean(false)) {
                result.put("message", root.path("msg").asText("创建订单失败"));
            }
            return result;
        } catch (Exception e) {
            log.error("AlchemyPay 创建订单异常", e);
            Map<String, Object> err = new HashMap<>();
            err.put("success", false);
            err.put("message", e.getMessage());
            return err;
        }
    }

    /**
     * 查询订单状态
     */
    public Map<String, Object> queryOrder(String orderId) {
        if (!enabled()) {
            Map<String, Object> r = new HashMap<>();
            r.put("success", false);
            r.put("message", "Alchemy Pay 未启用");
            return r;
        }

        try {
            String appId = appId();
            String secret = secret();
            String baseUrl = baseUrl();

            long timestamp = System.currentTimeMillis();
            String nonce = generateNonce();
            String signString = "appId=" + appId + "&nonce=" + nonce + "&timestamp=" + timestamp;
            String signature = sha256(signString + secret);

            String url = baseUrl + "/open/api/v4/merchant/order/query?orderId=" + orderId;
            HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(15000);
            conn.setRequestProperty("appId", appId);
            conn.setRequestProperty("timestamp", String.valueOf(timestamp));
            conn.setRequestProperty("nonce", nonce);
            conn.setRequestProperty("sign", signature);

            StringBuilder resp = new StringBuilder();
            try (BufferedReader br = new BufferedReader(
                    new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                while ((line = br.readLine()) != null) resp.append(line);
            }

            JsonNode root = om.readTree(resp.toString());
            Map<String, Object> result = new HashMap<>();
            result.put("success", root.path("success").asBoolean(false));
            result.put("status", root.path("data").path("status").asText(""));
            result.put("cryptoAmount", root.path("data").path("cryptoAmount").asText(""));
            result.put("txHash", root.path("data").path("txHash").asText(""));
            return result;
        } catch (Exception e) {
            log.error("AlchemyPay 查询订单异常", e);
            Map<String, Object> r = new HashMap<>();
            r.put("success", false);
            r.put("message", e.getMessage());
            return r;
        }
    }

    /**
     * 验证 Webhook 签名
     */
    public boolean verifyWebhook(Map<String, String> headers, String body) {
        try {
            String sign = headers.get("sign");
            String timestamp = headers.get("timestamp");
            String nonce = headers.get("nonce");
            if (sign == null || timestamp == null || nonce == null) return false;

            String signString = "appId=" + appId() + "&nonce=" + nonce + "&timestamp=" + timestamp;
            String expected = sha256(signString + secret());
            return expected.equalsIgnoreCase(sign);
        } catch (Exception e) {
            log.error("Webhook 验签失败", e);
            return false;
        }
    }

    // ===== 工具方法 =====
    private String generateNonce() {
        byte[] bytes = new byte[16];
        new SecureRandom().nextBytes(bytes);
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) sb.append(String.format("%02x", b));
        return sb.toString();
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
