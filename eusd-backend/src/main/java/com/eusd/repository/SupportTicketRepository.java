package com.eusd.repository;

import com.eusd.entity.SupportTicket;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface SupportTicketRepository extends JpaRepository<SupportTicket, UUID> {

    List<SupportTicket> findByStatus(String status);

    List<SupportTicket> findByUserId(UUID userId);

    List<SupportTicket> findByUserIdAndStatus(UUID userId, String status);

    List<SupportTicket> findByAgreementId(UUID agreementId);

    Page<SupportTicket> findByStatusOrderByCreatedAtAsc(String status, Pageable pageable);

    long countByStatus(String status);

    @Query("SELECT s FROM SupportTicket s WHERE " +
           "(:status IS NULL OR s.status = :status) AND " +
           "(:type IS NULL OR s.type = :type) " +
           "ORDER BY s.createdAt DESC")
    Page<SupportTicket> findByFilters(@Param("status") String status,
                                       @Param("type") String type,
                                       Pageable pageable);

    @Modifying
    @Transactional
    @Query("UPDATE SupportTicket s SET s.status = :status, s.assignedAdminId = :adminId, s.resolvedAt = :resolvedAt WHERE s.id = :id")
    int updateApproved(@Param("id") UUID id,
                       @Param("status") String status,
                       @Param("adminId") UUID adminId,
                       @Param("resolvedAt") LocalDateTime resolvedAt);

    @Modifying
    @Transactional
    @Query("UPDATE SupportTicket s SET s.status = 'REJECTED', s.assignedAdminId = :adminId, s.rejectReason = :reason, s.resolvedAt = :resolvedAt WHERE s.id = :id")
    int updateRejected(@Param("id") UUID id,
                       @Param("adminId") UUID adminId,
                       @Param("reason") String reason,
                       @Param("resolvedAt") LocalDateTime resolvedAt);

    @Modifying
    @Transactional
    @Query("UPDATE SupportTicket s SET s.status = 'CANCELED', s.resolvedAt = :resolvedAt WHERE s.id = :id AND s.status = 'PENDING'")
    int updateCanceled(@Param("id") UUID id, @Param("resolvedAt") LocalDateTime resolvedAt);
}
