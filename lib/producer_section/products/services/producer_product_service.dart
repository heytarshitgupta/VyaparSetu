import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/producer_product.dart';
import '../models/producer_product_draft.dart';
import '../models/product_price_parser.dart';
import 'producer_product_image_service.dart';

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
  /// If product has images, Storage cleanup must succeed before database deletion.
  Future<void> deleteProduct(String productId);

  /// Persists a new product draft strictly under the current authenticated producer.
  /// Forces status = draft. Caller cannot specify status or producer_id.
  Future<ProducerProduct> createDraft(ProducerProductDraft draft);

  /// Updates editable draft fields of an owned product.
  /// Does NOT allow updating producer_id, status, or images.
  Future<ProducerProduct> updateDraft({
    required String productId,
    required ProducerProductDraft draft,
  });

  /// Updates the stable Storage image paths for an owned product.
  Future<ProducerProduct> updateProductImages({
    required String productId,
    required List<String> imagePaths,
  });
}

/// Production implementation of [IProducerProductService] using Supabase.
///
/// Security note:
/// While PostgreSQL RLS is the authoritative security boundary, client queries
/// are also strictly scoped to `auth.uid()` to prevent accidental cross-tenant queries.
class ProducerProductService implements IProducerProductService {
  final SupabaseClient? client;
  final IProducerProductImageService? imageService;

  ProducerProductService({
    this.client,
    IProducerProductImageService? imageService,
    bool enableImageService = true,
  }) : imageService = enableImageService
            ? (imageService ?? ProducerProductImageService(client: client))
            : null;

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
  Future<ProducerProduct> createDraft(ProducerProductDraft draft) async {
    final userId = _currentUserId;

    final trimmedName = draft.name.trim();
    if (trimmedName.isEmpty) {
      throw const ProductOperationException('Product name cannot be empty');
    }

    try {
      final payload = {
        'producer_id': userId,
        'name': trimmedName,
        'description': draft.description.trim(),
        'category': draft.category.trim(),
        'price': ProductPriceParser.paiseToDecimalString(draft.pricePaise),
        'unit': draft.unit.trim().isEmpty ? 'piece' : draft.unit.trim(),
        'status': ProductStatus.draft.toDbValue(),
      };

      final response = await _supabaseClient
          .from('products')
          .insert(payload)
          .select()
          .single();

      return ProducerProduct.fromJson(response);
    } on ProductAuthException {
      rethrow;
    } catch (e) {
      throw ProductOperationException('Failed to create product draft', e);
    }
  }

  @override
  Future<ProducerProduct> updateDraft({
    required String productId,
    required ProducerProductDraft draft,
  }) async {
    final userId = _currentUserId;

    final trimmedName = draft.name.trim();
    if (trimmedName.isEmpty) {
      throw const ProductOperationException('Product name cannot be empty');
    }

    try {
      final payload = {
        'name': trimmedName,
        'description': draft.description.trim(),
        'category': draft.category.trim(),
        'price': ProductPriceParser.paiseToDecimalString(draft.pricePaise),
        'unit': draft.unit.trim().isEmpty ? 'piece' : draft.unit.trim(),
      };

      final response = await _supabaseClient
          .from('products')
          .update(payload)
          .eq('id', productId)
          .eq('producer_id', userId)
          .select()
          .maybeSingle();

      if (response == null) {
        throw const ProductOperationException('Product not found or not owned');
      }

      return ProducerProduct.fromJson(response);
    } on ProductAuthException {
      rethrow;
    } catch (e) {
      if (e is ProductOperationException) rethrow;
      throw ProductOperationException('Failed to update product draft', e);
    }
  }

  @override
  Future<ProducerProduct> updateProductImages({
    required String productId,
    required List<String> imagePaths,
  }) async {
    final userId = _currentUserId;

    // Validate that every image path is a valid stable Storage object path:
    // USER / PRODUCT / FILENAME (3 non-empty segments, no URLs or schemes).
    for (final path in imagePaths) {
      ProducerProductImageService.validateStoragePath(path);
    }

    try {
      final response = await _supabaseClient
          .from('products')
          .update({'images': imagePaths})
          .eq('id', productId)
          .eq('producer_id', userId)
          .select()
          .maybeSingle();

      if (response == null) {
        throw const ProductOperationException('Product not found or not owned');
      }

      return ProducerProduct.fromJson(response);
    } on ProductAuthException {
      rethrow;
    } catch (e) {
      if (e is ProductOperationException) rethrow;
      throw ProductOperationException('Failed to update product images', e);
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    final userId = _currentUserId;

    try {
      // 1. Fetch product to check for existing Storage images
      final existing = await _supabaseClient
          .from('products')
          .select('id, producer_id, images')
          .eq('id', productId)
          .eq('producer_id', userId)
          .maybeSingle();

      if (existing == null) {
        // Product does not exist or is not owned; DB delete will cleanly no-op
        return;
      }

      final imagesList = (existing['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      // 2. Storage Cleanup Lifecycle:
      // Storage DELETE policy (Migration 011) strictly verifies product ownership
      // via `private.producer_owns_product(product_id)`. Therefore, Storage images
      // MUST be deleted BEFORE the database row is deleted.
      if (imagesList.isNotEmpty) {
        // CASE C: Images are present, but image service is NOT available.
        // DO NOT delete DB row. Fail-safe: throw typed exception so product row
        // is preserved along with image references for retry.
        if (imageService == null) {
          throw const ProductOperationException(
            'Cannot delete product: product has images but no image service is available for Storage cleanup. Product was not deleted.',
          );
        }

        // CASE B: Images are present, and image service is available.
        // Attempt to delete every referenced Storage image first.
        // If ANY deletion fails (partial failure), halt immediately and DO NOT delete DB row.
        // Note: This is not transactionally atomic between Storage and DB, but retaining
        // the DB row preserves ownership evidence for remaining images and allows recovery.
        for (final imagePath in imagesList) {
          try {
            await imageService!.deleteProductImage(imagePath);
          } catch (e) {
            throw ProductOperationException(
              'Failed to delete product image ($imagePath) from storage. Product was not deleted.',
              e,
            );
          }
        }
      }

      // 3. CASE A (no images) OR CASE B (all Storage deletions succeeded):
      // Safely delete owned database row.
      await _supabaseClient
          .from('products')
          .delete()
          .eq('id', productId)
          .eq('producer_id', userId);
    } on ProductAuthException {
      rethrow;
    } catch (e) {
      if (e is ProductOperationException) rethrow;
      throw ProductOperationException('Failed to delete product', e);
    }
  }
}
