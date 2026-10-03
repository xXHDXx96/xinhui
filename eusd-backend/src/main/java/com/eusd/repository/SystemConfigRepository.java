package com.eusd.repository;

import com.eusd.entity.SystemConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SystemConfigRepository extends JpaRepository<SystemConfig, UUID> {

    Optional<SystemConfig> findByConfigGroupAndConfigKey(String configGroup, String configKey);

    List<SystemConfig> findByConfigGroup(String configGroup);

    List<SystemConfig> findByConfigGroupOrderByConfigKeyAsc(String configGroup);
}
