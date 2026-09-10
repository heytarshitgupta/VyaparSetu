import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/producer_home_models.dart';

/// Domain exception thrown when home dashboard operations fail.
class ProducerHomeOperationException implements Exception {
  final String message;
  final dynamic originalError;

  const ProducerHomeOperationException(this.message, [this.originalError]);

  @override
  String toString() => 'ProducerHomeOperationException: $message';
}

/// Abstract contract for Producer Home dashboard data operations.
/// Enables 100% mockable, offline unit and widget testing.
abstract class IProducerHomeService {
  /// Fetches orders summary strictly for current authenticated producer.
  Future<ProducerOrdersSummary> fetchOrdersSummary();

  /// Fetches active buyer needs, prioritized by relevance to producer's categories and location.
  Future<List<ProducerBuyerNeedItem>> fetchActiveBuyerNeeds({
    List<String>? relevantCategories,
    String? state,
    String? district,
    int limit = 3,
  });

  /// Derives explainable market demand signals from live `buyer_requests` and `orders`.
  Future<List<ProducerMarketSignalItem>> fetchMarketSignals({
    List<String>? relevantCategories,
  });
}

/// Production implementation of [IProducerHomeService] using Supabase.
class ProducerHomeService implements IProducerHomeService {
  final SupabaseClient? client;

  ProducerHomeService({this.client});

  SupabaseClient get _supabaseClient => client ?? Supabase.instance.client;

  String? get _currentUserId => _supabaseClient.auth.currentUser?.id;

