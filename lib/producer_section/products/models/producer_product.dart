import 'package:flutter/foundation.dart';

/// Lifecycle statuses for a product in VyaparSetu.
/// Maps 1:1 with remote PostgreSQL enum `public.product_status`.
enum ProductStatus {
  draft,
  active,
  hidden;

  /// Returns the lowercase string representation expected by PostgreSQL.
  String toDbValue() => name;

  /// Parses a database string to [ProductStatus].
  ///
  /// Throws [FormatException] if the status is unknown to prevent
  /// silently mislabeling corrupted or unexpected server data.
  static ProductStatus fromDbValue(String value) {
    switch (value.trim().toLowerCase()) {
      case 'draft':
        return ProductStatus.draft;
      case 'active':
        return ProductStatus.active;
      case 'hidden':
        return ProductStatus.hidden;
      default:
        throw FormatException('Unknown product status: "$value"');
    }
  }
}

/// Canonical, immutable domain model for a producer's product in VyaparSetu.
///
/// Reflects the authoritative schema defined in Migration 009 (`public.products`).
///
/// Monetary Rule:
/// Price is strictly represented as integer paise (`int? pricePaise`), completely
/// eliminating binary floating-point rounding inaccuracies.
/// (₹1.00 = 100 paise, ₹10.50 = 1050 paise, ₹1250.00 = 125000 paise).
@immutable
class ProducerProduct {
  final String id;
  final String producerId;
  final String name;
  final String description;
  final String category;

  /// Price in integer paise (₹1 = 100 paise).
  /// Nullable for drafts; strictly required and > 0 for active products.
  final int? pricePaise;

