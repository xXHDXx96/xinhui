import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/virtual_card.dart';
import '../providers/card_provider.dart';

class CardDetailPage extends StatelessWidget {
  final VirtualCard card;
  const CardDetailPage({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('卡片详情')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBigCard(card),
          const SizedBox(height: 24),
          _buildActions(context),
          const SizedBox(height: 24),
          _buildInfo(card),
        ],
      ),
    );
  }

  Widget _buildBigCard(VirtualCard card) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: card.isActive
          ? (card.isVirtual
            ? const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF00C853)],
                begin: Alignment.topLeft, end: Alignment.bottomRight)
            : const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF2A2A4E)],
                begin: Alignment.topLeft, end: Alignment.bottomRight))
          : const LinearGradient(
              colors: [Color(0xFF3A3A3A), Color(0xFF1A1A1A)],
              begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853),
                  borderRadius: BorderRadius.circular(4)),
                child: const Text('e', style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 4),
              const Text('USD.COM', style: TextStyle(color: Colors.white,
                fontSize: 14, fontWeight: FontWeight.bold)),
            ]),
            const Spacer(),
            Row(children: [
              const Icon(Icons.visibility, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text('${card.balance.toStringAsFixed(2)} ${card.currency}',
                style: const TextStyle(color: Colors.white,
                  fontSize: 26, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('•••• •••• •••• ${card.last4}',
                  style: const TextStyle(color: Colors.white70,
                    fontSize: 15, letterSpacing: 2)),
                Text(card.brand, style: const TextStyle(color: Colors.white,
                  fontSize: 20, fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _btn(Icons.arrow_downward, '充值', () {}),
        _btn(Icons.arrow_upward, '提现', () {}),
        _btn(Icons.swap_horiz, '划转', () {}),
        _btn(
          card.isActive ? Icons.lock : Icons.lock_open,
          card.isActive ? '冻结' : '解冻',
          () => _toggle(context),
        ),
      ],
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 56, height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFF00C853), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 26)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }

  Widget _buildInfo(VirtualCard card) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Column(children: [
        _row('卡片ID', card.id.length > 8 ? card.id.substring(0, 8) : card.id),
        _row('卡类型', card.cardTypeText),
        _row('状态', card.statusText),
        _row('品牌', card.brand),
      ]),
    );
  }

  Widget _row(String l, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(v, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ]),
    );
  }

  Future<void> _toggle(BuildContext context) async {
    final provider = context.read<CardProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: Text(card.isActive ? '冻结该卡片？' : '解冻该卡片？',
          style: const TextStyle(color: Colors.white)),
        content: Text(card.isActive
          ? '冻结后您的卡将暂时无法使用。'
          : '解冻后卡片将恢复使用。',
          style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853)),
            child: Text(card.isActive ? '冻结' : '解冻')),
        ],
      ),
    );
    if (confirmed != true) return;

    final r = await provider.toggleCardStatus(card.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r['message']?.toString() ?? ''),
          behavior: SnackBarBehavior.floating));
    }
  }
}
