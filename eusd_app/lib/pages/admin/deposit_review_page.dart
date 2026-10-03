import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class DepositReviewPage extends StatefulWidget {
  const DepositReviewPage({super.key});
  @override
  State<DepositReviewPage> createState() => _DepositReviewPageState();
}

class _DepositReviewPageState extends State<DepositReviewPage> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _error;
  String _statusFilter = 'PENDING';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService.adminGetDeposits(status: _statusFilter);
      setState(() {
        _orders = (r['content'] as List?) ?? [];
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
        title: const Text('充值审核'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00C853),
        backgroundColor: const Color(0xFF141414),
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _filterBar(),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator()))
            else if (_error != null)
              _errorWidget()
            else if (_orders.isEmpty)
              _emptyWidget()
            else
              ..._orders.map((o) => _orderCard(o as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  Widget _filterBar() {
    final filters = [
      {'label': '待审核', 'value': 'PENDING'},
      {'label': '已通过', 'value': 'APPROVED'},
      {'label': '已拒绝', 'value': 'REJECTED'},
      {'label': '全部', 'value': ''},
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

  Widget _orderCard(Map<String, dynamic> o) {
    final status = o['status']?.toString() ?? 'PENDING';
    final channel = o['channel']?.toString() ?? '';
    return Container(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${o['amountCny']} CNY',
                      style: const TextStyle(color: Colors.white,
                        fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_shortId(o['orderNo']),
                      style: const TextStyle(color: Colors.grey, fontSize: 11.5,
                        fontFamily: 'monospace')),
                  ],
                ),
              ),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF1F1F1F), height: 1),
          const SizedBox(height: 10),
          _infoRow('渠道', _channelName(channel)),
          _infoRow('用户', _shortId(o['userId'])),
          if (o['paymentTxid'] != null && o['paymentTxid'].toString().isNotEmpty)
            _infoRow('支付单号', o['paymentTxid'].toString()),
          if (o['userRemark'] != null && o['userRemark'].toString().isNotEmpty)
            _infoRow('用户备注', o['userRemark'].toString()),
          _infoRow('提交时间', _fmtTime(o['createdAt'])),
          if (status == 'APPROVED' && o['amountUsdt'] != null)
            _infoRow('到账 USDT', '${o['amountUsdt']} USDT'),
          if (status == 'REJECTED' && o['adminRemark'] != null)
            _infoRow('拒绝原因', o['adminRemark'].toString()),
          if (status == 'PENDING') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approve(o['id'].toString(), o['orderNo'].toString()),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('通过'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(o['id'].toString(), o['orderNo'].toString()),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('拒绝'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF44336),
                      side: const BorderSide(color: Color(0xFFF44336)),
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(String orderId, String orderNo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认通过？',
          style: TextStyle(color: Colors.white)),
        content: Text(
          '订单号：$orderNo\n\n'
          '确认后系统将按当前汇率自动换算成 USDT 并加到用户账户，此操作不可撤销。',
          style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 13.5)),
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
            child: const Text('确认通过'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final r = await ApiService.adminApproveDeposit(orderId);
    if (!mounted) return;
    _toast(r['success'] == true
      ? r['message']?.toString() ?? '已通过'
      : r['message']?.toString() ?? '失败');
    _load();
  }

  Future<void> _reject(String orderId, String orderNo) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('拒绝充值', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('订单号：$orderNo',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            const Text('请输入拒绝原因（会同步给用户）',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '例如：未查询到对应支付流水',
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
    final r = await ApiService.adminRejectDeposit(orderId, ctrl.text.trim());
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
          const Text('暂无充值申请',
            style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('用户提交充值后会显示在这里',
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
      width: 42, height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _statusChip(String s) {
    Color c; String text;
    switch (s) {
      case 'PENDING': c = const Color(0xFFFF9800); text = '待审核'; break;
      case 'APPROVED': c = const Color(0xFF00C853); text = '已通过'; break;
      case 'REJECTED': c = const Color(0xFFF44336); text = '已拒绝'; break;
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

  String _fmtTime(dynamic t) {
    if (t == null) return '—';
    try {
      final d = DateTime.parse(t.toString()).toLocal();
      final p = (int n) => n.toString().padLeft(2, '0');
      return '${d.month}/${d.day} ${p(d.hour)}:${p(d.minute)}';
    } catch (_) {
      return t.toString();
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));
  }
}
