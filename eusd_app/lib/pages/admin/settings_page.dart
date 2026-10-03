import 'package:flutter/material.dart';
import 'system_config_page.dart';
import '../../config/build_config.dart';
import '../../services/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _batchApprove = true;
  bool _approveConfirm = true;
  bool _rejectRequired = true;
  bool _notifyNew = true;
  bool _soundEnabled = false;
  bool _badgeEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('系统设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoPanel(),
          const SizedBox(height: 20),
          if (BuildConfig.isAdmin) ...[
            _sectionTitle('服务器配置'),
            _configEntry(),
            const SizedBox(height: 20),
          ],
          _sectionTitle('操作设置'),
          _settingGroup([
            _switchItem(
              icon: Icons.playlist_add_check,
              title: '批量通过开关',
              subtitle: '开启后可在工单列表页一键通过当前页所有待处理工单',
              value: _batchApprove,
              onChanged: (v) => setState(() => _batchApprove = v)),
            _switchItem(
              icon: Icons.verified_user_outlined,
              title: '审批二次确认',
              subtitle: '审批通过前弹出确认对话框，防止误操作',
              value: _approveConfirm,
              onChanged: (v) => setState(() => _approveConfirm = v)),
            _switchItem(
              icon: Icons.text_fields,
              title: '拒绝原因必填',
              subtitle: '拒绝解约申请时必须填写拒绝原因（至少3个字）',
              value: _rejectRequired,
              onChanged: (v) => setState(() => _rejectRequired = v)),
          ]),
          const SizedBox(height: 20),
          _sectionTitle('通知设置'),
          _settingGroup([
            _switchItem(
              icon: Icons.notifications_active_outlined,
              title: '新工单提醒',
              subtitle: '有新解约工单提交时显示通知',
              value: _notifyNew,
              onChanged: (v) => setState(() => _notifyNew = v)),
            _switchItem(
              icon: Icons.volume_up_outlined,
              title: '处理完成音效',
              subtitle: '工单处理成功时播放提示音',
              value: _soundEnabled,
              onChanged: (v) => setState(() => _soundEnabled = v)),
            _switchItem(
              icon: Icons.brightness_high_outlined,
              title: '待处理徽章',
              subtitle: '在客服 tab 显示待处理工单数',
              value: _badgeEnabled,
              onChanged: (v) => setState(() => _badgeEnabled = v)),
          ]),
          const SizedBox(height: 20),
          _sectionTitle('危险操作'),
          _dangerGroup(),
          const SizedBox(height: 24),
          Center(
            child: Text('V 1.0.0 · ${DateTime.now().year}',
              style: const TextStyle(color: Color(0xFF555555), fontSize: 12)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _infoPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.info_outline, color: Color(0xFF00C853), size: 20),
            SizedBox(width: 8),
            Text('系统信息', style: TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 16),
          _infoRow('系统名称', 'eUSD 客服后台'),
          _infoRow('版本号', 'v1.0.0'),
          _infoRow('后端地址', ApiService.adminBaseUrl),
          _infoRow('环境', '开发环境'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
          ),
          Expanded(
            child: Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 12.5,
                fontFamily: 'monospace'),
              textAlign: TextAlign.right,
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(t, style: const TextStyle(
        color: Colors.grey, fontSize: 12.5, fontWeight: FontWeight.w500)),
    );
  }

  Widget _settingGroup(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Column(
        children: List.generate(items.length, (i) => Container(
          decoration: BoxDecoration(
            border: i == items.length - 1 ? null : const Border(
              bottom: BorderSide(color: Color(0xFF1A1A1A), width: 1))),
          child: items[i],
        )),
      ),
    );
  }

  Widget _switchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF00C853), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(subtitle,
                  style: const TextStyle(color: Colors.grey,
                    fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          Switch(
            value: value, onChanged: onChanged,
            activeColor: const Color(0xFF00C853)),
        ],
      ),
    );
  }

  Widget _dangerGroup() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF44336).withOpacity(0.3))),
      child: Column(
        children: [
          _dangerItem(
            icon: Icons.delete_sweep_outlined,
            title: '清除本地数据',
            subtitle: '清除 App 中保存的所有本地设置和登录信息',
            buttonText: '清除',
            onTap: _confirmClear),
          Container(height: 1, color: const Color(0xFF1A1A1A)),
          _dangerItem(
            icon: Icons.logout,
            title: '退出登录',
            subtitle: '退出当前管理员账号，需要重新登录',
            buttonText: '退出',
            onTap: _confirmLogout),
        ],
      ),
    );
  }

  Widget _dangerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF44336).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFFF44336), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(subtitle,
                  style: const TextStyle(color: Colors.grey,
                    fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF44336),
              side: const BorderSide(color: Color(0xFFF44336)),
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8))),
            child: Text(buttonText, style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('清除本地数据', style: TextStyle(color: Colors.white)),
        content: const Text('将清除 App 中保存的所有本地设置和登录信息，确认继续？',
          style: TextStyle(color: Colors.grey, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ApiService.logout();
              _toast('已清除本地数据');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              minimumSize: const Size(100, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('退出登录', style: TextStyle(color: Colors.white)),
        content: const Text('确认退出当前管理员账号？',
          style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ApiService.logout();
              _toast('已退出登录');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              minimumSize: const Size(100, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));
  }

  Widget _configEntry() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF00C853).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.dns_outlined,
            color: Color(0xFF00C853), size: 22)),
        title: const Text('系统配置',
          style: TextStyle(color: Colors.white,
            fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Alchemy Pay / TRON 归集 / 收款码 / 支付密钥',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SystemConfigPage())),
      ),
    );
  }

}
