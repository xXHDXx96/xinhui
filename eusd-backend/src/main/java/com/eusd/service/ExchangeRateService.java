package com.eusd.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;

@Slf4j
@Service
@RequiredArgsConstructor
public class ExchangeRateService {

    @Value("${exchange.api-url}")
    private String apiUrl;

    @Value("${exchange.fallback-rate}")
    private String fallbackRateStr;

    @Value("${exchange.fee-rate}")
    private String feeRateStr;

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * 获取 CNY → USD 实时汇率（带缓存）
     */
    @Cacheable(value = "cnyUsdRate", unless = "#result == null")
    public BigDecimal getCnyToUsdRate() {
        try {
            String response = httpGet(apiUrl);
            JsonNode root = objectMapper.readTree(response);
            JsonNode rates = root.get("rates");
            if (rates != null && rates.has("USD")) {
                BigDecimal rate = new BigDecimal(rates.get("USD").asText());
                log.info("获取实时汇率 CNY→USD: {}", rate);
                return rate;
            }
        } catch (Exception e) {
            log.warn("汇率 API 调用失败，使用兜底汇率: {}", e.getMessage());
        }
        return new BigDecimal(fallbackRateStr);
    }

    /**
     * USD → CNY 反向汇率
     */
    public BigDecimal getUsdToCnyRate() {
        BigDecimal cnyToUsd = getCnyToUsdRate();
        if (cnyToUsd.compareTo(BigDecimal.ZERO) == 0) {
            return BigDecimal.ONE.divide(new BigDecimal(fallbackRateStr), 8, RoundingMode.HALF_UP);
        }
        return BigDecimal.ONE.divide(cnyToUsd, 8, RoundingMode.HALF_UP);
    }

    /**
     * 通用汇率对查询
     */
    public BigDecimal getRate(String fromAsset, String toAsset) {
        if (fromAsset.equals(toAsset)) return BigDecimal.ONE;
        if ("CNY".equals(fromAsset) && "USD".equals(toAsset)) return getCnyToUsdRate();
        if ("USD".equals(fromAsset) && "CNY".equals(toAsset)) return getUsdToCnyRate();
        if (isStableCoin(fromAsset) && isStableCoin(toAsset)) return BigDecimal.ONE;
        log.warn("未支持的汇率对: {} → {}", fromAsset, toAsset);
        return BigDecimal.ONE;
    }

    /**
     * 兑换报价
     */
    public ExchangeQuote quote(String fromAsset, String toAsset, BigDecimal amount) {
        BigDecimal rate = getRate(fromAsset, toAsset);
        BigDecimal gross = amount.multiply(rate).setScale(8, RoundingMode.DOWN);

        BigDecimal fee = BigDecimal.ZERO;
        BigDecimal net = gross;

        if (isStableCoin(fromAsset) && isStableCoin(toAsset) && !fromAsset.equals(toAsset)) {
            fee = gross.multiply(new BigDecimal(feeRateStr)).setScale(8, RoundingMode.DOWN);
            net = gross.subtract(fee);
        }

        return ExchangeQuote.builder()
            .fromAsset(fromAsset)
            .toAsset(toAsset)
            .fromAmount(amount)
            .toAmount(net)
            .grossAmount(gross)
            .rate(rate)
            .fee(fee)
            .build();
    }

    /**
     * 每 5 分钟清缓存
     */
    @Scheduled(fixedRate = 300000)
    @CacheEvict(value = "cnyUsdRate", allEntries = true)
    public void refresh() {
        log.debug("汇率缓存已清空，下次请求将重新拉取");
    }

    private boolean isStableCoin(String asset) {
        return "USDT".equals(asset) || "USDC".equals(asset) || "USD".equals(asset);
    }

    private String httpGet(String urlStr) throws Exception {
        HttpURLConnection conn = (HttpURLConnection) new URL(urlStr).openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(10000);

        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) sb.append(line);
        }
        return sb.toString();
    }

    /**
     * 兑换报价内部类
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExchangeQuote {
        private String fromAsset;
        private String toAsset;
        private BigDecimal fromAmount;
        private BigDecimal toAmount;
        private BigDecimal grossAmount;
        private BigDecimal rate;
        private BigDecimal fee;
    }
}
