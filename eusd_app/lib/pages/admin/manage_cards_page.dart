import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ManageCardsPage extends StatefulWidget {
  const ManageCardsPage({super.key});
  @override
  State<ManageCardsPage> createState() => _ManageCardsPageState();
}

class _ManageCardsPageState extends State<ManageCardsPage> {
  List<dynamic> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ApiService.adminListCards();
      if (r['success'] == true) {
        setState(() => _items = (r['items'] as List?) ?? []);
      } else {
        _toast(r['message']?.toString() ?? '加载失败');
      }
    } catch (e) {
      _toast('加载失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(String id, String status, String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: Text('确认$label？', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
            child: Text(label)),
        ],
      ),
    );
    if (ok != true) return;
    final r = await ApiService.adminUpdateCardStatus(id, status);
    if (r['success'] == true) { _toast('已$label'); _load(); }
    else { _toast(r['message']?.toString() ?? '失败'); }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('卡片管理'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
          ? const Center(child: Text('暂无卡片',
              style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final c = _items[i] as Map<String, dynamic>;
                final status = c['status']?.toString() ?? 'active';
                final isActive = status == 'active';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1F1F1F))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('•••• ${c['last4'] ?? '****'}',
                            style: const TextStyle(color: Colors.white,
                              fontSize: 15, fontWeight: FontWeight.w600,
                              fontFamily: 'monospace')),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isActive
                                ? const Color(0xFF00C853).withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6)),
                            child: Text(status,
                              style: TextStyle(
                                color: isActive ? const Color(0xFF00C853) : Colors.red,
                                fontSize: 11))),
                        ]),
                      const SizedBox(height: 6),
                      Text('${c['brand'] ?? 'VISA'} · ${c['cardType'] ?? 'virtual'} · ${c['currency'] ?? 'USD'}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('余额：${c['balance'] ?? 0}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(children: [
                        TextButton(
                          onPressed: () => _setStatus(
                            c['id'].toString(),
                            isActive ? 'blocked' : 'active',
                            isActive ? '冻结' : '解冻'),
                          child: Text(isActive ? '冻结' : '解冻',
                            style: TextStyle(
                              color: isActive ? Colors.red : const Color(0xFF00C853),
                              fontSize: 12))),
                        TextButton(
                          onPressed: () => _setStatus(
                            c['id'].toString(), 'canceled', '注销'),
                          child: const Text('注销',
                            style: TextStyle(color: Colors.red, fontSize: 12))),
                      ]),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
