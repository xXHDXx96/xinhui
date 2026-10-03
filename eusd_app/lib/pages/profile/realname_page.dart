import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RealnamePage extends StatefulWidget {
  const RealnamePage({super.key});
  @override
  State<RealnamePage> createState() => _RealnamePageState();
}

class _RealnamePageState extends State<RealnamePage> {
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final idNo = _idCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || idNo.isEmpty || phone.isEmpty) {
      _toast('请填写完整信息');
      return;
    }
    if (idNo.length != 18) {
      _toast('身份证号应为 18 位');
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await ApiService.submitRealname(
        realName: name, idNumber: idNo, phone: phone);
      if (r['success'] == true) {
        _toast('已提交，等待审核');
        if (mounted) Navigator.pop(context);
      } else {
        _toast(r['message']?.toString() ?? '提交失败');
      }
    } catch (e) {
      _toast('提交失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('实名认证')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                  Icon(Icons.verified_user, color: Color(0xFF00C853), size: 20),
                  SizedBox(width: 8),
                  Text('实名认证说明',
                    style: TextStyle(color: Colors.white, fontSize: 14,
                      fontWeight: FontWeight.w600)),
                ]),
                SizedBox(height: 10),
                Text('完成实名认证后可解锁全部功能，信息仅用于身份核验。',
                  style: TextStyle(color: Colors.grey, fontSize: 12.5, height: 1.7)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: '真实姓名',
              labelStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.person, color: Colors.grey),
              filled: true,
              fillColor: Color(0xFF0A0A0A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _idCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: '身份证号',
              labelStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.badge, color: Colors.grey),
              filled: true,
              fillColor: Color(0xFF0A0A0A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: '手机号',
              labelStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.phone, color: Colors.grey),
              filled: true,
              fillColor: Color(0xFF0A0A0A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _loading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
            child: Text(_loading ? '提交中...' : '提交认证',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
