package com.eusd.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.tron.trident.abi.FunctionEncoder;
import org.tron.trident.abi.TypeReference;
import org.tron.trident.abi.datatypes.Address;
import org.tron.trident.abi.datatypes.Function;
import org.tron.trident.abi.datatypes.generated.Uint256;
import org.tron.trident.core.ApiWrapper;
import org.tron.trident.core.contract.Trc20Contract;
import org.tron.trident.proto.Chain;
import org.tron.trident.proto.Response;
import org.tron.trident.utils.Base58Check;
import org.tron.trident.utils.Numeric;

import java.math.BigInteger;
import java.util.Arrays;

@Slf4j
@Service
@RequiredArgsConstructor
public class TronSweepService {

    private final SystemConfigService cfg;

    private ApiWrapper client;
    private String lastKey = "";

    // 从数据库缓存读，App 后台改完立即生效
    private boolean enabled() {
        return "true".equalsIgnoreCase(cfg.getCached("TRON", "enabled", "false"));
    }
    private String apiKey() {
        return cfg.getCached("TRON", "trongrid-api-key", "");
    }
    private String usdtContract() {
        return cfg.getCached("TRON", "usdt-contract", "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t");
    }
    private String hotWallet() {
        return cfg.getCached("TRON", "hot-wallet-address", "");
    }
    private String hotPrivateKey() {
        return cfg.getCached("TRON", "hot-wallet-private-key", "");
    }
    private String coldWallet() {
        return cfg.getCached("TRON", "cold-wallet", "");
    }
    private long minSweepAmount() {
        try { return Long.parseLong(cfg.getCached("TRON", "min-sweep-amount", "10")); }
        catch (Exception e) { return 10; }
    }

    public boolean isEnabled() { return enabled(); }

    private ApiWrapper getClient() {
        String pk = hotPrivateKey();
        String key = apiKey();
        // 私钥或 API Key 变化时重建 client
        String combined = pk + "|" + key;
        if (client == null || !combined.equals(lastKey)) {
            client = ApiWrapper.ofMainnet(pk, key);
            lastKey = combined;
            log.info("TRON 客户端已初始化/刷新");
        }
        return client;
    }

    public BigInteger getHotBalance() {
        if (!enabled()) return BigInteger.ZERO;
        try {
            Trc20Contract contract = new Trc20Contract(
                getClient().getContract(usdtContract()),
                hotWallet(),
                getClient());
            return contract.balanceOf(hotWallet());
        } catch (Exception e) {
            log.error("查询热钱包余额失败", e);
            return BigInteger.ZERO;
        }
    }

    public String sweep() {
        if (!enabled()) {
            log.warn("TRON 归集未启用");
            return null;
        }
        if (coldWallet() == null || coldWallet().isEmpty()) {
            log.warn("冷钱包地址未配置");
            return null;
        }

        BigInteger balance = getHotBalance();
        BigInteger minAmount = BigInteger.valueOf(minSweepAmount())
            .multiply(BigInteger.valueOf(1_000_000L));

        log.info("热钱包 USDT 余额: {} 微单位 ({} USDT)",
            balance, balance.divide(BigInteger.valueOf(1_000_000L)));

        if (balance.compareTo(minAmount) < 0) {
            log.info("余额不足 {} USDT，跳过归集", minSweepAmount());
            return null;
        }

        try {
            Function transfer = new Function(
                "transfer",
                Arrays.asList(new Address(coldWallet()), new Uint256(balance)),
                Arrays.asList(new TypeReference<org.tron.trident.abi.datatypes.Bool>() {}));

            String encoded = FunctionEncoder.encode(transfer);

            String hotHex = Numeric.toHexStringNoPrefix(
                Base58Check.base58ToBytes(hotWallet()));
            String contractHex = Numeric.toHexStringNoPrefix(
                Base58Check.base58ToBytes(usdtContract()));

            Response.TransactionExtention tx = getClient().triggerContract(
                hotHex,
                contractHex,
                encoded,
                0L,
                100_000_000L,
                "sweep",
                100_000_000L
            );

            if (tx.getResult().getResult()) {
                Chain.Transaction signed = getClient().signTransaction(tx.getTransaction());
                String txId = getClient().broadcastTransaction(signed);
                log.info("归集成功: {} USDT → {}, txId={}",
                    balance.divide(BigInteger.valueOf(1_000_000L)),
                    coldWallet(), txId);
                return txId;
            } else {
                log.error("归集失败: {}", tx.getResult().getMessage());
                return null;
            }
        } catch (Exception e) {
            log.error("归集异常", e);
            return null;
        }
    }
}
