package com.eusd.config;

import com.wechat.pay.java.core.RSAAutoCertificateConfig;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Slf4j
@Configuration
public class WechatPayConfig {

    @Value("${wechat.mch-id:}")
    private String mchId;

    @Value("${wechat.private-key-path:}")
    private String privateKeyPath;

    @Value("${wechat.merchant-serial-number:}")
    private String merchantSerialNumber;

    @Value("${wechat.api-v3-key:}")
    private String apiV3Key;

    @Value("${wechat.app-id:}")
    private String appId;

    @Value("${wechat.notify-url:}")
    private String notifyUrl;

    @Bean
    @ConditionalOnProperty(name = "wechat.enabled", havingValue = "true")
    public RSAAutoCertificateConfig rsaAutoCertificateConfig() {
        log.info("初始化微信支付 SDK，商户号: {}", mchId);
        return new RSAAutoCertificateConfig.Builder()
            .merchantId(mchId)
            .privateKeyFromPath(privateKeyPath)
            .merchantSerialNumber(merchantSerialNumber)
            .apiV3Key(apiV3Key)
            .build();
    }

    public String getMchId() { return mchId; }
    public String getAppId() { return appId; }
    public String getNotifyUrl() { return notifyUrl; }
    public String getPrivateKeyPath() { return privateKeyPath; }
    public String getMerchantSerialNumber() { return merchantSerialNumber; }
}
