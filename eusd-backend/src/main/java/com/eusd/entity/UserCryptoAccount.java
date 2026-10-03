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
@Table(name = "user_crypto_accounts", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"user_id", "asset"})
})
public class UserCryptoAccount {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "asset", nullable = false, length = 10)
    private String asset;

    @Column(name = "balance", precision = 24, scale = 8)
    @Builder.Default
    private BigDecimal balance = BigDecimal.ZERO;

    @Column(name = "frozen_balance", precision = 24, scale = 8)
    @Builder.Default
    private BigDecimal frozenBalance = BigDecimal.ZERO;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    public void prePersist() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (updatedAt == null) updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
