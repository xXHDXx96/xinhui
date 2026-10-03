import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InvitePage extends StatelessWidget {
  const InvitePage({super.key});

  // 改成你的邀请链接或邀请码
  static const String inviteCode = 'XH888888';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('邀请并赚取')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF2A1A3E)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              border: Border.all(color: const Color(0xFF333344))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.card_giftcard, color: Color(0xFF8888FF), size: 28),
                  SizedBox(width: 10),
                  Text('邀请好友 · 赚取奖励',
                    style: TextStyle(color: Colors.white,
                      fontSize: 17, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 12),
                const Text('每成功邀请一位好友注册并完成首充，最高可获 \$5 奖励',
                  style: TextStyle(color: Colors.white70,
                    fontSize: 13, height: 1.6)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Text('邀请码', style: TextStyle(
                      color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(inviteCode,
                      style: const TextStyle(color: Colors.white,
                        fontSize: 18, fontWeight: FontWeight.bold,
                        letterSpacing: 2))),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('邀请码已复制'),
                            behavior: SnackBarBehavior.floating));
                      }),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('邀请规则', style: TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _rule(1, '分享邀请码给好友'),
          _rule(2, '好友注册并完成首次充值'),
          _rule(3, '奖励自动发放到您的账户'),
          _rule(4, '邀请无上限，多邀多得'),
        ],
      ),
    );
  }

  Widget _rule(int no, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Row(children: [
        Container(
          width: 26, height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFF00C853), shape: BoxShape.circle),
          child: Center(child: Text('$no',
            style: const TextStyle(color: Colors.white,
              fontSize: 12, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(
          color: Colors.white70, fontSize: 13.5))),
      ]),
    );
  }
}
