package com.eusd.controller;

import com.eusd.service.RechargeFlowService;
import com.eusd.service.WechatPayService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/wechat")
@RequiredArgsConstructor
public class WechatPayController {

    private final WechatPayService wechatPayService;
    private final RechargeFlowService rechargeFlowService;

    /**
     * 预签约：获取跳转小程序所需参数
     */
    @PostMapping("/pre-sign")
    public Map<String, Object> preSign(@RequestParam String userId) {
        UUID uid = UUID.fromString(userId);
        String outContractCode = "WX_" + System.currentTimeMillis()
            + "_" + uid.toString().substring(0, 8);

        Map<String, String> signParams = wechatPayService.createPreSign(userId, outContractCode);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("signParams", signParams);
        result.put("outContractCode", outContractCode);
        return result;
    }

    /**
     * 主动扣款
     */
    @PostMapping("/deduct")
    public Map<String, Object> deduct(@RequestParam String planId,
                                       @RequestParam String contractId,
                                       @RequestParam String outTradeNo,
                                       @RequestParam String amount,
                                       @RequestParam(defaultValue = "eUSD Card 充值") String description) {
        BigDecimal amt = new BigDecimal(amount);
        boolean success = wechatPayService.deduct(planId, contractId, outTradeNo, amt, description);

        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        return result;
    }

    /**
     * 查询订单状态
     */
    @GetMapping("/query/{outTradeNo}")
    public Map<String, Object> query(@PathVariable String outTradeNo) {
        String state = wechatPayService.queryOrder(outTradeNo);
        Map<String, Object> result = new HashMap<>();
        result.put("tradeState", state);
        return result;
    }

    /**
     * 异步回调（微信服务器调用）
     */
    @PostMapping("/notify")
    public Map<String, String> notify(@RequestBody String body,
                                       @RequestHeader(value = "Wechatpay-Signature", required = false) String signature,
                                       @RequestHeader(value = "Wechatpay-Serial", required = false) String serial,
                                       @RequestHeader(value = "Wechatpay-Timestamp", required = false) String timestamp,
                                       @RequestHeader(value = "Wechatpay-Nonce", required = false) String nonce) {
        log.info("收到微信回调");

        Map<String, String> response = new HashMap<>();
        try {
            Map<String, Object> resource = wechatPayService.parseNotification(
                body, signature, serial, timestamp, nonce);

            String eventType = (String) resource.get("event_type");
            if (eventType == null) eventType = (String) resource.get("eventType");

            if ("TRANSACTION.SUCCESS".equals(eventType)
                || "papay.transaction.success".equals(eventType)) {
                String outTradeNo = (String) resource.get("out_trade_no");
                String transactionId = (String) resource.get("transaction_id");
                rechargeFlowService.handleRechargeSuccess(outTradeNo, transactionId);
            } else if ("SIGN".equals(eventType)
                || "papay.contract.sign".equals(eventType)) {
                wechatPayService.handleSignNotify(resource);
            }

            response.put("code", "SUCCESS");
            response.put("message", "OK");
            return response;
        } catch (Exception e) {
            log.error("处理微信回调异常", e);
            response.put("code", "FAIL");
            response.put("message", e.getMessage());
            return response;
        }
    }

    /**
     * 解约
     */
    @PostMapping("/terminate")
    public Map<String, Object> terminate(@RequestParam String planId,
                                          @RequestParam String outContractCode) {
        boolean success = wechatPayService.terminateContract(planId, outContractCode);
        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        return result;
    }
}
