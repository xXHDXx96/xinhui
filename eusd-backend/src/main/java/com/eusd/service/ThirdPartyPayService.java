package com.eusd.service;

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
import java.util.*;

/**
 * 第三方聚合支付（易支付 / 码支付 协议）
 * 个人开发者无需企业资质即可接入
 */
@Slf4j
@Service
public class ThirdPartyPayService {

    @Value("${thirdpay.enabled:false}") private boolean enabled;
    @Value("${thirdpay.gateway:}") private String gateway;
    @Value("${thirdpay.api-url:}") private String apiUrl;
    @Value("${thirdpay.pid:}") private String pid;
    @Value("${thirdpay.key:}") private String key;
    @Value("${thirdpay.notify-url:}") private String notifyUrl;
    @Value("${thirdpay.return-url:}") private String returnUrl;

    public boolean isEnabled() { return enabled; }

    /**
     * 生成支付跳转 URL
     * @param outTradeNo 商户订单号
     * @param amount 金额（元）
     * @param payType 支付类型：alipay / wxpay / qqpay
     * @param subject 商品名称
     */
    public String createPayUrl(String outTradeNo, BigDecimal amount,
                                String payType, String subject) {
        if (!enabled) throw new RuntimeException("第三方支付未启用");
        try {
            Map<String, String> params = new TreeMap<>();
            params.put("pid", pid);
            params.put("type", payType);
            params.put("out_trade_no", outTradeNo);
            params.put("notify_url", notifyUrl);
            params.put("return_url", returnUrl);
            params.put("name", subject);
            params.put("money", amount.setScale(2, BigDecimal.ROUND_HALF_UP).toString());

            params.put("sign", sign(params));
            params.put("sign_type", "MD5");

            StringBuilder url = new StringBuilder(apiUrl);
            url.append("?");
            for (Map.Entry<String, String> e : params.entrySet()) {
                url.append(URLEncoder.encode(e.getKey(), "UTF-8"))
                   .append("=")
                   .append(URLEncoder.encode(e.getValue(), "UTF-8"))
                   .append("&");
            }
            url.deleteCharAt(url.length() - 1);

            log.info("生成第三方支付链接: outTradeNo={}, type={}", outTradeNo, payType);
            return url.toString();
        } catch (Exception e) {
            log.error("生成支付链接异常", e);
            throw new RuntimeException("PAY_URL_FAILED", e);
        }
    }

    /**
     * 生成二维码支付（返回二维码图片地址或二维码内容）
     */
    public Map<String, String> createQrPay(String outTradeNo, BigDecimal amount,
                                            String payType, String subject) {
        if (!enabled) throw new RuntimeException("第三方支付未启用");
        try {
            Map<String, String> params = new TreeMap<>();
            params.put("pid", pid);
            params.put("type", payType);
            params.put("out_trade_no", outTradeNo);
            params.put("notify_url", notifyUrl);
            params.put("return_url", returnUrl);
            params.put("name", subject);
            params.put("money", amount.setScale(2, BigDecimal.ROUND_HALF_UP).toString());
            params.put("clientip", "127.0.0.1");
            params.put("device", "mobile");
            params.put("sign", sign(params));
            params.put("sign_type", "MD5");

            String resp = post(gateway, params);
            log.info("二维码支付返回: {}", resp);

            Map<String, String> result = new HashMap<>();
            result.put("raw", resp);
            if (resp != null && resp.contains("code_url")) {
                result.put("qrCode", extract(resp, "code_url"));
                result.put("payUrl", extract(resp, "payurl"));
            }
            return result;
        } catch (Exception e) {
            log.error("生成二维码支付异常", e);
            throw new RuntimeException("QR_PAY_FAILED", e);
        }
    }

    /**
     * 验证异步回调签名
     */
    public boolean verifyNotify(Map<String, String> params) {
        if (params == null || params.isEmpty()) return false;
        String receivedSign = params.get("sign");
        if (receivedSign == null) return false;

        Map<String, String> sorted = new TreeMap<>(params);
        sorted.remove("sign");
        sorted.remove("sign_type");

        String calcSign = sign(sorted);
        boolean ok = calcSign.equalsIgnoreCase(receivedSign);
        if (!ok) log.warn("第三方支付回调验签失败");
        return ok;
    }

    /**
     * 查询订单状态
     */
    public Map<String, String> queryOrder(String outTradeNo) {
        try {
            Map<String, String> params = new TreeMap<>();
            params.put("act", "order");
            params.put("pid", pid);
            params.put("key", key);
            params.put("out_trade_no", outTradeNo);

            String resp = post(gateway, params);
            Map<String, String> result = new HashMap<>();
            result.put("raw", resp);
            result.put("status", extract(resp, "status"));
            result.put("tradeNo", extract(resp, "trade_no"));
            return result;
        } catch (Exception e) {
            log.error("查询订单异常", e);
            return Collections.emptyMap();
        }
    }

    /**
     * MD5 签名（易支付通用规则）
     */
    private String sign(Map<String, String> params) {
        try {
            StringBuilder sb = new StringBuilder();
            for (Map.Entry<String, String> e : params.entrySet()) {
                if (e.getValue() == null || e.getValue().isEmpty()) continue;
                sb.append(e.getKey()).append("=").append(e.getValue()).append("&");
            }
            sb.append("key=").append(key);

            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] digest = md.digest(sb.toString().getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder();
            for (byte b : digest) hex.append(String.format("%02x", b));
            return hex.toString();
        } catch (Exception e) {
            throw new RuntimeException("SIGN_FAILED", e);
        }
    }

    private String post(String url, Map<String, String> params) throws Exception {
        StringBuilder form = new StringBuilder();
        for (Map.Entry<String, String> e : params.entrySet()) {
            if (form.length() > 0) form.append("&");
            form.append(URLEncoder.encode(e.getKey(), "UTF-8"))
                .append("=")
                .append(URLEncoder.encode(e.getValue() == null ? "" : e.getValue(), "UTF-8"));
        }

        HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
        conn.setRequestMethod("POST");
        conn.setDoOutput(true);
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(30000);
        conn.setRequestProperty("Content-Type",
            "application/x-www-form-urlencoded;charset=UTF-8");

        try (OutputStream os = conn.getOutputStream()) {
            os.write(form.toString().getBytes(StandardCharsets.UTF_8));
        }

        StringBuilder resp = new StringBuilder();
        try (BufferedReader br = new BufferedReader(
                new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
            String line;
            while ((line = br.readLine()) != null) resp.append(line);
        }
        return resp.toString();
    }

    private String extract(String json, String key) {
        try {
            String search = "\"" + key + "\"";
            int i = json.indexOf(search);
            if (i < 0) return "";
            int c = json.indexOf(":", i);
            int s = json.indexOf("\"", c);
            int e = json.indexOf("\"", s + 1);
            if (s >= 0 && e > s) return json.substring(s + 1, e);
            int s2 = c + 1;
            while (s2 < json.length() && (json.charAt(s2) == ' ' || json.charAt(s2) == '"')) s2++;
            int e2 = s2;
            while (e2 < json.length() && json.charAt(e2) != ',' && json.charAt(e2) != '}') e2++;
            return json.substring(s2, e2).trim().replace("\"", "");
        } catch (Exception e) {
            return "";
        }
    }
}
