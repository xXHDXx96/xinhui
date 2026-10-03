import 'package:flutter/material.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});
  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _pinEnabled = false;
  bool _bioEnabled = false;
  bool _smsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('密钥验证')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00C853).withOpacity(0.3))),
            child: const Row(children: [
              Icon(Icons.shield_outlined, color: Color(0xFF00C853), size: 20),
              SizedBox(width: 10),
              Expanded(child: Text(
                '开启密钥验证可提高账户安全性，转账、提现等敏感操作需二次验证。',
                style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.5))),
            ]),
          ),
          const SizedBox(height: 20),
          _switchItem(
            icon: Icons.pin_outlined,
            title: '支付密码',
            subtitle: '交易时需输入 6 位数字密码',
            value: _pinEnabled,
            onChanged: (v) => setState(() => _pinEnabled = v),
          ),
          _switchItem(
            icon: Icons.fingerprint,
            title: '指纹/面容解锁',
            subtitle: '使用生物识别快速验证',
            value: _bioEnabled,
            onChanged: (v) => setState(() => _bioEnabled = v),
          ),
          _switchItem(
            icon: Icons.sms_outlined,
            title: '短信验证',
            subtitle: '大额交易需短信验证码',
            value: _smsEnabled,
            onChanged: (v) => setState(() => _smsEnabled = v),
          ),
          const SizedBox(height: 20),
          _infoBox('安全提示',
            '建议定期更换密码，不要在公共网络下进行敏感操作。如发现账户异常请立即联系客服。'),
        ],
      ),
    );
  }

  Widget _switchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              fontSize: 14.5, fontWeight: FontWeight.w500)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        )),
        Switch(value: value, onChanged: onChanged,
          activeColor: const Color(0xFF00C853)),
      ]),
    );
  }

  Widget _infoBox(String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.info_outline, color: Color(0xFF00C853), size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white,
              fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          Text(desc, style: const TextStyle(color: Colors.grey,
            fontSize: 12.5, height: 1.6)),
        ],
      ),
    );
  }
}
