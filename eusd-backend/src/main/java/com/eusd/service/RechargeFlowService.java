package com.eusd.service;

import com.eusd.entity.RechargeOrder;
import com.eusd.entity.UserCryptoAccount;
import com.eusd.entity.UserFiatAccount;
import com.eusd.repository.RechargeOrderRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class RechargeFlowService {

    private final RechargeOrderRepository orderRepo;
    private final ExchangeRateService rateService;

    @PersistenceContext
    private EntityManager em;

    /**
     * 生成订单号
     */
    public String generateOutTradeNo(String channel) {
        return channel + "_" + System.currentTimeMillis() + "_"
            + UUID.randomUUID().toString().substring(0, 8);
    }

    /**
     * 创建充值订单（用户点击"充值"时调用）
     */
    @Transactional
    public RechargeOrder createOrder(UUID userId, String channel,
                                     BigDecimal fiat, String targetAsset) {
        RechargeOrder order = RechargeOrder.builder()
            .userId(userId)
            .channel(channel)
            .outTradeNo(generateOutTradeNo(channel))
            .fiatAmount(fiat)
            .fiatCurrency("CNY")
            .targetAsset(targetAsset != null ? targetAsset : "USD")
            .status("CREATED")
            .retryCount(0)
            .build();
        orderRepo.save(order);
        log.info("充值订单已创建: outTradeNo={}, amount={} {}",
            order.getOutTradeNo(), fiat, targetAsset);
        return order;
    }

    /**
     * 处理充值成功（各渠道回调时调用）
     * 链路：法币入账 → 汇率换算 → 加密资产入账 → 更新订单
     */
    @Transactional
    public void handleRechargeSuccess(String outTradeNo, String channelTradeNo) {
        RechargeOrder order = orderRepo.findByOutTradeNo(outTradeNo)
            .orElseThrow(() -> new RuntimeException("ORDER_NOT_FOUND"));

        if ("SUCCESS".equals(order.getStatus())) {
            log.warn("订单已处理，跳过: {}", outTradeNo);
            return;
        }

        UUID userId = order.getUserId();
        BigDecimal fiatAmount = order.getFiatAmount();
        String targetAsset = order.getTargetAsset();

        // 1. 法币账户加钱
        addFiatBalance(userId, order.getFiatCurrency(), fiatAmount);
        log.info("法币入账: userId={}, {} {}", userId, fiatAmount, order.getFiatCurrency());

        // 2. 汇率报价（CNY → USD/USDT）
        ExchangeRateService.ExchangeQuote quote =
            rateService.quote("CNY", targetAsset, fiatAmount);

        // 3. 扣减法币
        deductFiatBalance(userId, order.getFiatCurrency(), fiatAmount);

        // 4. 加密资产入账
        addCryptoBalance(userId, targetAsset, quote.getToAmount());
        log.info("资产入账: userId={}, {} {}", userId, quote.getToAmount(), targetAsset);

        // 5. 更新订单
        order.setStatus("SUCCESS");
        order.setChannelTradeNo(channelTradeNo);
        order.setExchangeRate(quote.getRate());
        order.setTargetAmount(quote.getToAmount());
        order.setCompletedAt(LocalDateTime.now());
        orderRepo.save(order);

        log.info("充值完成: outTradeNo={}, rate={}, fee={}, net={}",
            outTradeNo, quote.getRate(), quote.getFee(), quote.getToAmount());
    }

    /**
     * 处理充值失败
     */
    @Transactional
    public void handleRechargeFailed(String outTradeNo, String reason) {
        orderRepo.findByOutTradeNo(outTradeNo).ifPresent(order -> {
            order.setStatus("FAILED");
            order.setFailReason(reason);
            orderRepo.save(order);
            log.warn("充值失败: outTradeNo={}, reason={}", outTradeNo, reason);
        });
    }

    /**
     * 增加法币余额（不存在则创建账户）
     */
    @Transactional
    public void addFiatBalance(UUID userId, String currency, BigDecimal amount) {
        UserFiatAccount account = findFiatAccount(userId, currency);
        if (account == null) {
            account = UserFiatAccount.builder()
                .userId(userId)
                .currency(currency)
                .balance(BigDecimal.ZERO)
                .frozenBalance(BigDecimal.ZERO)
                .build();
        }
        account.setBalance(account.getBalance().add(amount));
        em.merge(account);
    }

    /**
     * 扣减法币余额
     */
    @Transactional
    public void deductFiatBalance(UUID userId, String currency, BigDecimal amount) {
        UserFiatAccount account = findFiatAccount(userId, currency);
        if (account == null || account.getBalance().compareTo(amount) < 0) {
            throw new RuntimeException("INSUFFICIENT_FIAT_BALANCE");
        }
        account.setBalance(account.getBalance().subtract(amount));
        em.merge(account);
    }

    /**
     * 增加加密资产余额
     */
    @Transactional
    public void addCryptoBalance(UUID userId, String asset, BigDecimal amount) {
        UserCryptoAccount account = findCryptoAccount(userId, asset);
        if (account == null) {
            account = UserCryptoAccount.builder()
                .userId(userId)
                .asset(asset)
                .balance(BigDecimal.ZERO)
                .frozenBalance(BigDecimal.ZERO)
                .build();
        }
        account.setBalance(account.getBalance().add(amount));
        em.merge(account);
    }

    /**
     * 扣减加密资产余额（消费、兑换时调用）
     */
    @Transactional
    public void deductCryptoBalance(UUID userId, String asset, BigDecimal amount) {
        UserCryptoAccount account = findCryptoAccount(userId, asset);
        if (account == null || account.getBalance().compareTo(amount) < 0) {
            throw new RuntimeException("INSUFFICIENT_CRYPTO_BALANCE");
        }
        account.setBalance(account.getBalance().subtract(amount));
        em.merge(account);
    }

    /**
     * 查询加密资产余额
     */
    public BigDecimal getCryptoBalance(UUID userId, String asset) {
        UserCryptoAccount account = findCryptoAccount(userId, asset);
        return account != null ? account.getBalance() : BigDecimal.ZERO;
    }

    /**
     * 查询法币余额
     */
    public BigDecimal getFiatBalance(UUID userId, String currency) {
        UserFiatAccount account = findFiatAccount(userId, currency);
        return account != null ? account.getBalance() : BigDecimal.ZERO;
    }

    private UserFiatAccount findFiatAccount(UUID userId, String currency) {
        try {
            return em.createQuery(
                "SELECT a FROM UserFiatAccount a WHERE a.userId = :userId AND a.currency = :currency",
                UserFiatAccount.class)
                .setParameter("userId", userId)
                .setParameter("currency", currency)
                .getSingleResult();
        } catch (Exception e) {
            return null;
        }
    }

    private UserCryptoAccount findCryptoAccount(UUID userId, String asset) {
        try {
            return em.createQuery(
                "SELECT a FROM UserCryptoAccount a WHERE a.userId = :userId AND a.asset = :asset",
                UserCryptoAccount.class)
                .setParameter("userId", userId)
                .setParameter("asset", asset)
                .getSingleResult();
        } catch (Exception e) {
            return null;
        }
    }
}
