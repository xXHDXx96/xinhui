import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于 eUSD.com')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 88, height: 88,
              decoration: const BoxDecoration(
                color: Color(0xFF00C853), shape: BoxShape.circle),
              child: const Center(
                child: Text('e', style: TextStyle(
                  color: Colors.white, fontSize: 48,
                  fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('鑫汇Pay', style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text('V 1.0.0', style: TextStyle(
              color: Colors.grey, fontSize: 13)),
          ),
          const SizedBox(height: 30),
          _section('产品介绍',
            '鑫汇Pay 是一款数字资产支付管理应用，为用户提供安全、便捷的充值、兑换、虚拟卡管理等服务。'
            '我们致力于连接法币和加密资产，让数字资产支付变得像日常支付一样简单。'),
          const SizedBox(height: 16),
          _section('核心功能',
            '• 法币充值：支持支付宝、微信、云闪付\n'
            '• 数字资产：USDT、USDC、USD 多币种\n'
            '• 虚拟卡：即时申请、全球消费\n'
            '• 实体卡：全球邮寄、NFC 支付\n'
            '• 货币兑换：实时汇率、极速到账\n'
            '• 安全防护：多重加密、冷钱包隔离'),
          const SizedBox(height: 16),
          _section('联系我们',
            '客服邮箱：cs@eusd.com\n'
            'Telegram：@your_support\n'
            '官方网站：eusd.com'),
          const SizedBox(height: 24),
          _infoRow('版本号', 'V 1.0.0'),
          _infoRow('构建日期', '2026-10-02'),
          _infoRow('服务条款', '点击查看', onTap: () {}),
          _infoRow('隐私政策', '点击查看', onTap: () {}),
          const SizedBox(height: 24),
          const Center(
            child: Text('© 2026 鑫汇Pay\nAll Rights Reserved',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.8)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(
            color: Colors.grey, fontSize: 13, height: 1.7)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1F1F1F))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(
              color: Colors.grey, fontSize: 13)),
            Row(children: [
              Text(value, style: const TextStyle(
                color: Colors.white, fontSize: 13)),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}
