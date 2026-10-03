import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});
  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  List<dynamic> _agreements = [];
  List<dynamic> _tickets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final a = await ApiService.getAgreements();
      final tr = await ApiService.getTicketStatus();
      final t = (tr['tickets'] as List<dynamic>?) ?? [];
      setState(() {
        _agreements = a;
        _tickets = t;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = '加载失败: $e'; _loading = false; });
    }
  }

  Future<void> _requestTerminate(String agreementId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('申请解约', style: TextStyle(color: Colors.white)),
        content: const Text(
          '解约申请提交后，客服将在24小时内审核处理。\n\n'
          '审核期间：\n'
          '• 代扣协议仍然有效\n'
          '• 已签约的免密支付不会立即失效\n'
          '• 审核通过后自动扣款将停止\n\n'
          '确认提交解约申请吗？',
          style: TextStyle(color: Colors.grey, height: 1.6)),
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
            child: const Text('确认提交'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      final r = await ApiService.requestTerminate(agreementId);
      if (!mounted) return;
      if (r['success'] == true) {
        _toast('解约申请已提交，客服审核中');
        _load();
      } else {
        _toast(r['message']?.toString() ?? '提交失败');
      }
    } catch (e) {
      _toast('提交失败: $e');
    }
  }

  Future<void> _cancelTerminate(String ticketId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('取消解约申请',
          style: TextStyle(color: Colors.white)),
        content: const Text('确认取消解约申请？协议将继续保持有效。',
          style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('返回', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              minimumSize: const Size(100, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('确认取消'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      final r = await ApiService.cancelTerminate(ticketId);
      if (!mounted) return;
      if (r['success'] == true) {
        _toast('解约申请已取消');
        _load();
      } else {
        _toast(r['message']?.toString() ?? '取消失败');
      }
    } catch (e) {
      _toast('取消失败: $e');
    }
  }

  Map<String, dynamic>? _findTicket(String agreementId) {
    for (final t in _tickets) {
      if (t is Map && t['agreementId']?.toString() == agreementId) {
        return t as Map<String, dynamic>;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('支付方式管理'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? _errorWidget()
          : RefreshIndicator(
              color: const Color(0xFF00C853),
              backgroundColor: const Color(0xFF141414),
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _headerTip(),
                  const SizedBox(height: 20),
                  const Text('已签约的支付方式',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (_agreements.isEmpty)
                    _emptyAgreements()
                  else
                    ..._agreements.map((a) =>
                      _agreementCard(a as Map<String, dynamic>)),
                  const SizedBox(height: 24),
                  if (_tickets.isNotEmpty) ...[
                    const Text('解约申请记录',
                      style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ..._tickets.map((t) =>
                      _ticketCard(t as Map<String, dynamic>)),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _headerTip() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00C853).withOpacity(0.3))),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF00C853), size: 20),
          SizedBox(width: 12),
          Expanded(child: Text(
            '免密代扣协议由支付渠道直接管理。解约需经客服审核确认，审核通过后自动扣款将立即停止。',
            style: TextStyle(color: Colors.grey, fontSize: 12.5, height: 1.5))),
        ],
      ),
    );
  }

  Widget _agreementCard(Map<String, dynamic> a) {
    final channel = a['channel']?.toString() ?? '';
    final status = a['status']?.toString() ?? 'SIGNED';
    final id = a['id']?.toString() ?? '';
    final ticket = _findTicket(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Column(
        children: [
          Row(
            children: [
              _channelIcon(channel),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_channelDisplay(channel),
                    style: const TextStyle(color: Colors.white,
                      fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(_statusText(status),
                    style: TextStyle(color: _statusColor(status), fontSize: 12.5)),
                ],
              )),
              _statusChip(status),
            ],
          ),
          if (a['agreementNo'] != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            const SizedBox(height: 10),
            _infoLine('协议号', _mask(a['agreementNo'].toString())),
          ],
          if (a['signedAt'] != null) ...[
            const SizedBox(height: 6),
            _infoLine('签约时间', _fmtDate(a['signedAt'])),
          ],
          const SizedBox(height: 14),
          _actions(id, status, ticket),
        ],
      ),
    );
  }

  Widget _actions(String agreementId, String status, Map<String, dynamic>? ticket) {
    if (status == 'TERMINATED') {
      return Row(children: [
        const Icon(Icons.check_circle, color: Colors.grey, size: 16),
        const SizedBox(width: 8),
        Text('协议已解约', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ]);
    }

    if (status == 'PENDING_TERMINATION') {
      final tid = ticket?['id']?.toString();
      return Row(children: [
        const SizedBox(width: 14, height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
        const SizedBox(width: 10),
        const Expanded(child: Text('客服审核中，预计24小时内处理',
          style: TextStyle(color: Colors.orange, fontSize: 13))),
        if (tid != null)
          TextButton(
            onPressed: () => _cancelTerminate(tid),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: const Text('取消申请', style: TextStyle(fontSize: 12)),
          ),
      ]);
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _requestTerminate(agreementId),
        icon: const Icon(Icons.link_off, size: 16),
        label: const Text('申请解约'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: BorderSide(color: Colors.red.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
    );
  }

  Widget _ticketCard(Map<String, dynamic> t) {
    final status = t['status']?.toString() ?? 'PENDING';
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
            Icon(_ticketIcon(status), color: _ticketColor(status), size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(_ticketTitle(status),
              style: TextStyle(color: _ticketColor(status),
                fontSize: 14, fontWeight: FontWeight.w500))),
            Text(_fmtDate(t['createdAt']),
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
          if (t['resolvedAt'] != null) ...[
            const SizedBox(height: 6),
            Text('处理时间：${_fmtDate(t['resolvedAt'])}',
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
          if (t['rejectReason'] != null &&
              t['rejectReason'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6)),
              child: Text('拒绝原因：${t['rejectReason']}',
                style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyAgreements() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Column(children: [
        Icon(Icons.link_off, size: 48, color: Colors.grey[600]),
        const SizedBox(height: 12),
        const Text('暂无签约的支付方式',
          style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        const Text('前往充值页面签约支付宝/微信/云闪付',
          style: TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
    );
  }

  Widget _errorWidget() {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
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
    ));
  }

  Widget _channelIcon(String c) {
    IconData icon;
    Color color;
    switch (c) {
      case 'ALIPAY': icon = Icons.account_balance_wallet; color = const Color(0xFF1677FF); break;
      case 'WECHAT': icon = Icons.wechat; color = const Color(0xFF07C160); break;
      case 'UNIONPAY': icon = Icons.payment; color = const Color(0xFFE60012); break;
      default: icon = Icons.payment; color = Colors.grey;
    }
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _statusChip(String s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(s).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12)),
      child: Text(_statusText(s),
        style: TextStyle(color: _statusColor(s),
          fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  Widget _infoLine(String l, String v) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      Text(v, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }

  String _channelDisplay(String c) {
    switch (c) {
      case 'ALIPAY': return '支付宝免密代扣';
      case 'WECHAT': return '微信支付委托代扣';
      case 'UNIONPAY': return '云闪付无感支付';
      default: return c;
    }
  }

  String _statusText(String s) {
    switch (s) {
      case 'SIGNED': return '已签约';
      case 'PENDING_TERMINATION': return '解约审核中';
      case 'TERMINATED': return '已解约';
      default: return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'SIGNED': return const Color(0xFF00C853);
      case 'PENDING_TERMINATION': return Colors.orange;
      case 'TERMINATED': return Colors.grey;
      default: return Colors.grey;
    }
  }

  IconData _ticketIcon(String s) {
    switch (s) {
      case 'PENDING': return Icons.hourglass_empty;
      case 'APPROVED': return Icons.check_circle_outline;
      case 'REJECTED': return Icons.cancel_outlined;
      case 'CANCELED': return Icons.remove_circle_outline;
      default: return Icons.info_outline;
    }
  }

  Color _ticketColor(String s) {
    switch (s) {
      case 'PENDING': return Colors.orange;
      case 'APPROVED': return const Color(0xFF00C853);
      case 'REJECTED': return Colors.red;
      case 'CANCELED': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _ticketTitle(String s) {
    switch (s) {
      case 'PENDING': return '解约申请审核中';
      case 'APPROVED': return '解约成功';
      case 'REJECTED': return '解约申请被拒绝';
      case 'CANCELED': return '解约申请已取消';
      default: return s;
    }
  }

  String _mask(String s) {
    if (s.length <= 8) return s;
    return '${s.substring(0, 4)}****${s.substring(s.length - 4)}';
  }

  String _fmtDate(dynamic d) {
    if (d == null) return '—';
    final s = d.toString();
    try {
      final dt = DateTime.parse(s).toLocal();
      final p = (int n) => n.toString().padLeft(2, '0');
      return '${dt.year}-${p(dt.month)}-${p(dt.day)} ${p(dt.hour)}:${p(dt.minute)}';
    } catch (_) {
      return s.length > 16 ? s.substring(0, 16) : s;
    }
  }

  void _toast(String m) {
    if (!mounted || m.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));
  }
}
