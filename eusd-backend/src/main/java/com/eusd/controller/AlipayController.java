package com.eusd.controller;

import com.eusd.entity.RechargeOrder;
import com.eusd.service.AlipayService;
import com.eusd.service.RechargeFlowService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/alipay")
@RequiredArgsConstructor
public class AlipayController {

    private final AlipayService alipayService;
    private final RechargeFlowService rechargeFlowService;

    /**
     * 生成签约链接
     * 前端调用后拿到 signUrl，用 WebView 打开或跳转支付宝
     */
    @PostMapping("/sign-url")
    public Map<String, Object> createSignUrl(@RequestParam String userId) {
        UUID uid = UUID.fromString(userId);
        String externalAgreementNo = "AGREE_" + System.currentTimeMillis()
            + "_" + uid.toString().substring(0, 8);
        String signUrl = alipayService.createSignUrl(uid, externalAgreementNo);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("signUrl", signUrl);
        result.put("externalAgreementNo", externalAgreementNo);
        return result;
    }

    /**
     * 主动扣款（免密代扣）
     */
    @PostMapping("/deduct")
    public Map<String, Object> deduct(@RequestParam String agreementNo,
                                       @RequestParam String outTradeNo,
                                       @RequestParam String amount,
                                       @RequestParam(defaultValue = "eUSD Card 充值") String subject) {
        BigDecimal amt = new BigDecimal(amount);
        boolean success = alipayService.deduct(agreementNo, outTradeNo, amt, subject);

        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        return result;
    }

    /**
     * 异步回调（支付宝服务器调用）
     */
    @PostMapping("/notify")
    public String notify(@RequestParam Map<String, String> params) {
        log.info("收到支付宝回调: {}", params);

        if (!alipayService.verifyNotify(params)) {
            log.warn("支付宝回调验签失败");
            return "fail";
        }

        try {
            if (params.containsKey("trade_status")) {
                String tradeStatus = params.get("trade_status");
                String outTradeNo = params.get("out_trade_no");
                String tradeNo = params.get("trade_no");

                if ("TRADE_SUCCESS".equals(tradeStatus) || "TRADE_FINISHED".equals(tradeStatus)) {
                    rechargeFlowService.handleRechargeSuccess(outTradeNo, tradeNo);
                } else if ("TRADE_CLOSED".equals(tradeStatus)) {
                    rechargeFlowService.handleRechargeFailed(outTradeNo, "TRADE_CLOSED");
                }
            } else if (params.containsKey("external_agreement_no")) {
                alipayService.handleSignNotify(params);
            }

            return "success";
        } catch (Exception e) {
            log.error("处理支付宝回调异常", e);
            return "fail";
        }
    }

    /**
     * 同步返回（用户签约完成后跳转回）
     */
    @GetMapping("/return")
    public Map<String, Object> returnUrl(@RequestParam Map<String, String> params) {
        log.info("支付宝同步返回: {}", params);
        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("message", "签约完成，请返回 App");
        return result;
    }

    /**
     * 解约
     */
    @PostMapping("/unsign")
    public Map<String, Object> unsign(@RequestParam String agreementNo,
                                       @RequestParam String externalAgreementNo) {
        boolean success = alipayService.unsign(agreementNo, externalAgreementNo);
        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        return result;
    }
}
