import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});
  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  bool _loading = true;
  Map<String, dynamic> _stats = {
    'pendingTickets': 0, 'approvedTickets': 0,
    'rejectedTickets': 0, 'totalTickets': 0,
  };
  Map<String, int> _channelCounts = {'ALIPAY': 0, 'WECHAT': 0, 'UNIONPAY': 0};
  String _lastUpdated = '—';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await ApiService.adminGetStats();
      final t = await ApiService.adminGetTickets(page: 0, size: 500);
      final list = (t['content'] as List?) ?? [];
      final counts = {'ALIPAY': 0, 'WECHAT': 0, 'UNIONPAY': 0};
      for (final item in list) {
        final ch = item['channel']?.toString() ?? '';
        if (counts.containsKey(ch)) counts[ch] = counts[ch]! + 1;
      }
      final now = DateTime.now();
      final p = (int n) => n.toString().padLeft(2, '0');
      setState(() {
        if (s['success'] != false) _stats = s;
        _channelCounts = counts;
        _lastUpdated = '${now.year}-${p(now.month)}-${p(now.day)} '
          '${p(now.hour)}:${p(now.minute)}:${p(now.second)}';
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  int get _processedCount =>
    (_stats['approvedTickets'] as int) + (_stats['rejectedTickets'] as int);
  int get _total => (_stats['totalTickets'] as int) == 0
    ? 1 : _stats['totalTickets'] as int;
  int get _processedRate => ((_processedCount / _total) * 100).round();
  int get _approvalRate => _processedCount == 0 ? 0 :
    (((_stats['approvedTickets'] as int) / _processedCount) * 100).round();
  int get _rejectRate => _processedCount == 0 ? 0 :
    (((_stats['rejectedTickets'] as int) / _processedCount) * 100).round();
  int get _channelTotal => _channelCounts.values.fold(0, (a, b) => a + b);
  int _channelPercent(String ch) => _channelTotal == 0 ? 0 :
    ((_channelCounts[ch]! / _channelTotal) * 100).round();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据统计'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            color: const Color(0xFF00C853),
            backgroundColor: const Color(0xFF141414),
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _statsGrid(),
                const SizedBox(height: 20),
                _metricsRow(),
                const SizedBox(height: 20),
                _channelPanel(),
                const SizedBox(height: 20),
                Center(child: Text('最后更新：$_lastUpdated',
                  style: const TextStyle(color: Color(0xFF666666), fontSize: 12))),
                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }

  Widget _statsGrid() {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.55,
      children: [
        _statCard('待处理工单', '${_stats['pendingTickets']}',
          const Color(0xFFFF9800), Icons.hourglass_empty, '需要客服处理'),
        _statCard('已通过', '${_stats['approvedTickets']}',
          const Color(0xFF00C853), Icons.check_circle_outline, '成功解约'),
        _statCard('已拒绝', '${_stats['rejectedTickets']}',
          const Color(0xFFF44336), Icons.cancel_outlined, '未通过审核'),
        _statCard('工单总数', '${_stats['totalTickets']}',
          const Color(0xFF8888FF), Icons.list_alt, '全部记录'),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color,
                   IconData icon, String hint) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
            const Spacer(),
            Text(value, style: TextStyle(
              color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(hint, style: const TextStyle(
            color: Color(0xFF666666), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _metricsRow() {
    return Column(children: [
      _metricCard('处理率', _processedRate, const Color(0xFF4D9DFF),
        '已处理 $_processedCount / 共 ${_stats['totalTickets']}'),
      const SizedBox(height: 12),
      _metricCard('通过率', _approvalRate, const Color(0xFF00C853),
        '通过 ${_stats['approvedTickets']} / 已处理 $_processedCount'),
      const SizedBox(height: 12),
      _metricCard('拒绝率', _rejectRate, const Color(0xFFF44336),
        '拒绝 ${_stats['rejectedTickets']} / 已处理 $_processedCount'),
    ]);
  }

  Widget _metricCard(String label, int percent, Color color, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            Text('$percent%', style: TextStyle(color: color,
              fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100, minHeight: 6,
              backgroundColor: const Color(0xFF1F1F1F),
              valueColor: AlwaysStoppedAnimation<Color>(color))),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(
            color: Color(0xFF666666), fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _channelPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.donut_small, color: Color(0xFF00C853), size: 18),
            SizedBox(width: 8),
            Text('渠道分布', style: TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 20),
          _channelRow('支付宝', 'ALIPAY', const Color(0xFF1677FF)),
          const SizedBox(height: 16),
          _channelRow('微信支付', 'WECHAT', const Color(0xFF07C160)),
          const SizedBox(height: 16),
          _channelRow('云闪付', 'UNIONPAY', const Color(0xFFE60012)),
        ],
      ),
    );
  }

  Widget _channelRow(String label, String code, Color color) {
    final percent = _channelPercent(code);
    return Row(children: [
      Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      SizedBox(width: 76, child: Text(label,
        style: const TextStyle(color: Colors.white70, fontSize: 12.5))),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: percent / 100, minHeight: 8,
          backgroundColor: const Color(0xFF1F1F1F),
          valueColor: AlwaysStoppedAnimation<Color>(color)))),
      const SizedBox(width: 12),
      SizedBox(width: 30, child: Text('${_channelCounts[code]}',
        textAlign: TextAlign.right,
        style: const TextStyle(color: Colors.white,
          fontSize: 13, fontWeight: FontWeight.w600))),
    ]);
  }
}
