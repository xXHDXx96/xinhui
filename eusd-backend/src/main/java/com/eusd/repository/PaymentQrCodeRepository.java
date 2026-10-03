package com.eusd.repository;

import com.eusd.entity.PaymentQrCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface PaymentQrCodeRepository extends JpaRepository<PaymentQrCode, UUID> {

    List<PaymentQrCode> findAllByOrderByCreatedAtDesc();

    List<PaymentQrCode> findByChannel(String channel);

    @Query("SELECT q FROM PaymentQrCode q WHERE q.channel = :channel AND q.enabled = true ORDER BY q.usedCount ASC, q.createdAt ASC")
    List<PaymentQrCode> findForRotation(@Param("channel") String channel);
}
