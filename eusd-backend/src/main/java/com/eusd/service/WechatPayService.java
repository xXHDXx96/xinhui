package com.eusd.service;

import com.eusd.config.WechatPayConfig;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.wechat.pay.java.core.RSAAutoCertificateConfig;
import com.wechat.pay.java.core.http.*;
import com.wechat.pay.java.core.notification.NotificationParser;
import com.wechat.pay.java.core.notification.RequestParam;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
public class WechatPayService {

    private final WechatPayConfig cfg;
    private final RSAAutoCertificateConfig rsaConfig;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public WechatPayService(WechatPayConfig cfg,
                            ObjectProvider<RSAAutoCertificateConfig> provider) {
        this.cfg = cfg;
        this.rsaConfig = provider.getIfAvailable();
        if (this.rsaConfig == null) {
            log.warn("微信支付未启用（wechat.enabled=false），相关接口将不可用");
        }
    }

    private void ensureEnabled() {
        if (rsaConfig == null) {
            throw new RuntimeException("微信支付未启用，请先在 application.yml 中配置 wechat.enabled=true 及真实密钥");
        }
    }

    private HttpClient buildClient() {
        return new DefaultHttpClientBuilder().config(rsaConfig).build();
    }

    private RequestBody jsonBody(Object obj) throws Exception {
        return new JsonRequestBody.Builder().body(objectMapper.writeValueAsString(obj)).build();
    }

    /**
     * 预签约（获取小程序跳转参数）
     */
    @SuppressWarnings({"unchecked", "rawtypes"})
    public Map<String, String> createPreSign(String userId, String outContractCode) {
        ensureEnabled();
        try {
            Map<String, Object> body = new HashMap<>();
            body.put("appid", cfg.getAppId());
            body.put("mchid", cfg.getMchId());
            body.put("plan_id", "your_plan_id");
            body.put("out_contract_code", outContractCode);
            body.put("contract_display_account",
                "用户" + userId.substring(Math.max(0, userId.length() - 4)));
            body.put("notify_url", cfg.getNotifyUrl());
            body.put("version", "1.0");

            HttpRequest request = new HttpRequest.Builder()
                .httpMethod(HttpMethod.POST)
                .url("https://api.mch.weixin.qq.com/v3/papay/sign/contracts/pre-entrust-sign/mini-program")
                .body(jsonBody(body))
                .build();

            HttpResponse<Map> response = buildClient().execute(request, Map.class);
            Map<String, Object> result = response.getServiceResponse();
            if (result == null) {
                throw new RuntimeException("微信预签约返回为空");
            }

            Map<String, String> out = new HashMap<>();
            out.put("prepayId", String.valueOf(result.get("prepay_id")));
            out.put("miniProgramAppId", String.valueOf(result.get("mini_program_appid")));
            out.put("sign", String.valueOf(result.get("sign")));
            out.put("timestamp", String.valueOf(result.get("timestamp")));
            out.put("nonceStr", String.valueOf(result.get("nonce_str")));
            out.put("package", String.valueOf(result.get("package")));
            log.info("微信预签约成功: userId={}", userId);
            return out;
        } catch (Exception e) {
            log.error("微信预签约异常: userId={}", userId, e);
            throw new RuntimeException("WECHAT_PRE_SIGN_FAILED", e);
        }
    }

    /**
     * 申请扣款（免密支付）
     */
    @SuppressWarnings({"unchecked", "rawtypes"})
    public boolean deduct(String planId, String contractId, String outTradeNo,
                          BigDecimal amount, String description) {
        ensureEnabled();
        try {
            int amountCents = amount.multiply(new BigDecimal("100")).intValue();

            Map<String, Object> body = new HashMap<>();
            body.put("appid", cfg.getAppId());
            body.put("mchid", cfg.getMchId());
            body.put("description", description);
            body.put("out_trade_no", outTradeNo);
            body.put("plan_id", planId);
            body.put("contract_id", contractId);

            Map<String, Object> amt = new HashMap<>();
            amt.put("total", amountCents);
            amt.put("currency", "CNY");
            body.put("amount", amt);

            HttpRequest request = new HttpRequest.Builder()
                .httpMethod(HttpMethod.POST)
                .url("https://api.mch.weixin.qq.com/v3/papay/transactions")
                .body(jsonBody(body))
                .build();

            buildClient().execute(request, Map.class);
            log.info("微信扣款成功: outTradeNo={}, amount={}", outTradeNo, amount);
            return true;
        } catch (Exception e) {
            log.error("微信扣款异常: outTradeNo={}", outTradeNo, e);
            return false;
        }
    }

    /**
     * 查询订单状态
     */
    @SuppressWarnings({"unchecked", "rawtypes"})
    public String queryOrder(String outTradeNo) {
        ensureEnabled();
        try {
            HttpRequest request = new HttpRequest.Builder()
                .httpMethod(HttpMethod.GET)
                .url("https://api.mch.weixin.qq.com/v3/papay/transactions/out-trade-no/" + outTradeNo)
                .build();

            HttpResponse<Map> response = buildClient().execute(request, Map.class);
            Map<String, Object> result = response.getServiceResponse();
            if (result == null) return "UNKNOWN";
            return String.valueOf(result.get("trade_state"));
        } catch (Exception e) {
            log.error("查询微信订单异常", e);
            return "UNKNOWN";
        }
    }

    /**
     * 解约
     */
    @SuppressWarnings({"unchecked", "rawtypes"})
    public boolean terminateContract(String planId, String outContractCode) {
        ensureEnabled();
        try {
            Map<String, Object> body = new HashMap<>();
            body.put("contract_termination_remark", "用户申请解约");

            String url = String.format(
                "https://api.mch.weixin.qq.com/v3/papay/sign/contracts/plan-id/%s/out-contract-code/%s/terminate",
                planId, outContractCode);

            HttpRequest request = new HttpRequest.Builder()
                .httpMethod(HttpMethod.POST)
                .url(url)
                .body(jsonBody(body))
                .build();

            buildClient().execute(request, Map.class);
            log.info("微信解约成功: planId={}", planId);
            return true;
        } catch (Exception e) {
            log.error("微信解约异常", e);
            return false;
        }
    }

    /**
     * 解析回调通知
     */
    @SuppressWarnings({"unchecked", "rawtypes"})
    public Map<String, Object> parseNotification(String body, String signature,
                                                  String serial, String timestamp, String nonce) {
        ensureEnabled();
        try {
            RequestParam requestParam = new RequestParam.Builder()
                .serialNumber(serial)
                .nonce(nonce)
                .signature(signature)
                .timestamp(timestamp)
                .body(body)
                .build();

            NotificationParser parser = new NotificationParser(rsaConfig);
            Map<String, Object> result = parser.parse(requestParam, Map.class);
            log.info("微信回调解析成功: eventType={}", result.get("event_type"));
            return result;
        } catch (Exception e) {
            log.error("微信回调验签失败", e);
            throw new RuntimeException("WECHAT_NOTIFY_VERIFY_FAILED", e);
        }
    }

    /**
     * 处理签约成功回调
     */
    public void handleSignNotify(Map<String, Object> resource) {
        Object resObj = resource.get("resource");
        if (resObj instanceof Map) {
            Map<?, ?> res = (Map<?, ?>) resObj;
            log.info("微信签约回调: contractId={}, state={}",
                res.get("contract_id"), res.get("contract_state"));
        }
    }
}
