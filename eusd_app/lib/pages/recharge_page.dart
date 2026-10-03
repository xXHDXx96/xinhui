import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';

class RechargePage extends StatefulWidget {
  const RechargePage({super.key});
  @override
  State<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends State<RechargePage> {
  bool _loading = false;
  String? _orderNo;
  String? _qrContent;
  String? _qrType;
  String? _merchantName;
  String? _channel;
  String? _status;

  final _channels = [
    {'id': 'ALIPAY', 'name': '支付宝', 'sub': '扫码跳转支付宝支付',
      'icon': Icons.account_balance_wallet, 'color': const Color(0xFF1677FF)},
    {'id': 'WECHAT', 'name': '微信支付', 'sub': '扫码跳转微信支付',
      'icon': Icons.wechat, 'color': const Color(0xFF07C160)},
    {'id': 'UNIONPAY', 'name': '云闪付', 'sub': '扫码跳转银行卡支付',
      'icon': Icons.payment, 'color': const Color(0xFFE60012)},
  ];

  Future<void> _pickChannel(String channel) async {
    setState(() => _loading = true);
    try {
      final r = await ApiService.createDeposit(channel: channel);
      if (r['success'] != true) {
        _toast(r['message']?.toString() ?? '创建失败');
        return;
      }
      setState(() {
        _orderNo = r['orderNo']?.toString();
        _qrContent = r['qrContent']?.toString();
        _qrType = r['qrType']?.toString() ?? 'TEXT';
        _merchantName = r['merchantName']?.toString();
        _channel = channel;
        _status = 'CREATED';
      });
    } catch (e) {
      _toast('创建失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showSubmitDialog() async {
    final amountCtrl = TextEditingController();
    final txidCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text('填写支付信息',
          style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请填写你实际支付的金额与支付单号，客服将据此审核',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 14),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '实际支付金额',
                labelStyle: TextStyle(color: Colors.grey),
                prefixText: '￥ ',
                prefixStyle: TextStyle(color: Color(0xFF00C853)),
                filled: true,
                fillColor: Color(0xFF0A0A0A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: txidCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '支付单号（从支付凭证里复制）',
                labelStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF0A0A0A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              final a = amountCtrl.text.trim();
              final t = txidCtrl.text.trim();
              if (a.isEmpty || t.isEmpty) return;
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853)),
            child: const Text('提交'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    setState(() => _loading = true);
    try {
      final r = await ApiService.submitDepositTxid(
        orderNo: _orderNo!,
        amount: amountCtrl.text.trim(),
        paymentTxid: txidCtrl.text.trim(),
      );
      if (r['success'] == true) {
        final st = r['status']?.toString() ?? 'PENDING';
        setState(() => _status = st);
        _toast(st == 'APPROVED' ? '已到账' : '已提交，客服将尽快审核');
      } else {
        _toast(r['message']?.toString() ?? '提交失败');
      }
    } catch (e) {
      _toast('提交失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    setState(() {
      _orderNo = null; _qrContent = null; _qrType = null;
      _merchantName = null; _channel = null; _status = null;
    });
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
        title: const Text('充值'),
        actions: [
          if (_orderNo != null)
            TextButton(onPressed: _reset, child: const Text('重新充值')),
        ],
      ),
      body: _orderNo == null ? _buildChannelList() : _buildQrPage(),
    );
  }

  Widget _buildChannelList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1F1F1F))),
            child: const Row(children: [
              Icon(Icons.bolt, color: Color(0xFF00C853), size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('选择支付方式，扫码付款后回 App 填写支付信息',
                style: TextStyle(color: Colors.white70, fontSize: 13))),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('选择支付方式',
            style: TextStyle(color: Colors.white,
              fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._channels.map(_channelCard),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1F1F1F))),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.help_outline, color: Color(0xFF00C853), size: 18),
                  SizedBox(width: 8),
                  Text('充值流程', style: TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
                SizedBox(height: 10),
                Text('1. 选择支付方式，显示收款码',
                  style: TextStyle(color: Colors.grey, fontSize: 12.5, height: 1.9)),
                Text('2. 扫码完成付款',
                  style: TextStyle(color: Colors.grey, fontSize: 12.5, height: 1.9)),
                Text('3. 回来填写支付金额和单号',
                  style: TextStyle(color: Colors.grey, fontSize: 12.5, height: 1.9)),
                Text('4. 小额自动到账，大额客服审核',
                  style: TextStyle(color: Colors.grey, fontSize: 12.5, height: 1.9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _channelCard(Map<String, dynamic> ch) {
    return GestureDetector(
      onTap: _loading ? null : () => _pickChannel(ch['id'] as String),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F1F1F))),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: (ch['color'] as Color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14)),
            child: Icon(ch['icon'] as IconData,
              color: ch['color'] as Color, size: 28)),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ch['name'] as String, style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(ch['sub'] as String,
                style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
            ])),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
        ]),
      ),
    );
  }

  Widget _buildQrPage() {
    final orderNo = _orderNo ?? '';
    final qrContent = _qrContent ?? '';
    final qrType = _qrType ?? 'TEXT';
    final status = _status ?? 'CREATED';

    Widget qrWidget;
    if (qrContent.isEmpty) {
      qrWidget = const SizedBox(width: 240, height: 240,
        child: Center(child: Text('收款码未配置\n请联系客服',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey))));
    } else if (qrType == 'IMAGE') {
      qrWidget = Image.network(qrContent,
        width: 240, height: 240, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox(width: 240, height: 240,
          child: Center(child: Text('图片加载失败'))));
    } else {
      qrWidget = QrImageView(
        data: qrContent,
        version: QrVersions.auto,
        size: 240,
        backgroundColor: Colors.white);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2A1E), Color(0xFF00C853)],
                begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Column(children: [
              Text(_channelName(_channel ?? 'ALIPAY'),
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              const Text('扫码支付',
                style: TextStyle(color: Colors.white,
                  fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('订单号：$orderNo',
                style: const TextStyle(color: Colors.white60, fontSize: 11,
                  fontFamily: 'monospace')),
            ]),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: qrWidget,
          ),
          const SizedBox(height: 12),
          if (_merchantName != null && _merchantName!.isNotEmpty)
            Text('收款方：$_merchantName',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          Text('用${_channelName(_channel ?? 'ALIPAY')}扫一扫完成付款',
            style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
          const SizedBox(height: 16),
          if (status == 'CREATED')
            ElevatedButton.icon(
              onPressed: _loading ? null : _showSubmitDialog,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('我已支付，填写支付信息'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              ),
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1F1F1F))),
            child: Row(children: [
              _statusIcon(status),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_statusText(status),
                    style: TextStyle(color: _statusColor(status),
                      fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(_statusHint(status),
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              )),
            ]),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _reset,
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('取消，重新充值'),
          ),
        ],
      ),
    );
  }

  Widget _statusIcon(String s) {
    IconData i; Color c;
    switch (s) {
      case 'CREATED': i = Icons.qr_code; c = const Color(0xFF4D9DFF); break;
      case 'PENDING': i = Icons.hourglass_top; c = const Color(0xFFFFA000); break;
      case 'APPROVED': i = Icons.check_circle; c = const Color(0xFF00C853); break;
      case 'REJECTED': i = Icons.cancel; c = Colors.red; break;
      default: i = Icons.info_outline; c = Colors.grey;
    }
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15), shape: BoxShape.circle),
      child: Icon(i, color: c, size: 22));
  }

  String _statusText(String s) {
    switch (s) {
      case 'CREATED': return '等待付款';
      case 'PENDING': return '已提交，等待审核';
      case 'APPROVED': return '已到账';
      case 'REJECTED': return '已拒绝';
      default: return s;
    }
  }

  String _statusHint(String s) {
    switch (s) {
      case 'CREATED': return '扫码后完成付款，回来填写支付信息';
      case 'PENDING': return '客服将尽快审核，请耐心等待';
      case 'APPROVED': return 'USDT 已进入您的账户';
      case 'REJECTED': return '订单被拒，如有疑问请联系客服';
      default: return '';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'CREATED': return const Color(0xFF4D9DFF);
      case 'PENDING': return const Color(0xFFFFA000);
      case 'APPROVED': return const Color(0xFF00C853);
      case 'REJECTED': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _channelName(String id) {
    switch (id) {
      case 'ALIPAY': return '支付宝';
      case 'WECHAT': return '微信支付';
      case 'UNIONPAY': return '云闪付';
      default: return id;
    }
  }
}
