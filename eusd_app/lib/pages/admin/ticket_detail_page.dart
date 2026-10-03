import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class TicketDetailPage extends StatefulWidget {
  final String ticketId;
  const TicketDetailPage({super.key, required this.ticketId});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  Map<String, dynamic> _ticket = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ApiService.adminGetTicketDetail(widget.ticketId);
      setState(() { _ticket = r; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工单详情'),
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
                _headerCard(),
                const SizedBox(height: 16),
                if (_ticket['agreementNo'] != null ||
                    _ticket['channel'] != null) _agreementCard(),
                const SizedBox(height: 16),
                _timelineCard(),
                const SizedBox(height: 16),
                if (_ticket['status'] == 'PENDING') _actionButtons(),
                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }

  Widget _headerCard() {
    final status = _ticket['status']?.toString() ?? 'PENDING';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('工单信息',
                  style: TextStyle(color: Colors.white,
                    fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('工单 ID', _ticket['id']?.toString() ?? '—'),
          _infoRow('用户 ID', _ticket['userId']?.toString() ?? '—'),
          _infoRow('工单类型', _typeName(_ticket['type']?.toString())),
          _infoRow('提交时间', _fmtTime(_ticket['createdAt'])),
          if (_ticket['resolvedAt'] != null)
            _infoRow('处理时间', _fmtTime(_ticket['resolvedAt'])),
          if (_ticket['assignedAdminId'] != null)
            _infoRow('处理客服', _shortId(_ticket['assignedAdminId'])),
          if (_ticket['remark'] != null &&
              _ticket['remark'].toString().isNotEmpty)
            _infoRowFull('备注', _ticket['remark'].toString()),
          if (_ticket['rejectReason'] != null &&
              _ticket['rejectReason'].toString().isNotEmpty)
            _infoRowFull('拒绝原因', _ticket['rejectReason'].toString(),
              isError: true),
        ],
      ),
    );
  }

  Widget _agreementCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('关联支付协议',
                  style: TextStyle(color: Colors.white,
                    fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              if (_ticket['channel'] != null)
                _channelChip(_ticket['channel'].toString()),
            ],
          ),
          const SizedBox(height: 16),
          if (_ticket['agreementNo'] != null)
            _infoRow('协议号', _ticket['agreementNo'].toString()),
          if (_ticket['externalAgreementNo'] != null)
            _infoRow('外部协议号', _ticket['externalAgreementNo'].toString()),
          if (_ticket['contractId'] != null)
            _infoRow('渠道协议 ID', _ticket['contractId'].toString()),
          if (_ticket['planId'] != null)
            _infoRow('模板 ID', _ticket['planId'].toString()),
          if (_ticket['contractCode'] != null)
            _infoRow('签约流水号', _ticket['contractCode'].toString()),
          if (_ticket['agreementStatus'] != null)
            _infoRow('协议状态',
              _agreementStatusName(_ticket['agreementStatus'].toString())),
          if (_ticket['signedAt'] != null)
            _infoRow('签约时间', _fmtTime(_ticket['signedAt'])),
        ],
      ),
    );
  }

  Widget _timelineCard() {
    final events = _buildTimeline();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('操作日志',
            style: TextStyle(color: Colors.white,
              fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('暂无操作日志',
                style: TextStyle(color: Colors.grey, fontSize: 13))),
            )
          else
            ...List.generate(events.length, (i) =>
              _timelineItem(events[i], i == events.length - 1)),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildTimeline() {
    final list = <Map<String, dynamic>>[];
    final t = _ticket;
    if (t['createdAt'] != null) list.add({
      'time': t['createdAt'],
      'title': '用户提交解约申请',
      'desc': '渠道：${_channelName(t['channel']?.toString())}',
      'color': const Color(0xFF4D9DFF),
    });
    if (t['status'] == 'PENDING') list.add({
      'time': t['createdAt'],
      'title': '等待客服审核',
      'desc': '预计 24 小时内处理',
      'color': const Color(0xFFFF9800),
    });
    if (t['status'] == 'APPROVED' && t['resolvedAt'] != null) {
      list.add({
        'time': t['resolvedAt'],
        'title': '客服审批通过',
        'desc': '已调用渠道解约 API',
        'color': const Color(0xFF00C853),
      });
      list.add({
        'time': t['resolvedAt'],
        'title': '协议已成功解约',
        'desc': '用户侧自动扣款已停止',
        'color': const Color(0xFF00C853),
      });
    }
    if (t['status'] == 'REJECTED' && t['resolvedAt'] != null) list.add({
      'time': t['resolvedAt'],
      'title': '客服拒绝解约申请',
      'desc': t['rejectReason']?.toString() ?? '未说明原因',
      'color': const Color(0xFFF44336),
    });
    if (t['status'] == 'CANCELED') list.add({
      'time': t['resolvedAt'] ?? t['createdAt'],
      'title': '用户取消了解约申请',
      'desc': '协议保持有效',
      'color': Colors.grey,
    });
    return list;
  }

  Widget _timelineItem(Map<String, dynamic> e, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12, height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: e['color'] as Color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (e['color'] as Color).withOpacity(0.3), width: 4)),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFF1F1F1F)),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e['title'] as String,
                    style: const TextStyle(color: Colors.white,
                      fontSize: 13.5, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(e['desc'] as String,
                    style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
                  const SizedBox(height: 4),
                  Text(_fmtTime(e['time']),
                    style: const TextStyle(color: Color(0xFF555555), fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF44336).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF44336).withOpacity(0.3))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber, color: Color(0xFFF44336), size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '审批通过后，系统将立即调用支付渠道的解约 API，用户侧自动扣款将停止。此操作不可撤销。',
                  style: TextStyle(color: Color(0xFFFF9999),
                    fontSize: 12.5, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _approve,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('通过并解约'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reject,
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('拒绝'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF44336),
                  side: const BorderSide(color: Color(0xFFF44336)),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _approve() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认解约？', style: TextStyle(color: Colors.white)),
        content: Text(
          '渠道：${_channelName(_ticket['channel']?.toString())}\n'
          '协议号：${_ticket['agreementNo'] ?? '—'}\n\n'
          '将调用真实解约 API，不可撤销。',
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
            child: const Text('确认解约'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final r = await ApiService.adminApprove(widget.ticketId);
    if (!mounted) return;
    _toast(r['success'] == true
      ? r['message']?.toString() ?? '解约成功'
      : r['message']?.toString() ?? '失败');
    _load();
  }

  Future<void> _reject() async {
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
    final r = await ApiService.adminReject(widget.ticketId, ctrl.text.trim());
    if (!mounted) return;
    _toast(r['success'] == true ? '已拒绝' : r['message']?.toString() ?? '失败');
    _load();
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
          ),
          Expanded(
            child: Text(value,
              style: const TextStyle(color: Colors.white,
                fontSize: 13, fontFamily: 'monospace'),
              textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _infoRowFull(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isError
                ? const Color(0xFFF44336).withOpacity(0.08)
                : const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(8),
              border: isError
                ? Border.all(color: const Color(0xFFF44336).withOpacity(0.3))
                : null),
            child: Text(value,
              style: TextStyle(
                color: isError ? const Color(0xFFFF9999) : Colors.white,
                fontSize: 13, height: 1.5)),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(
        color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _channelChip(String c) {
    Color color;
    switch (c) {
      case 'ALIPAY': color = const Color(0xFF1677FF); break;
      case 'WECHAT': color = const Color(0xFF07C160); break;
      case 'UNIONPAY': color = const Color(0xFFE60012); break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8)),
      child: Text(_channelName(c),
        style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
    );
  }

  String _channelName(String? c) {
    switch (c) {
      case 'ALIPAY': return '支付宝';
      case 'WECHAT': return '微信支付';
      case 'UNIONPAY': return '云闪付';
      default: return c ?? '—';
    }
  }

  String _agreementStatusName(String s) {
    switch (s) {
      case 'SIGNED': return '已签约';
      case 'PENDING_TERMINATION': return '解约审核中';
      case 'TERMINATED': return '已解约';
      default: return s;
    }
  }

  String _typeName(String? t) {
    switch (t) {
      case 'TERMINATION': return '解约申请';
      default: return t ?? '—';
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
      return '${d.year}-${p(d.month)}-${p(d.day)} ${p(d.hour)}:${p(d.minute)}:${p(d.second)}';
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
