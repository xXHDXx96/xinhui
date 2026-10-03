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
@Table(name = "support_tickets")
public class SupportTicket {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "agreement_id")
    private UUID agreementId;

    @Column(name = "type", length = 30)
    @Builder.Default
    private String type = "TERMINATION";

    @Column(name = "status", length = 20)
    @Builder.Default
    private String status = "PENDING";

    @Column(name = "assigned_admin_id")
    private UUID assignedAdminId;

    @Column(name = "remark", columnDefinition = "TEXT")
    private String remark;

    @Column(name = "reject_reason", length = 256)
    private String rejectReason;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "resolved_at")
    private LocalDateTime resolvedAt;

    @PrePersist
    public void prePersist() {
        if (createdAt == null) createdAt = LocalDateTime.now();
    }
}
