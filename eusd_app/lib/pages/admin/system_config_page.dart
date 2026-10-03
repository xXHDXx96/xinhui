import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SystemConfigPage extends StatefulWidget {
  const SystemConfigPage({super.key});
  @override
  State<SystemConfigPage> createState() => _SystemConfigPageState();
}

class _SystemConfigPageState extends State<SystemConfigPage>
    with SingleTickerProviderStateMixin {

  late TabController _tabCtrl;
  List<String> _groups = [];
  bool _loading = true;

  // 每个分组的配置项缓存
  final Map<String, List<dynamic>> _configs = {};

  static const Map<String, String> _groupNames = {
    'ALCHEMY': 'Alchemy Pay',
    'TRON': 'TRON 归集',
    'PAYMENT': '收款码',
    'ALIPAY': '支付宝官方',
    'WECHAT': '微信支付',
    'STRIPE': 'Stripe',
    'SYSTEM': '系统',
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 1, vsync: this);
    _loadGroups();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() => _loading = true);
    try {
      final r = await ApiService.getConfigGroups();
      final list = (r['groups'] as List?)?.cast<String>() ?? [];
      if (list.isEmpty) {
        setState(() { _loading = false; });
        return;
      }
      // 重建 TabController
      _tabCtrl.dispose();
      _tabCtrl = TabController(length: list.length, vsync: this);
      setState(() {
        _groups = list;
        _loading = false;
      });
      // 预加载第一个分组
      _loadConfigs(list.first);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadConfigs(String group) async {
    final r = await ApiService.getConfigList(group);
    if (r['success'] == true && mounted) {
      setState(() {
        _configs[group] = (r['items'] as List?) ?? [];
      });
    }
  }

  Future<void> _editConfig(Map<String, dynamic> item, String group) async {
    final isSecret = item['isSecret'] == true;
    final currentVal = item['value']?.toString() ?? '';

    final ctrl = TextEditingController(text: isSecret ? '' : currentVal);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          item['displayName']?.toString() ?? item['key']?.toString() ?? '配置',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['description'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  item['description'].toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            if (isSecret)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(children: [
                  Icon(Icons.warning_amber, color: Color(0xFFFF9800), size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text(
                    '敏感字段，留空表示不修改，输入新值会覆盖',
                    style: TextStyle(color: Color(0xFFFF9800), fontSize: 11.5),
                  )),
                ]),
              ),
            TextField(
              controller: ctrl,
              autofocus: !isSecret,
              maxLines: isSecret ? 1 : 3,
              minLines: 1,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: isSecret ? '（已设置，输入新值覆盖）' : '输入值',
                hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0A0A0A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (c2) => AlertDialog(
                  backgroundColor: const Color(0xFF141414),
                  title: const Text('确认删除？',
                    style: TextStyle(color: Colors.white)),
                  content: const Text('删除后此项配置将从数据库移除',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c2, false),
                      child: const Text('取消',
                        style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(c2, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF44336)),
                      child: const Text('删除'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              Navigator.pop(ctx);
              final r = await ApiService.deleteConfig(item['id'].toString());
              if (!mounted) return;
              _toast(r['success'] == true ? '已删除' : '删除失败');
              _loadConfigs(group);
            },
            child: const Text('删除', style: TextStyle(color: Color(0xFFF44336))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newVal = ctrl.text;
              if (!isSecret && newVal.isEmpty) {
                _toast('请输入值');
                return;
              }
              if (isSecret && newVal.isEmpty) {
                // 敏感字段留空 = 不改
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(ctx);
              final r = await ApiService.setConfig(
                group: group,
                key: item['key'].toString(),
                value: newVal,
              );
              if (!mounted) return;
              _toast(r['success'] == true
                ? r['message']?.toString() ?? '已保存'
                : r['message']?.toString() ?? '保存失败');
              _loadConfigs(group);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewConfig(String group) async {
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isSecret = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('新增配置项',
            style: TextStyle(color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('配置键（英文）'),
                _field(keyCtrl, '例如 custom-key'),
                const SizedBox(height: 10),
                _label('配置值'),
                _field(valCtrl, '值'),
                const SizedBox(height: 10),
                _label('显示名称'),
                _field(nameCtrl, '可选'),
                const SizedBox(height: 10),
                _label('说明'),
                _field(descCtrl, '可选'),
                const SizedBox(height: 10),
                Row(children: [
                  Checkbox(
                    value: isSecret,
                    onChanged: (v) => setSt(() => isSecret = v ?? false),
                    activeColor: const Color(0xFF00C853),
                  ),
                  const Text('敏感字段（展示时脱敏）',
                    style: TextStyle(color: Colors.grey, fontSize: 12.5)),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (keyCtrl.text.trim().isEmpty) {
                  _toast('请输入配置键');
                  return;
                }
                Navigator.pop(ctx);
                final r = await ApiService.setConfig(
                  group: group,
                  key: keyCtrl.text.trim(),
                  value: valCtrl.text,
                  displayName: nameCtrl.text.trim().isEmpty
                    ? null : nameCtrl.text.trim(),
                  isSecret: isSecret,
                  description: descCtrl.text.trim().isEmpty
                    ? null : descCtrl.text.trim(),
                );
                if (!mounted) return;
                _toast(r['success'] == true ? '已新增' : '失败');
                _loadConfigs(group);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                minimumSize: const Size(80, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
              child: const Text('新增'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(t, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }

  Widget _field(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0A0A0A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
      ),
    );
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
        title: const Text('系统配置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadGroups();
              for (final g in _groups) { _loadConfigs(g); }
            },
          ),
        ],
        bottom: _loading || _groups.isEmpty ? null : TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: const Color(0xFF00C853),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF00C853),
          onTap: (i) => _loadConfigs(_groups[i]),
          tabs: _groups.map((g) => Tab(text: _groupNames[g] ?? g)).toList(),
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _groups.isEmpty
          ? const Center(child: Text('暂无配置分组',
              style: TextStyle(color: Colors.grey)))
          : TabBarView(
              controller: _tabCtrl,
              children: _groups.map(_buildGroupView).toList(),
            ),
      floatingActionButton: _groups.isEmpty ? null : FloatingActionButton.extended(
        onPressed: () => _addNewConfig(_groups[_tabCtrl.index]),
        backgroundColor: const Color(0xFF00C853),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('新增配置', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildGroupView(String group) {
    final list = _configs[group];
    if (list == null) {
      // 懒加载
      _loadConfigs(group);
      return const Center(child: CircularProgressIndicator());
    }
    if (list.isEmpty) {
      return const Center(child: Text('暂无配置项',
        style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      color: const Color(0xFF00C853),
      backgroundColor: const Color(0xFF141414),
      onRefresh: () => _loadConfigs(group),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final item = list[i] as Map<String, dynamic>;
          return _buildConfigCard(group, item);
        },
      ),
    );
  }

  Widget _buildConfigCard(String group, Map<String, dynamic> item) {
    final isSecret = item['isSecret'] == true;
    final val = item['value']?.toString() ?? '';
    return GestureDetector(
      onTap: () => _editConfig(item, group),
      child: Container(
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
              Expanded(
                child: Text(
                  item['displayName']?.toString() ?? item['key'].toString(),
                  style: const TextStyle(color: Colors.white,
                    fontSize: 14, fontWeight: FontWeight.w600))),
              if (isSecret)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4)),
                  child: const Text('敏感',
                    style: TextStyle(color: Color(0xFFFF9800), fontSize: 10))),
            ]),
            const SizedBox(height: 6),
            Text(item['key'].toString(),
              style: const TextStyle(color: Color(0xFF666666),
                fontSize: 11, fontFamily: 'monospace')),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(8)),
              child: Text(
                val.isEmpty ? '（未设置）' : val,
                style: TextStyle(
                  color: val.isEmpty ? const Color(0xFF555555) : Colors.white70,
                  fontSize: 12.5, fontFamily: 'monospace'),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            if (item['description'] != null &&
                item['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(item['description'].toString(),
                style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}
