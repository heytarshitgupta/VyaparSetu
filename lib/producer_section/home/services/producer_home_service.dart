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
    int? limit,
  });

  /// Derives explainable market demand signals from live `buyer_requests` and `orders`.
  Future<List<ProducerMarketSignalItem>> fetchMarketSignals({
    List<String>? relevantCategories,
    String? state,
    String? district,
    int? limit,
  });
}

/// Production implementation of [IProducerHomeService] using Supabase.
class ProducerHomeService implements IProducerHomeService {
  final SupabaseClient? client;
  final String? currentUserId;
  final Future<List<dynamic>> Function()? buyerRequestsFetcher;
  final Future<List<dynamic>> Function(String producerId)? producerOrdersFetcher;

  ProducerHomeService({
    this.client,
    this.currentUserId,
    this.buyerRequestsFetcher,
    this.producerOrdersFetcher,
  });

  SupabaseClient get _supabaseClient => client ?? Supabase.instance.client;

  String? get _currentUserId {
    if (currentUserId != null) return currentUserId;
    try {
      return (client ?? Supabase.instance.client).auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

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
    int? limit,
  }) async {
    try {
      final List<dynamic> rawList;
      if (buyerRequestsFetcher != null) {
        rawList = await buyerRequestsFetcher!();
      } else {
        // Producer RLS permits selecting active buyer requests
        final response = await _supabaseClient
            .from('buyer_requests')
            .select()
            .eq('status', 'active')
            .order('created_at', ascending: false);
        rawList = response as List<dynamic>;
      }

      final list = rawList
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

      if (limit != null && limit > 0) {
        return list.take(limit).toList();
      }
      return list;
    } catch (e) {
      throw ProducerHomeOperationException('Failed to load active buyer needs', e);
    }
  }

