import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RechargeHistoryPage extends StatefulWidget {
  const RechargeHistoryPage({super.key});
  @override
  State<RechargeHistoryPage> createState() => _RechargeHistoryPageState();
}

class _RechargeHistoryPageState extends State<RechargeHistoryPage> {
  List<dynamic> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ApiService.getDepositHistory();
      if (r['success'] == true && mounted) {
        _orders = (r['orders'] as List?) ?? [];
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('充值记录'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _orders.isEmpty
          ? _empty()
          : RefreshIndicator(
              color: const Color(0xFF00C853),
              backgroundColor: const Color(0xFF141414),
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (_, i) =>
                  _orderCard(_orders[i] as Map<String, dynamic>),
              ),
            ),
    );
  }

  Widget _orderCard(Map<String, dynamic> o) {
    final status = o['status']?.toString() ?? 'PENDING';
    Color c; String statusText;
    switch (status) {
      case 'SUCCESS': c = const Color(0xFF00C853); statusText = '已完成'; break;
      case 'PENDING': c = const Color(0xFFFF9800); statusText = '审核中'; break;
      case 'APPROVED': c = const Color(0xFF00C853); statusText = '已到账'; break;
      case 'REJECTED': c = const Color(0xFFF44336); statusText = '已拒绝'; break;
      case 'FAILED': c = const Color(0xFFF44336); statusText = '失败'; break;
      default: c = Colors.grey; statusText = status;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: c.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.arrow_downward, color: c, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('+ ${o['amountCny'] ?? o['fiatAmount'] ?? '0'} CNY',
                  style: const TextStyle(color: Colors.white,
                    fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_shortId(o['orderNo'] ?? o['outTradeNo']),
                  style: const TextStyle(color: Colors.grey,
                    fontSize: 11, fontFamily: 'monospace')),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
              child: Text(statusText, style: TextStyle(
                color: c, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFF1F1F1F), height: 1),
          const SizedBox(height: 10),
          _row('到账金额', '${o['amountUsdt'] ?? o['targetAmount'] ?? '0'} USDT'),
          const SizedBox(height: 4),
          _row('提交时间', _fmtTime(o['createdAt'])),
        ],
      ),
    );
  }

  Widget _row(String l, String v) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(v, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]);
  }

  Widget _empty() {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey[700]),
        const SizedBox(height: 12),
        const Text('暂无充值记录',
          style: TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    ));
  }

  String _shortId(dynamic id) {
    if (id == null) return '—';
    final s = id.toString();
    return s.length > 20 ? '${s.substring(0, 10)}...${s.substring(s.length - 6)}' : s;
  }

  String _fmtTime(dynamic t) {
    if (t == null) return '—';
    try {
      final d = DateTime.parse(t.toString()).toLocal();
      final p = (int n) => n.toString().padLeft(2, '0');
      return '${d.year}-${p(d.month)}-${p(d.day)} ${p(d.hour)}:${p(d.minute)}';
    } catch (_) { return t.toString(); }
  }
}
