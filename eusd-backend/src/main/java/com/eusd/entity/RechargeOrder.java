package com.eusd.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "recharge_orders")
public class RechargeOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "channel", length = 20)
    private String channel;

    @Column(name = "out_trade_no", unique = true, nullable = false, length = 64)
    private String outTradeNo;

    @Column(name = "channel_trade_no", length = 128)
    private String channelTradeNo;

    @Column(name = "fiat_amount", precision = 18, scale = 2)
    private BigDecimal fiatAmount;

    @Column(name = "fiat_currency", length = 10)
    @Builder.Default
    private String fiatCurrency = "CNY";

    @Column(name = "target_asset", length = 10)
    private String targetAsset;

    @Column(name = "target_amount", precision = 24, scale = 8)
    private BigDecimal targetAmount;

    @Column(name = "exchange_rate", precision = 18, scale = 8)
    private BigDecimal exchangeRate;

    @Column(name = "status", length = 20)
    @Builder.Default
    private String status = "CREATED";

    @Column(name = "retry_count")
    @Builder.Default
    private Integer retryCount = 0;

    @Column(name = "fail_reason", length = 256)
    private String failReason;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @PrePersist
    public void prePersist() {
        if (createdAt == null) createdAt = LocalDateTime.now();
    }
}
