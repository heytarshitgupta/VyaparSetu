import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// V2 Request Model
// ---------------------------------------------------------------------------

class PricingRequestV2 {
  // Required
  final String productName;
  final String category;
  final String description;

  // Optional metadata (never used as ML features)
  final String? productId;
  final String? producerId;
  final String? unit;
  final double? currentPrice;

  // Optional cost fields
  final double? rawMaterialCost;
  final double? packagingCost;
  final double? laborCost;
  final double? otherCost;
  final double? productionQuantity;
  final double? desiredMarginPercent;

  // Optional demand signals
  final int? activeRequestCount;
  final double? averageTargetPrice;
  final double? recentCompletedPrice;
  final int? completedOrderCount;

  const PricingRequestV2({
    required this.productName,
    required this.category,
    required this.description,
    this.productId,
    this.producerId,
    this.unit,
    this.currentPrice,
    this.rawMaterialCost,
    this.packagingCost,
    this.laborCost,
    this.otherCost,
    this.productionQuantity,
    this.desiredMarginPercent,
    this.activeRequestCount,
    this.averageTargetPrice,
    this.recentCompletedPrice,
    this.completedOrderCount,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'product_name': productName,
      'category': category,
      'description': description,
    };
    if (productId != null) map['product_id'] = productId;
    if (producerId != null) map['producer_id'] = producerId;
    if (unit != null) map['unit'] = unit;
    if (currentPrice != null) map['current_price'] = currentPrice;
    if (rawMaterialCost != null) map['raw_material_cost'] = rawMaterialCost;
    if (packagingCost != null) map['packaging_cost'] = packagingCost;
    if (laborCost != null) map['labor_cost'] = laborCost;
    if (otherCost != null) map['other_cost'] = otherCost;
    if (productionQuantity != null) map['production_quantity'] = productionQuantity;
    if (desiredMarginPercent != null) map['desired_margin_percent'] = desiredMarginPercent;
    if (activeRequestCount != null) map['active_request_count'] = activeRequestCount;
    if (averageTargetPrice != null) map['average_target_price'] = averageTargetPrice;
    if (recentCompletedPrice != null) map['recent_completed_price'] = recentCompletedPrice;
    if (completedOrderCount != null) map['completed_order_count'] = completedOrderCount;
    return map;
  }
}

// ---------------------------------------------------------------------------
// V2 Response Model
// ---------------------------------------------------------------------------

class PricingApiResponse {
  final double suggestedPrice;
  final double suggestedPriceLow;
  final double suggestedPriceHigh;
  final double? marketTypicalPrice;
  final double? estimatedUnitCost;
  final double? costFloor;
  final double? bulkPrice;
  final String confidence; // 'high' | 'medium' | 'low'
  final String reason;
  final List<String> signalsUsed;

  const PricingApiResponse({
    required this.suggestedPrice,
    required this.suggestedPriceLow,
    required this.suggestedPriceHigh,
    this.marketTypicalPrice,
    this.estimatedUnitCost,
    this.costFloor,
    this.bulkPrice,
    this.confidence = 'medium',
    required this.reason,
    this.signalsUsed = const [],
  });

  factory PricingApiResponse.fromJson(Map<String, dynamic> json) {
    double? parseDouble(String key) {
      final v = json[key];
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    final signals = json['signals_used'];
    final List<String> signalsList = signals is List
        ? signals.map((e) => e.toString()).toList()
        : const [];

    return PricingApiResponse(
      suggestedPrice: parseDouble('suggested_price') ?? 0.0,
      suggestedPriceLow: parseDouble('suggested_price_low') ?? 0.0,
      suggestedPriceHigh: parseDouble('suggested_price_high') ?? 0.0,
      marketTypicalPrice: parseDouble('market_typical_price'),
      estimatedUnitCost: parseDouble('estimated_unit_cost'),
      costFloor: parseDouble('cost_floor'),
      bulkPrice: parseDouble('bulk_price'),
      confidence: (json['confidence'] as String?) ?? 'medium',
      reason: (json['reason'] as String?) ?? '',
      signalsUsed: signalsList,
    );
  }

  /// Human-readable confidence label for Producer-facing UI.
  String get confidenceLabel {
    switch (confidence) {
      case 'high':
        return 'Strong estimate';
      case 'medium':
        return 'Good estimate';
      default:
        return 'Basic estimate';
    }
  }

  /// Backward-compatibility getters for legacy references
  double get recommendedPrice => suggestedPrice;
  double get breakEvenFloor => costFloor ?? suggestedPriceLow;
  double get marketCeiling => suggestedPriceHigh;
  String get aiGuidance => reason;
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class PricingApiService {
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8001';
    }
    return 'http://localhost:8001';
  }

  @visibleForTesting
  static http.Client? customClient;

  /// V2 pricing call. [productId] and [producerId] are optional metadata only.
  static Future<PricingApiResponse?> fetchPrice(PricingRequestV2 request) async {
    final uri = Uri.parse('$baseUrl/price');
    final body = jsonEncode(request.toJson());

    try {
      final postFuture = customClient != null
          ? customClient!.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
          : http.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: body,
            );
      final response = await postFuture.timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return PricingApiResponse.fromJson(decoded);
        }
      }

      if (kDebugMode) {
        debugPrint('Pricing API error ${response.statusCode}: ${response.body}');
      }
      return null;
    } on TimeoutException catch (_) {
      if (kDebugMode) debugPrint('Pricing API timed out.');
      return null;
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('Pricing API fetch failed: $e');
      return null;
    }
  }
}
