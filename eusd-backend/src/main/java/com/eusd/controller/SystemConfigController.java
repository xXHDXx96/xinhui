package com.eusd.controller;

import com.eusd.entity.SystemConfig;
import com.eusd.service.SystemConfigService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/admin/config")
@RequiredArgsConstructor
public class SystemConfigController {

    private final SystemConfigService service;

    /** 所有分组 */
    @GetMapping("/groups")
    public Map<String, Object> groups() {
        Map<String, Object> r = new HashMap<>();
        r.put("success", true);
        r.put("groups", service.listGroups());
        return r;
    }

    /** 某分组下所有配置 */
    @GetMapping("/list/{group}")
    public Map<String, Object> list(@PathVariable String group) {
        List<Map<String, Object>> items = new ArrayList<>();
        for (SystemConfig c : service.listByGroup(group)) {
            Map<String, Object> m = new HashMap<>();
            m.put("id", c.getId());
            m.put("key", c.getConfigKey());
            m.put("value", Boolean.TRUE.equals(c.getIsSecret()) ? mask(c.getConfigValue()) : c.getConfigValue());
            m.put("displayName", c.getDisplayName());
            m.put("isSecret", c.getIsSecret());
            m.put("description", c.getDescription());
            m.put("updatedAt", c.getUpdatedAt());
            items.add(m);
        }
        Map<String, Object> r = new HashMap<>();
        r.put("success", true);
        r.put("items", items);
        return r;
    }

    /** 新增或修改配置 */
    @PostMapping("/set")
    public Map<String, Object> set(@RequestParam String group,
                                    @RequestParam String key,
                                    @RequestParam String value,
                                    @RequestParam(required = false) String displayName,
                                    @RequestParam(required = false) Boolean isSecret,
                                    @RequestParam(required = false) String description) {
        Map<String, Object> r = new HashMap<>();
        try {
            SystemConfig cfg = service.set(group, key, value, displayName, isSecret, description);
            service.reload();
            r.put("success", true);
            r.put("id", cfg.getId());
            r.put("message", "配置已保存（部分配置需要重启后端生效）");
        } catch (Exception e) {
            r.put("success", false);
            r.put("message", e.getMessage());
        }
        return r;
    }

    /** 删除配置 */
    @DeleteMapping("/delete/{id}")
    public Map<String, Object> delete(@PathVariable String id) {
        Map<String, Object> r = new HashMap<>();
        try {
            service.delete(UUID.fromString(id));
            service.reload();
            r.put("success", true);
            r.put("message", "已删除");
        } catch (Exception e) {
            r.put("success", false);
            r.put("message", e.getMessage());
        }
        return r;
    }

    /** 手动刷新缓存 */
    @PostMapping("/reload")
    public Map<String, Object> reload() {
        service.reload();
        Map<String, Object> r = new HashMap<>();
        r.put("success", true);
        r.put("message", "缓存已刷新");
        return r;
    }

    /** 敏感值脱敏 */
    private String mask(String s) {
        if (s == null || s.length() <= 6) return "******";
        return s.substring(0, 3) + "******" + s.substring(s.length() - 3);
    }
}
