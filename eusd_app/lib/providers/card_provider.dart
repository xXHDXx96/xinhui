import 'package:flutter/foundation.dart';
import '../models/virtual_card.dart';
import '../services/api_service.dart';

class CardProvider extends ChangeNotifier {
  List<VirtualCard> _cards = [];
  bool _loading = false;
  String? _error;

  List<VirtualCard> get cards => _cards;
  bool get loading => _loading;
  String? get error => _error;
  int get cardCount => _cards.length;
  double get totalBalance => _cards.fold(0.0, (s, c) => s + c.balance);
  bool get isEmpty => _cards.isEmpty;

  Future<void> loadCards() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final r = await ApiService.getCards();
      _cards = r;
    } catch (e) {
      _error = '加载卡片失败: $e';
      _cards = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createCard({
    String? holderName,
    String? brand,
    String? cardType,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final r = await ApiService.createCard(
        holderName: holderName,
        brand: brand,
        cardType: cardType,
      );
      if (r['success'] == true) {
        await loadCards();
        return {'success': true, 'message': '虚拟卡创建成功'};
      }
      return {'success': false, 'message': r['message'] ?? '创建失败'};
    } catch (e) {
      return {'success': false, 'message': '创建失败: $e'};
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> toggleCardStatus(String cardId) async {
    final card = _cards.firstWhere(
      (c) => c.id == cardId,
      orElse: () => VirtualCard(id: '', userId: '', last4: '****'),
    );
    if (card.id.isEmpty) return {'success': false, 'message': '卡片不存在'};

    final newStatus = card.isActive ? 'blocked' : 'active';
    try {
      final r = await ApiService.updateCardStatus(cardId, newStatus);
      if (r['success'] == true) {
        final i = _cards.indexWhere((c) => c.id == cardId);
        if (i >= 0) {
          _cards[i] = _cards[i].copyWith(status: newStatus);
          notifyListeners();
        }
        return {
          'success': true,
          'message': newStatus == 'blocked' ? '卡片已冻结' : '卡片已解冻',
        };
      }
      return {'success': false, 'message': r['message'] ?? '操作失败'};
    } catch (e) {
      return {'success': false, 'message': '操作失败: $e'};
    }
  }

  VirtualCard? findById(String id) {
    for (final c in _cards) {
      if (c.id == id) return c;
    }
    return null;
  }
}
