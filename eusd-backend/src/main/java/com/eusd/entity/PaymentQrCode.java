package com.eusd.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "payment_qr_codes")
public class PaymentQrCode {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "channel", nullable = false, length = 20)
    private String channel;

    @Column(name = "merchant_name", length = 64)
    private String merchantName;

    @Column(name = "qr_content", columnDefinition = "TEXT")
    private String qrContent;

    @Column(name = "qr_type", length = 16)
    @Builder.Default
    private String qrType = "TEXT";

    @Column(name = "enabled")
    @Builder.Default
    private Boolean enabled = true;

    @Column(name = "used_count")
    @Builder.Default
    private Long usedCount = 0L;

    @Column(name = "remark", length = 256)
    private String remark;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    public void prePersist() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (usedCount == null) usedCount = 0L;
    }
}
