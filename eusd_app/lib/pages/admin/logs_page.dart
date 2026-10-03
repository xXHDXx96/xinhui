import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});
  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _logs = [];
  String _actionFilter = '';
  String _channelFilter = '';
  String _lastUpdated = '—';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ApiService.adminGetTickets(page: 0, size: 1000);
      final tickets = (r['content'] as List?) ?? [];
      final logs = <Map<String, dynamic>>[];
      for (final t in tickets) {
        final tm = t as Map<String, dynamic>;
        final ch = tm['channel']?.toString() ?? '';
        if (tm['createdAt'] != null) {
          logs.add({
            'time': tm['createdAt'], 'action': 'PENDING',
            'title': '提交解约申请', 'channel': ch,
            'ticketId': tm['id'], 'userId': tm['userId'],
            'color': const Color(0xFFFF9800),
            'icon': Icons.hourglass_empty,
          });
        }
        if (tm['status'] == 'APPROVED' && tm['resolvedAt'] != null) {
          logs.add({
            'time': tm['resolvedAt'], 'action': 'APPROVED',
            'title': '客服审批通过并解约', 'channel': ch,
            'ticketId': tm['id'], 'userId': tm['userId'],
            'color': const Color(0xFF00C853),
            'icon': Icons.check_circle_outline,
          });
        }
        if (tm['status'] == 'REJECTED' && tm['resolvedAt'] != null) {
          logs.add({
            'time': tm['resolvedAt'], 'action': 'REJECTED',
            'title': '客服拒绝解约', 'channel': ch,
            'ticketId': tm['id'], 'userId': tm['userId'],
            'color': const Color(0xFFF44336),
            'icon': Icons.cancel_outlined,
          });
        }
        if (tm['status'] == 'CANCELED' && tm['resolvedAt'] != null) {
          logs.add({
            'time': tm['resolvedAt'], 'action': 'CANCELED',
            'title': '用户取消解约申请', 'channel': ch,
            'ticketId': tm['id'], 'userId': tm['userId'],
            'color': const Color(0xFF888888),
            'icon': Icons.remove_circle_outline,
          });
        }
      }
      logs.sort((a, b) {
        try {
          return DateTime.parse(b['time'].toString())
            .compareTo(DateTime.parse(a['time'].toString()));
        } catch (_) { return 0; }
      });
      final now = DateTime.now();
      final p = (int n) => n.toString().padLeft(2, '0');
      setState(() {
        _logs = logs;
        _lastUpdated = '${now.year}-${p(now.month)}-${p(now.day)} '
          '${p(now.hour)}:${p(now.minute)}:${p(now.second)}';
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _logs.where((l) {
      if (_actionFilter.isNotEmpty && l['action'] != _actionFilter) return false;
      if (_channelFilter.isNotEmpty && l['channel'] != _channelFilter) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('操作日志'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          _filterBar(),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                ? _empty()
                : RefreshIndicator(
                    color: const Color(0xFF00C853),
                    backgroundColor: const Color(0xFF141414),
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _logItem(_filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1F1F1F), width: 1))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('全部',
              _actionFilter.isEmpty && _channelFilter.isEmpty,
              () => setState(() { _actionFilter = ''; _channelFilter = ''; })),
            _filterChip('提交', _actionFilter == 'PENDING',
              () => setState(() => _actionFilter = 'PENDING')),
            _filterChip('通过', _actionFilter == 'APPROVED',
              () => setState(() => _actionFilter = 'APPROVED')),
            _filterChip('拒绝', _actionFilter == 'REJECTED',
              () => setState(() => _actionFilter = 'REJECTED')),
            const SizedBox(width: 12),
            Container(width: 1, height: 20, color: const Color(0xFF1F1F1F)),
            const SizedBox(width: 12),
            _filterChip('支付宝', _channelFilter == 'ALIPAY',
              () => setState(() => _channelFilter =
                _channelFilter == 'ALIPAY' ? '' : 'ALIPAY')),
            _filterChip('微信', _channelFilter == 'WECHAT',
              () => setState(() => _channelFilter =
                _channelFilter == 'WECHAT' ? '' : 'WECHAT')),
            _filterChip('云闪付', _channelFilter == 'UNIONPAY',
              () => setState(() => _channelFilter =
                _channelFilter == 'UNIONPAY' ? '' : 'UNIONPAY')),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00C853) : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF00C853) : const Color(0xFF1F1F1F))),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : Colors.grey,
          fontSize: 12.5, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _logItem(Map<String, dynamic> log) {
    final color = log['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle),
            child: Icon(log['icon'] as IconData, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(log['title'] as String,
                      style: TextStyle(color: color, fontSize: 13.5,
                        fontWeight: FontWeight.w600))),
                    Text(_fmtShort(log['time']),
                      style: const TextStyle(color: Color(0xFF666666), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                if ((log['channel'] as String).isNotEmpty)
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _channelColor(log['channel'] as String).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4)),
                      child: Text(_channelName(log['channel'] as String),
                        style: TextStyle(
                          color: _channelColor(log['channel'] as String),
                          fontSize: 10, fontWeight: FontWeight.w500)),
                    ),
                  ]),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.description_outlined,
                      color: Color(0xFF666666), size: 12),
                    const SizedBox(width: 4),
                    Expanded(child: Text(_shortId(log['ticketId']),
                      style: const TextStyle(color: Color(0xFF888888),
                        fontSize: 11, fontFamily: 'monospace'),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 56, color: Colors.grey[700]),
          const SizedBox(height: 12),
          const Text('暂无操作日志',
            style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text('最后更新：$_lastUpdated',
            style: const TextStyle(color: Color(0xFF555555), fontSize: 11)),
        ],
      ),
    );
  }

  Color _channelColor(String c) {
    switch (c) {
      case 'ALIPAY': return const Color(0xFF1677FF);
      case 'WECHAT': return const Color(0xFF07C160);
      case 'UNIONPAY': return const Color(0xFFE60012);
      default: return Colors.grey;
    }
  }

  String _channelName(String c) {
    switch (c) {
      case 'ALIPAY': return '支付宝';
      case 'WECHAT': return '微信支付';
      case 'UNIONPAY': return '云闪付';
      default: return c;
    }
  }

  String _shortId(dynamic id) {
    if (id == null) return '—';
    final s = id.toString();
    return s.length > 12 ? '${s.substring(0, 8)}...${s.substring(s.length - 4)}' : s;
  }

  String _fmtShort(dynamic t) {
    if (t == null) return '—';
    try {
      final d = DateTime.parse(t.toString()).toLocal();
      final p = (int n) => n.toString().padLeft(2, '0');
      return '${d.month}/${d.day} ${p(d.hour)}:${p(d.minute)}';
    } catch (_) {
      return t.toString().length > 16 ? t.toString().substring(0, 16) : t.toString();
    }
  }
}
