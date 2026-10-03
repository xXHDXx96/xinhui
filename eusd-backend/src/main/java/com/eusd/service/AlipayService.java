package com.eusd.service;

import com.alipay.api.AlipayClient;
import com.alipay.api.domain.AgreementParams;
import com.alipay.api.domain.AlipayTradePayModel;
import com.alipay.api.domain.AlipayUserAgreementPageSignModel;
import com.alipay.api.domain.AlipayUserAgreementUnsignModel;
import com.alipay.api.internal.util.AlipaySignature;
import com.alipay.api.request.AlipayTradePayRequest;
import com.alipay.api.request.AlipayUserAgreementPageSignRequest;
import com.alipay.api.request.AlipayUserAgreementUnsignRequest;
import com.alipay.api.response.AlipayTradePayResponse;
import com.alipay.api.response.AlipayUserAgreementPageSignResponse;
import com.alipay.api.response.AlipayUserAgreementUnsignResponse;
import com.eusd.repository.PaymentAgreementRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AlipayService {

    private final AlipayClient alipayClient;
    private final PaymentAgreementRepository agreementRepository;

    @Value("${alipay.notify-url}")
    private String notifyUrl;

    @Value("${alipay.return-url}")
    private String returnUrl;

    @Value("${alipay.alipay-public-key}")
    private String alipayPublicKey;

    /**
     * 生成签约链接
     */
    public String createSignUrl(UUID userId, String externalAgreementNo) {
        try {
            AlipayUserAgreementPageSignRequest request = new AlipayUserAgreementPageSignRequest();
            request.setNotifyUrl(notifyUrl);
            request.setReturnUrl(returnUrl);

            AlipayUserAgreementPageSignModel model = new AlipayUserAgreementPageSignModel();
            model.setPersonalProductCode("GENERAL_WITHHOLDING_P");
            model.setSignScene("INDUSTRY|CARRENTAL");
            model.setExternalAgreementNo(externalAgreementNo);
            model.setProductCode("CYCLE_PAY_AUTH");
            request.setBizModel(model);

            AlipayUserAgreementPageSignResponse response = alipayClient.pageExecute(request);
            if (response.isSuccess()) {
                log.info("支付宝签约链接生成成功: userId={}", userId);
                return response.getBody();
            }
            throw new RuntimeException("ALIPAY_SIGN_FAILED: " + response.getSubMsg());
        } catch (Exception e) {
            log.error("生成支付宝签约链接异常", e);
            throw new RuntimeException("ALIPAY_SIGN_EXCEPTION", e);
        }
    }

    /**
     * 主动扣款
     */
    public boolean deduct(String agreementNo, String outTradeNo,
                          BigDecimal amount, String subject) {
        try {
            AlipayTradePayRequest request = new AlipayTradePayRequest();
            AlipayTradePayModel model = new AlipayTradePayModel();
            model.setOutTradeNo(outTradeNo);
            model.setSubject(subject);
            model.setTotalAmount(amount.toPlainString());
            model.setProductCode("GENERAL_WITHHOLDING");

            AgreementParams ap = new AgreementParams();
            ap.setAgreementNo(agreementNo);
            model.setAgreementParams(ap);
            request.setBizModel(model);

            AlipayTradePayResponse response = alipayClient.execute(request);
            if (response.isSuccess()) {
                log.info("支付宝扣款成功: outTradeNo={}, amount={}", outTradeNo, amount);
                return true;
            }
            log.warn("支付宝扣款失败: outTradeNo={}, code={}, msg={}",
                outTradeNo, response.getSubCode(), response.getSubMsg());
            return false;
        } catch (Exception e) {
            log.error("支付宝扣款异常: outTradeNo={}", outTradeNo, e);
            return false;
        }
    }

    /**
     * 解约
     */
    public boolean unsign(String agreementNo, String externalAgreementNo) {
        try {
            AlipayUserAgreementUnsignRequest request = new AlipayUserAgreementUnsignRequest();
            AlipayUserAgreementUnsignModel model = new AlipayUserAgreementUnsignModel();
            model.setAgreementNo(agreementNo);
            model.setExternalAgreementNo(externalAgreementNo);
            request.setBizModel(model);

            AlipayUserAgreementUnsignResponse response = alipayClient.execute(request);
            if (response.isSuccess()) {
                log.info("支付宝解约成功: agreementNo={}", agreementNo);
                return true;
            }
            log.warn("支付宝解约失败: agreementNo={}, msg={}", agreementNo, response.getSubMsg());
            return false;
        } catch (Exception e) {
            log.error("支付宝解约异常: agreementNo={}", agreementNo, e);
            return false;
        }
    }

    /**
     * 验证回调签名
     */
    public boolean verifyNotify(Map<String, String> params) {
        try {
            return AlipaySignature.rsaCheckV1(params, alipayPublicKey, "UTF-8", "RSA2");
        } catch (Exception e) {
            log.error("支付宝回调验签异常", e);
            return false;
        }
    }

    /**
     * 处理签约成功回调
     */
    public void handleSignNotify(Map<String, String> params) {
        String external = params.get("external_agreement_no");
        String agreementNo = params.get("agreement_no");
        String status = params.get("status");

        log.info("支付宝签约回调: ext={}, agreementNo={}, status={}",
            external, agreementNo, status);

        if (!"NORMAL".equals(status)) {
            log.warn("签约状态非 NORMAL: {}", status);
            return;
        }

        agreementRepository.findByExternalAgreementNo(external).ifPresent(a -> {
            a.setAgreementNo(agreementNo);
            a.setStatus("SIGNED");
            agreementRepository.save(a);
            log.info("支付宝协议已激活: userId={}", a.getUserId());
        });
    }
}
