import 'package:flutter/material.dart';
import 'deposit_review_page.dart';
import 'manage_qr_page.dart';
import 'manage_users_page.dart';
import 'manage_cards_page.dart';
import 'manage_admins_page.dart';
import 'system_config_page.dart';
import 'settings_page.dart';
import 'ticket_list_page.dart';
import 'stats_page.dart';
import 'logs_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('后台管理'),
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('交易'),
          _menuGroup([
            _item(context, Icons.receipt_long, '充值订单审核', '通过 / 拒绝待审订单',
                () => const DepositReviewPage()),
            _item(context, Icons.qr_code_2, '收款码管理', 'U商收款码增删改',
                () => const ManageQrPage()),
          ]),
          const SizedBox(height: 20),
          _sectionTitle('用户'),
          _menuGroup([
            _item(context, Icons.people, '用户管理', '用户列表 / 封禁 / KYC',
                () => const ManageUsersPage()),
            _item(context, Icons.credit_card, '卡片管理', '所有卡片 / 冻结 / 注销',
                () => const ManageCardsPage()),
          ]),
          const SizedBox(height: 20),
          _sectionTitle('客服'),
          _menuGroup([
            _item(context, Icons.support_agent, '工单列表', '查看/回复用户工单',
                () => const TicketListPage()),
          ]),
          const SizedBox(height: 20),
          _sectionTitle('系统'),
          _menuGroup([
            _item(context, Icons.settings_applications, '系统配置', '充值/汇率/开关等参数',
                () => const SystemConfigPage()),
            _item(context, Icons.tune, '参数设置', '通用设置',
                () => const SettingsPage()),
          ]),
          const SizedBox(height: 20),
          _sectionTitle('运维'),
          _menuGroup([
            _item(context, Icons.bar_chart, '数据统计', '用户/交易/充值等数据',
                () => const StatsPage()),
            _item(context, Icons.history, '操作日志', '查看管理操作记录',
                () => const LogsPage()),
          ]),
          const SizedBox(height: 20),
          _sectionTitle('权限'),
          _menuGroup([
            _item(context, Icons.admin_panel_settings, '管理员账号', '增删管理员 / 角色',
                () => const ManageAdminsPage()),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String s) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(s,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            )),
      );

  Widget _menuGroup(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F1F1F)),
        ),
        child: Column(children: children),
      );

  Widget _item(BuildContext context, IconData icon, String title, String sub,
      Widget Function() builder) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF00C853).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: const Color(0xFF00C853), size: 22),
      ),
      title: Text(title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          )),
      subtitle: Text(sub,
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => builder()));
      },
    );
  }
}
