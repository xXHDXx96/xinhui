package com.eusd.config;

import com.eusd.service.SystemConfigService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

/**
 * 启动时初始化默认配置项
 * 已经存在的不会覆盖，只补缺失的
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class SystemConfigInitializer implements CommandLineRunner {

    private final SystemConfigService svc;

    @Override
    public void run(String... args) {
        // ===== Alchemy Pay =====
        svc.initDefault("ALCHEMY", "enabled", "false",
            "是否启用 Alchemy Pay", false, "true / false");
        svc.initDefault("ALCHEMY", "app-id", "",
            "Alchemy App ID", false, "商户后台获取");
        svc.initDefault("ALCHEMY", "secret", "",
            "Alchemy Secret", true, "商户后台获取，敏感");
        svc.initDefault("ALCHEMY", "base-url", "https://openapi.alchemypay.org",
            "接口地址", false, "生产: openapi.alchemypay.org / 沙箱: openapi-test.alchemypay.org");
        svc.initDefault("ALCHEMY", "callback-url", "",
            "Webhook 回调地址", false, "https://你的域名/api/onramp/webhook");
        svc.initDefault("ALCHEMY", "settle-address", "",
            "USDT 收款地址", false, "你的 TRC20 地址");
        svc.initDefault("ALCHEMY", "settle-network", "TRX",
            "结算网络", false, "TRX / ETH / BSC");
        svc.initDefault("ALCHEMY", "settle-crypto", "USDT",
            "结算币种", false, "USDT / USDC");

        // ===== TRON 归集 =====
        svc.initDefault("TRON", "enabled", "false",
            "是否启用 TRON 归集", false, "true / false");
        svc.initDefault("TRON", "trongrid-api-key", "",
            "TronGrid API Key", true, "trongrid.io 申请");
        svc.initDefault("TRON", "usdt-contract", "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
            "USDT 合约地址", false, "TRC20 USDT 固定地址");
        svc.initDefault("TRON", "hot-wallet-address", "",
            "热钱包地址", false, "T 开头");
        svc.initDefault("TRON", "hot-wallet-private-key", "",
            "热钱包私钥", true, "64位十六进制，敏感");
        svc.initDefault("TRON", "cold-wallet", "",
            "冷钱包地址", false, "归集目标地址，T 开头");
        svc.initDefault("TRON", "min-sweep-amount", "10",
            "最小归集金额", false, "USDT 数量，低于此值不归集");

        // ===== 收款码 =====
        svc.initDefault("PAYMENT", "alipay-qr", "/qr/alipay.png",
            "支付宝收款码路径", false, "静态资源路径");
        svc.initDefault("PAYMENT", "wechat-qr", "/qr/wechat.png",
            "微信收款码路径", false, "静态资源路径");
        svc.initDefault("PAYMENT", "unionpay-qr", "/qr/unionpay.png",
            "云闪付收款码路径", false, "静态资源路径");
        svc.initDefault("PAYMENT", "support-contact", "@your_telegram",
            "客服联系方式", false, "Telegram 号");

        // ===== 支付宝官方（可选） =====
        svc.initDefault("ALIPAY", "app-id", "",
            "支付宝 App ID", false, "开放平台获取");
        svc.initDefault("ALIPAY", "private-key", "",
            "应用私钥", true, "敏感");
        svc.initDefault("ALIPAY", "alipay-public-key", "",
            "支付宝公钥", false, "开放平台获取");
        svc.initDefault("ALIPAY", "gateway-url", "https://openapi.alipay.com/gateway.do",
            "网关地址", false, "");

        // ===== 微信支付（可选） =====
        svc.initDefault("WECHAT", "enabled", "false",
            "是否启用微信支付", false, "true / false");
        svc.initDefault("WECHAT", "app-id", "",
            "微信 App ID", false, "");
        svc.initDefault("WECHAT", "mch-id", "",
            "微信商户号", false, "");
        svc.initDefault("WECHAT", "private-key-path", "",
            "商户私钥路径", false, "服务器文件路径");
        svc.initDefault("WECHAT", "merchant-serial-number", "",
            "证书序列号", false, "");
        svc.initDefault("WECHAT", "api-v3-key", "",
            "APIv3 密钥", true, "敏感");

        // ===== Stripe（可选） =====
        svc.initDefault("STRIPE", "secret-key", "",
            "Stripe Secret Key", true, "sk_ 开头");
        svc.initDefault("STRIPE", "publishable-key", "",
            "Stripe Publishable Key", false, "pk_ 开头");
        svc.initDefault("STRIPE", "webhook-secret", "",
            "Stripe Webhook Secret", true, "whsec_ 开头");

        // ===== 系统 =====
        svc.initDefault("SYSTEM", "admin-password", "xh2024admin",
            "管理员密码", true, "App 长按头像进后台用");
        svc.initDefault("SYSTEM", "min-deposit-amount", "10",
            "最低充值金额", false, "CNY");
        svc.initDefault("SYSTEM", "exchange-fee-rate", "0.005",
            "兑换手续费率", false, "0.005 = 0.5%");

        svc.reload();
        log.info("系统配置初始化完成");
    }
}
