package com.eusd.repository;

import com.eusd.entity.RechargeOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RechargeOrderRepository extends JpaRepository<RechargeOrder, UUID> {

    Optional<RechargeOrder> findByOutTradeNo(String outTradeNo);

    List<RechargeOrder> findByUserId(UUID userId);

    List<RechargeOrder> findByUserIdAndStatus(UUID userId, String status);

    List<RechargeOrder> findByStatusAndRetryCountLessThan(String status, Integer retryCount);

    List<RechargeOrder> findByStatus(String status);

    long countByStatus(String status);

    @Modifying
    @Transactional
    @Query("UPDATE RechargeOrder r SET r.status = :status, r.channelTradeNo = :channelTradeNo, r.exchangeRate = :rate, r.targetAmount = :targetAmount, r.completedAt = :completedAt WHERE r.outTradeNo = :outTradeNo")
    int updateSuccess(@Param("outTradeNo") String outTradeNo,
                      @Param("channelTradeNo") String channelTradeNo,
                      @Param("rate") BigDecimal rate,
                      @Param("targetAmount") BigDecimal targetAmount,
                      @Param("completedAt") LocalDateTime completedAt);

    @Modifying
    @Transactional
    @Query("UPDATE RechargeOrder r SET r.status = 'FAILED', r.failReason = :reason WHERE r.outTradeNo = :outTradeNo")
    int updateFailed(@Param("outTradeNo") String outTradeNo,
                     @Param("reason") String reason);

    @Modifying
    @Transactional
    @Query("UPDATE RechargeOrder r SET r.retryCount = r.retryCount + 1 WHERE r.id = :id")
    int incrementRetryCount(@Param("id") UUID id);

    @Modifying
    @Transactional
    @Query("UPDATE RechargeOrder r SET r.status = 'SUCCESS', r.completedAt = :completedAt WHERE r.id = :id")
    int updateRetrySuccess(@Param("id") UUID id,
                           @Param("completedAt") LocalDateTime completedAt);
}
