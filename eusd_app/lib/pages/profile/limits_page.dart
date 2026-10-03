import 'package:flutter/material.dart';

class LimitsPage extends StatelessWidget {
  const LimitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('账户限额')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('充值限额'),
          _limitCard([
            {'label': '单笔限额', 'value': '50,000 CNY'},
            {'label': '每日限额', 'value': '200,000 CNY'},
            {'label': '每月限额', 'value': '1,000,000 CNY'},
          ]),
          const SizedBox(height: 20),
          _sectionTitle('消费限额'),
          _limitCard([
            {'label': '每笔消费', 'value': '500,000 USD'},
            {'label': '每日总消费', 'value': '5,000,000 USD'},
            {'label': '每月总消费', 'value': '10,000,000 USD'},
          ]),
          const SizedBox(height: 20),
          _sectionTitle('ATM 提现'),
          _limitCard([
            {'label': '每笔 ATM 提现', 'value': '10,000 USD'},
            {'label': '每日 ATM 提现', 'value': '50,000 USD'},
            {'label': '每月 ATM 提现', 'value': '1,000,000 USD'},
          ]),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3))),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('如需提高限额，请联系在线客服申请',
                style: TextStyle(color: Color(0xFFFF9800), fontSize: 12.5))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(t, style: const TextStyle(color: Colors.grey,
      fontSize: 12.5, fontWeight: FontWeight.w500)));

  Widget _limitCard(List<Map<String, String>> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Column(
        children: List.generate(rows.length, (i) {
          final r = rows[i];
          return Padding(
            padding: EdgeInsets.only(
              bottom: i == rows.length - 1 ? 0 : 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r['label']!, style: const TextStyle(
                  color: Colors.grey, fontSize: 13)),
                Text(r['value']!, style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }),
      ),
    );
  }
}
