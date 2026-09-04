import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/producer_product.dart';

/// Domain exception thrown when an operation is attempted without an authenticated producer.
class ProductAuthException implements Exception {
  final String message;
  const ProductAuthException([this.message = 'Authentication required']);

  @override
  String toString() => 'ProductAuthException: $message';
}

/// Domain exception representing product operation failures without exposing raw database errors.
class ProductOperationException implements Exception {
  final String message;
  final dynamic originalError;

  const ProductOperationException(this.message, [this.originalError]);

  @override
  String toString() => 'ProductOperationException: $message';
}

/// Abstract contract for Producer Products data operations.
/// Enables 100% offline, deterministic unit testing and decoupling.
abstract class IProducerProductService {
  /// Fetches the current authenticated producer's products, sorted newest first.
  Future<List<ProducerProduct>> fetchProducts({ProductStatus? statusFilter});

  /// Updates the status of an owned product.
  Future<ProducerProduct> updateProductStatus({
    required String productId,
    required ProductStatus newStatus,
  });

  /// Hard-deletes an owned product by ID.
  Future<void> deleteProduct(String productId);
}

/// Production implementation of [IProducerProductService] using Supabase.
///
/// Security note:
/// While PostgreSQL RLS is the authoritative security boundary, client queries
/// are also strictly scoped to `auth.uid()` to prevent accidental cross-tenant queries.
class ProducerProductService implements IProducerProductService {
  final SupabaseClient? client;

  ProducerProductService({this.client});

  SupabaseClient get _supabaseClient => client ?? Supabase.instance.client;

  String get _currentUserId {
    final user = _supabaseClient.auth.currentUser;
    if (user == null || user.id.isEmpty) {
      throw const ProductAuthException('No authenticated user session found');
    }
    return user.id;
  }

  @override
  Future<List<ProducerProduct>> fetchProducts({ProductStatus? statusFilter}) async {
    final userId = _currentUserId;

    try {
      var query = _supabaseClient
          .from('products')
          .select()
          .eq('producer_id', userId);

      if (statusFilter != null) {
        query = query.eq('status', statusFilter.toDbValue());
      }

      final response = await query.order('created_at', ascending: false);

      final list = response as List<dynamic>;
      return list
          .map((row) => ProducerProduct.fromJson(row as Map<String, dynamic>))
          .toList();
    } on ProductAuthException {
      rethrow;
    } catch (e) {
      throw ProductOperationException('Failed to fetch products', e);
    }
  }

  @override
  Future<ProducerProduct> updateProductStatus({
    required String productId,
    required ProductStatus newStatus,
  }) async {
    final userId = _currentUserId;

    try {
      final response = await _supabaseClient
          .from('products')
          .update({'status': newStatus.toDbValue()})
          .eq('id', productId)
          .eq('producer_id', userId)
          .select()
          .single();

      return ProducerProduct.fromJson(response);
    } on ProductAuthException {
      rethrow;
    } catch (e) {
      throw ProductOperationException('Failed to update product status', e);
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    final userId = _currentUserId;

    try {
      await _supabaseClient
          .from('products')
          .delete()
          .eq('id', productId)
          .eq('producer_id', userId);
    } on ProductAuthException {
      rethrow;
    } catch (e) {
      throw ProductOperationException('Failed to delete product', e);
    }
  }
}
