import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/virtual_card.dart';
import '../providers/card_provider.dart';
import 'card_detail_page.dart';
import 'add_card_page.dart';

class CardManagementPage extends StatefulWidget {
  const CardManagementPage({super.key});
  @override
  State<CardManagementPage> createState() => _CardManagementPageState();
}

class _CardManagementPageState extends State<CardManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardProvider>().loadCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('卡片'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddCardPage()))
                .then((_) => context.read<CardProvider>().loadCards());
            },
          ),
        ],
      ),
      body: Consumer<CardProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.cards.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            color: const Color(0xFF00C853),
            backgroundColor: const Color(0xFF141414),
            onRefresh: provider.loadCards,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTotalCard(provider),
                const SizedBox(height: 20),
                const Text('我的卡片',
                  style: TextStyle(color: Colors.white,
                    fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (provider.cards.isEmpty)
                  _empty()
                else
                  ...provider.cards.map((c) => _cardItem(c)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalCard(CardProvider p) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2A1E), Color(0xFF00C853)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.account_balance_wallet,
              color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('总资产', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
          const SizedBox(height: 12),
          Text('\$${p.totalBalance.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white,
              fontSize: 34, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('${p.cardCount} 张卡片',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _cardItem(VirtualCard card) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CardDetailPage(card: card)))
          .then((_) => context.read<CardProvider>().loadCards());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 190,
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
                begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853),
                        borderRadius: BorderRadius.circular(4)),
                      child: const Text('e',
                        style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 4),
                    const Text('USD.COM',
                      style: TextStyle(color: Colors.white,
                        fontSize: 14, fontWeight: FontWeight.bold)),
                  ]),
                  if (!card.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8)),
                      child: Text(card.statusText,
                        style: const TextStyle(color: Colors.red, fontSize: 11))),
                ],
              ),
              const Spacer(),
              Row(children: [
                Icon(card.isActive ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                Text('${card.balance.toStringAsFixed(2)} ${card.currency}',
                  style: const TextStyle(color: Colors.white,
                    fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('•••• ${card.last4}',
                    style: const TextStyle(color: Colors.white70,
                      fontSize: 15, letterSpacing: 2)),
                  Text(card.brand,
                    style: const TextStyle(color: Colors.white,
                      fontSize: 18, fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(children: [
        Icon(Icons.credit_card_outlined, size: 64, color: Colors.grey[600]),
        const SizedBox(height: 16),
        const Text('暂无卡片', style: TextStyle(color: Colors.grey, fontSize: 16)),
        const SizedBox(height: 24),
        SizedBox(width: 180, child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddCardPage()))
              .then((_) => context.read<CardProvider>().loadCards());
          },
          icon: const Icon(Icons.add), label: const Text('申请新卡'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
            minimumSize: const Size(0, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)))),
        ),
      ]),
    );
  }
}
