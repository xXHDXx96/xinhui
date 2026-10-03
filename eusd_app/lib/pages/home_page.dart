import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/card_provider.dart';
import 'card_management_page.dart';
import 'recharge_page.dart';
import 'support_page.dart';
import 'add_card_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CardProvider>();
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(title: const Text('首页'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A2540), Color(0xFF1E4976)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('总资产 (USD)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Text(fmt.format(p.totalBalance),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(children: [
                  Text('${p.cards.length} 张卡片', style: const TextStyle(color: Colors.white70)),
                  const Spacer(),
                  Text('≈ ¥${(p.totalBalance * 7.24).toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white70)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('快捷操作', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            _quick(context, Icons.add_card, '添加卡片', Colors.blue, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCardPage()));
            }),
            _quick(context, Icons.account_balance_wallet, '充值', Colors.green, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RechargePage()));
            }),
            _quick(context, Icons.swap_horiz, '兑换', Colors.orange, () {}),
            _quick(context, Icons.support_agent, '客服', Colors.purple, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportPage()));
            }),
          ]),
          const SizedBox(height: 24),
          const Text('卡片总览', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...p.cards.take(3).map((c) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: c.brand == 'VISA' ? Colors.blue : Colors.orange,
                    child: Text(c.brand[0], style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text('**** ${c.last4}'),
                  subtitle: Text('${c.currency} ${c.balance.toStringAsFixed(2)}'),
                  trailing: Text(
                    c.status.toUpperCase(),
                    style: TextStyle(
                      color: c.isActive ? Colors.green : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 24),
          const Text('最近交易', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._txns(),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.card_giftcard, color: Colors.amber),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('邀请好友', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('每邀请一位得 \$5', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              ElevatedButton(onPressed: () {}, child: const Text('立即邀请')),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _quick(BuildContext ctx, IconData i, String label, Color c, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(i, color: c),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }

  List<Widget> _txns() {
    final items = [
      ('Starbucks', -8.50, '10-01 09:23'),
      ('Amazon.com', -45.00, '09-30 18:11'),
      ('退款', 12.00, '09-29 14:02'),
      ('Netflix', -15.99, '09-28 07:45'),
    ];
    return items.map((t) {
      final inc = t.$2 > 0;
      return Card(
        margin: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          dense: true,
          leading: Icon(inc ? Icons.arrow_downward : Icons.arrow_upward,
              color: inc ? Colors.green : Colors.red, size: 18),
          title: Text(t.$1),
          subtitle: Text(t.$3, style: const TextStyle(fontSize: 11)),
          trailing: Text(
            '${inc ? '+' : ''}\$${t.$2.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: inc ? Colors.green : Colors.red),
          ),
        ),
      );
    }).toList();
  }
}
