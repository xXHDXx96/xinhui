package com.eusd.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * 收款码查询接口
 * App 拉取三张个人收款码的地址，直接显示图片，无任何中转页
 */
@RestController
@RequestMapping("/api/payment")
public class PaymentQrController {

    @Value("${payment.alipay-qr}") private String alipayQr;
    @Value("${payment.wechat-qr}") private String wechatQr;
    @Value("${payment.unionpay-qr}") private String unionpayQr;
    @Value("${payment.support-contact}") private String supportContact;

    @GetMapping("/qr")
    public Map<String, Object> getQr() {
        Map<String, Object> r = new HashMap<>();
        r.put("success", true);
        r.put("alipay", alipayQr);
        r.put("wechat", wechatQr);
        r.put("unionpay", unionpayQr);
        r.put("supportContact", supportContact);
        return r;
    }
}
