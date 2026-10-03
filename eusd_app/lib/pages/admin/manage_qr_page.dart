import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ManageQrPage extends StatefulWidget {
  const ManageQrPage({super.key});
  @override
  State<ManageQrPage> createState() => _ManageQrPageState();
}

class _ManageQrPageState extends State<ManageQrPage> {
  bool _loading = false;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ApiService.listQrCodes();
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
    String channel = 'ALIPAY';
    final merchantCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final remarkCtrl = TextEditingController();
    String qrType = 'TEXT';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          title: const Text('添加收款码',
            style: TextStyle(color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('渠道', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButton<String>(
                  value: channel,
                  dropdownColor: const Color(0xFF141414),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'ALIPAY', child: Text('支付宝', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'WECHAT', child: Text('微信', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'UNIONPAY', child: Text('云闪付', style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (v) => setSt(() => channel = v ?? 'ALIPAY'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: merchantCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'U商名称',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('类型', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                Row(children: [
                  Radio<String>(
                    value: 'TEXT', groupValue: qrType,
                    onChanged: (v) => setSt(() => qrType = v ?? 'TEXT'),
                    activeColor: const Color(0xFF00C853)),
                  const Text('二维码内容', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 12),
                  Radio<String>(
                    value: 'IMAGE', groupValue: qrType,
                    onChanged: (v) => setSt(() => qrType = v ?? 'TEXT'),
                    activeColor: const Color(0xFF00C853)),
                  const Text('图片URL', style: TextStyle(color: Colors.white)),
                ]),
                const SizedBox(height: 8),
                TextField(
                  controller: contentCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: qrType == 'TEXT' ? '二维码内容' : '图片URL',
                    labelStyle: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: remarkCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: '备注（可选）',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () {
                if (contentCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853)),
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    setState(() => _loading = true);
    try {
      final r = await ApiService.addQrCode(
        channel: channel,
        qrContent: contentCtrl.text.trim(),
        qrType: qrType,
        merchantName: merchantCtrl.text.trim(),
        remark: remarkCtrl.text.trim(),
      );
      if (r['success'] == true) {
        _toast('已添加');
        _load();
      } else {
        _toast(r['message']?.toString() ?? '添加失败');
      }
    } catch (e) {
      _toast('添加失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    final r = await ApiService.deleteQrCode(id);
    if (r['success'] == true) { _toast('已删除'); _load(); }
  }

  Future<void> _toggle(String id) async {
    final r = await ApiService.toggleQrCode(id);
    if (r['success'] == true) { _load(); }
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
        title: const Text('收款码管理'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addDialog),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading && _items.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
          ? const Center(child: Text('暂无收款码',
              style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i] as Map<String, dynamic>;
                final enabled = item['enabled'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1F1F1F))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4)),
                          child: Text(item['channel']?.toString() ?? '',
                            style: const TextStyle(color: Color(0xFF00C853), fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item['merchantName']?.toString() ?? '未命名',
                          style: const TextStyle(color: Colors.white, fontSize: 14))),
                        Switch(
                          value: enabled,
                          onChanged: (_) => _toggle(item['id'].toString()),
                          activeThumbColor: const Color(0xFF00C853)),
                      ]),
                      const SizedBox(height: 8),
                      Text('内容：${item['qrContent']?.toString() ?? ''}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('已用 ${item['usedCount'] ?? 0} 次',
                            style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          TextButton(
                            onPressed: () => _delete(item['id'].toString()),
                            child: const Text('删除',
                              style: TextStyle(color: Colors.red, fontSize: 12))),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
