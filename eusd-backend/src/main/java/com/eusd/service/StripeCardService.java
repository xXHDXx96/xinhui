package com.eusd.service;

import com.eusd.entity.VirtualCard;
import com.eusd.repository.VirtualCardRepository;
import com.stripe.exception.StripeException;
import com.stripe.model.issuing.Card;
import com.stripe.param.issuing.CardCreateParams;
import com.stripe.param.issuing.CardListParams;
import com.stripe.param.issuing.CardUpdateParams;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class StripeCardService {

    private final VirtualCardRepository repo;

    /**
     * 创建虚拟卡
     */
    @Transactional
    public VirtualCard createVirtualCard(UUID userId, String cardholderId, String currency) {
        try {
            CardCreateParams params = CardCreateParams.builder()
                .setCardholder(cardholderId)
                .setCurrency(currency)
                .setType(CardCreateParams.Type.VIRTUAL)
                .setStatus(CardCreateParams.Status.ACTIVE)
                .build();

            Card stripeCard = Card.create(params);

            VirtualCard card = VirtualCard.builder()
                .userId(userId)
                .stripeCardId(stripeCard.getId())
                .stripeCardholderId(cardholderId)
                .last4(stripeCard.getLast4())
                .brand(stripeCard.getBrand() != null
                    ? stripeCard.getBrand().toUpperCase() : "VISA")
                .cardType("virtual")
                .currency(currency)
                .status("active")
                .build();

            repo.save(card);
            log.info("虚拟卡创建成功: userId={}, cardId={}, last4={}",
                userId, stripeCard.getId(), stripeCard.getLast4());
            return card;
        } catch (StripeException e) {
            log.error("虚拟卡创建失败: userId={}", userId, e);
            throw new RuntimeException("STRIPE_CARD_CREATE_FAILED: " + e.getMessage(), e);
        }
    }

    /**
     * 创建实体卡（含邮寄地址）
     */
    @Transactional
    public VirtualCard createPhysicalCard(UUID userId, String cardholderId, String currency,
                                            String shippingName, String shippingPhone,
                                            String line1, String city, String state,
                                            String postalCode, String country) {
        try {
            CardCreateParams params = CardCreateParams.builder()
                .setCardholder(cardholderId)
                .setCurrency(currency)
                .setType(CardCreateParams.Type.PHYSICAL)
                .setStatus(CardCreateParams.Status.ACTIVE)
                .setShipping(CardCreateParams.Shipping.builder()
                    .setName(shippingName)
                    .setPhoneNumber(shippingPhone)
                    .setAddress(CardCreateParams.Shipping.Address.builder()
                        .setLine1(line1)
                        .setCity(city)
                        .setState(state)
                        .setPostalCode(postalCode)
                        .setCountry(country)
                        .build())
                    .build())
                .build();

            Card stripeCard = Card.create(params);

            VirtualCard card = VirtualCard.builder()
                .userId(userId)
                .stripeCardId(stripeCard.getId())
                .stripeCardholderId(cardholderId)
                .last4(stripeCard.getLast4())
                .brand(stripeCard.getBrand() != null
                    ? stripeCard.getBrand().toUpperCase() : "VISA")
                .cardType("physical")
                .currency(currency)
                .status("active")
                .build();

            repo.save(card);
            log.info("实体卡创建成功: userId={}, cardId={}", userId, stripeCard.getId());
            return card;
        } catch (StripeException e) {
            log.error("实体卡创建失败: userId={}", userId, e);
            throw new RuntimeException("STRIPE_PHYSICAL_CARD_FAILED", e);
        }
    }

    /**
     * 更新卡片状态（active / inactive / canceled）
     */
    @Transactional
    public void updateCardStatus(UUID cardId, String newStatus) {
        VirtualCard card = repo.findById(cardId)
            .orElseThrow(() -> new RuntimeException("CARD_NOT_FOUND"));

        try {
            CardUpdateParams.Status stripeStatus;
            switch (newStatus) {
                case "blocked":
                case "inactive":
                    stripeStatus = CardUpdateParams.Status.INACTIVE;
                    break;
                case "canceled":
                    stripeStatus = CardUpdateParams.Status.CANCELED;
                    break;
                default:
                    stripeStatus = CardUpdateParams.Status.ACTIVE;
            }

            Card existing = Card.retrieve(card.getStripeCardId());
            existing.update(CardUpdateParams.builder().setStatus(stripeStatus).build());

            card.setStatus(newStatus);
            repo.save(card);
            log.info("卡片状态更新: cardId={}, status={}", cardId, newStatus);
        } catch (StripeException e) {
            log.error("卡片状态更新失败: cardId={}", cardId, e);
            throw new RuntimeException("STRIPE_CARD_UPDATE_FAILED", e);
        }
    }

    /**
     * 查询用户所有卡片
     */
    public List<VirtualCard> listUserCards(UUID userId) {
        return repo.findByUserId(userId);
    }

    /**
     * 查询单张卡片
     */
    public VirtualCard getCard(UUID cardId) {
        return repo.findById(cardId)
            .orElseThrow(() -> new RuntimeException("CARD_NOT_FOUND"));
    }

    /**
     * 根据 Stripe Card ID 查询本地卡片
     */
    public VirtualCard getByStripeCardId(String stripeCardId) {
        return repo.findByStripeCardId(stripeCardId).orElse(null);
    }

    /**
     * 从 Stripe 同步卡片状态到本地
     */
    public Card syncCardFromStripe(String stripeCardId) {
        try {
            Card stripeCard = Card.retrieve(stripeCardId);
            repo.findByStripeCardId(stripeCardId).ifPresent(card -> {
                card.setStatus(stripeCard.getStatus());
                card.setLast4(stripeCard.getLast4());
                repo.save(card);
            });
            return stripeCard;
        } catch (StripeException e) {
            log.error("同步 Stripe 卡片失败: {}", stripeCardId, e);
            throw new RuntimeException("STRIPE_CARD_SYNC_FAILED", e);
        }
    }

    /**
     * 列出 Cardholder 下所有卡片
     */
    public List<Card> listStripeCardsByCardholder(String cardholderId) {
        try {
            CardListParams params = CardListParams.builder()
                .setCardholder(cardholderId)
                .build();
            return Card.list(params).getData();
        } catch (StripeException e) {
            log.error("查询 Stripe 卡片列表失败: {}", cardholderId, e);
            throw new RuntimeException("STRIPE_CARD_LIST_FAILED", e);
        }
    }

    /**
     * 处理 Stripe Webhook 的卡片事件
     */
    @Transactional
    public void handleCardWebhook(String stripeCardId, String status) {
        repo.findByStripeCardId(stripeCardId).ifPresent(card -> {
            card.setStatus(status);
            repo.save(card);
            log.info("Webhook 更新卡片状态: stripeCardId={}, status={}",
                stripeCardId, status);
        });
    }
}
