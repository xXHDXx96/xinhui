import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLogin = true;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty) { _toast('请输入邮箱'); return; }
    if (password.isEmpty) { _toast('请输入密码'); return; }
    if (password.length < 6) { _toast('密码至少 6 位'); return; }
    if (!_isLogin && _nicknameCtrl.text.trim().isEmpty) {
      _toast('请输入昵称');
      return;
    }

    setState(() => _loading = true);
    try {
      final r = _isLogin
        ? await ApiService.login(email, password)
        : await ApiService.register(email, password, _nicknameCtrl.text.trim());

      if (r['success'] == true) {
        final token = r['token']?.toString();
        final userId = (r['user'] as Map?)?['id']?.toString();
        if (token == null || userId == null) {
          _toast('登录返回数据异常');
          return;
        }
        await ApiService.setAuth(token, userId);

        if (!mounted) return;
        _toast(_isLogin ? '登录成功' : '注册成功');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const MainScaffold()));
          }
        });
      } else {
        _toast(r['message']?.toString() ?? '操作失败');
      }
    } catch (e) {
      _toast('网络错误: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 打开服务器设置弹窗
  Future<void> _showServerSettings() async {
    final ctrl = TextEditingController(text: AppConfig.baseUrl);
    bool testing = false;
    bool? ok;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('服务器设置',
                style: TextStyle(color: Colors.white,
                  fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('修改后需要重新登录才生效',
                style: TextStyle(color: Colors.grey, fontSize: 12.5)),
              const SizedBox(height: 20),
              const Text('服务器地址', style: TextStyle(
                color: Colors.grey, fontSize: 12.5)),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'http://1.2.3.4:8080',
                  hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0A0A0A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14)),
              ),
              const SizedBox(height: 16),
              if (ok != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (ok! ? const Color(0xFF00C853) : const Color(0xFFF44336))
                      .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Icon(ok! ? Icons.check_circle : Icons.cancel,
                      color: ok! ? const Color(0xFF00C853) : const Color(0xFFF44336),
                      size: 16),
                    const SizedBox(width: 8),
                    Text(ok! ? '连接成功' : '连接失败，请检查地址和网络',
                      style: TextStyle(
                        color: ok! ? const Color(0xFF00C853) : const Color(0xFFF44336),
                        fontSize: 12.5)),
                  ]),
                ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: testing ? null : () async {
                      setSheet(() { testing = true; ok = null; });
                      await AppConfig.setBaseUrl(ctrl.text);
                      final r = await AppConfig.testConnection();
                      setSheet(() { testing = false; ok = r; });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00C853),
                      side: const BorderSide(color: Color(0xFF00C853)),
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                    child: testing
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(
                            color: Color(0xFF00C853), strokeWidth: 2))
                      : const Text('测试连接'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final url = ctrl.text.trim();
                      if (url.isEmpty) return;
                      await AppConfig.setBaseUrl(url);
                      Navigator.pop(ctx);
                      _toast('已保存，请重新登录');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                    child: const Text('保存'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () async {
                    await AppConfig.reset();
                    ctrl.text = AppConfig.baseUrl;
                    setSheet(() { ok = null; });
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text('还原默认地址', style: TextStyle(fontSize: 12.5)),
                ),
              ),
            ],
          ),
        ),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.dns_outlined, color: Colors.grey),
            tooltip: '服务器设置',
            onPressed: _showServerSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00C853),
                    shape: BoxShape.circle),
                  child: const Center(
                    child: Text('e', style: TextStyle(
                      color: Colors.white,
                      fontSize: 40, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text('鑫汇Pay',
                  style: TextStyle(color: Colors.white,
                    fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(_isLogin ? '登录账户，开始使用' : '注册账户',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ),
              const SizedBox(height: 40),

              _label('邮箱'),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: _inputDecoration('your@email.com', Icons.mail_outline),
              ),
              const SizedBox(height: 16),

              if (!_isLogin) ...[
                _label('昵称'),
                TextField(
                  controller: _nicknameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: _inputDecoration('给自己取个名字', Icons.person_outline),
                ),
                const SizedBox(height: 16),
              ],

              _label('密码'),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: _inputDecoration('至少 6 位', Icons.lock_outline)
                  .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure))),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
                  child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                    : Text(_isLogin ? '登录' : '注册',
                        style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _isLogin = !_isLogin;
                    _passwordCtrl.clear();
                    _nicknameCtrl.clear();
                  }),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF00C853)),
                  child: Text(_isLogin ? '还没有账户？立即注册' : '已有账户？返回登录',
                    style: const TextStyle(fontSize: 14)),
                ),
              ),

              const SizedBox(height: 40),
              Center(
                child: Text('继续即表示同意 服务条款 和 隐私政策',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11.5)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(t, style: const TextStyle(
        color: Colors.grey, fontSize: 13)),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
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
}
