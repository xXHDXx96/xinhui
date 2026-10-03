package com.eusd.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * 系统配置（键值对存储）
 * 支持后台随时增删改，启动时覆盖 application.yml 的默认值
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "system_configs")
public class SystemConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** 配置分组：ALCHEMY / TRON / PAYMENT / ALIPAY / WECHAT / STRIPE / SYSTEM */
    @Column(name = "config_group", length = 30, nullable = false)
    private String configGroup;

    /** 配置键：如 app-id、secret、hot-wallet-address */
    @Column(name = "config_key", length = 100, nullable = false)
    private String configKey;

    /** 配置值 */
    @Column(name = "config_value", length = 512)
    private String configValue;

    /** 显示名称（给后台展示用） */
    @Column(name = "display_name", length = 100)
    private String displayName;

    /** 是否为敏感字段（前台显示为 ***） */
    @Column(name = "is_secret")
    @Builder.Default
    private Boolean isSecret = false;

    /** 备注说明 */
    @Column(name = "description", length = 256)
    private String description;

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
    public void preUpdate() { updatedAt = LocalDateTime.now(); }
}
