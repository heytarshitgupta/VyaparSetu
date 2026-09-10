import 'package:flutter/foundation.dart';
import '../models/producer_home_models.dart';
import '../services/producer_home_service.dart';

/// State management provider for Producer Home dashboard.
/// Manages live orders summary, active buyer requests preview, and market demand signals.
/// Supports fault-tolerant partial loads so one section failure does not break the screen.
class ProducerHomeDashboardProvider extends ChangeNotifier {
  final IProducerHomeService _service;

  ProducerHomeDashboardProvider({
    IProducerHomeService? service,
  }) : _service = service ?? ProducerHomeService();

  ProducerOrdersSummary? _ordersSummary;
  List<ProducerBuyerNeedItem> _buyerNeeds = const [];
  List<ProducerMarketSignalItem> _marketSignals = const [];

  bool _isLoadingOrders = false;
  bool _isLoadingBuyerNeeds = false;
  bool _isLoadingSignals = false;

  bool _hasOrdersError = false;
  bool _hasBuyerNeedsError = false;
  bool _hasSignalsError = false;

  bool _isRefreshing = false;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  ProducerOrdersSummary? get ordersSummary => _ordersSummary;
  List<ProducerBuyerNeedItem> get buyerNeeds => _buyerNeeds;
  List<ProducerMarketSignalItem> get marketSignals => _marketSignals;

  bool get isLoadingOrders => _isLoadingOrders;
  bool get isLoadingBuyerNeeds => _isLoadingBuyerNeeds;
  bool get isLoadingSignals => _isLoadingSignals;

  bool get hasOrdersError => _hasOrdersError;
  bool get hasBuyerNeedsError => _hasBuyerNeedsError;
  bool get hasSignalsError => _hasSignalsError;

  bool get isRefreshing => _isRefreshing;
  bool get isLoadingAny => _isLoadingOrders || _isLoadingBuyerNeeds || _isLoadingSignals;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Loads all home dashboard sections in parallel with independent fault boundaries.
  Future<void> loadDashboard({
    List<String>? relevantCategories,
    String? state,
    String? district,
  }) async {
    _isLoadingOrders = true;
    _isLoadingBuyerNeeds = true;
    _isLoadingSignals = true;
    _hasOrdersError = false;
    _hasBuyerNeedsError = false;
    _hasSignalsError = false;
    notifyListeners();

    await Future.wait([
      _loadOrdersSummarySafe(),
      _loadBuyerNeedsSafe(
        relevantCategories: relevantCategories,
        state: state,
        district: district,
      ),
      _loadMarketSignalsSafe(relevantCategories: relevantCategories),
    ]);

    notifyListeners();
  }

  /// Pull-to-refresh action.
  Future<void> refresh({
    List<String>? relevantCategories,
    String? state,
    String? district,
  }) async {
    _isRefreshing = true;
    notifyListeners();

    try {
      await loadDashboard(
        relevantCategories: relevantCategories,
        state: state,
        district: district,
      );
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> _loadOrdersSummarySafe() async {
    try {
      _ordersSummary = await _service.fetchOrdersSummary();
      _hasOrdersError = false;
    } catch (_) {
      _hasOrdersError = true;
      _ordersSummary = null;
    } finally {
      _isLoadingOrders = false;
    }
  }

  Future<void> _loadBuyerNeedsSafe({
    List<String>? relevantCategories,
    String? state,
    String? district,
  }) async {
    try {
      _buyerNeeds = await _service.fetchActiveBuyerNeeds(
        relevantCategories: relevantCategories,
        state: state,
        district: district,
        limit: 3,
      );
      _hasBuyerNeedsError = false;
    } catch (_) {
      _hasBuyerNeedsError = true;
      _buyerNeeds = const [];
    } finally {
      _isLoadingBuyerNeeds = false;
    }
  }

  Future<void> _loadMarketSignalsSafe({
    List<String>? relevantCategories,
  }) async {
    try {
      _marketSignals = await _service.fetchMarketSignals(
        relevantCategories: relevantCategories,
      );
      _hasSignalsError = false;
    } catch (_) {
      _hasSignalsError = true;
      _marketSignals = const [];
    } finally {
      _isLoadingSignals = false;
    }
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
