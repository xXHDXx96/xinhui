import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nickCtrl = TextEditingController();
  Map<String, dynamic> _user = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await ApiService.getUserInfo();
    if (r['success'] == true && mounted) {
      setState(() {
        _user = r;
        _nickCtrl.text = r['nickname']?.toString() ?? '';
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final name = _nickCtrl.text.trim();
    if (name.isEmpty) {
      _toast('请输入昵称');
      return;
    }
    setState(() => _saving = true);
    try {
      final r = await ApiService.updateProfile(nickname: name);
      if (!mounted) return;
      if (r['success'] == true) {
        _toast('保存成功');
        Navigator.pop(context, true);
      } else {
        _toast(r['message']?.toString() ?? '保存失败');
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
      appBar: AppBar(title: const Text('个人信息')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 96, height: 96,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00C853), shape: BoxShape.circle),
                  child: Center(child: Text(
                    (_user['nickname']?.toString() ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white,
                      fontSize: 40, fontWeight: FontWeight.bold))),
                ),
              ),
              const SizedBox(height: 30),
              _label('昵称'),
              TextField(
                controller: _nickCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: _inputDeco('请输入昵称'),
              ),
              const SizedBox(height: 20),
              _label('邮箱（不可修改）'),
              TextField(
                controller: TextEditingController(text: _user['email']?.toString() ?? ''),
                enabled: false,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
                decoration: _inputDeco(''),
              ),
              const SizedBox(height: 20),
              _label('KYC 状态'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1F1F1F))),
                child: Row(children: [
                  Icon(
                    _user['kycStatus'] == 'VERIFIED'
                      ? Icons.verified : Icons.pending_outlined,
                    color: _user['kycStatus'] == 'VERIFIED'
                      ? const Color(0xFF00C853) : const Color(0xFFFF9800),
                    size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _user['kycStatus']?.toString() ?? 'UNVERIFIED',
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                ]),
              ),
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
                    : const Text('保存',
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

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
    filled: true,
    fillColor: const Color(0xFF141414),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF00C853), width: 1.2)),
  );
}