  @override
  Future<List<ProducerMarketSignalItem>> fetchMarketSignals({
    List<String>? relevantCategories,
    String? state,
    String? district,
    int? limit,
  }) async {
    try {
      // Fetch active buyer requests with required BI dimensions
      final List<dynamic> reqList;
      if (buyerRequestsFetcher != null) {
        reqList = await buyerRequestsFetcher!();
      } else {
        final reqResponse = await _supabaseClient
            .from('buyer_requests')
            .select('category, product_name, quantity, unit, target_price, urgency, state, district')
            .eq('status', 'active');
        reqList = reqResponse as List<dynamic>;
      }

      // Accumulate demand metrics per normalized category
      final Map<String, _CategoryDemandAccumulator> accumulators = {};

      for (final row in reqList) {
        if (row is! Map<String, dynamic>) continue;
        final rawCat = (row['category'] as String?)?.trim() ?? '';
        if (rawCat.isEmpty) continue;
        final normCat = _normalizeCategory(rawCat);
        if (normCat.isEmpty) continue;

        final acc = accumulators.putIfAbsent(normCat, () => _CategoryDemandAccumulator());
        acc.requestCount++;

        // Quantity & Unit
        final rawQty = row['quantity'];
        final double? qty = (rawQty is num)
            ? rawQty.toDouble()
            : (rawQty != null ? double.tryParse(rawQty.toString()) : null);
        final unit = (row['unit'] as String?)?.trim().toLowerCase();
        if (qty != null && qty > 0 && unit != null && unit.isNotEmpty) {
          acc.quantities.add(qty);
          acc.units.add(unit);
        }

        // Target Price
        final rawPrice = row['target_price'];
        final double? price = (rawPrice is num)
            ? rawPrice.toDouble()
            : (rawPrice != null ? double.tryParse(rawPrice.toString()) : null);
        if (price != null && price > 0) {
          acc.targetPrices.add(price);
        }

        // Urgency
        final urgency = (row['urgency'] as String?)?.trim().toLowerCase();
        if (urgency == 'high') {
          acc.highUrgencyCount++;
        }

        // Geography
        final rowState = (row['state'] as String?)?.trim();
        if (rowState != null && rowState.isNotEmpty) {
          acc.stateCounts[rowState] = (acc.stateCounts[rowState] ?? 0) + 1;
        }
        final rowDistrict = (row['district'] as String?)?.trim();
        if (rowDistrict != null && rowDistrict.isNotEmpty) {
          acc.districtCounts[rowDistrict] = (acc.districtCounts[rowDistrict] ?? 0) + 1;
        }
      }

      // If user has an active session, fetch their completed order counts
      final userId = _currentUserId;
      int producerCompletedCount = 0;
      if (userId != null && userId.isNotEmpty) {
        try {
          if (producerOrdersFetcher != null) {
            final ordersResponse = await producerOrdersFetcher!(userId);
            producerCompletedCount = ordersResponse.length;
          } else {
            final ordersResponse = await _supabaseClient
                .from('orders')
                .select('id')
                .eq('producer_id', userId)
                .eq('status', 'completed');
            producerCompletedCount = (ordersResponse as List<dynamic>).length;
          }
        } catch (_) {}
      }

      // Normalize comparison keys and expand craft categories
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

      // Collect all candidate categories
      final allCategories = <String>{
        ...normProducerCats,
        ...accumulators.keys,
      };

      final signals = <ProducerMarketSignalItem>[];

      for (final cat in allCategories) {
        final acc = accumulators[cat] ?? _CategoryDemandAccumulator();
        final activeReqs = acc.requestCount;
        final isProducerCat = normProducerCats.contains(cat) ||
            normProducerCats.any((p) => cat.contains(p) || p.contains(cat));

        // Quantity aggregation: aggregate only if all units are identical
        double? totalRequestedQuantity;
        String? representativeUnit;
        if (acc.quantities.isNotEmpty && acc.units.isNotEmpty) {
          final firstUnit = acc.units.first;
          final allSameUnit = acc.units.every((u) => u == firstUnit);
          if (allSameUnit) {
            totalRequestedQuantity = acc.quantities.fold<double>(0.0, (sum, q) => sum + q);
            representativeUnit = firstUnit;
          } else {
            totalRequestedQuantity = null;
            representativeUnit = null;
          }
        }

        // Target price statistics
        double? minPrice;
        double? maxPrice;
        double? avgPrice;
        if (acc.targetPrices.isNotEmpty) {
          minPrice = acc.targetPrices.reduce((a, b) => a < b ? a : b);
          maxPrice = acc.targetPrices.reduce((a, b) => a > b ? a : b);
          final sum = acc.targetPrices.fold<double>(0.0, (s, p) => s + p);
          avgPrice = sum / acc.targetPrices.length;
        }

        // Top geography
        String? topState;
        if (acc.stateCounts.isNotEmpty) {
          final sortedStates = acc.stateCounts.entries.toList()
            ..sort((a, b) {
              if (b.value != a.value) return b.value.compareTo(a.value);
              if (normState != null && a.key.toLowerCase() == normState) return -1;
              if (normState != null && b.key.toLowerCase() == normState) return 1;
              return a.key.compareTo(b.key);
            });
          topState = sortedStates.first.key;
        }

        String? topDistrict;
        if (acc.districtCounts.isNotEmpty) {
          final sortedDistricts = acc.districtCounts.entries.toList()
            ..sort((a, b) {
              if (b.value != a.value) return b.value.compareTo(a.value);
              if (normDistrict != null && a.key.toLowerCase() == normDistrict) return -1;
              if (normDistrict != null && b.key.toLowerCase() == normDistrict) return 1;
              return a.key.compareTo(b.key);
            });
          topDistrict = sortedDistricts.first.key;
        }

        // Deterministic relevance score
        int relevanceScore = 0;
        if (normProducerCats.contains(cat)) {
          relevanceScore += 20;
        } else if (normProducerCats.any((p) => cat.contains(p) || p.contains(cat))) {
          relevanceScore += 12;
        }
        if (normDistrict != null && topDistrict != null && topDistrict.toLowerCase() == normDistrict) {
          relevanceScore += 4;
        }
        if (normState != null && topState != null && topState.toLowerCase() == normState) {
          relevanceScore += 2;
        }
        if (acc.highUrgencyCount > 0) {
          relevanceScore += 2;
        }

        // Demand Level
        MarketDemandLevel level;
        String title = _formatCategoryDisplay(cat);
        String subtitle;

        if (activeReqs >= 3 || (activeReqs >= 2 && producerCompletedCount >= 1)) {
          level = MarketDemandLevel.high;
          subtitle = '$activeReqs active buyer requests in market';
        } else if (activeReqs >= 1 || (isProducerCat && producerCompletedCount >= 1)) {
          level = MarketDemandLevel.growing;
          subtitle = activeReqs > 0
              ? '$activeReqs buyer request waiting'
              : 'Consistent order demand';
        } else {
          level = MarketDemandLevel.steady;
          subtitle = 'Market presence active';
        }

        signals.add(ProducerMarketSignalItem(
          category: cat,
          level: level,
          activeRequestCount: activeReqs,
          completedOrderCount: isProducerCat ? producerCompletedCount : 0,
          title: title,
          subtitle: subtitle,
          totalRequestedQuantity: totalRequestedQuantity,
          representativeUnit: representativeUnit,
          minTargetPrice: minPrice,
          maxTargetPrice: maxPrice,
          averageTargetPrice: avgPrice,
          topState: topState,
          topDistrict: topDistrict,
          highUrgencyCount: acc.highUrgencyCount,
          relevanceScore: relevanceScore,
        ));
      }

      // Sort signals: producer's own categories first, then relevance score, then demand level, then count
      signals.sort((a, b) {
        final aIsProducer = normProducerCats.contains(a.category) ||
            normProducerCats.any((p) => a.category.contains(p) || p.contains(a.category));
        final bIsProducer = normProducerCats.contains(b.category) ||
            normProducerCats.any((p) => b.category.contains(p) || p.contains(b.category));

        if (aIsProducer && !bIsProducer) return -1;
        if (!aIsProducer && bIsProducer) return 1;

        if (b.relevanceScore != a.relevanceScore) {
          return b.relevanceScore.compareTo(a.relevanceScore);
        }

        if (a.level.index != b.level.index) {
          return a.level.index.compareTo(b.level.index);
        }

        return b.activeRequestCount.compareTo(a.activeRequestCount);
      });

      if (limit != null && limit > 0) {
        return signals.take(limit).toList();
      }
      return signals;
    } catch (e) {
      throw ProducerHomeOperationException('Failed to load market demand signals', e);
    }
  }

  static const Map<String, List<String>> _craftCategoryExpansions = {
    'agriculture': ['food', 'grains', 'spices', 'produce'],
    'clothing': ['textiles', 'apparel', 'fabric', 'home'],
    'handicraft': ['crafts', 'home', 'decor'],
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
    final cleaned = cat
        .toLowerCase()
        .replaceAll('&', '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
    if (cleaned == 'handicrafts') return 'handicraft';
    if (cleaned == 'clothing textiles' || cleaned == 'clothing and textiles' || cleaned == 'textiles' || cleaned == 'apparel') {
      return 'clothing';
    }
    if (cleaned == 'agriculture products' || cleaned == 'agriculture and food') {
      return 'agriculture';
    }
    return cleaned;
  }

  String _formatCategoryDisplay(String cat) {
    if (cat.isEmpty) return 'Craft & Goods';
    final parts = cat.split(RegExp(r'[\s_]+'));
    return parts.map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}').join(' ');
  }
}

class _CategoryDemandAccumulator {
  int requestCount = 0;
  final List<double> quantities = [];
  final List<String> units = [];
  final List<double> targetPrices = [];
  final Map<String, int> stateCounts = {};
  final Map<String, int> districtCounts = {};
  int highUrgencyCount = 0;
}
