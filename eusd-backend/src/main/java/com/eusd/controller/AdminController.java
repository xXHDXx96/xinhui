package com.eusd.controller;

import com.eusd.entity.PaymentAgreement;
import com.eusd.entity.SupportTicket;
import com.eusd.repository.PaymentAgreementRepository;
import com.eusd.repository.SupportTicketRepository;
import com.eusd.service.AlipayService;
import com.eusd.service.UnionPayService;
import com.eusd.service.WechatPayService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final SupportTicketRepository ticketRepository;
    private final PaymentAgreementRepository agreementRepository;
    private final AlipayService alipayService;
    private final WechatPayService wechatPayService;
    private final UnionPayService unionPayService;

    /**
     * 工单列表（分页 + 筛选）
     */
    @GetMapping("/tickets")
    public Map<String, Object> listTickets(@RequestParam(required = false) String status,
                                            @RequestParam(required = false) String type,
                                            @RequestParam(defaultValue = "0") int page,
                                            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<SupportTicket> ticketPage = ticketRepository.findByFilters(status, type, pageable);

        List<Map<String, Object>> enriched = new ArrayList<>();
        for (SupportTicket t : ticketPage.getContent()) {
            Map<String, Object> m = new HashMap<>();
            m.put("id", t.getId());
            m.put("userId", t.getUserId());
            m.put("type", t.getType());
            m.put("status", t.getStatus());
            m.put("remark", t.getRemark());
            m.put("rejectReason", t.getRejectReason());
            m.put("createdAt", t.getCreatedAt());
            m.put("resolvedAt", t.getResolvedAt());

            if (t.getAgreementId() != null) {
                agreementRepository.findById(t.getAgreementId()).ifPresent(a -> {
                    m.put("channel", a.getChannel());
                    m.put("agreementNo", a.getAgreementNo());
                    m.put("externalAgreementNo", a.getExternalAgreementNo());
                });
            }
            enriched.add(m);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("content", enriched);
        result.put("totalElements", ticketPage.getTotalElements());
        result.put("totalPages", ticketPage.getTotalPages());
        result.put("page", page);
        result.put("size", size);
        return result;
    }

    /**
     * 工单详情
     */
    @GetMapping("/tickets/{id}")
    public Map<String, Object> ticketDetail(@PathVariable String id) {
        UUID tid = UUID.fromString(id);
        SupportTicket ticket = ticketRepository.findById(tid).orElse(null);

        Map<String, Object> result = new HashMap<>();
        if (ticket == null) {
            result.put("success", false);
            result.put("message", "工单不存在");
            return result;
        }

        result.put("id", ticket.getId());
        result.put("userId", ticket.getUserId());
        result.put("type", ticket.getType());
        result.put("status", ticket.getStatus());
        result.put("remark", ticket.getRemark());
        result.put("rejectReason", ticket.getRejectReason());
        result.put("createdAt", ticket.getCreatedAt());
        result.put("resolvedAt", ticket.getResolvedAt());
        result.put("assignedAdminId", ticket.getAssignedAdminId());

        if (ticket.getAgreementId() != null) {
            agreementRepository.findById(ticket.getAgreementId()).ifPresent(a -> {
                result.put("channel", a.getChannel());
                result.put("agreementNo", a.getAgreementNo());
                result.put("externalAgreementNo", a.getExternalAgreementNo());
                result.put("contractId", a.getContractId());
                result.put("planId", a.getPlanId());
                result.put("contractCode", a.getContractCode());
                result.put("agreementStatus", a.getStatus());
                result.put("signedAt", a.getSignedAt());
            });
        }
        return result;
    }

    /**
     * 客服审批通过 → 调用渠道真实解约 API
     */
    @PostMapping("/approve-terminate")
    public Map<String, Object> approveTerminate(@RequestParam String ticketId,
                                                  @RequestParam(required = false) String adminId) {
        UUID tid = UUID.fromString(ticketId);
        Map<String, Object> result = new HashMap<>();

        SupportTicket ticket = ticketRepository.findById(tid).orElse(null);
        if (ticket == null) {
            result.put("success", false);
            result.put("message", "工单不存在");
            return result;
        }

        if (!"PENDING".equals(ticket.getStatus())) {
            result.put("success", false);
            result.put("message", "工单已处理，当前状态：" + ticket.getStatus());
            return result;
        }

        PaymentAgreement agreement = agreementRepository.findById(ticket.getAgreementId()).orElse(null);
        if (agreement == null) {
            result.put("success", false);
            result.put("message", "关联协议不存在");
            return result;
        }

        boolean terminated = false;
        String errorMsg = null;

        try {
            switch (agreement.getChannel()) {
                case "ALIPAY":
                    terminated = alipayService.unsign(
                        agreement.getAgreementNo(),
                        agreement.getExternalAgreementNo());
                    if (!terminated) errorMsg = "支付宝解约失败";
                    break;
                case "WECHAT":
                    terminated = wechatPayService.terminateContract(
                        agreement.getPlanId(),
                        agreement.getContractCode());
                    if (!terminated) errorMsg = "微信解约失败";
                    break;
                case "UNIONPAY":
                    terminated = unionPayService.terminateContract(
                        agreement.getContractId());
                    if (!terminated) errorMsg = "云闪付解约失败";
                    break;
                default:
                    errorMsg = "未知渠道: " + agreement.getChannel();
            }
        } catch (Exception e) {
            log.error("调用渠道解约 API 异常", e);
            errorMsg = "渠道解约异常: " + e.getMessage();
        }

        if (terminated) {
            agreement.setStatus("TERMINATED");
            agreement.setTerminatedAt(LocalDateTime.now());
            agreement.setTerminatedReason("客服审批通过，用户主动解约");
            agreementRepository.save(agreement);

            ticket.setStatus("APPROVED");
            ticket.setResolvedAt(LocalDateTime.now());
            if (adminId != null && !adminId.isEmpty()) {
                ticket.setAssignedAdminId(UUID.fromString(adminId));
            }
            ticketRepository.save(ticket);

            log.info("解约成功: ticketId={}, userId={}, channel={}",
                tid, ticket.getUserId(), agreement.getChannel());

            result.put("success", true);
            result.put("message", "解约成功");
        } else {
            result.put("success", false);
            result.put("message", errorMsg != null ? errorMsg : "解约失败，请重试");
        }
        return result;
    }

    /**
     * 客服拒绝解约 → 协议状态回滚为 SIGNED
     */
    @PostMapping("/reject-terminate")
    public Map<String, Object> rejectTerminate(@RequestParam String ticketId,
                                                 @RequestParam(required = false) String adminId,
                                                 @RequestParam(required = false) String reason) {
        UUID tid = UUID.fromString(ticketId);
        Map<String, Object> result = new HashMap<>();

        SupportTicket ticket = ticketRepository.findById(tid).orElse(null);
        if (ticket == null) {
            result.put("success", false);
            result.put("message", "工单不存在");
            return result;
        }

        if (!"PENDING".equals(ticket.getStatus())) {
            result.put("success", false);
            result.put("message", "工单已处理");
            return result;
        }

        if (ticket.getAgreementId() != null) {
            agreementRepository.findById(ticket.getAgreementId()).ifPresent(a -> {
                a.setStatus("SIGNED");
                agreementRepository.save(a);
            });
        }

        ticket.setStatus("REJECTED");
        ticket.setRejectReason(reason != null ? reason : "未说明原因");
        ticket.setResolvedAt(LocalDateTime.now());
        if (adminId != null && !adminId.isEmpty()) {
            ticket.setAssignedAdminId(UUID.fromString(adminId));
        }
        ticketRepository.save(ticket);

        log.info("解约申请已拒绝: ticketId={}, userId={}, reason={}",
            tid, ticket.getUserId(), reason);

        result.put("success", true);
        result.put("message", "已拒绝解约申请");
        return result;
    }

    /**
     * 统计面板
     */
    @GetMapping("/stats")
    public Map<String, Object> stats() {
        Map<String, Object> result = new HashMap<>();

        long pendingCount = ticketRepository.countByStatus("PENDING");
        long approvedCount = ticketRepository.countByStatus("APPROVED");
        long rejectedCount = ticketRepository.countByStatus("REJECTED");

        result.put("pendingTickets", pendingCount);
        result.put("approvedTickets", approvedCount);
        result.put("rejectedTickets", rejectedCount);
        result.put("totalTickets", pendingCount + approvedCount + rejectedCount);
        return result;
    }

    /**
     * 查询协议详情（调试用）
     */
    @GetMapping("/agreement/{agreementId}")
    public Map<String, Object> agreementDetail(@PathVariable String agreementId) {
        UUID aid = UUID.fromString(agreementId);
        PaymentAgreement agreement = agreementRepository.findById(aid).orElse(null);

        Map<String, Object> result = new HashMap<>();
        if (agreement == null) {
            result.put("success", false);
            result.put("message", "协议不存在");
            return result;
        }
        result.put("success", true);
        result.put("agreement", agreement);
        return result;
    }
}
