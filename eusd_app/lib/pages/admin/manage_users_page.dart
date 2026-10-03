import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});
  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  List<dynamic> _items = [];
  bool _loading = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ApiService.adminListUsers(keyword: _searchCtrl.text.trim());
      if (r['success'] == true) {
        setState(() => _items = (r['items'] as List?) ?? []);
      } else {
        _toast(r['message']?.toString() ?? '加载失败');
      }
    } catch (e) {
      _toast('加载失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ban(String id, bool banned) async {
    final action = banned ? '解封' : '封禁';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: Text('确认$action？', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: banned ? const Color(0xFF00C853) : Colors.red),
            child: Text(action)),
        ],
      ),
    );
    if (ok != true) return;
    final r = banned
      ? await ApiService.adminUnbanUser(id)
      : await ApiService.adminBanUser(id);
    if (r['success'] == true) { _toast('已$action'); _load(); }
    else { _toast(r['message']?.toString() ?? '失败'); }
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
        title: const Text('用户管理'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '搜索邮箱 / 昵称 / 手机号',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF141414),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Color(0xFF00C853)),
                  onPressed: _load),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_items.isEmpty)
            const Expanded(child: Center(child: Text('暂无用户',
              style: TextStyle(color: Colors.grey))))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final u = _items[i] as Map<String, dynamic>;
                  final banned = u['kycStatus'] == 'BANNED';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1F1F1F))),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: banned
                            ? Colors.red.withValues(alpha: 0.15)
                            : const Color(0xFF00C853).withValues(alpha: 0.15),
                          shape: BoxShape.circle),
                        child: Center(child: Text(
                          (u['nickname']?.toString() ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            color: banned ? Colors.red : const Color(0xFF00C853),
                            fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u['email']?.toString() ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 13.5),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text('KYC: ${u['kycStatus'] ?? 'UNVERIFIED'} · ${u['kycLevel'] ?? 'NONE'}',
                            style: const TextStyle(color: Colors.grey, fontSize: 11.5)),
                        ],
                      )),
                      TextButton(
                        onPressed: () => _ban(u['id'].toString(), banned),
                        child: Text(banned ? '解封' : '封禁',
                          style: TextStyle(
                            color: banned ? const Color(0xFF00C853) : Colors.red,
                            fontSize: 12))),
                    ]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
