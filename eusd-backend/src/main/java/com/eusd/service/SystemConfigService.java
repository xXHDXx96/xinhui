package com.eusd.service;

import com.eusd.entity.SystemConfig;
import com.eusd.repository.SystemConfigRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class SystemConfigService {

    private final SystemConfigRepository repo;

    /** 取一个配置值，没有就返回默认 */
    public String get(String group, String key, String defaultValue) {
        return repo.findByConfigGroupAndConfigKey(group, key)
            .map(SystemConfig::getConfigValue)
            .orElse(defaultValue);
    }

    /** 取分组下所有配置 */
    public List<SystemConfig> listByGroup(String group) {
        return repo.findByConfigGroupOrderByConfigKeyAsc(group);
    }

    /** 全部分组列表 */
    public List<String> listGroups() {
        return List.of("ALCHEMY", "TRON", "PAYMENT", "ALIPAY", "WECHAT", "STRIPE", "SYSTEM");
    }

    /** 设置/更新配置 */
    @Transactional
    public SystemConfig set(String group, String key, String value,
                             String displayName, Boolean isSecret, String description) {
        SystemConfig cfg = repo.findByConfigGroupAndConfigKey(group, key)
            .orElseGet(() -> SystemConfig.builder()
                .configGroup(group)
                .configKey(key)
                .build());

        cfg.setConfigValue(value);
        if (displayName != null) cfg.setDisplayName(displayName);
        if (isSecret != null) cfg.setIsSecret(isSecret);
        if (description != null) cfg.setDescription(description);

        repo.save(cfg);
        log.info("配置已更新: {}.{}", group, key);
        return cfg;
    }

    /** 批量设置（用于初始化） */
    @Transactional
    public void initDefault(String group, String key, String defaultValue,
                             String displayName, Boolean isSecret, String description) {
        if (repo.findByConfigGroupAndConfigKey(group, key).isPresent()) return;
        repo.save(SystemConfig.builder()
            .configGroup(group)
            .configKey(key)
            .configValue(defaultValue)
            .displayName(displayName)
            .isSecret(isSecret != null && isSecret)
            .description(description)
            .build());
    }

    /** 删除一个配置 */
    @Transactional
    public void delete(UUID id) {
        repo.deleteById(id);
        log.info("配置已删除: {}", id);
    }

    /** 把某分组所有配置导出为 Map */
    public Map<String, String> getGroupMap(String group) {
        Map<String, String> map = new HashMap<>();
        for (SystemConfig c : repo.findByConfigGroup(group)) {
            map.put(c.getConfigKey(), c.getConfigValue());
        }
        return map;
    }

    /** 启动时把所有配置加载到内存缓存 */
    private final Map<String, String> cache = new HashMap<>();

    public void reload() {
        cache.clear();
        for (SystemConfig c : repo.findAll()) {
            cache.put(c.getConfigGroup() + "." + c.getConfigKey(), c.getConfigValue());
        }
        log.info("配置缓存已刷新，共 {} 项", cache.size());
    }

    public String getCached(String group, String key, String defaultValue) {
        String v = cache.get(group + "." + key);
        return (v == null || v.isEmpty()) ? defaultValue : v;
    }
}
