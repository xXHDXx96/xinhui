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
@Table(name = "deposit_orders")
public class DepositOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "order_no", unique = true, nullable = false, length = 64)
    private String orderNo;

    @Column(name = "channel", nullable = false, length = 20)
    private String channel;

    @Column(name = "qr_code_id")
    private UUID qrCodeId;

    @Column(name = "qr_merchant_name", length = 64)
    private String qrMerchantName;

    @Column(name = "amount_cny", precision = 18, scale = 2)
    private BigDecimal amountCny;

    @Column(name = "amount_usdt", precision = 24, scale = 8)
    private BigDecimal amountUsdt;

    @Column(name = "exchange_rate", precision = 18, scale = 8)
    private BigDecimal exchangeRate;

    @Column(name = "payment_txid", length = 128)
    private String paymentTxid;

    @Column(name = "payment_screenshot", length = 512)
    private String paymentScreenshot;

    @Column(name = "user_remark", length = 256)
    private String userRemark;

    @Column(name = "admin_remark", length = 256)
    private String adminRemark;

    @Column(name = "status", length = 20)
    @Builder.Default
    private String status = "PENDING";

    @Column(name = "auto_approved")
    private Boolean autoApproved;

    @Column(name = "paid_at")
    private LocalDateTime paidAt;

    @Column(name = "reviewer_id")
    private UUID reviewerId;

    @Column(name = "reviewed_at")
    private LocalDateTime reviewedAt;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    public void prePersist() {
        if (createdAt == null) createdAt = LocalDateTime.now();
    }
}
