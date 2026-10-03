package com.eusd.repository;

import com.eusd.entity.KhqrOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface KhqrOrderRepository extends JpaRepository<KhqrOrder, UUID> {

    Optional<KhqrOrder> findByOrderNo(String orderNo);

    Optional<KhqrOrder> findByMd5(String md5);

    List<KhqrOrder> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
