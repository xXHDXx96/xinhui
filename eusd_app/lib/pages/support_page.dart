import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  // ===== 改这里：你的 TG 客服号 =====
  static const String mainSupport = 'your_support';
  static const String vipSupport = 'your_vip';
  static const String channelName = 'your_channel';
  // ==================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('客服中心'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statusCard(context),
          const SizedBox(height: 20),
          const Text('选择客服',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _supportItem(context,
            icon: Icons.headset_mic,
            color: const Color(0xFF00C853),
            title: '在线人工客服',
            subtitle: '7×24 小时在线 · 平均 1 分钟内回复',
            badge: '在线',
            username: mainSupport),
          _supportItem(context,
            icon: Icons.workspace_premium,
            color: const Color(0xFFFFB300),
            title: 'VIP 专属客服',
            subtitle: '尊享用户专线 · 优先处理',
            username: vipSupport),
          const SizedBox(height: 20),
          const Text('官方频道',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _supportItem(context,
            icon: Icons.campaign_outlined,
            color: const Color(0xFF8888FF),
            title: 'Telegram 官方频道',
            subtitle: '最新公告 · 活动通知',
            username: channelName,
            isChannel: true),
          const SizedBox(height: 20),
          const Text('常见问题',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _faq('如何申请虚拟卡？', '进入「卡片」页 → 点击右上角「+」 → 选择虚拟卡或实体卡'),
          _faq('充值多久到账？', '支付完成后提交单号，客服将在 5 分钟内审核入账'),
          _faq('如何解约代扣协议？', '进入「我的」 → 支付方式管理 → 申请解约'),
          _faq('卡片被冻结怎么办？', '联系在线客服处理'),
          _faq('充值未到账怎么办？', '联系在线客服并提供订单号'),
          const SizedBox(height: 32),
          Center(child: Text('客服工作时间：7×24 小时在线',
            style: TextStyle(color: Colors.grey[600], fontSize: 12))),
          const SizedBox(height: 8),
          Center(child: Text('版本 V 1.0.0',
            style: TextStyle(color: Colors.grey[700], fontSize: 11))),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _statusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0088CC), Color(0xFF00A8E8)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle),
          child: const Icon(Icons.telegram, color: Colors.white, size: 32)),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Telegram 在线客服',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(children: [
              Container(width: 8, height: 8,
                decoration: const BoxDecoration(color: Color(0xFF00FF88), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('客服在线中 · 点击立即对话',
                style: TextStyle(color: Colors.white70, fontSize: 12.5)),
            ]),
          ],
        )),
        const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
      ]),
    );
  }

  Widget _supportItem(BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String username,
    String? badge,
    bool isChannel = false,
  }) {
    return GestureDetector(
      onTap: () => _openTelegram(context, username),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1F1F1F))),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(title, style: const TextStyle(color: Colors.white,
                  fontSize: 15, fontWeight: FontWeight.w600)),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4)),
                    child: Text(badge,
                      style: const TextStyle(color: Color(0xFF00C853), fontSize: 10))),
                ],
              ]),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
              const SizedBox(height: 4),
              Text('@$username',
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          )),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ]),
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
          title: Text(q, style: const TextStyle(color: Colors.white,
            fontSize: 14, fontWeight: FontWeight.w500)),
          children: [
            Align(alignment: Alignment.centerLeft,
              child: Text(a, style: const TextStyle(
                color: Colors.grey, fontSize: 13, height: 1.6))),
          ],
        ),
      ),
    );
  }

  Future<void> _openTelegram(BuildContext context, String username) async {
    final url = 'https://t.me/$username';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showCopyDialog(context, username);
      }
    } catch (e) {
      _showCopyDialog(context, username);
    }
  }

  void _showCopyDialog(BuildContext context, String username) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('未安装 Telegram',
          style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请先安装 Telegram，或复制客服号手动添加：',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Expanded(child: Text('@$username',
                  style: const TextStyle(color: Color(0xFF00C853),
                    fontSize: 14, fontWeight: FontWeight.w600))),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.grey, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: '@$username'));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('客服号已复制'),
                        behavior: SnackBarBehavior.floating));
                  }),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}
