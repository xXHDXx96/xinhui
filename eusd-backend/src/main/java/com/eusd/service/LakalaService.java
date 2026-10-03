package com.eusd.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.math.BigDecimal;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.HashMap;
import java.util.Map;

/**
 * Lakala Japan 支付网关
 * 文档: https://pay.lakala-japan.com/
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class LakalaService {

    private final ObjectMapper om = new ObjectMapper();

    @Value("${lakala.enabled:false}") private boolean enabled;
    @Value("${lakala.partner-code:}") private String partnerCode;
    @Value("${lakala.credential-code:}") private String credentialCode;
    @Value("${lakala.base-url:https://pay.lakala-japan.com}") private String baseUrl;
    @Value("${lakala.notify-url:}") private String notifyUrl;

    public boolean isEnabled() { return enabled; }

    /**
     * 创建 QRCode 支付单
     * @param orderId 你的订单号（唯一）
     * @param amount 金额（最小单位，JPY 100 = 100 日元；CNY 100 = 1.00 元）
     * @param currency JPY / CNY
     * @param channel Alipay / Wechat / Alipay+
     * @return { codeUrl, qrcodeImg, payUrl, orderId }
     */
    public Map<String, Object> createQrOrder(String orderId, long amount,
                                              String currency, String channel) {
        if (!enabled) {
            return Map.of("success", false, "message", "Lakala 未启用");
        }

        try {
            // 构造签名参数
            long time = System.currentTimeMillis();
            String nonceStr = generateNonce();
            String sign = buildSign(time, nonceStr);

            // 请求体
            Map<String, Object> body = new HashMap<>();
            body.put("description", "鑫汇Pay 充值");
            body.put("price", amount);
            body.put("currency", currency);
            body.put("channel", channel);
            if (notifyUrl != null && !notifyUrl.isEmpty()) {
                body.put("notify_url", notifyUrl + "/api/lakala/notify");
            }

            String json = om.writeValueAsString(body);

            // URL
            String url = baseUrl + "/api/v1.0/gateway/partners/" + partnerCode
                + "/orders/" + orderId
                + "?time=" + time
                + "&nonce_str=" + URLEncoder.encode(nonceStr, "UTF-8")
                + "&sign=" + sign;

            HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
            conn.setRequestMethod("PUT");
            conn.setDoOutput(true);
            conn.setConnectTimeout(15000);
            conn.setReadTimeout(30000);
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setRequestProperty("Accept", "application/json");

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

            log.info("Lakala 创建订单返回: code={}, body={}", code, resp);

            JsonNode root = om.readTree(resp.toString());
            Map<String, Object> result = new HashMap<>();
            result.put("success", "SUCCESS".equals(root.path("return_code").asText()));
            result.put("resultCode", root.path("result_code").asText(""));
            result.put("orderId", root.path("order_id").asText(""));
            result.put("partnerOrderId", root.path("partner_order_id").asText(""));
            result.put("codeUrl", root.path("code_url").asText(""));
            result.put("qrcodeImg", root.path("qrcode_img").asText(""));
            result.put("payUrl", root.path("pay_url").asText(""));
            result.put("channel", root.path("channel").asText(""));
            if (!Boolean.TRUE.equals(result.get("success"))) {
                result.put("message", root.path("return_msg").asText("创建失败"));
            }
            return result;
        } catch (Exception e) {
            log.error("Lakala 创建订单异常", e);
            return Map.of("success", false, "message", e.getMessage());
        }
    }

    /**
     * 查询订单状态
     */
    public Map<String, Object> queryOrder(String orderId) {
        if (!enabled) {
            return Map.of("success", false, "message", "Lakala 未启用");
        }
        try {
            long time = System.currentTimeMillis();
            String nonceStr = generateNonce();
            String sign = buildSign(time, nonceStr);

            String url = baseUrl + "/api/v1.0/gateway/partners/" + partnerCode
                + "/orders/" + orderId
                + "?time=" + time
                + "&nonce_str=" + URLEncoder.encode(nonceStr, "UTF-8")
                + "&sign=" + sign;

            HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(15000);
            conn.setRequestProperty("Accept", "application/json");

            StringBuilder resp = new StringBuilder();
            try (BufferedReader br = new BufferedReader(
                    new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                while ((line = br.readLine()) != null) resp.append(line);
            }

            log.info("Lakala 查询订单返回: {}", resp);

            JsonNode root = om.readTree(resp.toString());
            Map<String, Object> result = new HashMap<>();
            result.put("success", "SUCCESS".equals(root.path("return_code").asText()));
            result.put("resultCode", root.path("result_code").asText(""));
            result.put("channelOrderId", root.path("channel_order_id").asText(""));
            result.put("totalFee", root.path("total_fee").asLong(0));
            result.put("payTime", root.path("pay_time").asText(""));
            result.put("channel", root.path("channel").asText(""));
            return result;
        } catch (Exception e) {
            log.error("Lakala 查询订单异常", e);
            return Map.of("success", false, "message", e.getMessage());
        }
    }

    /**
     * 申请退款
     */
    public Map<String, Object> refund(String orderId, String refundId, long fee) {
        try {
            long time = System.currentTimeMillis();
            String nonceStr = generateNonce();
            String sign = buildSign(time, nonceStr);

            Map<String, Object> body = new HashMap<>();
            body.put("fee", fee);
            String json = om.writeValueAsString(body);

            String url = baseUrl + "/api/v1.0/gateway/partners/" + partnerCode
                + "/orders/" + orderId + "/refunds/" + refundId
                + "?time=" + time
                + "&nonce_str=" + URLEncoder.encode(nonceStr, "UTF-8")
                + "&sign=" + sign;

            HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
            conn.setRequestMethod("PUT");
            conn.setDoOutput(true);
            conn.setConnectTimeout(15000);
            conn.setReadTimeout(30000);
            conn.setRequestProperty("Content-Type", "application/json");

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

            log.info("Lakala 退款返回: code={}, body={}", code, resp);

            JsonNode root = om.readTree(resp.toString());
            Map<String, Object> result = new HashMap<>();
            result.put("success", "SUCCESS".equals(root.path("return_code").asText()));
            result.put("resultCode", root.path("result_code").asText(""));
            return result;
        } catch (Exception e) {
            log.error("Lakala 退款异常", e);
            return Map.of("success", false, "message", e.getMessage());
        }
    }

    /**
     * 验证回调签名
     */
    public boolean verifyNotify(Map<String, String> params) {
        try {
            String time = params.get("time");
            String nonceStr = params.get("nonce_str");
            String receivedSign = params.get("sign");
            if (time == null || nonceStr == null || receivedSign == null) return false;

            String expected = buildSign(Long.parseLong(time), nonceStr);
            return expected.equalsIgnoreCase(receivedSign);
        } catch (Exception e) {
            log.error("Lakala 回调验签失败", e);
            return false;
        }
    }

    /**
     * 签名算法：SHA256(partner_code&time&nonce_str&credential_code)
     */
    private String buildSign(long time, String nonceStr) {
        try {
            String validString = partnerCode + "&" + time + "&" + nonceStr + "&" + credentialCode;
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(validString.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : digest) sb.append(String.format("%02x", b));
            return sb.toString().toLowerCase();
        } catch (Exception e) {
            throw new RuntimeException("签名失败", e);
        }
    }

    private String generateNonce() {
        String chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        StringBuilder sb = new StringBuilder();
        SecureRandom r = new SecureRandom();
        for (int i = 0; i < 20; i++) sb.append(chars.charAt(r.nextInt(chars.length())));
        return sb.toString();
    }
}
