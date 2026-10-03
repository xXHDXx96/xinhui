package com.eusd.repository;

import com.eusd.entity.VirtualCard;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface VirtualCardRepository extends JpaRepository<VirtualCard, UUID> {

    List<VirtualCard> findByUserId(UUID userId);

    List<VirtualCard> findByUserIdAndStatus(UUID userId, String status);

    List<VirtualCard> findByUserIdAndCardType(UUID userId, String cardType);

    Optional<VirtualCard> findByStripeCardId(String stripeCardId);

    long countByUserIdAndStatus(UUID userId, String status);

    @Modifying
    @Transactional
    @Query("UPDATE VirtualCard v SET v.status = :status WHERE v.id = :id")
    int updateStatus(@Param("id") UUID id, @Param("status") String status);

    @Modifying
    @Transactional
    @Query("UPDATE VirtualCard v SET v.status = :status WHERE v.stripeCardId = :stripeCardId")
    int updateStatusByStripeCardId(@Param("stripeCardId") String stripeCardId,
                                    @Param("status") String status);
}
