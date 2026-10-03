import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/virtual_card.dart';
import '../config/app_config.dart';

class ApiService {
  // 服务器地址（改你自己的）

  static String get baseUrl => AppConfig.baseUrl;
  static String get adminBaseUrl => AppConfig.adminBaseUrl;

  static String? _token;
  static String? _userId;

  static Future<void> init() async {
    await AppConfig.load();
    final p = await SharedPreferences.getInstance();
    _token = p.getString('token');
    _userId = p.getString('userId');
  }

  static Future<void> setAuth(String token, String userId) async {
    _token = token;
    _userId = userId;
    final p = await SharedPreferences.getInstance();
    await p.setString('token', token);
    await p.setString('userId', userId);
  }

  static Future<void> logout() async {
    _token = null;
    _userId = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('token');
    await p.remove('userId');
  }

  static String? get userId => _userId;
  static bool get isLoggedIn => _userId != null && _userId!.isNotEmpty;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ===== 通用请求 =====
  static Future<Map<String, dynamic>> _doGet(String url) async {
    try {
      final r = await http.get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 20));
      return _handle(r);
    } catch (e) {
      return {'success': false, 'message': '网络错误: $e'};
    }
  }

  static Future<Map<String, dynamic>> _doPost(String url, {Map<String, String>? q}) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: q);
      final r = await http.post(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));
      return _handle(r);
    } catch (e) {
      return {'success': false, 'message': '网络错误: $e'};
    }
  }

  static Future<Map<String, dynamic>> _doPostJson(String url, Map<String, dynamic> body) async {
    try {
      final r = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));
      return _handle(r);
    } catch (e) {
      return {'success': false, 'message': '网络错误: $e'};
    }
  }

  static Map<String, dynamic> _handle(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.body.isEmpty) return {'success': true};
      try {
        final d = jsonDecode(r.body);
        if (d is Map<String, dynamic>) return d;
        return {'success': true, 'data': d};
      } catch (_) {
        return {'success': true, 'raw': r.body};
      }
    }
    return {'success': false, 'message': 'HTTP ${r.statusCode}'};
  }

  static Future<Map<String, dynamic>> _get(String p) => _doGet('$baseUrl$p');
  static Future<Map<String, dynamic>> _post(String p, {Map<String, String>? q}) =>
    _doPost('$baseUrl$p', q: q);

  // ==========================================
  // 用户登录注册
  // ==========================================
  static Future<Map<String, dynamic>> register(String email, String password, String nickname) async {
    return _doPostJson('$baseUrl/user/register', {
      'email': email,
      'password': password,
      'nickname': nickname,
    });
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    return _doPostJson('$baseUrl/user/login', {
      'email': email,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> getUserInfo() async {
    if (_userId == null) return {'success': false};
    return _get('/user/info/$_userId');
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? nickname,
    String? avatarUrl,
  }) async {
    if (_userId == null) return {'success': false};
    final q = <String, String>{'userId': _userId!};
    if (nickname != null) q['nickname'] = nickname;
    if (avatarUrl != null) q['avatarUrl'] = avatarUrl;
    return _post('/user/update', q: q);
  }

  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_userId == null) return {'success': false};
    return _post('/user/change-password', q: {
      'userId': _userId!,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  // ==========================================
  // 余额
  // ==========================================
  static Future<Map<String, dynamic>> getBalance() async {
    if (_userId == null) return {'success': false};
    return _get('/recharge/balance/$_userId');
  }

  // ==========================================
  // 充值申请（扫码支付 + 客服审核）
  // ==========================================
  static Future<Map<String, dynamic>> createDeposit({
    required String channel,
  }) async {
    if (_userId == null) return {'success': false, 'message': '未登录'};
    return _post('/deposit/create', q: {
      'userId': _userId!,
      'channel': channel,
    });
  }

  static Future<Map<String, dynamic>> submitDepositTxid({
    required String orderNo,
    required String amount,
    required String paymentTxid,
    String? screenshot,
  }) async {
    final q = <String, String>{
      'orderNo': orderNo,
      'amount': amount,
      'paymentTxid': paymentTxid,
    };
    if (screenshot != null) q['screenshot'] = screenshot;
    return _post('/deposit/submit', q: q);
  }

  static Future<Map<String, dynamic>> getDepositStatus(String orderNo) async {
    return _get('/deposit/status/$orderNo');
  }

  // ===== 管理员 - 收款码管理 =====
  static Future<Map<String, dynamic>> listQrCodes() async {
    return _get('/admin/qr-codes/list');
  }

  static Future<Map<String, dynamic>> addQrCode({
    required String channel,
    required String qrContent,
    String qrType = 'TEXT',
    String? merchantName,
    String? remark,
  }) async {
    return _post('/admin/qr-codes/add', q: {
      'channel': channel,
      'qrContent': qrContent,
      'qrType': qrType,
      if (merchantName != null && merchantName.isNotEmpty) 'merchantName': merchantName,
      if (remark != null && remark.isNotEmpty) 'remark': remark,
    });
  }

  static Future<Map<String, dynamic>> deleteQrCode(String id) async {
    return _post('/admin/qr-codes/delete/$id', q: {});
  }

  static Future<Map<String, dynamic>> toggleQrCode(String id) async {
    return _post('/admin/qr-codes/toggle/$id', q: {});
  }

  // ===== 管理员 - 用户管理 =====
  static Future<Map<String, dynamic>> adminListUsers({String? keyword}) async {
    final q = keyword != null && keyword.isNotEmpty ? '?keyword=$keyword' : '';
    return _get('/admin/users/list$q');
  }

  static Future<Map<String, dynamic>> adminBanUser(String id) async {
    return _post('/admin/users/ban/$id', q: {});
  }

  static Future<Map<String, dynamic>> adminUnbanUser(String id) async {
    return _post('/admin/users/unban/$id', q: {});
  }

  // ===== 管理员 - 卡片管理 =====
  static Future<Map<String, dynamic>> adminListCards() async {
    return _get('/admin/cards/list');
  }

  static Future<Map<String, dynamic>> adminUpdateCardStatus(String id, String status) async {
    return _post('/admin/cards/status/$id', q: {'status': status});
  }

  // ===== 管理员 - 账号管理 =====
  static Future<Map<String, dynamic>> adminListAccounts() async {
    return _get('/admin/accounts/list');
  }

  static Future<Map<String, dynamic>> adminAddAccount({
    required String username,
    required String password,
    String role = 'SUPPORT',
  }) async {
    return _post('/admin/accounts/add', q: {
      'username': username,
      'password': password,
      'role': role,
    });
  }

  static Future<Map<String, dynamic>> adminDeleteAccount(String id) async {
    return _post('/admin/accounts/delete/$id', q: {});
  }

  // ===== 管理员 - 收款码 =====
  static Future<Map<String, dynamic>> getChannelQr(String channel) async {
    return _get('/deposit/qr/$channel');
  }

  static Future<Map<String, dynamic>> submitRealname({
    required String realName,
    required String idNumber,
    required String phone,
  }) async {
    if (_userId == null) return {'success': false, 'message': '未登录'};
    return _post('/user/realname', q: {
      'userId': _userId!,
      'realName': realName,
      'idNumber': idNumber,
      'phone': phone,
    });
  }


  static Future<Map<String, dynamic>> getDepositHistory() async {
    if (_userId == null) return {'success': false};
    return _get('/deposit/history/$_userId');
  }

  // ==========================================
  // 充值订单（旧接口，保留兼容）
  // ==========================================
  static Future<Map<String, dynamic>> createRechargeOrder({
    required String channel,
    required double amount,
    String targetAsset = 'USD',
  }) async {
    if (_userId == null) return {'success': false, 'message': '未登录'};
    return _post('/recharge/create', q: {
      'userId': _userId!,
      'channel': channel,
      'amount': amount.toString(),
      'targetAsset': targetAsset,
    });
  }

  static Future<String> getOrderStatus(String outTradeNo) async {
    final r = await _get('/recharge/status/$outTradeNo');
    return r['status']?.toString() ?? 'UNKNOWN';
  }

  static Future<Map<String, dynamic>> getQuote({
    required String fromAsset,
    required String toAsset,
    required double amount,
  }) async {
    return _get('/recharge/quote?fromAsset=$fromAsset&toAsset=$toAsset&amount=$amount');
  }

  static Future<Map<String, dynamic>> getRechargeHistory() async {
    if (_userId == null) return {'success': false};
    return _get('/recharge/history/$_userId');
  }

  static Future<Map<String, dynamic>> exchange({
    required String fromAsset,
    required String toAsset,
    required double amount,
  }) async {
    if (_userId == null) return {'success': false};
    return _post('/recharge/exchange', q: {
      'userId': _userId!,
      'fromAsset': fromAsset,
      'toAsset': toAsset,
      'amount': amount.toString(),
    });
  }

  // ==========================================
  // 代扣协议
  // ==========================================
  static Future<List<dynamic>> getAgreements() async {
    if (_userId == null) return [];
    final r = await _get('/agreement/list/$_userId');
    return (r['agreements'] as List?) ?? [];
  }

  static Future<List<dynamic>> getSignedAgreements() async {
    if (_userId == null) return [];
    final r = await _get('/agreement/signed/$_userId');
    return (r['agreements'] as List?) ?? [];
  }

  static Future<Map<String, dynamic>> requestTerminate(String agreementId) async {
    if (_userId == null) return {'success': false};
    return _post('/agreement/request-terminate', q: {
      'userId': _userId!,
      'agreementId': agreementId,
    });
  }

  static Future<Map<String, dynamic>> cancelTerminate(String ticketId) async {
    if (_userId == null) return {'success': false};
    return _post('/agreement/cancel-terminate', q: {
      'userId': _userId!,
      'ticketId': ticketId,
    });
  }

  static Future<Map<String, dynamic>> getTicketStatus() async {
    if (_userId == null) return {'success': false};
    return _get('/agreement/ticket-status/$_userId');
  }

  // ==========================================
  // 支付宝
  // ==========================================
  static Future<Map<String, dynamic>> alipaySignUrl() async {
    if (_userId == null) return {'success': false};
    return _post('/alipay/sign-url', q: {'userId': _userId!});
  }

  static Future<Map<String, dynamic>> alipayUnsign({
    required String agreementNo,
    required String externalAgreementNo,
  }) async {
    return _post('/alipay/unsign', q: {
      'agreementNo': agreementNo,
      'externalAgreementNo': externalAgreementNo,
    });
  }

  // ==========================================
  // 微信支付
  // ==========================================
  static Future<Map<String, dynamic>> wechatPreSign() async {
    if (_userId == null) return {'success': false};
    return _post('/wechat/pre-sign', q: {'userId': _userId!});
  }

  static Future<Map<String, dynamic>> wechatTerminate({
    required String planId,
    required String outContractCode,
  }) async {
    return _post('/wechat/terminate', q: {
      'planId': planId,
      'outContractCode': outContractCode,
    });
  }

  // ==========================================
  // 云闪付
  // ==========================================
  static Future<Map<String, dynamic>> unionPaySignTn() async {
    if (_userId == null) return {'success': false};
    return _post('/unionpay/sign-tn', q: {'userId': _userId!});
  }

  static Future<Map<String, dynamic>> unionPayTerminate(String contractId) async {
    return _post('/unionpay/terminate', q: {'contractId': contractId});
  }

  // ==========================================
  // 虚拟卡
  // ==========================================
  static Future<List<VirtualCard>> getVirtualCards() async {
    if (_userId == null) return [];
    final r = await _get('/cards/list/$_userId');
    final list = (r['cards'] as List?) ?? [];
    return list.map((e) => VirtualCard.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Map<String, dynamic>> createVirtualCard() async {
    if (_userId == null) return {'success': false};
    return _post('/cards/virtual', q: {'userId': _userId!});
  }

  static Future<Map<String, dynamic>> createPhysicalCard({
    required String shippingName,
    required String shippingPhone,
    required String line1,
    required String city,
    required String state,
    required String postalCode,
    required String country,
  }) async {
    if (_userId == null) return {'success': false};
    return _post('/cards/physical', q: {
      'userId': _userId!,
      'shippingName': shippingName,
      'shippingPhone': shippingPhone,
      'line1': line1,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
    });
  }

  static Future<Map<String, dynamic>> updateCardStatus(String cardId, String status) async {
    return _post('/cards/$cardId/status', q: {'status': status});
  }

  // ==========================================
  // 客服后台 - 解约工单
  // ==========================================
  static Future<Map<String, dynamic>> adminGetTickets({
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    final q = <String, String>{'page': '$page', 'size': '$size'};
    if (status != null && status.isNotEmpty) q['status'] = status;
    final query = q.entries.map((e) => '${e.key}=${e.value}').join('&');
    return _doGet('$adminBaseUrl/tickets?$query');
  }

  static Future<Map<String, dynamic>> adminGetTicketDetail(String id) async {
    return _doGet('$adminBaseUrl/tickets/$id');
  }

  static Future<Map<String, dynamic>> adminApprove(String ticketId) async {
    return _doPost('$adminBaseUrl/approve-terminate', q: {'ticketId': ticketId});
  }

  static Future<Map<String, dynamic>> adminReject(String ticketId, String reason) async {
    return _doPost('$adminBaseUrl/reject-terminate', q: {
      'ticketId': ticketId,
      'reason': reason,
    });
  }

  static Future<Map<String, dynamic>> adminGetStats() async {
    return _doGet('$adminBaseUrl/stats');
  }

  // ==========================================
  // 客服后台 - 充值审核
  // ==========================================
  static Future<Map<String, dynamic>> adminGetDeposits({
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    final q = <String, String>{'page': '$page', 'size': '$size'};
    if (status != null && status.isNotEmpty) q['status'] = status;
    final query = q.entries.map((e) => '${e.key}=${e.value}').join('&');
    return _doGet('$adminBaseUrl/deposits?$query');
  }

  static Future<Map<String, dynamic>> adminApproveDeposit(String orderId) async {
    return _doPost('$adminBaseUrl/deposits/approve', q: {'orderId': orderId});
  }

  static Future<Map<String, dynamic>> adminRejectDeposit(String orderId, String reason) async {
    return _doPost('$adminBaseUrl/deposits/reject', q: {
      'orderId': orderId,
      'reason': reason,
    });
  }

  // ===== 收款码 =====
  static Future<Map<String, dynamic>> getPaymentQr() async {
    return _get('/payment/qr');
  }

  // ===== On-Ramp 入金（Alchemy Pay）=====
  static Future<Map<String, dynamic>> createOnRampOrder({
    required String amount,
    String fiatCurrency = 'USD',
  }) async {
    if (_userId == null) return {'success': false, 'message': '未登录'};
    return _post('/onramp/create', q: {
      'userId': _userId!,
      'amount': amount,
      'fiatCurrency': fiatCurrency,
    });
  }

  static Future<Map<String, dynamic>> getOnRampStatus(String orderId) async {
    return _get('/onramp/status/$orderId');
  }

  // ===== 系统配置管理 =====
  static Future<Map<String, dynamic>> getConfigGroups() async {
    return _doGet('$adminBaseUrl/config/groups');
  }

  static Future<Map<String, dynamic>> getConfigList(String group) async {
    return _doGet('$adminBaseUrl/config/list/$group');
  }

  static Future<Map<String, dynamic>> setConfig({
    required String group,
    required String key,
    required String value,
    String? displayName,
    bool? isSecret,
    String? description,
  }) async {
    final q = <String, String>{
      'group': group,
      'key': key,
      'value': value,
    };
    if (displayName != null) q['displayName'] = displayName;
    if (isSecret != null) q['isSecret'] = isSecret.toString();
    if (description != null) q['description'] = description;
    return _doPost('$adminBaseUrl/config/set', q: q);
  }

  static Future<Map<String, dynamic>> deleteConfig(String id) async {
    try {
      final r = await http.delete(
        Uri.parse('$adminBaseUrl/config/delete/$id'),
        headers: _headers,
      ).timeout(const Duration(seconds: 20));
      return _handle(r);
    } catch (e) {
      return {'success': false, 'message': '网络错误: $e'};
    }
  }

  // ===== KHQR =====
  static Future<Map<String, dynamic>> createKHQROrder() async {
    if (_userId == null) return {'success': false, 'message': '未登录'};
    return _post('/khqr/create', q: {
      'userId': _userId!,
    });
  }

  static Future<Map<String, dynamic>> checkKHQRStatus(String md5) async {
    return _get('/khqr/status/$md5');
  }

  // ===== Lakala 支付 =====
  static Future<Map<String, dynamic>> createLakalaOrder({
    required String channel,
    required String amount,
    String currency = 'JPY',
  }) async {
    if (_userId == null) return {'success': false, 'message': '未登录'};
    return _post('/lakala/create', q: {
      'userId': _userId!,
      'channel': channel,
      'amount': amount,
      'currency': currency,
    });
  }

  static Future<Map<String, dynamic>> getLakalaStatus(String orderNo) async {
    return _get('/lakala/status/$orderNo');
  }
  // ===== 虚拟卡 =====
  static Future<List<VirtualCard>> getCards() async {
    if (_userId == null) return [];
    final r = await _get('/cards/list/$_userId');
    final list = (r['cards'] as List?) ?? [];
    return list.map((e) => VirtualCard.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Map<String, dynamic>> createCard({
    String? holderName,
    String? brand,
    String? cardType,
  }) async {
    if (_userId == null) return {'success': false, 'message': '未登录'};
    return _post('/cards/virtual', q: {
      'userId': _userId!,
      if (holderName != null && holderName.isNotEmpty) 'holderName': holderName,
      if (brand != null) 'brand': brand,
      if (cardType != null) 'cardType': cardType,
    });
  }

}
