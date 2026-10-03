package com.eusd.service;

import com.eusd.entity.DepositOrder;
import com.eusd.entity.PaymentQrCode;
import com.eusd.repository.DepositOrderRepository;
import com.eusd.repository.PaymentQrCodeRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class DepositService {

    private final DepositOrderRepository depositRepo;
    private final PaymentQrCodeRepository qrRepo;
    private final ExchangeRateService rateService;
    private final RechargeFlowService rechargeFlowService;
    private final SystemConfigService cfg;

    private PaymentQrCode pickQrCode(String channel) {
        List<PaymentQrCode> list = qrRepo.findForRotation(channel);
        if (list.isEmpty()) return null;
        PaymentQrCode picked = list.get(0);
        picked.setUsedCount((picked.getUsedCount() == null ? 0L : picked.getUsedCount()) + 1);
        qrRepo.save(picked);
        return picked;
    }

    @Transactional
    public DepositOrder createDeposit(UUID userId, String channel) {
        if (!"true".equalsIgnoreCase(cfg.getCached("DEPOSIT", "enabled", "true"))) {
            throw new RuntimeException("充值功能已关闭");
        }

        String ch = channel.toUpperCase();
        String channelKey;
        switch (ch) {
            case "ALIPAY": channelKey = "alipay-enabled"; break;
            case "WECHAT": channelKey = "wechat-enabled"; break;
            case "UNIONPAY": channelKey = "unionpay-enabled"; break;
            default: channelKey = "alipay-enabled";
        }
        if (!"true".equalsIgnoreCase(cfg.getCached("DEPOSIT", channelKey, "true"))) {
            throw new RuntimeException("该支付方式已关闭");
        }

        PaymentQrCode qr = pickQrCode(ch);
        if (qr == null) {
            throw new RuntimeException("该渠道暂未配置收款码，请联系客服");
        }

        String orderNo = "DEP_" + System.currentTimeMillis()
            + "_" + UUID.randomUUID().toString().substring(0, 6);

        DepositOrder order = DepositOrder.builder()
            .userId(userId)
            .orderNo(orderNo)
            .channel(ch)
            .qrCodeId(qr.getId())
            .qrMerchantName(qr.getMerchantName())
            .amountCny(BigDecimal.ZERO)
            .status("CREATED")
            .build();

        depositRepo.save(order);
        log.info("充值订单已生成: orderNo={}, userId={}, channel={}, qrMerchant={}",
            orderNo, userId, ch, qr.getMerchantName());
        return order;
    }

    @Transactional
    public DepositOrder submitDeposit(String orderNo, BigDecimal amountCny, String paymentTxid) {
        DepositOrder order = depositRepo.findByOrderNo(orderNo)
            .orElseThrow(() -> new RuntimeException("订单不存在"));

        if ("APPROVED".equals(order.getStatus())) {
            throw new RuntimeException("订单已到账，无需重复提交");
        }
        if ("REJECTED".equals(order.getStatus())) {
            throw new RuntimeException("订单已被拒绝");
        }
        if ("PENDING".equals(order.getStatus())) {
            throw new RuntimeException("订单已提交，请耐心等待审核");
        }

        if (amountCny == null || amountCny.compareTo(BigDecimal.ZERO) <= 0) {
            throw new RuntimeException("请输入有效金额");
        }

        BigDecimal minAmt = new BigDecimal(cfg.getCached("DEPOSIT", "min-amount", "10"));
        BigDecimal maxAmt = new BigDecimal(cfg.getCached("DEPOSIT", "max-amount", "50000"));
        if (amountCny.compareTo(minAmt) < 0) {
            throw new RuntimeException("最低充值 " + minAmt.toPlainString() + " 元");
        }
        if (amountCny.compareTo(maxAmt) > 0) {
            throw new RuntimeException("单笔最高充值 " + maxAmt.toPlainString() + " 元");
        }

        BigDecimal dailyLimit = new BigDecimal(cfg.getCached("DEPOSIT", "daily-limit", "200000"));
        BigDecimal todayTotal = getTodayTotal(order.getUserId());
        if (todayTotal.add(amountCny).compareTo(dailyLimit) > 0) {
            throw new RuntimeException("今日剩余额度不足（每日上限 "
                + dailyLimit.toPlainString() + " 元）");
        }

        order.setAmountCny(amountCny);
        order.setPaymentTxid(paymentTxid);
        order.setStatus("PENDING");
        depositRepo.save(order);

        log.info("充值已提交: orderNo={}, amount={} CNY, txid={}",
            orderNo, amountCny, paymentTxid);

        applyAutoApprove(order);
        return order;
    }

    @Transactional
    public DepositOrder approveDeposit(UUID orderId, UUID reviewerId) {
        DepositOrder order = depositRepo.findById(orderId)
            .orElseThrow(() -> new RuntimeException("订单不存在"));
        if (!"PENDING".equals(order.getStatus())) {
            throw new RuntimeException("订单已处理：" + order.getStatus());
        }
        ExchangeRateService.ExchangeQuote quote =
            rateService.quote("CNY", "USDT", order.getAmountCny());
        BigDecimal usdtAmount = quote.getToAmount();
        rechargeFlowService.addCryptoBalance(order.getUserId(), "USDT", usdtAmount);
        order.setStatus("APPROVED");
        order.setAmountUsdt(usdtAmount);
        order.setExchangeRate(quote.getRate());
        order.setReviewerId(reviewerId);
        order.setAutoApproved(false);
        order.setReviewedAt(LocalDateTime.now());
        depositRepo.save(order);
        log.info("充值审核通过: orderNo={}, {} CNY → {} USDT",
            order.getOrderNo(), order.getAmountCny(), usdtAmount);
        return order;
    }

    @Transactional
    public DepositOrder rejectDeposit(UUID orderId, UUID reviewerId, String reason) {
        DepositOrder order = depositRepo.findById(orderId)
            .orElseThrow(() -> new RuntimeException("订单不存在"));
        if (!"PENDING".equals(order.getStatus())) {
            throw new RuntimeException("订单已处理");
        }
        order.setStatus("REJECTED");
        order.setAdminRemark(reason != null ? reason : "未说明原因");
        order.setReviewerId(reviewerId);
        order.setReviewedAt(LocalDateTime.now());
        depositRepo.save(order);
        log.info("充值审核拒绝: orderNo={}, reason={}", order.getOrderNo(), reason);
        return order;
    }

    private void applyAutoApprove(DepositOrder order) {
        if (!"PENDING".equals(order.getStatus())) return;
        if (!"true".equalsIgnoreCase(cfg.getCached("DEPOSIT", "auto-approve-enabled", "true"))) {
            log.info("自动审核已关闭，等待客服: orderNo={}", order.getOrderNo());
            return;
        }
        BigDecimal maxAuto = new BigDecimal(cfg.getCached("DEPOSIT", "auto-approve-max", "1000"));
        if (order.getAmountCny() == null
                || order.getAmountCny().compareTo(BigDecimal.ZERO) <= 0
                || order.getAmountCny().compareTo(maxAuto) > 0) {
            log.info("金额 {} 超过自动阈值 {}，进入客服审核: orderNo={}",
                order.getAmountCny(), maxAuto, order.getOrderNo());
            return;
        }
        try {
            ExchangeRateService.ExchangeQuote quote =
                rateService.quote("CNY", "USDT", order.getAmountCny());
            BigDecimal usdtAmount = quote.getToAmount();
            rechargeFlowService.addCryptoBalance(order.getUserId(), "USDT", usdtAmount);
            order.setStatus("APPROVED");
            order.setAmountUsdt(usdtAmount);
            order.setExchangeRate(quote.getRate());
            order.setAutoApproved(true);
            order.setReviewedAt(LocalDateTime.now());
            depositRepo.save(order);
            log.info("自动审核通过: orderNo={}, {} CNY → {} USDT",
                order.getOrderNo(), order.getAmountCny(), usdtAmount);
        } catch (Exception e) {
            log.error("自动审核失败，降级为待客服审核: orderNo={}", order.getOrderNo(), e);
        }
    }

    @Transactional
    public void onLakalaPaid(String orderNo, String channelOrderId, String totalFee) {
        DepositOrder order = depositRepo.findByOrderNo(orderNo)
            .orElseThrow(() -> new RuntimeException("订单不存在: " + orderNo));
        if ("APPROVED".equals(order.getStatus()) || "REJECTED".equals(order.getStatus())) {
            log.info("Lakala 回调：订单已处理({})，跳过: {}", order.getStatus(), orderNo);
            return;
        }
        if ((order.getAmountCny() == null || order.getAmountCny().compareTo(BigDecimal.ZERO) <= 0)
                && totalFee != null && !totalFee.isEmpty()) {
            try { order.setAmountCny(new BigDecimal(totalFee)); } catch (Exception ignore) {}
        }
        if (order.getPaymentTxid() == null || order.getPaymentTxid().isEmpty()) {
            order.setPaymentTxid(channelOrderId);
        }
        order.setPaidAt(LocalDateTime.now());
        if ("CREATED".equals(order.getStatus())) {
            order.setStatus("PENDING");
        }
        depositRepo.save(order);
        applyAutoApprove(order);
    }

    public DepositOrder getById(UUID id) {
        return depositRepo.findById(id)
            .orElseThrow(() -> new RuntimeException("订单不存在"));
    }

    public DepositOrder getByOrderNo(String orderNo) {
        return depositRepo.findByOrderNo(orderNo)
            .orElseThrow(() -> new RuntimeException("订单不存在"));
    }

    @Transactional
    public void updateOrder(DepositOrder order) {
        depositRepo.save(order);
    }

    public List<DepositOrder> listByUser(UUID userId) {
        return depositRepo.findByUserIdOrderByCreatedAtDesc(userId);
    }

    private BigDecimal getTodayTotal(UUID userId) {
        try {
            LocalDateTime start = LocalDate.now().atStartOfDay();
            LocalDateTime end = start.plusDays(1);
            List<DepositOrder> list = depositRepo.findByUserIdOrderByCreatedAtDesc(userId);
            BigDecimal total = BigDecimal.ZERO;
            for (DepositOrder o : list) {
                if (o.getCreatedAt() != null
                    && !o.getCreatedAt().isBefore(start)
                    && o.getCreatedAt().isBefore(end)
                    && ("PENDING".equals(o.getStatus()) || "APPROVED".equals(o.getStatus()))
                    && o.getAmountCny() != null) {
                    total = total.add(o.getAmountCny());
                }
            }
            return total;
        } catch (Exception e) {
            return BigDecimal.ZERO;
        }
    }
}
