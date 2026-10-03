package com.eusd.controller;

import com.eusd.service.RechargeFlowService;
import com.eusd.service.UnionPayService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/unionpay")
@RequiredArgsConstructor
public class UnionPayController {

    private final UnionPayService unionPayService;
    private final RechargeFlowService rechargeFlowService;

    /**
     * 获取签约 TN，前端用 TN 唤起云闪付 App 签约
     */
    @PostMapping("/sign-tn")
    public Map<String, Object> getSignTn(@RequestParam String userId) {
        UUID uid = UUID.fromString(userId);
        String contractCode = "UP_" + System.currentTimeMillis()
            + "_" + uid.toString().substring(0, 8);

        String tn = unionPayService.getSignTn(userId, contractCode);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("tn", tn);
        result.put("contractCode", contractCode);
        return result;
    }

    /**
     * 主动扣款
     */
    @PostMapping("/deduct")
    public Map<String, Object> deduct(@RequestParam String contractId,
                                       @RequestParam String orderNo,
                                       @RequestParam String amount,
                                       @RequestParam(defaultValue = "eUSD Card 充值") String description) {
        BigDecimal amt = new BigDecimal(amount);
        boolean success = unionPayService.deduct(contractId, orderNo, amt, description);

        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        return result;
    }

    /**
     * 查询订单
     */
    @GetMapping("/query/{orderNo}")
    public Map<String, String> query(@PathVariable String orderNo) {
        return unionPayService.queryOrder(orderNo);
    }

    /**
     * 异步回调（银联服务器调用）
     */
    @PostMapping("/notify")
    public String notify(@RequestParam Map<String, String> params) {
        log.info("收到云闪付回调: {}", params);

        try {
            String txnType = params.get("txnType");
            String txnSubType = params.get("txnSubType");

            if ("72".equals(txnType) && "01".equals(txnSubType)) {
                unionPayService.handleSignNotify(params);
            }

            if ("72".equals(txnType) && "02".equals(txnSubType)) {
                String respCode = params.get("respCode");
                String orderId = params.get("orderId");
                String queryId = params.get("queryId");

                if ("00".equals(respCode)) {
                    rechargeFlowService.handleRechargeSuccess(orderId, queryId);
                } else {
                    rechargeFlowService.handleRechargeFailed(orderId, params.get("respMsg"));
                }
            }

            if ("72".equals(txnType) && "03".equals(txnSubType)) {
                log.info("云闪付解约通知: contractId={}", params.get("contractId"));
            }

            return "ok";
        } catch (Exception e) {
            log.error("处理云闪付回调异常", e);
            return "fail";
        }
    }

    /**
     * 同步返回（用户签约完成后跳转）
     */
    @GetMapping("/return")
    public Map<String, Object> returnUrl(@RequestParam Map<String, String> params) {
        log.info("云闪付同步返回: {}", params);
        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("message", "签约完成，请返回 App");
        return result;
    }

    /**
     * 解约
     */
    @PostMapping("/terminate")
    public Map<String, Object> terminate(@RequestParam String contractId) {
        boolean success = unionPayService.terminateContract(contractId);
        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        return result;
    }
}
