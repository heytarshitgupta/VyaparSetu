/// Formats a rupee amount with standard Indian numeral grouping (e.g. ₹73,910, ₹1,79,930).
String formatIndianRupees(double amount) {
  final isNegative = amount < 0;
  final absAmount = amount.abs();
  final whole = absAmount.truncate();
  final decimals = ((absAmount - whole) * 100).round();

  final wholeStr = whole.toString();
  String formattedWhole;
  if (wholeStr.length <= 3) {
    formattedWhole = wholeStr;
  } else {
    final last3 = wholeStr.substring(wholeStr.length - 3);
    final rest = wholeStr.substring(0, wholeStr.length - 3);
    final buffer = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(rest[i]);
    }
    buffer.write(',');
    buffer.write(last3);
    formattedWhole = buffer.toString();
  }

  final prefix = isNegative ? '-₹' : '₹';
  if (decimals == 0) {
    return '$prefix$formattedWhole';
  } else {
    return '$prefix$formattedWhole.${decimals.toString().padLeft(2, '0')}';
  }
}

/// Producer-scoped summary of orders and sales from `public.orders`.
class ProducerOrdersSummary {
  final int totalOrders;
  final int completedOrders;
  final int pendingOrConfirmedOrders;
  final int cancelledOrders;

  /// Completed revenue in Indian Rupees (from `total_amount` of completed orders).
  /// Strictly excludes pending, confirmed, and cancelled orders.
  final double completedSales;

  const ProducerOrdersSummary({
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrConfirmedOrders,
    required this.cancelledOrders,
    required this.completedSales,
  });

  /// Formatted rupee string (e.g. "₹73,910").
  String get formattedCompletedSales => formatIndianRupees(completedSales);

  /// Empty / zero state constructor.
  const ProducerOrdersSummary.empty()
      : totalOrders = 0,
        completedOrders = 0,
        pendingOrConfirmedOrders = 0,
        cancelledOrders = 0,
        completedSales = 0.0;

  /// Factory constructing summary strictly from orders list where `producer_id = auth.uid()`.
  factory ProducerOrdersSummary.fromOrdersList(List<dynamic> rows) {
    int total = 0;
    int completed = 0;
    int pendingOrConfirmed = 0;
    int cancelled = 0;
    double sales = 0.0;

    for (final raw in rows) {
      if (raw is! Map<String, dynamic>) continue;
      total++;
      final status = (raw['status'] as String?)?.trim().toLowerCase() ?? '';
      final totalAmount = (raw['total_amount'] as num?)?.toDouble() ?? 0.0;

      switch (status) {
        case 'completed':
          completed++;
          // Strictly add total_amount only for completed orders
          sales += totalAmount;
          break;
        case 'pending':
        case 'confirmed':
          pendingOrConfirmed++;
          break;
        case 'cancelled':
          cancelled++;
          break;
      }
    }

    return ProducerOrdersSummary(
      totalOrders: total,
      completedOrders: completed,
      pendingOrConfirmedOrders: pendingOrConfirmed,
      cancelledOrders: cancelled,
      completedSales: sales,
    );
  }
}

/// Active buyer request item from `public.buyer_requests`.
class ProducerBuyerNeedItem {
  final String id;
  final String productName;
  final String category;
  final double quantity;
  final String unit;
  final double? targetPrice;
  final String urgency; // 'low', 'medium', 'high'
  final String status;
  final String state;
  final String district;
  final String? notes;
  final DateTime createdAt;

  const ProducerBuyerNeedItem({
    required this.id,
    required this.productName,
    required this.category,
    required this.quantity,
    required this.unit,
    this.targetPrice,
    required this.urgency,
    required this.status,
    required this.state,
    required this.district,
    this.notes,
    required this.createdAt,
  });

  factory ProducerBuyerNeedItem.fromJson(Map<String, dynamic> json) {
    final rawQty = json['quantity'];
    final double qty = (rawQty is num)
        ? rawQty.toDouble()
        : double.tryParse(rawQty?.toString() ?? '') ?? 0.0;

    final rawPrice = json['target_price'];
    final double? price = (rawPrice is num)
        ? rawPrice.toDouble()
        : (rawPrice != null ? double.tryParse(rawPrice.toString()) : null);

    final rawDate = json['created_at'];
    final createdAt = rawDate != null
        ? DateTime.tryParse(rawDate.toString()) ?? DateTime.now()
        : DateTime.now();

    return ProducerBuyerNeedItem(
      id: json['id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      quantity: qty,
      unit: json['unit']?.toString() ?? 'piece',
      targetPrice: price,
      urgency: json['urgency']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'active',
      state: json['state']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      notes: json['notes']?.toString(),
      createdAt: createdAt,
    );
  }
}

/// Demand level classification for explainable market signals.
enum MarketDemandLevel {
  high,
  growing,
  steady;

  String toDisplayKey() {
    switch (this) {
      case MarketDemandLevel.high:
        return 'high';
      case MarketDemandLevel.growing:
        return 'growing';
      case MarketDemandLevel.steady:
        return 'steady';
    }
  }
}

/// Lightweight, explainable market signal derived deterministically from Supabase
/// `buyer_requests` and `orders`.
class ProducerMarketSignalItem {
  final String category;
  final MarketDemandLevel level;
  final int activeRequestCount;
  final int completedOrderCount;
  final String title;
  final String subtitle;

  // BI V2 Extended Metrics
  final double? totalRequestedQuantity;
  final String? representativeUnit;
  final double? minTargetPrice;
  final double? maxTargetPrice;
  final double? averageTargetPrice;
  final String? topState;
  final String? topDistrict;
  final int highUrgencyCount;
  final int relevanceScore;

  const ProducerMarketSignalItem({
    required this.category,
    required this.level,
    this.activeRequestCount = 0,
    this.completedOrderCount = 0,
    this.title = '',
    this.subtitle = '',
    this.totalRequestedQuantity,
    this.representativeUnit,
    this.minTargetPrice,
    this.maxTargetPrice,
    this.averageTargetPrice,
    this.topState,
    this.topDistrict,
    this.highUrgencyCount = 0,
    this.relevanceScore = 0,
  });
}
