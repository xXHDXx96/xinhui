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
@Table(name = "virtual_cards")
public class VirtualCard {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "stripe_card_id", length = 64)
    private String stripeCardId;

    @Column(name = "stripe_cardholder_id", length = 64)
    private String stripeCardholderId;

    @Column(name = "last4", length = 4)
    private String last4;

    @Column(name = "brand", length = 20)
    @Builder.Default
    private String brand = "VISA";

    @Column(name = "card_type", length = 20)
    @Builder.Default
    private String cardType = "virtual";

    @Column(name = "currency", length = 10)
    @Builder.Default
    private String currency = "USD";

    @Column(name = "status", length = 20)
    @Builder.Default
    private String status = "active";

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
