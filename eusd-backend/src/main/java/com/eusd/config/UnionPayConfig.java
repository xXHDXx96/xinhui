package com.eusd.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

@Configuration
public class UnionPayConfig {

    @Value("${unionpay.mer-id}")
    private String merId;

    @Value("${unionpay.cert-path}")
    private String certPath;

    @Value("${unionpay.cert-pwd}")
    private String certPwd;

    @Value("${unionpay.back-url}")
    private String backUrl;

    @Value("${unionpay.front-url}")
    private String frontUrl;

    @Value("${unionpay.plan-id}")
    private String planId;

    @Value("${unionpay.version:5.1.0}")
    private String version;

    @Value("${unionpay.sign-method:01}")
    private String signMethod;

    @Value("${unionpay.charset:UTF-8}")
    private String charset;

    @Value("${unionpay.gateway-url}")
    private String gatewayUrl;

    public String getMerId() { return merId; }
    public String getCertPath() { return certPath; }
    public String getCertPwd() { return certPwd; }
    public String getBackUrl() { return backUrl; }
    public String getFrontUrl() { return frontUrl; }
    public String getPlanId() { return planId; }
    public String getVersion() { return version; }
    public String getSignMethod() { return signMethod; }
    public String getCharset() { return charset; }
    public String getGatewayUrl() { return gatewayUrl; }
}
