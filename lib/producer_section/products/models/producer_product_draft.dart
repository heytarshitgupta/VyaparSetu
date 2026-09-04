import 'package:flutter/foundation.dart';
import 'producer_product.dart';

/// Immutable domain model representing editable draft state for Add/Edit Product.
///
/// Kept distinct from [ProducerProduct] to maintain a strict separation between
/// in-flight, unpersisted user input and canonical persisted database rows.
///
/// Data Boundaries:
/// - Uses exact integer paise (`pricePaise`) — zero double parsing.
/// - Stores only stable Storage object paths in [images] (e.g. `user_id/product_id/filename.jpg`).
/// - No platform-specific types (no XFile, File, Uint8List, base64, or signed URLs).
/// - Default values align strictly with Migration 009 schema defaults.
@immutable
class ProducerProductDraft {
  final String name;
  final String category;
  final String description;
  final int? pricePaise;
  final String unit;
  final List<String> images;

  const ProducerProductDraft({
    this.name = '',
    this.category = '',
    this.description = '',
    this.pricePaise,
    this.unit = 'piece',
    this.images = const [],
  });

  /// Factory constructor to initialize draft state from an existing persisted product.
  factory ProducerProductDraft.fromProduct(ProducerProduct product) {
    return ProducerProductDraft(
      name: product.name,
      category: product.category,
      description: product.description,
      pricePaise: product.pricePaise,
      unit: product.unit,
      images: List.unmodifiable(product.images),
    );
  }

  /// Whether the draft satisfies minimum criteria to be persisted as a draft in public.products.
  /// Migration 009 requires: non-empty trimmed name.
  bool get hasValidDraftName => name.trim().isNotEmpty;

  /// Whether the draft satisfies all constraints required by Migration 009 to transition to active.
  /// Migration 009 requires:
  /// - trimmed name length >= 2
  /// - trimmed category length >= 2
  /// - pricePaise != null && pricePaise > 0
  /// Note: Photos are NOT required for active status.
  bool get canMarkActive =>
      name.trim().length >= 2 &&
      category.trim().length >= 2 &&
      pricePaise != null &&
      pricePaise! > 0;

  /// Creates a copy of this draft with the given fields replaced.
  ProducerProductDraft copyWith({
    String? name,
    String? category,
    String? description,
    int? pricePaise,
    bool setPriceNull = false,
    String? unit,
    List<String>? images,
  }) {
    return ProducerProductDraft(
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      pricePaise: setPriceNull ? null : (pricePaise ?? this.pricePaise),
      unit: unit ?? this.unit,
      images: images ?? this.images,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProducerProductDraft &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          category == other.category &&
          description == other.description &&
          pricePaise == other.pricePaise &&
          unit == other.unit &&
          listEquals(images, other.images);

  @override
  int get hashCode =>
      name.hashCode ^
      category.hashCode ^
      description.hashCode ^
      pricePaise.hashCode ^
      unit.hashCode ^
      Object.hashAll(images);

  @override
  String toString() =>
      'ProducerProductDraft(name: $name, category: $category, pricePaise: $pricePaise, unit: $unit, imagesCount: ${images.length})';
}
