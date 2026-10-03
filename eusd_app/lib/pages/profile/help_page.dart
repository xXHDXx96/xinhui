import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  // 改成你的 TG 客服号
  static const String supportTg = 'your_support';
  static const String supportEmail = 'cs@eusd.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('帮助中心')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2A1E), Color(0xFF00C853)],
                begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Column(children: [
              const Icon(Icons.support_agent, color: Colors.white, size: 40),
              const SizedBox(height: 12),
              const Text('需要帮助？', style: TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('7×24 小时在线客服为您服务',
                style: TextStyle(color: Colors.white70, fontSize: 12.5)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 44,
                child: ElevatedButton(
                  onPressed: () => _openTg(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F2A1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
                  child: const Text('联系在线客服',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('常见问题', style: TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _faq('如何申请虚拟卡？',
            '进入「卡片」页 → 点击右上角「+」 → 选择虚拟卡或实体卡，按照提示完成申请。虚拟卡即时发放，实体卡需要 4-6 周邮寄。'),
          _faq('充值多久到账？',
            '用户在 App 选择支付方式，输入金额生成收款码，付款后提交支付单号，客服将在 5 分钟内审核。审核通过后 USDT 自动到账。'),
          _faq('如何解约代扣协议？',
            '进入「我的」→「支付方式管理」→ 选择要解约的协议 → 点击「申请解约」。客服将在 24 小时内处理。'),
          _faq('卡片被冻结怎么办？',
            '进入卡片详情页，点击右上角「更多」→「解冻该卡片」。如果无法解冻，请联系在线客服处理。'),
          _faq('充值未到账怎么办？',
            '请先确认支付单号是否填写正确。如果超过 30 分钟仍未到账，请联系在线客服并提供订单号。'),
          _faq('兑换手续费是多少？',
            'CNY 到 USDT 兑换手续费为 0.5%，其他币种之间兑换同样按 0.5% 收取。费用在兑换前会明确显示。'),
          _faq('忘记密码怎么办？',
            '在登录页点击「忘记密码」，或联系在线客服通过邮箱验证重置密码。'),
          _faq('账户被限制怎么办？',
            '如果您的账户因异常活动被限制，请联系在线客服，提供相关信息申请解除限制。'),
          const SizedBox(height: 24),
          const Text('联系方式', style: TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _contactItem(context, Icons.telegram, 'Telegram 客服',
            '@$supportTg', () => _openTg(context)),
          _contactItem(context, Icons.mail_outline, '客服邮箱',
            supportEmail, () => _copyText(context, supportEmail)),
        ],
      ),
    );
  }

  Widget _faq(String q, String a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Theme(
        data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: const Color(0xFF00C853),
          collapsedIconColor: Colors.grey,
          title: Text(q, style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          children: [
            Align(alignment: Alignment.centerLeft,
              child: Text(a, style: const TextStyle(
                color: Colors.grey, fontSize: 13, height: 1.7))),
          ],
        ),
      ),
    );
  }

  Widget _contactItem(BuildContext context, IconData icon,
                       String title, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1F1F1F))),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF00C853), size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white,
                fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
            ],
          )),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ]),
      ),
    );
  }

  Future<void> _openTg(BuildContext context) async {
    final url = 'https://t.me/$supportTg';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _copyText(context, '@$supportTg');
      }
    } catch (_) {
      _copyText(context, '@$supportTg');
    }
  }

  void _copyText(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制: $text'),
        behavior: SnackBarBehavior.floating));
  }
}
