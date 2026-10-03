package com.eusd.controller;

import com.eusd.entity.DepositOrder;
import com.eusd.service.DepositService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;

@Slf4j
@Controller
@RequestMapping("/pay")
@RequiredArgsConstructor
public class PayPageController {

    private final DepositService depositService;

    @Value("${payment.alipay-qr:/qr/alipay.png}") private String alipayQr;
    @Value("${payment.wechat-qr:/qr/wechat.png}") private String wechatQr;
    @Value("${payment.unionpay-qr:/qr/unionpay.png}") private String unionpayQr;
    @Value("${payment.support-contact:@your_telegram}") private String supportContact;

    @GetMapping("/page/{orderNo}")
    public String payPage(@PathVariable String orderNo, Model model) {
        try {
            DepositOrder order = depositService.getByOrderNo(orderNo);

            String qrImage;
            String channelName;
            switch (order.getChannel()) {
                case "ALIPAY":
                    qrImage = alipayQr;
                    channelName = "支付宝";
                    break;
                case "WECHAT":
                    qrImage = wechatQr;
                    channelName = "微信支付";
                    break;
                case "UNIONPAY":
                    qrImage = unionpayQr;
                    channelName = "云闪付";
                    break;
                default:
                    qrImage = alipayQr;
                    channelName = "支付宝";
            }

            model.addAttribute("orderNo", order.getOrderNo());
            model.addAttribute("channel", order.getChannel());
            model.addAttribute("channelName", channelName);
            model.addAttribute("qrImage", qrImage);
            model.addAttribute("supportContact", supportContact);

            log.info("访问支付页: orderNo={}, channel={}", orderNo, channelName);
            return "pay";
        } catch (Exception e) {
            log.error("加载支付页失败: orderNo={}", orderNo, e);
            model.addAttribute("error", "订单不存在或已过期");
            return "pay-error";
        }
    }
}
