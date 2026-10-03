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
@Table(name = "payment_agreements")
public class PaymentAgreement {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "channel", nullable = false, length = 20)
    private String channel;

    @Column(name = "agreement_no", length = 128)
    private String agreementNo;

    @Column(name = "external_agreement_no", length = 64)
    private String externalAgreementNo;

    @Column(name = "plan_id", length = 64)
    private String planId;

    @Column(name = "contract_id", length = 128)
    private String contractId;

    @Column(name = "open_id", length = 128)
    private String openId;

    @Column(name = "contract_code", length = 64)
    private String contractCode;

    @Column(name = "status", length = 30)
    @Builder.Default
    private String status = "SIGNED";

    @Column(name = "signed_at")
    private LocalDateTime signedAt;

    @Column(name = "terminated_at")
    private LocalDateTime terminatedAt;

    @Column(name = "terminated_reason", length = 256)
    private String terminatedReason;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    public void prePersist() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (signedAt == null) signedAt = LocalDateTime.now();
    }
}
