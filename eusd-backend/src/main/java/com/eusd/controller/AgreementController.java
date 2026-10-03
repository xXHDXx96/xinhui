package com.eusd.controller;

import com.eusd.entity.PaymentAgreement;
import com.eusd.entity.SupportTicket;
import com.eusd.repository.PaymentAgreementRepository;
import com.eusd.repository.SupportTicketRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/agreement")
@RequiredArgsConstructor
public class AgreementController {

    private final PaymentAgreementRepository agreementRepository;
    private final SupportTicketRepository ticketRepository;

    /**
     * 查询用户所有签约协议
     */
    @GetMapping("/list/{userId}")
    public Map<String, Object> list(@PathVariable String userId) {
        UUID uid = UUID.fromString(userId);
        List<PaymentAgreement> agreements = agreementRepository.findByUserId(uid);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("agreements", agreements);
        return result;
    }

    /**
     * 查询用户已签约的有效协议
     */
    @GetMapping("/signed/{userId}")
    public Map<String, Object> signed(@PathVariable String userId) {
        UUID uid = UUID.fromString(userId);
        List<PaymentAgreement> agreements =
            agreementRepository.findByUserIdAndStatus(uid, "SIGNED");

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("agreements", agreements);
        return result;
    }

    /**
     * 用户发起解约申请
     * 不直接解约，而是创建客服工单，状态改为 PENDING_TERMINATION
     */
    @PostMapping("/request-terminate")
    public Map<String, Object> requestTerminate(@RequestParam String userId,
                                                  @RequestParam String agreementId) {
        UUID uid = UUID.fromString(userId);
        UUID aid = UUID.fromString(agreementId);

        Map<String, Object> result = new HashMap<>();

        PaymentAgreement agreement = agreementRepository.findById(aid).orElse(null);
        if (agreement == null) {
            result.put("success", false);
            result.put("message", "协议不存在");
            return result;
        }

        if (!agreement.getUserId().equals(uid)) {
            result.put("success", false);
            result.put("message", "无权操作该协议");
            return result;
        }

        if (!"SIGNED".equals(agreement.getStatus())) {
            result.put("success", false);
            result.put("message", "当前协议状态为「" + agreement.getStatus() + "」，无法申请解约");
            return result;
        }

        List<SupportTicket> existingTickets = ticketRepository.findByUserIdAndStatus(uid, "PENDING");
        boolean hasPending = existingTickets.stream()
            .anyMatch(t -> aid.equals(t.getAgreementId()));
        if (hasPending) {
            result.put("success", false);
            result.put("message", "已有待处理的解约申请，请勿重复提交");
            return result;
        }

        agreement.setStatus("PENDING_TERMINATION");
        agreementRepository.save(agreement);

        SupportTicket ticket = SupportTicket.builder()
            .userId(uid)
            .agreementId(aid)
            .type("TERMINATION")
            .status("PENDING")
            .remark("用户申请解约，渠道：" + agreement.getChannel())
            .build();
        ticketRepository.save(ticket);

        log.info("解约申请已提交: userId={}, agreementId={}, ticketId={}",
            uid, aid, ticket.getId());

        result.put("success", true);
        result.put("ticketId", ticket.getId());
        result.put("message", "解约申请已提交，客服将在24小时内处理");
        return result;
    }

    /**
     * 查询用户解约工单状态
     */
    @GetMapping("/ticket-status/{userId}")
    public Map<String, Object> ticketStatus(@PathVariable String userId) {
        UUID uid = UUID.fromString(userId);
        List<SupportTicket> tickets = ticketRepository.findByUserId(uid);

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("tickets", tickets);
        return result;
    }

    /**
     * 用户取消解约申请（工单状态还是 PENDING 时可取消）
     */
    @PostMapping("/cancel-terminate")
    public Map<String, Object> cancelTerminate(@RequestParam String userId,
                                                 @RequestParam String ticketId) {
        UUID uid = UUID.fromString(userId);
        UUID tid = UUID.fromString(ticketId);

        Map<String, Object> result = new HashMap<>();

        SupportTicket ticket = ticketRepository.findById(tid).orElse(null);
        if (ticket == null || !ticket.getUserId().equals(uid)) {
            result.put("success", false);
            result.put("message", "工单不存在");
            return result;
        }

        if (!"PENDING".equals(ticket.getStatus())) {
            result.put("success", false);
            result.put("message", "工单已处理，无法取消");
            return result;
        }

        ticket.setStatus("CANCELED");
        ticket.setResolvedAt(LocalDateTime.now());
        ticketRepository.save(ticket);

        if (ticket.getAgreementId() != null) {
            agreementRepository.findById(ticket.getAgreementId()).ifPresent(a -> {
                a.setStatus("SIGNED");
                agreementRepository.save(a);
            });
        }

        log.info("解约申请已取消: userId={}, ticketId={}", uid, tid);
        result.put("success", true);
        result.put("message", "解约申请已取消");
        return result;
    }

    /**
     * 查询协议详情
     */
    @GetMapping("/detail/{agreementId}")
    public Map<String, Object> detail(@PathVariable String agreementId) {
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
