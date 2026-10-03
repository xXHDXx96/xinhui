class VirtualCard {
  final String id;
  final String userId;
  final String? stripeCardId;
  final String? stripeCardholderId;
  final String last4;
  final String brand;
  final String cardType;
  final String currency;
  final String status;
  final double balance;
  final DateTime? createdAt;

  VirtualCard({
    required this.id,
    required this.userId,
    this.stripeCardId,
    this.stripeCardholderId,
    required this.last4,
    this.brand = 'VISA',
    this.cardType = 'virtual',
    this.currency = 'USD',
    this.status = 'active',
    this.balance = 0.0,
    this.createdAt,
  });

  factory VirtualCard.fromJson(Map<String, dynamic> json) {
    return VirtualCard(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      stripeCardId: json['stripeCardId']?.toString(),
      stripeCardholderId: json['stripeCardholderId']?.toString(),
      last4: json['last4']?.toString() ?? '****',
      brand: json['brand']?.toString() ?? 'VISA',
      cardType: json['cardType']?.toString() ?? 'virtual',
      currency: json['currency']?.toString() ?? 'USD',
      status: json['status']?.toString() ?? 'active',
      balance: _toDouble(json['balance']),
      createdAt: _toDateTime(json['createdAt']),
    );
  }

  bool get isActive => status == 'active';
  bool get isVirtual => cardType == 'virtual';
  bool get isPhysical => cardType == 'physical';
  String get maskedNumber => '•••• •••• •••• $last4';
  String get statusText {
    switch (status) {
      case 'active': return '正常';
      case 'blocked':
      case 'inactive': return '已冻结';
      case 'canceled': return '已注销';
      default: return status;
    }
  }
  String get cardTypeText => isVirtual ? '虚拟卡' : '实体卡';

  VirtualCard copyWith({String? status, double? balance}) => VirtualCard(
    id: id, userId: userId,
    stripeCardId: stripeCardId, stripeCardholderId: stripeCardholderId,
    last4: last4, brand: brand, cardType: cardType,
    currency: currency, status: status ?? this.status,
    balance: balance ?? this.balance, createdAt: createdAt);

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
