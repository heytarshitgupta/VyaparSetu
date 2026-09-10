import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PricingApiResponse {
  final double recommendedPrice;
  final double breakEvenFloor;
  final double marketCeiling;
  final String aiGuidance;
  final String pricingTier;

  PricingApiResponse({
    required this.recommendedPrice,
    required this.breakEvenFloor,
    this.marketCeiling = 0.0,
    required this.aiGuidance,
    required this.pricingTier,
  });

  factory PricingApiResponse.fromJson(Map<String, dynamic> json) {
    return PricingApiResponse(
      recommendedPrice: (json['recommended_price'] as num?)?.toDouble() ?? 0.0,
      breakEvenFloor: (json['break_even_floor'] as num?)?.toDouble() ?? 0.0,
      marketCeiling: (json['market_ceiling'] as num?)?.toDouble() ?? 0.0,
      aiGuidance: (json['ai_guidance'] as String?) ?? '',
      pricingTier: (json['pricing_tier'] as String?) ?? 'B2C Retail Tier',
    );
  }
}

class PricingApiService {
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8001';
    }
    return 'http://localhost:8001';
  }

  static Future<PricingApiResponse?> fetchPrice({
    required String productId,
    required String category,
    required String description,
  }) async {
    final uri = Uri.parse('$baseUrl/price');
    final body = jsonEncode({
      'product_id': productId,
      'category': category,
      'description': description,
    });

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 4));

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
      if (kDebugMode) {
        debugPrint('Pricing API timed out; using fallback price.');
      }
      return null;
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('Pricing API fetch failed: $e');
      }
      return null;
    }
  }
}
