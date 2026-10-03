package com.eusd.service;

import com.eusd.entity.User;
import com.eusd.repository.UserRepository;
import com.stripe.exception.StripeException;
import com.stripe.model.issuing.Cardholder;
import com.stripe.param.issuing.CardholderCreateParams;
import com.stripe.param.issuing.CardholderUpdateParams;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class StripeCardholderService {

    private final UserRepository userRepository;

    /**
     * 创建 Stripe Cardholder（发卡前置条件）
     */
    public Cardholder createCardholder(UUID userId, String name, String email, String phone,
                                        String line1, String city, String state,
                                        String postalCode, String country) {
        try {
            CardholderCreateParams params = CardholderCreateParams.builder()
                .setName(name)
                .setEmail(email)
                .setStatus(CardholderCreateParams.Status.ACTIVE)
                .setType(CardholderCreateParams.Type.INDIVIDUAL)
                .setBilling(CardholderCreateParams.Billing.builder()
                    .setAddress(CardholderCreateParams.Billing.Address.builder()
                        .setLine1(line1)
                        .setCity(city)
                        .setState(state)
                        .setPostalCode(postalCode)
                        .setCountry(country)
                        .build())
                    .build())
                .build();
            Cardholder c = Cardholder.create(params);
            log.info("Cardholder 创建成功: userId={}, id={}", userId, c.getId());
            return c;
        } catch (StripeException e) {
            log.error("Cardholder 创建失败: userId={}", userId, e);
            throw new RuntimeException("STRIPE_CARDHOLDER_CREATE_FAILED: " + e.getMessage(), e);
        }
    }

    public Cardholder getCardholder(String cardholderId) {
        try {
            return Cardholder.retrieve(cardholderId);
        } catch (StripeException e) {
            log.error("查询 Cardholder 失败: {}", cardholderId, e);
            throw new RuntimeException("STRIPE_CARDHOLDER_QUERY_FAILED", e);
        }
    }

    /**
     * 更新支出限额（日 / 月）
     */
    public Cardholder updateSpendingLimits(String cardholderId, Long daily, Long monthly) {
        try {
            CardholderUpdateParams.SpendingControls.Builder controls =
                CardholderUpdateParams.SpendingControls.builder();

            List<CardholderUpdateParams.SpendingControls.SpendingLimit> limits = new ArrayList<>();
            if (daily != null) {
                limits.add(CardholderUpdateParams.SpendingControls.SpendingLimit.builder()
                    .setAmount(daily)
                    .setInterval(CardholderUpdateParams.SpendingControls.SpendingLimit.Interval.DAILY)
                    .build());
            }
            if (monthly != null) {
                limits.add(CardholderUpdateParams.SpendingControls.SpendingLimit.builder()
                    .setAmount(monthly)
                    .setInterval(CardholderUpdateParams.SpendingControls.SpendingLimit.Interval.MONTHLY)
                    .build());
            }
            if (!limits.isEmpty()) {
                controls.addAllSpendingLimit(limits);
            }

            CardholderUpdateParams params = CardholderUpdateParams.builder()
                .setSpendingControls(controls.build())
                .build();

            Cardholder existing = Cardholder.retrieve(cardholderId);
            Cardholder updated = existing.update(params);
            log.info("Cardholder 支出限额已更新: {}", cardholderId);
            return updated;
        } catch (StripeException e) {
            log.error("更新 Cardholder 支出限额失败: {}", cardholderId, e);
            throw new RuntimeException("STRIPE_UPDATE_SPENDING_LIMITS_FAILED", e);
        }
    }

    /**
     * 根据用户ID创建或获取 Cardholder
     * 简化实现：每次新建（生产应先查本地表里存的 cardholder_id）
     */
    public Cardholder getOrCreateCardholder(UUID userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new RuntimeException("USER_NOT_FOUND"));

        String name = user.getNickname() != null ? user.getNickname() : "eUSD User";
        String email = user.getEmail();

        return createCardholder(userId, name, email, null,
            "N/A", "N/A", "N/A", "00000", "US");
    }
}
