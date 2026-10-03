package com.eusd.repository;

import com.eusd.entity.PaymentAgreement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PaymentAgreementRepository extends JpaRepository<PaymentAgreement, UUID> {

    List<PaymentAgreement> findByUserId(UUID userId);

    List<PaymentAgreement> findByUserIdAndStatus(UUID userId, String status);

    List<PaymentAgreement> findByChannelAndStatus(String channel, String status);

    Optional<PaymentAgreement> findByAgreementNo(String agreementNo);

    Optional<PaymentAgreement> findByExternalAgreementNo(String externalAgreementNo);

    Optional<PaymentAgreement> findByContractId(String contractId);

    Optional<PaymentAgreement> findByContractCode(String contractCode);

    @Modifying
    @Transactional
    @Query("UPDATE PaymentAgreement p SET p.status = :status WHERE p.id = :id")
    int updateStatus(@Param("id") UUID id, @Param("status") String status);

    @Modifying
    @Transactional
    @Query("UPDATE PaymentAgreement p SET p.status = :status, p.terminatedAt = :terminatedAt, p.terminatedReason = :reason WHERE p.id = :id")
    int updateTermination(@Param("id") UUID id,
                          @Param("status") String status,
                          @Param("terminatedAt") LocalDateTime terminatedAt,
                          @Param("reason") String reason);

    @Modifying
    @Transactional
    @Query("UPDATE PaymentAgreement p SET p.agreementNo = :agreementNo, p.contractId = :contractId, p.openId = :openId, p.contractCode = :contractCode WHERE p.id = :id")
    int updateChannelInfo(@Param("id") UUID id,
                          @Param("agreementNo") String agreementNo,
                          @Param("contractId") String contractId,
                          @Param("openId") String openId,
                          @Param("contractCode") String contractCode);
}
