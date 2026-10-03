package com.eusd.service;

import com.eusd.entity.KhqrOrder;
import com.eusd.repository.KhqrOrderRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import kh.gov.nbc.bakong_khqr.BakongKHQR;
import kh.gov.nbc.bakong_khqr.model.KHQRCurrency;
import kh.gov.nbc.bakong_khqr.model.KHQRData;
import kh.gov.nbc.bakong_khqr.model.KHQRResponse;
import kh.gov.nbc.bakong_khqr.model.MerchantInfo;
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
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class KHQRService {

    private final KhqrOrderRepository khqrRepo;
    private final ObjectMapper om = new ObjectMapper();

    @Value("${bakong.enabled:false}") private boolean enabled;
    @Value("${bakong.token:}") private String bakongToken;
    @Value("${bakong.account:lantonpay@lant}") private String bakongAccount;
    @Value("${bakong.merchant-name:XI WEN}") private String merchantName;
    @Value("${bakong.merchant-city:PHNOM PENH}") private String merchantCity;
    @Value("${bakong.merchant-id:969114467}") private String merchantId;
    @Value("${bakong.acquiring-bank:LantonPay}") private String acquiringBank;
    @Value("${bakong.currency:USD}") private String currency;
    @Value("${bakong.api-url:https://api-bakong.nbc.gov.kh}") private String apiUrl;

    public boolean isEnabled() { return enabled; }

    public Map<String, Object> createStaticQR(UUID userId) {
        if (!enabled) {
            return Map.of("success", false, "message", "KHQR 未启用");
        }
        try {
            String orderNo = "KHQR_" + System.currentTimeMillis()
                + "_" + UUID.randomUUID().toString().substring(0, 6);

            MerchantInfo info = new MerchantInfo();
            info.setBakongAccountId(bakongAccount);
            info.setMerchantName(merchantName);
            info.setMerchantCity(merchantCity);
            info.setMerchantId(merchantId);
            info.setAcquiringBank(acquiringBank);
            info.setMerchantCategoryCode("5999");
            info.setCurrency("KHR".equalsIgnoreCase(currency) ? KHQRCurrency.KHR : KHQRCurrency.USD);
            // 不设置 amount → 静态码
            info.setBillNumber(orderNo);

            KHQRResponse<KHQRData> response = BakongKHQR.generateMerchant(info);

            if (response == null) {
                return Map.of("success", false, "message", "SDK 返回 null");
            }
            if (response.getData() == null) {
                String err = response.getKHQRStatus() == null ? "unknown"
                    : response.getKHQRStatus().toString();
                log.error("KHQR SDK 错误: {}", err);
                return Map.of("success", false, "message", "SDK 错误: " + err);
            }

            String qrString = response.getData().getQr();
            String md5 = response.getData().getMd5();
            if (md5 == null || md5.isEmpty()) md5 = md5(qrString);

            KhqrOrder order = KhqrOrder.builder()
                .userId(userId)
                .orderNo(orderNo)
                .md5(md5)
                .qrString(qrString)
                .amount(BigDecimal.ZERO)
                .currency(currency)
                .status("CREATED")
                .build();
            khqrRepo.save(order);

            log.info("KHQR 生成成功: orderNo={}, currency={}, md5={}",
                orderNo, currency, md5);

            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("orderNo", orderNo);
            result.put("md5", md5);
            result.put("qrString", qrString);
            return result;
        } catch (Exception e) {
            log.error("生成 KHQR 异常", e);
            return Map.of("success", false, "message", e.getMessage());
        }
    }

    public Map<String, Object> checkPayment(String md5) {
        Map<String, Object> result = new HashMap<>();
        if (!enabled) {
            result.put("status", "UNPAID");
            return result;
        }
        try {
            String url = apiUrl + "/v1/check_transaction_by_md5";
            Map<String, String> body = new HashMap<>();
            body.put("md5", md5);
            String json = om.writeValueAsString(body);

            HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
            conn.setRequestMethod("POST");
            conn.setDoOutput(true);
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(15000);
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setRequestProperty("Authorization", "Bearer " + bakongToken);

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

            log.info("KHQR 查询返回: {}", resp);

            JsonNode root = om.readTree(resp.toString());
            int responseCode = root.path("responseCode").asInt(-1);
            if (responseCode == 0) {
                String status = root.path("data").path("status").asText("UNPAID");
                String amount = root.path("data").path("amount").asText("0");

                if ("PAID".equals(status)) {
                    khqrRepo.findByMd5(md5).ifPresent(o -> {
                        o.setStatus("PAID");
                        o.setAmount(new BigDecimal(amount));
                        o.setPaidAt(LocalDateTime.now());
                        khqrRepo.save(o);
                    });
                }

                result.put("status", status);
                result.put("amount", amount);
                return result;
            }
            result.put("status", "UNPAID");
            return result;
        } catch (Exception e) {
            log.error("查询 KHQR 支付状态异常", e);
            result.put("status", "UNPAID");
            return result;
        }
    }

    private String md5(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] digest = md.digest(input.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : digest) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
