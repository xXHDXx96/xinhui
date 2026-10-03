package com.eusd.controller;

import com.eusd.entity.RechargeOrder;
import com.eusd.repository.RechargeOrderRepository;
import com.eusd.service.RechargeFlowService;
import com.eusd.service.ThirdPartyPayService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/pay")
@RequiredArgsConstructor
public class ThirdPartyPayController {

    private final ThirdPartyPayService payService;
    private final RechargeFlowService rechargeFlowService;
    private final RechargeOrderRepository orderRepo;

    /**
     * 创建支付（返回支付跳转 URL 或二维码）
     * 前端直接打开这个 URL，或把 URL 生成二维码
     */
    @PostMapping("/create")
    public Map<String, Object> create(@RequestParam String userId,
                                       @RequestParam String channel,
                                       @RequestParam String amount,
                                       @RequestParam(defaultValue = "USD") String targetAsset) {
        UUID uid = UUID.fromString(userId);
        BigDecimal amt = new BigDecimal(amount);

        RechargeOrder order = rechargeFlowService.createOrder(
            uid, channel.toUpperCase(), amt, targetAsset);

        // channel → 第三方网关的 type
        String payType;
        switch (channel.toUpperCase()) {
            case "ALIPAY": payType = "alipay"; break;
            case "WECHAT": payType = "wxpay"; break;
            case "UNIONPAY": payType = "alipay"; break; // 云闪付走 alipay 通道
            default: payType = "alipay";
        }

        String payUrl = payService.createPayUrl(
            order.getOutTradeNo(), amt, payType, "eUSD Card 充值");

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("outTradeNo", order.getOutTradeNo());
        result.put("payUrl", payUrl);
        result.put("amount", amt);
        return result;
    }

    /**
     * 异步回调（第三方支付网关调用）
     */
    @PostMapping("/notify")
    @ResponseBody
    public String notify(@RequestParam Map<String, String> params) {
        log.info("第三方支付回调: {}", params);

        if (!payService.verifyNotify(params)) {
            return "fail";
        }

        String tradeStatus = params.get("trade_status");
        String outTradeNo = params.get("out_trade_no");
        String tradeNo = params.get("trade_no");

        if ("TRADE_SUCCESS".equals(tradeStatus) || "1".equals(tradeStatus)) {
            try {
                rechargeFlowService.handleRechargeSuccess(outTradeNo, tradeNo);
                return "success";
            } catch (Exception e) {
                log.error("处理充值成功异常", e);
                return "fail";
            }
        }

        if ("TRADE_CLOSED".equals(tradeStatus)) {
            rechargeFlowService.handleRechargeFailed(outTradeNo, "TRADE_CLOSED");
        }
        return "success";
    }

    /**
     * 同步返回（用户支付完成后跳转回来）
     */
    @GetMapping("/return")
    public Map<String, Object> returnUrl(@RequestParam Map<String, String> params) {
        log.info("第三方支付同步返回: {}", params);
        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("outTradeNo", params.get("out_trade_no"));
        result.put("message", "支付完成，请返回 App 查看余额");
        return result;
    }

    /**
     * 查询订单
     */
    @GetMapping("/query/{outTradeNo}")
    public Map<String, Object> query(@PathVariable String outTradeNo) {
        Map<String, String> r = payService.queryOrder(outTradeNo);
        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("data", r);
        return result;
    }
}