  @override
  Future<ProducerOrdersSummary> fetchOrdersSummary() async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      return const ProducerOrdersSummary.empty();
    }

    try {
      // Strictly scope orders to producer_id = current authenticated user
      final response = await _supabaseClient
          .from('orders')
          .select('status, total_amount')
          .eq('producer_id', userId);

      final list = response as List<dynamic>;
      return ProducerOrdersSummary.fromOrdersList(list);
    } catch (e) {
      throw ProducerHomeOperationException('Failed to load orders summary', e);
    }
  }

  @override
  Future<List<ProducerBuyerNeedItem>> fetchActiveBuyerNeeds({
    List<String>? relevantCategories,
    String? state,
    String? district,
    int limit = 3,
  }) async {
    try {
      // Producer RLS permits selecting active buyer requests
      final response = await _supabaseClient
          .from('buyer_requests')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final list = (response as List<dynamic>)
          .map((row) => ProducerBuyerNeedItem.fromJson(row as Map<String, dynamic>))
          .toList();

      if (list.isEmpty) return const [];

      // Normalize comparison keys and expand craft categories to product taxonomy
      final normProducerCats = <String>{};
      for (final c in (relevantCategories ?? [])) {
        final norm = _normalizeCategory(c);
        if (norm.isEmpty) continue;
        normProducerCats.add(norm);
        if (_craftCategoryExpansions.containsKey(norm)) {
          normProducerCats.addAll(_craftCategoryExpansions[norm]!);
        }
      }

      final normDistrict = district?.toLowerCase().trim();
      final normState = state?.toLowerCase().trim();

      // Score and sort requests by relevance
      list.sort((a, b) {
        if (normProducerCats.isNotEmpty) {
          final aHasMatch = _hasCategoryMatch(a, normProducerCats);
          final bHasMatch = _hasCategoryMatch(b, normProducerCats);
          if (aHasMatch && !bHasMatch) return -1;
          if (!aHasMatch && bHasMatch) return 1;
        }

        final scoreA = _calculateRelevanceScore(a, normProducerCats, normDistrict, normState);
        final scoreB = _calculateRelevanceScore(b, normProducerCats, normDistrict, normState);

        if (scoreB != scoreA) {
          return scoreB.compareTo(scoreA);
        }
        return b.createdAt.compareTo(a.createdAt);
      });

      return list.take(limit).toList();
    } catch (e) {
      throw ProducerHomeOperationException('Failed to load active buyer needs', e);
    }
  }

  @override
  Future<List<ProducerMarketSignalItem>> fetchMarketSignals({
    List<String>? relevantCategories,
  }) async {
    try {
      // Fetch active buyer requests to count current demand by category
      final reqResponse = await _supabaseClient
          .from('buyer_requests')
          .select('category')
          .eq('status', 'active');

      final reqList = reqResponse as List<dynamic>;
      final Map<String, int> activeCountByCategory = {};

      for (final row in reqList) {
        if (row is! Map<String, dynamic>) continue;
        final cat = (row['category'] as String?)?.trim().toLowerCase() ?? '';
        if (cat.isNotEmpty) {
          activeCountByCategory[cat] = (activeCountByCategory[cat] ?? 0) + 1;
        }
      }

      // If user has an active session, fetch their completed order counts
      final userId = _currentUserId;
      int producerCompletedCount = 0;
      if (userId != null && userId.isNotEmpty) {
        try {
          final ordersResponse = await _supabaseClient
              .from('orders')
              .select('id')
              .eq('producer_id', userId)
              .eq('status', 'completed');
          producerCompletedCount = (ordersResponse as List<dynamic>).length;
        } catch (_) {}
      }

      // Build explainable category signals
      final normProducerCats = (relevantCategories ?? [])
          .map((c) => c.toLowerCase().trim())
          .where((c) => c.isNotEmpty)
          .toList();

      // Collect all candidate categories
      final allCategories = <String>{
        ...normProducerCats,
        ...activeCountByCategory.keys,
      };

      final signals = <ProducerMarketSignalItem>[];

      for (final cat in allCategories) {
        final activeReqs = activeCountByCategory[cat] ?? 0;
        final isProducerCat = normProducerCats.contains(cat);

        // Explainable rule:
        // High interest: category has >= 3 active requests OR (>= 2 active requests + completed order activity)
        // Growing demand: category has 1–2 active requests OR completed order activity
        // Steady demand: weaker active demand but producer relevance
        MarketDemandLevel level;
        String title;
        String subtitle;

        if (activeReqs >= 3 || (activeReqs >= 2 && producerCompletedCount >= 1)) {
          level = MarketDemandLevel.high;
          title = _formatCategoryDisplay(cat);
          subtitle = '$activeReqs active buyer requests in market';
        } else if (activeReqs >= 1 || (isProducerCat && producerCompletedCount >= 1)) {
          level = MarketDemandLevel.growing;
          title = _formatCategoryDisplay(cat);
          subtitle = activeReqs > 0
              ? '$activeReqs buyer request waiting'
              : 'Consistent order demand';
        } else {
          level = MarketDemandLevel.steady;
          title = _formatCategoryDisplay(cat);
          subtitle = 'Market presence active';
        }

        signals.add(ProducerMarketSignalItem(
          category: cat,
          level: level,
          activeRequestCount: activeReqs,
          completedOrderCount: isProducerCat ? producerCompletedCount : 0,
          title: title,
          subtitle: subtitle,
        ));
      }

      // Sort signals: producer's own categories first, then by demand level
      signals.sort((a, b) {
        final aIsProducer = normProducerCats.contains(a.category);
        final bIsProducer = normProducerCats.contains(b.category);

        if (aIsProducer && !bIsProducer) return -1;
        if (!aIsProducer && bIsProducer) return 1;

        return a.level.index.compareTo(b.level.index);
      });

      return signals.take(3).toList();
    } catch (e) {
      throw ProducerHomeOperationException('Failed to load market demand signals', e);
    }
  }

  static const Map<String, List<String>> _craftCategoryExpansions = {
    'agriculture products': ['food', 'agriculture', 'grains', 'spices', 'produce'],
    'agriculture': ['food', 'agriculture', 'grains', 'spices', 'produce'],
    'clothing textiles': ['clothing', 'textiles', 'apparel', 'fabric'],
    'handicrafts': ['handicraft', 'crafts', 'home', 'decor'],
  };

  bool _hasCategoryMatch(ProducerBuyerNeedItem item, Set<String> producerCategories) {
    final itemCat = _normalizeCategory(item.category);
    if (producerCategories.contains(itemCat)) return true;
    for (final pCat in producerCategories) {
      if (itemCat.contains(pCat) || pCat.contains(itemCat)) return true;
    }
    return false;
  }

  int _calculateRelevanceScore(
    ProducerBuyerNeedItem item,
    Set<String> producerCategories,
    String? district,
    String? state,
  ) {
    int score = 0;
    final itemCat = _normalizeCategory(item.category);

    // Exact or partial category match
    if (producerCategories.contains(itemCat)) {
      score += 20;
    } else {
      for (final pCat in producerCategories) {
        if (itemCat.contains(pCat) || pCat.contains(itemCat)) {
          score += 12;
          break;
        }
      }
    }

    // Geographic relevance
    if (district != null && district.isNotEmpty && item.district.toLowerCase() == district) {
      score += 4;
    }
    if (state != null && state.isNotEmpty && item.state.toLowerCase() == state) {
      score += 2;
    }

    // Urgency bonus
    if (item.urgency.toLowerCase() == 'high') {
      score += 3;
    } else if (item.urgency.toLowerCase() == 'medium') {
      score += 1;
    }

    return score;
  }

  String _normalizeCategory(String cat) {
    return cat
        .toLowerCase()
        .replaceAll('&', '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
  }

  String _formatCategoryDisplay(String cat) {
    if (cat.isEmpty) return 'Craft & Goods';
    final parts = cat.split(RegExp(r'[\s_]+'));
    return parts.map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}').join(' ');
  }
}