  final String unit;
  final List<String> images;
  final ProductStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProducerProduct({
    required this.id,
    required this.producerId,
    required this.name,
    this.description = '',
    this.category = '',
    this.pricePaise,
    this.unit = 'piece',
    this.images = const [],
    this.status = ProductStatus.draft,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Display-ready decimal string representation (e.g. "1250.50") or null if price is null.
  /// Contains no currency symbols or locale-specific formatting.
  String? get priceDecimalString => paiseToDecimalString(pricePaise);

  /// Factory constructor to parse JSON rows from PostgREST / Supabase.
  factory ProducerProduct.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawProducerId = json['producer_id'];
    final rawName = json['name'];
    final rawStatus = json['status'];

    if (rawId == null || rawId.toString().trim().isEmpty) {
      throw const FormatException('Product record missing required "id"');
    }
    if (rawProducerId == null || rawProducerId.toString().trim().isEmpty) {
      throw const FormatException('Product record missing required "producer_id"');
    }
    if (rawName == null) {
      throw const FormatException('Product record missing required "name"');
    }
    if (rawStatus == null || rawStatus is! String) {
      throw const FormatException('Product record missing or non-string "status"');
    }

    final createdAtRaw = json['created_at'];
    final updatedAtRaw = json['updated_at'];

    final createdAt = createdAtRaw != null
        ? DateTime.parse(createdAtRaw.toString())
        : DateTime.now();
    final updatedAt = updatedAtRaw != null
        ? DateTime.parse(updatedAtRaw.toString())
        : createdAt;

    return ProducerProduct(
      id: rawId.toString(),
      producerId: rawProducerId.toString(),
      name: rawName.toString(),
      description: (json['description'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      pricePaise: parsePriceToPaise(json['price']),
      unit: (json['unit'] as String?) ?? 'piece',
      images: _parseImages(json['images']),
      status: ProductStatus.fromDbValue(rawStatus),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Serializes model to JSON map for database operations.
  /// Converts integer paise to exact two-decimal string (NUMERIC(12, 2)).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'producer_id': producerId,
      'name': name,
      'description': description,
      'category': category,
      'price': priceDecimalString,
      'unit': unit,
      'images': images,
      'status': status.toDbValue(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Safe copyWith method supporting explicit setting of nullable price.
  ProducerProduct copyWith({
    String? id,
    String? producerId,
    String? name,
    String? description,
    String? category,
    int? pricePaise,
    bool setPriceNull = false,
    String? unit,
    List<String>? images,
    ProductStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProducerProduct(
      id: id ?? this.id,
      producerId: producerId ?? this.producerId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      pricePaise: setPriceNull ? null : (pricePaise ?? this.pricePaise),
      unit: unit ?? this.unit,
      images: images ?? this.images,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Parses PostgreSQL NUMERIC(12, 2) representation into integer paise.
  ///
  /// Handles String representations deterministically without floating-point math.
  /// Handles `num` by formatting to fixed 2 decimal places before parsing.
  /// Throws [FormatException] if the value is malformed or invalid.
  static int? parsePriceToPaise(dynamic value) {
    if (value == null) return null;

    final String text;
    if (value is num) {
      if (value.isNaN || value.isInfinite) {
        throw FormatException('Invalid numeric value: $value');
      }
      text = value.toStringAsFixed(2);
    } else if (value is String) {
      text = value.trim();
      if (text.isEmpty) return null;
    } else {
      throw FormatException('Cannot parse price from type: ${value.runtimeType}');
    }

    final parts = text.split('.');
    if (parts.length > 2) {
      throw FormatException('Malformed monetary string with multiple decimal points: "$text"');
    }

    final wholeStr = parts[0].trim();
    if (wholeStr.isEmpty && parts.length == 1) {
      throw FormatException('Empty whole price: "$text"');
    }

    bool isNegative = false;
    String cleanWhole = wholeStr;
    if (cleanWhole.startsWith('-')) {
      isNegative = true;
      cleanWhole = cleanWhole.substring(1);
    } else if (cleanWhole.startsWith('+')) {
      cleanWhole = cleanWhole.substring(1);
    }

    final whole = cleanWhole.isEmpty ? 0 : int.tryParse(cleanWhole);
    if (whole == null) {
      throw FormatException('Malformed whole portion in price: "$text"');
    }

    int fraction = 0;
    if (parts.length == 2) {
      final fracStr = parts[1].trim();
      if (fracStr.isEmpty) {
        fraction = 0;
      } else if (fracStr.length == 1) {
        final d = int.tryParse(fracStr);
        if (d == null) throw FormatException('Malformed fraction in price: "$text"');
        fraction = d * 10;
      } else if (fracStr.length == 2) {
        final d = int.tryParse(fracStr);
        if (d == null) throw FormatException('Malformed fraction in price: "$text"');
        fraction = d;
      } else {
        // If extra decimal places are present, verify they are only trailing zeroes
        final d = int.tryParse(fracStr.substring(0, 2));
        final remainder = fracStr.substring(2);
        final remInt = int.tryParse(remainder);
        if (d == null || remInt == null || remInt != 0) {
          throw FormatException('Price exceeds 2-decimal precision (NUMERIC(12,2)): "$text"');
        }
        fraction = d;
      }
    }

    final totalPaise = (whole * 100) + fraction;
    return isNegative ? -totalPaise : totalPaise;
  }

  /// Converts integer paise back to an exact two-decimal string for Supabase / PostgreSQL.
  ///
  /// Examples:
  /// - null -> null
  /// - 1 -> "0.01"
  /// - 100 -> "1.00"
  /// - 1050 -> "10.50"
  /// - 125050 -> "1250.50"
  static String? paiseToDecimalString(int? paise) {
    if (paise == null) return null;
    final isNegative = paise < 0;
    final absPaise = paise.abs();
    final whole = absPaise ~/ 100;
    final fraction = absPaise % 100;
    final formatted = '$whole.${fraction.toString().padLeft(2, '0')}';
    return isNegative ? '-$formatted' : formatted;
  }

  /// Parses PostgreSQL TEXT[] array into `List<String>`.
  static List<String> _parseImages(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProducerProduct &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          producerId == other.producerId &&
          name == other.name &&
          description == other.description &&
          category == other.category &&
          pricePaise == other.pricePaise &&
          unit == other.unit &&
          listEquals(images, other.images) &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      producerId.hashCode ^
      name.hashCode ^
      description.hashCode ^
      category.hashCode ^
      pricePaise.hashCode ^
      unit.hashCode ^
      Object.hashAll(images) ^
      status.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() =>
      'ProducerProduct(id: $id, name: $name, status: ${status.name}, pricePaise: $pricePaise, unit: $unit)';
}
