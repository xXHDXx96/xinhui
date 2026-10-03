import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  bool _obscure1 = true, _obscure2 = true, _obscure3 = true;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_oldCtrl.text.isEmpty) { _toast('请输入原密码'); return; }
    if (_newCtrl.text.length < 6) { _toast('新密码至少6位'); return; }
    if (_newCtrl.text != _confirmCtrl.text) { _toast('两次输入不一致'); return; }

    setState(() => _saving = true);
    try {
      final r = await ApiService.changePassword(
        oldPassword: _oldCtrl.text, newPassword: _newCtrl.text);
      if (!mounted) return;
      if (r['success'] == true) {
        _toast('密码已修改');
        Navigator.pop(context);
      } else {
        _toast(r['message']?.toString() ?? '修改失败');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
      appBar: AppBar(title: const Text('修改密码')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          _label('原密码'),
          _pwdField(_oldCtrl, '请输入原密码', _obscure1,
            () => setState(() => _obscure1 = !_obscure1)),
          const SizedBox(height: 16),
          _label('新密码'),
          _pwdField(_newCtrl, '至少6位', _obscure2,
            () => setState(() => _obscure2 = !_obscure2)),
          const SizedBox(height: 16),
          _label('确认新密码'),
          _pwdField(_confirmCtrl, '再次输入', _obscure3,
            () => setState(() => _obscure3 = !_obscure3)),
          const SizedBox(height: 40),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
              child: _saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                : const Text('确认修改',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(t, style: const TextStyle(color: Colors.grey, fontSize: 13)));

  Widget _pwdField(TextEditingController ctrl, String hint,
                   bool obscure, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF141414),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey, size: 20),
          onPressed: toggle),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00C853), width: 1.2)),
      ),
    );
  }
}
