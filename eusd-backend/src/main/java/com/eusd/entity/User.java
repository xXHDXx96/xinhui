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
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "email", unique = true, nullable = false, length = 128)
    private String email;

    @Column(name = "phone", unique = true, length = 20)
    private String phone;

    @Column(name = "password_hash", length = 256)
    private String passwordHash;

    @Column(name = "kyc_status", length = 20)
    @Builder.Default
    private String kycStatus = "UNVERIFIED";

    @Column(name = "kyc_level", length = 20)
    @Builder.Default
    private String kycLevel = "NONE";

    @Column(name = "real_name", length = 64)
    private String realName;

    @Column(name = "id_number", length = 32)
    private String idNumber;

    @Column(name = "realname_submitted_at")
    private LocalDateTime realnameSubmittedAt;

    @Column(name = "nickname", length = 64)
    private String nickname;

    @Column(name = "avatar_url", length = 256)
    private String avatarUrl;

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
