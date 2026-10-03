import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ManageAdminsPage extends StatefulWidget {
  const ManageAdminsPage({super.key});
  @override
  State<ManageAdminsPage> createState() => _ManageAdminsPageState();
}

class _ManageAdminsPageState extends State<ManageAdminsPage> {
  List<dynamic> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ApiService.adminListAccounts();
      if (r['success'] == true) {
        setState(() => _items = (r['items'] as List?) ?? []);
      }
    } catch (e) {
      _toast('加载失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addDialog() async {
    final userCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    String role = 'SUPPORT';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          title: const Text('添加管理员',
            style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '用户名',
                  labelStyle: TextStyle(color: Colors.grey))),
              const SizedBox(height: 12),
              TextField(
                controller: pwdCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '密码',
                  labelStyle: TextStyle(color: Colors.grey))),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: role,
                dropdownColor: const Color(0xFF141414),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'SUPER',
                    child: Text('超级管理员', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'ADMIN',
                    child: Text('管理员', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'SUPPORT',
                    child: Text('客服', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (v) => setSt(() => role = v ?? 'SUPPORT')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () {
                if (userCtrl.text.trim().isEmpty || pwdCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853)),
              child: const Text('添加')),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final r = await ApiService.adminAddAccount(
      username: userCtrl.text.trim(),
      password: pwdCtrl.text.trim(),
      role: role,
    );
    if (r['success'] == true) { _toast('已添加'); _load(); }
    else { _toast(r['message']?.toString() ?? '添加失败'); }
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text('确认删除？', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    final r = await ApiService.adminDeleteAccount(id);
    if (r['success'] == true) { _toast('已删除'); _load(); }
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
        title: const Text('管理员账号'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addDialog),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
          ? const Center(child: Text('暂无管理员',
              style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final a = _items[i] as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1F1F1F))),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853).withValues(alpha: 0.15),
                        shape: BoxShape.circle),
                      child: const Icon(Icons.admin_panel_settings,
                        color: Color(0xFF00C853), size: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['username']?.toString() ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(a['role']?.toString() ?? 'SUPPORT',
                          style: const TextStyle(color: Colors.grey, fontSize: 11.5)),
                      ])),
                    TextButton(
                      onPressed: () => _delete(a['id'].toString()),
                      child: const Text('删除',
                        style: TextStyle(color: Colors.red, fontSize: 12))),
                  ]),
                );
              },
            ),
    );
  }
}
