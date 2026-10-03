import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/build_config.dart';
import 'login_page.dart';
import 'payment_methods_page.dart';
import 'profile/edit_profile_page.dart';
import 'profile/realname_page.dart';
import 'profile/change_password_page.dart';
import 'profile/security_page.dart';
import 'profile/limits_page.dart';
import 'profile/trade_settings_page.dart';
import 'profile/recharge_history_page.dart';
import 'profile/withdraw_history_page.dart';
import 'profile/invite_page.dart';
import 'profile/language_page.dart';
import 'profile/devices_page.dart';
import 'profile/help_page.dart';
import 'profile/about_page.dart';
import 'admin/admin_home_page.dart';
import 'admin/manage_qr_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> _user = {};
  int _points = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);
    try {
      final r = await ApiService.getUserInfo();
      if (r['success'] == true) {
        setState(() {
          _user = r;
          _points = 0; // 积分默认 0
        });
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('确认退出？',
          style: TextStyle(color: Colors.white, fontSize: 17)),
        content: const Text('退出后需要重新登录',
          style: TextStyle(color: Colors.grey, fontSize: 13.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false);
  }

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page))
      .then((_) => _loadUser());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUser),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00C853),
        backgroundColor: const Color(0xFF141414),
        onRefresh: _loadUser,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _userCard(),
            const SizedBox(height: 20),
            _pointsCard(),
            const SizedBox(height: 20),
            _sectionTitle('账户'),
            _menuGroup([
              _item(Icons.person_outline, '个人信息',
                onTap: () => _push(const EditProfilePage())),
              _item(Icons.lock_outline, '修改密码',
                onTap: () => _push(const ChangePasswordPage())),
              _item(Icons.shield_outlined, '密钥验证',
                onTap: () => _push(const SecurityPage())),
              _item(Icons.speed, '账户限额',
                onTap: () => _push(const LimitsPage())),
              _item(Icons.compare_arrows, '交易设置',
                onTap: () => _push(const TradeSettingsPage())),
            ]),
            const SizedBox(height: 20),
            _sectionTitle('支付'),
            _menuGroup([
              _item(Icons.payment, '支付方式管理',
                subtitle: '支付宝 · 微信 · 云闪付',
                onTap: () => _push(const PaymentMethodsPage())),
              _item(Icons.receipt_long_outlined, '充值记录',
                onTap: () => _push(const RechargeHistoryPage())),
              _item(Icons.account_balance_wallet_outlined, '提现记录',
                onTap: () => _push(const WithdrawHistoryPage())),
            ]),
            const SizedBox(height: 20),
            _sectionTitle('其他'),
            _menuGroup([
              _item(Icons.person_add_alt, '邀请并赚取',
                onTap: () => _push(const InvitePage())),
              _item(Icons.language, '语言', trailing: '中文（简体）',
                onTap: () => _push(const LanguagePage())),
              _item(Icons.devices, '设备管理',
                onTap: () => _push(const DevicesPage())),
              _item(Icons.qr_code, '收款码管理',
                onTap: () => _push(const ManageQrPage())),
              _item(Icons.help_outline, '帮助中心',
                onTap: () => _push(const HelpPage())),
              _item(Icons.info_outline, '关于 eUSD.com',
                onTap: () => _push(const AboutPage())),
              _item(Icons.mail_outline, 'cs@eusd.com',
                onTap: () => _push(const HelpPage())),
            ]),
            const SizedBox(height: 24),
            const Center(child: Text('V 1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12))),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5252),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
                child: const Text('退出',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _userCard() {
    final email = _user['email']?.toString() ?? '未登录';
    final nickname = _user['nickname']?.toString() ?? '用户';
    final kycLevel = _user['kycLevel']?.toString() ?? 'NONE';
    final initial = nickname.isNotEmpty ? nickname[0].toUpperCase() : 'U';

    String badge;
    switch (kycLevel) {
      case 'PREMIUM': badge = '尊享用户'; break;
      case 'BASIC': badge = '基础用户'; break;
      default: badge = '未实名';
    }

    return GestureDetector(
      onTap: () => _push(const RealnamePage()),
      onLongPress: BuildConfig.isAdmin ? _showAdminEntry : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: const Color(0xFF1F1F1F))),
        child: Row(children: [
          Container(
            width: 60, height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF00C853), shape: BoxShape.circle),
            child: Center(child: Text(initial,
              style: const TextStyle(color: Colors.white,
                fontSize: 24, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nickname, style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6)),
                child: Text(badge, style: const TextStyle(
                  color: Color(0xFF00C853), fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          )),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
        ]),
      ),
    );
  }

  Widget _pointsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F1F1F))),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB300).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.star, color: Color(0xFFFFB300), size: 22),
        ),
        const SizedBox(width: 14),
        const Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('积分（青铜）', style: TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            SizedBox(height: 4),
            Text('累计签到 7 天可获得额外奖励',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        )),
        Text(_points.toStringAsFixed(2), style: const TextStyle(
          color: Color(0xFFFFB300), fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        const Text('Pts', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(title, style: const TextStyle(
        color: Colors.grey, fontSize: 12.5, fontWeight: FontWeight.w500)),
    );
  }

  Widget _menuGroup(List<Widget> items) {
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

  Widget _item(IconData icon, String title, {
    String? subtitle, String? trailing, required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF00C853).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF00C853), size: 18),
      ),
      title: Text(title, style: const TextStyle(
        color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(subtitle, style: const TextStyle(
          color: Colors.grey, fontSize: 12)),
      ) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  /// 长按用户卡片 → 管理员入口（仅管理版）
  void _showAdminEntry() {
    final pwdCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.admin_panel_settings, color: Color(0xFF00C853), size: 22),
          SizedBox(width: 8),
          Text('管理员验证', style: TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请输入管理员密码',
              style: TextStyle(color: Colors.grey, fontSize: 12.5)),
            const SizedBox(height: 12),
            TextField(
              controller: pwdCtrl,
              obscureText: true,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '管理密码',
                hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0A0A0A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              const adminPassword = 'xh2024admin';
              if (pwdCtrl.text.trim() != adminPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('密码错误'),
                    behavior: SnackBarBehavior.floating));
                return;
              }
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const AdminHomePage()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('进入'),
          ),
        ],
      ),
    );
  }
}
