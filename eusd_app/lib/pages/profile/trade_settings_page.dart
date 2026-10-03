import 'package:flutter/material.dart';

class TradeSettingsPage extends StatefulWidget {
  const TradeSettingsPage({super.key});
  @override
  State<TradeSettingsPage> createState() => _TradeSettingsPageState();
}

class _TradeSettingsPageState extends State<TradeSettingsPage> {
  bool _priceAlert = true;
  bool _tradeNotify = true;
  bool _slippage = false;

  String _defaultAsset = 'USDT';
  String _slippageValue = '0.5%';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('交易设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('默认资产', style: TextStyle(
            color: Colors.grey, fontSize: 12.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1F1F1F))),
            child: DropdownButton<String>(
              value: _defaultAsset,
              isExpanded: true,
              dropdownColor: const Color(0xFF1F1F1F),
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: const [
                DropdownMenuItem(value: 'USDT', child: Text('USDT 泰达币')),
                DropdownMenuItem(value: 'USDC', child: Text('USDC 美元币')),
                DropdownMenuItem(value: 'USD', child: Text('USD 美元')),
              ],
              onChanged: (v) => setState(() => _defaultAsset = v ?? 'USDT'),
            ),
          ),
          const SizedBox(height: 20),
          const Text('滑点容忍度', style: TextStyle(
            color: Colors.grey, fontSize: 12.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1F1F1F))),
            child: DropdownButton<String>(
              value: _slippageValue,
              isExpanded: true,
              dropdownColor: const Color(0xFF1F1F1F),
              underline: const SizedBox(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: const [
                DropdownMenuItem(value: '0.1%', child: Text('0.1%')),
                DropdownMenuItem(value: '0.5%', child: Text('0.5%')),
                DropdownMenuItem(value: '1.0%', child: Text('1.0%')),
                DropdownMenuItem(value: '3.0%', child: Text('3.0%')),
              ],
              onChanged: (v) => setState(() => _slippageValue = v ?? '0.5%'),
            ),
          ),
          const SizedBox(height: 24),
          _switchItem(
            icon: Icons.notifications_active_outlined,
            title: '价格预警',
            subtitle: '关注资产价格异动时推送提醒',
            value: _priceAlert,
            onChanged: (v) => setState(() => _priceAlert = v)),
          _switchItem(
            icon: Icons.receipt_long_outlined,
            title: '交易通知',
            subtitle: '交易成功/失败时推送提醒',
            value: _tradeNotify,
            onChanged: (v) => setState(() => _tradeNotify = v)),
          _switchItem(
            icon: Icons.warning_amber_outlined,
            title: '大额交易二次确认',
            subtitle: '超过 10000 USD 的交易需要二次确认',
            value: _slippage,
            onChanged: (v) => setState(() => _slippage = v)),
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
}
