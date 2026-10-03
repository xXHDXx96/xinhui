package com.eusd.repository;

import com.eusd.entity.DepositOrder;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DepositOrderRepository extends JpaRepository<DepositOrder, UUID> {

    Optional<DepositOrder> findByOrderNo(String orderNo);

    List<DepositOrder> findByUserIdOrderByCreatedAtDesc(UUID userId);

    List<DepositOrder> findByStatusOrderByCreatedAtAsc(String status);

    Page<DepositOrder> findByStatusOrderByCreatedAtAsc(String status, Pageable pageable);

    long countByStatus(String status);

    @Query("SELECT d FROM DepositOrder d WHERE " +
           "(:status IS NULL OR d.status = :status) AND " +
           "(:channel IS NULL OR d.channel = :channel) " +
           "ORDER BY d.createdAt DESC")
    Page<DepositOrder> findByFilters(@Param("status") String status,
                                      @Param("channel") String channel,
                                      Pageable pageable);
}
