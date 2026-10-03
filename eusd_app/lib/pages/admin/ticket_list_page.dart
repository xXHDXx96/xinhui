import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'ticket_detail_page.dart';
import 'stats_page.dart';
import 'logs_page.dart';
import 'settings_page.dart';
import 'deposit_review_page.dart';

class TicketListPage extends StatefulWidget {
  const TicketListPage({super.key});
  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  List<dynamic> _tickets = [];
  bool _loading = true;
  String? _error;
  String _statusFilter = '';
  Map<String, dynamic> _stats = {
    'pendingTickets': 0, 'approvedTickets': 0,
    'rejectedTickets': 0, 'totalTickets': 0,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService.adminGetTickets(status: _statusFilter);
      final s = await ApiService.adminGetStats();
      setState(() {
        _tickets = (r['content'] as List?) ?? [];
        if (s['success'] == true) _stats = s;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = '加载失败: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('客服中心'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: '充值审核',
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DepositReviewPage()))
              .then((_) => _load()),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: '数据统计',
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const StatsPage())),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '操作日志',
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const LogsPage())),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '系统设置',
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00C853),
        backgroundColor: const Color(0xFF141414),
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statsRow(),
            const SizedBox(height: 20),
            _filterBar(),
            const SizedBox(height: 16),
            const Text('解约工单',
              style: TextStyle(color: Colors.white,
                fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator()))
            else if (_error != null)
              _errorWidget()
            else if (_tickets.isEmpty)
              _emptyWidget()
            else
              ..._tickets.map((t) => _ticketCard(t as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(child: _statCard('待处理', _stats['pendingTickets'].toString(),
          const Color(0xFFFF9800), Icons.hourglass_empty)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('已通过', _stats['approvedTickets'].toString(),
          const Color(0xFF00C853), Icons.check_circle_outline)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('已拒绝', _stats['rejectedTickets'].toString(),
          const Color(0xFFF44336), Icons.cancel_outlined)),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(
            color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(
            color: Colors.grey, fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _filterBar() {
    final filters = [
      {'label': '全部', 'value': ''},
      {'label': '待处理', 'value': 'PENDING'},
      {'label': '已通过', 'value': 'APPROVED'},
      {'label': '已拒绝', 'value': 'REJECTED'},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final sel = _statusFilter == f['value'];
          return GestureDetector(
            onTap: () {
              setState(() => _statusFilter = f['value'] as String);
              _load();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF00C853) : const Color(0xFF141414),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? const Color(0xFF00C853) : const Color(0xFF1F1F1F))),
              child: Text(f['label'] as String,
                style: TextStyle(
                  color: sel ? Colors.white : Colors.grey,
                  fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _ticketCard(Map<String, dynamic> t) {
    final status = t['status']?.toString() ?? 'PENDING';
    final channel = t['channel']?.toString() ?? '';
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => TicketDetailPage(ticketId: t['id'].toString()),
      )).then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1F1F1F))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _channelIcon(channel),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_channelName(channel),
                      style: const TextStyle(color: Colors.white,
                        fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text('工单 ${_shortId(t['id'])}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11.5)),
                  ],
                )),
                _statusChip(status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF1F1F1F), height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.grey, size: 14),
                const SizedBox(width: 4),
                Expanded(child: Text(_shortId(t['userId']),
                  style: const TextStyle(color: Colors.grey, fontSize: 12))),
                const Icon(Icons.schedule, color: Colors.grey, size: 14),
                const SizedBox(width: 4),
                Text(_fmtTime(t['createdAt']),
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            if (status == 'PENDING') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: ElevatedButton(
                    onPressed: () => _approve(t['id'].toString()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      minimumSize: const Size(0, 38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                    child: const Text('通过',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton(
                    onPressed: () => _reject(t['id'].toString()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF44336),
                      side: const BorderSide(color: Color(0xFFF44336)),
                      minimumSize: const Size(0, 38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                    child: const Text('拒绝',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  )),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _approve(String ticketId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认解约？', style: TextStyle(color: Colors.white)),
        content: const Text(
          '将通过支付渠道的 API 发起真实解约，此操作不可撤销。',
          style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 13.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              minimumSize: const Size(100, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('确认解约'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final r = await ApiService.adminApprove(ticketId);
    if (!mounted) return;
    _toast(r['success'] == true
      ? r['message']?.toString() ?? '解约成功'
      : r['message']?.toString() ?? '失败');
    _load();
  }

  Future<void> _reject(String ticketId) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('拒绝解约', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请输入拒绝原因（会同步给用户）',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '例如：账户存在异常交易，请先联系客服处理',
                hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0A0A0A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().length < 3) {
                _toast('请填写至少3个字的拒绝原因');
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              minimumSize: const Size(100, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('确认拒绝'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final r = await ApiService.adminReject(ticketId, ctrl.text.trim());
    if (!mounted) return;
    _toast(r['success'] == true ? '已拒绝' : r['message']?.toString() ?? '失败');
    _load();
  }

  Widget _errorWidget() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(_error ?? '加载失败', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              minimumSize: const Size(100, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _emptyWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[700]),
          const SizedBox(height: 12),
          const Text('暂无工单', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('用户提交解约申请后会显示在这里',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _channelIcon(String c) {
    IconData icon;
    Color color;
    switch (c) {
      case 'ALIPAY': icon = Icons.account_balance_wallet; color = const Color(0xFF1677FF); break;
      case 'WECHAT': icon = Icons.wechat; color = const Color(0xFF07C160); break;
      case 'UNIONPAY': icon = Icons.payment; color = const Color(0xFFE60012); break;
      default: icon = Icons.help_outline; color = Colors.grey;
    }
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _statusChip(String s) {
    Color c; String text;
    switch (s) {
      case 'PENDING': c = const Color(0xFFFF9800); text = '待处理'; break;
      case 'APPROVED': c = const Color(0xFF00C853); text = '已通过'; break;
      case 'REJECTED': c = const Color(0xFFF44336); text = '已拒绝'; break;
      case 'CANCELED': c = Colors.grey; text = '已取消'; break;
      default: c = Colors.grey; text = s;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(
        color: c, fontSize: 11.5, fontWeight: FontWeight.w600)),
    );
  }

  String _channelName(String c) {
    switch (c) {
      case 'ALIPAY': return '支付宝免密代扣';
      case 'WECHAT': return '微信支付委托代扣';
      case 'UNIONPAY': return '云闪付无感支付';
      default: return c;
    }
  }

  String _shortId(dynamic id) {
    if (id == null) return '—';
    final s = id.toString();
    return s.length > 12 ? '${s.substring(0, 8)}...${s.substring(s.length - 4)}' : s;
  }

  String _fmtTime(dynamic t) {
    if (t == null) return '—';
    try {
      final d = DateTime.parse(t.toString()).toLocal();
      final p = (int n) => n.toString().padLeft(2, '0');
      return '${d.month}/${d.day} ${p(d.hour)}:${p(d.minute)}';
    } catch (_) {
      return t.toString().length > 16 ? t.toString().substring(0, 16) : t.toString();
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));
  }
}
