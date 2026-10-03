package com.eusd.service;

import com.eusd.config.UnionPayConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.math.BigDecimal;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HashMap;
import java.util.Map;
import java.util.TreeMap;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class UnionPayService {

    private final UnionPayConfig cfg;

    /**
     * 获取签约 TN，前端用此唤起云闪付 App 完成签约
     */
    public String getSignTn(String userId, String contractCode) {
        try {
            Map<String, String> p = new TreeMap<>();
            p.put("version", cfg.getVersion());
            p.put("encoding", cfg.getCharset());
            p.put("signMethod", cfg.getSignMethod());
            p.put("txnType", "72");
            p.put("txnSubType", "01");
            p.put("bizType", "000902");
            p.put("channelType", "07");
            p.put("merId", cfg.getMerId());
            p.put("accessType", "0");
            p.put("planId", cfg.getPlanId());
            p.put("contractCode", contractCode);
            p.put("backUrl", cfg.getBackUrl());
            p.put("frontUrl", cfg.getFrontUrl());
            p.put("signature", sign(p));

            Map<String, String> r = parse(post(cfg.getGatewayUrl(), p));
            if ("00".equals(r.get("respCode"))) {
                log.info("云闪付 TN 生成成功: userId={}, tn={}", userId, r.get("tn"));
                return r.get("tn");
            }
            log.warn("云闪付 TN 生成失败: {}", r.get("respMsg"));
            throw new RuntimeException("UNIONPAY_SIGN_TN_FAILED: " + r.get("respMsg"));
        } catch (Exception e) {
            log.error("云闪付签约异常: userId={}", userId, e);
            throw new RuntimeException("UNIONPAY_SIGN_EXCEPTION", e);
        }
    }

    /**
     * 后台扣款（凭 contractId 发起）
     */
    public boolean deduct(String contractId, String orderNo,
                          BigDecimal amount, String description) {
        try {
            long amountFen = amount.multiply(new BigDecimal("100")).longValue();

            Map<String, String> p = new TreeMap<>();
            p.put("version", cfg.getVersion());
            p.put("encoding", cfg.getCharset());
            p.put("signMethod", cfg.getSignMethod());
            p.put("txnType", "72");
            p.put("txnSubType", "02");
            p.put("bizType", "000902");
            p.put("channelType", "07");
            p.put("merId", cfg.getMerId());
            p.put("accessType", "0");
            p.put("contractId", contractId);
            p.put("orderId", orderNo);
            p.put("txnAmt", String.valueOf(amountFen));
            p.put("currencyCode", "156");
            p.put("orderDesc", description);
            p.put("backUrl", cfg.getBackUrl());
            p.put("signature", sign(p));

            Map<String, String> r = parse(post(cfg.getGatewayUrl(), p));
            String respCode = r.get("respCode");
            if ("00".equals(respCode) || "03".equals(respCode)
                || "04".equals(respCode) || "05".equals(respCode)) {
                log.info("云闪付扣款请求已发送: orderNo={}, respCode={}", orderNo, respCode);
                return true;
            }
            log.warn("云闪付扣款失败: orderNo={}, respCode={}, msg={}",
                orderNo, respCode, r.get("respMsg"));
            return false;
        } catch (Exception e) {
            log.error("云闪付扣款异常: orderNo={}", orderNo, e);
            return false;
        }
    }

    /**
     * 查询订单状态
     */
    public Map<String, String> queryOrder(String orderNo) {
        try {
            Map<String, String> p = new TreeMap<>();
            p.put("version", cfg.getVersion());
            p.put("encoding", cfg.getCharset());
            p.put("signMethod", cfg.getSignMethod());
            p.put("txnType", "00");
            p.put("txnSubType", "00");
            p.put("bizType", "000000");
            p.put("merId", cfg.getMerId());
            p.put("accessType", "0");
            p.put("orderId", orderNo);
            p.put("signature", sign(p));
            return parse(post(cfg.getGatewayUrl(), p));
        } catch (Exception e) {
            log.error("云闪付查询异常: orderNo={}", orderNo, e);
            return new HashMap<>();
        }
    }

    /**
     * 解约
     */
    public boolean terminateContract(String contractId) {
        try {
            Map<String, String> p = new TreeMap<>();
            p.put("version", cfg.getVersion());
            p.put("encoding", cfg.getCharset());
            p.put("signMethod", cfg.getSignMethod());
            p.put("txnType", "72");
            p.put("txnSubType", "03");
            p.put("bizType", "000902");
            p.put("channelType", "07");
            p.put("merId", cfg.getMerId());
            p.put("accessType", "0");
            p.put("contractId", contractId);
            p.put("signature", sign(p));

            Map<String, String> r = parse(post(cfg.getGatewayUrl(), p));
            if ("00".equals(r.get("respCode"))) {
                log.info("云闪付解约成功: contractId={}", contractId);
                return true;
            }
            log.warn("云闪付解约失败: contractId={}, msg={}", contractId, r.get("respMsg"));
            return false;
        } catch (Exception e) {
            log.error("云闪付解约异常: contractId={}", contractId, e);
            return false;
        }
    }

    /**
     * 处理签约异步通知
     */
    public void handleSignNotify(Map<String, String> params) {
        String contractId = params.get("contractId");
        String openId = params.get("openId");
        String contractCode = params.get("contractCode");
        String respCode = params.get("respCode");
        log.info("云闪付签约回调: contractId={}, openId={}, contractCode={}, respCode={}",
            contractId, openId, contractCode, respCode);
    }

    /**
     * 处理扣款异步通知
     */
    public void handlePayNotify(Map<String, String> params) {
        String orderId = params.get("orderId");
        String respCode = params.get("respCode");
        String queryId = params.get("queryId");
        log.info("云闪付扣款回调: orderId={}, respCode={}, queryId={}",
            orderId, respCode, queryId);
    }

    /**
     * 生成签名（占位：生产需替换为证书私钥 RSA 签名）
     */
    private String sign(Map<String, String> p) throws Exception {
        String s = p.entrySet().stream()
            .filter(e -> e.getValue() != null && !e.getValue().isEmpty())
            .map(e -> e.getKey() + "=" + e.getValue())
            .collect(Collectors.joining("&"));
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] d = md.digest(s.getBytes(StandardCharsets.UTF_8));
        StringBuilder sb = new StringBuilder();
        for (byte b : d) sb.append(String.format("%02x", b));
        return sb.toString();
    }

    private String post(String url, Map<String, String> p) throws Exception {
        StringBuilder f = new StringBuilder();
        for (Map.Entry<String, String> e : p.entrySet()) {
            if (f.length() > 0) f.append("&");
            f.append(URLEncoder.encode(e.getKey(), "UTF-8")).append("=")
             .append(URLEncoder.encode(e.getValue() == null ? "" : e.getValue(), "UTF-8"));
        }

        HttpURLConnection c = (HttpURLConnection) new URL(url).openConnection();
        c.setRequestMethod("POST");
        c.setDoOutput(true);
        c.setConnectTimeout(10000);
        c.setReadTimeout(30000);
        c.setRequestProperty("Content-Type",
            "application/x-www-form-urlencoded;charset=UTF-8");

        try (OutputStream os = c.getOutputStream()) {
            os.write(f.toString().getBytes(StandardCharsets.UTF_8));
        }

        StringBuilder r = new StringBuilder();
        try (BufferedReader br = new BufferedReader(
                new InputStreamReader(c.getInputStream(), StandardCharsets.UTF_8))) {
            String l;
            while ((l = br.readLine()) != null) r.append(l);
        }
        return r.toString();
    }

    private Map<String, String> parse(String s) {
        Map<String, String> m = new HashMap<>();
        if (s == null || s.isEmpty()) return m;
        for (String pair : s.split("&")) {
            int i = pair.indexOf('=');
            if (i > 0) {
                try {
                    m.put(pair.substring(0, i),
                        URLDecoder.decode(pair.substring(i + 1), "UTF-8"));
                } catch (Exception ignored) {}
            }
        }
        return m;
    }
}
