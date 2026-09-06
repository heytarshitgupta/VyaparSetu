import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'producer_product_service.dart';

/// Pluggable generator for unpredictable, collision-resistant filenames.
abstract class IProductImageFilenameGenerator {
  /// Generates a secure, collision-resistant filename with the given normalized [extension].
  /// Example output: `a1b2c3d4e5f60718293a4b5c6d7e8f90.jpg`
  String generateFilename(String extension);
}

/// Default production generator using a cryptographically secure random source.
/// Generates a 32-character hexadecimal string without user input.
class SecureRandomFilenameGenerator implements IProductImageFilenameGenerator {
  final Random _random;

  SecureRandomFilenameGenerator({Random? random})
      : _random = random ?? Random.secure();

  @override
  String generateFilename(String extension) {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    final hexString = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final cleanExt = extension.startsWith('.') ? extension.substring(1) : extension;
    return '$hexString.$cleanExt';
  }
}

/// Abstract contract for Producer Product Image Storage operations.
///
/// Decouples Supabase Storage mechanics from domain logic, form management,
/// and future image picker/compression implementations.
abstract class IProducerProductImageService {
  /// Uploads product image bytes to the private 'product-images' bucket.
  ///
  /// Constructs the path deterministically:
  /// `<auth.uid()>/<productId>/<generated-filename>`
  ///
  /// Returns the stable relative Storage object path (NOT a signed URL).
  Future<String> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    required String contentType,
  });

  /// Deletes an owned image from the 'product-images' bucket using its [storagePath].
  Future<void> deleteProductImage(String storagePath);

  /// Generates a temporary signed URL for private image viewing.
  /// Does NOT persist the signed URL.
  Future<String> createSignedImageUrl({
    required String storagePath,
    int expiresInSeconds = 3600,
  });
}

/// Production implementation of [IProducerProductImageService] targeting Supabase Storage.
class ProducerProductImageService implements IProducerProductImageService {
  static const String bucketName = 'product-images';
  static const int maxFileSizeBytes = 5242880; // 5 MB

  final SupabaseClient? client;
  final IProductImageFilenameGenerator filenameGenerator;

  ProducerProductImageService({
    this.client,
    IProductImageFilenameGenerator? filenameGenerator,
  }) : filenameGenerator = filenameGenerator ?? SecureRandomFilenameGenerator();

  SupabaseClient get _supabaseClient => client ?? Supabase.instance.client;

  String get _currentUserId {
    final user = _supabaseClient.auth.currentUser;
    if (user == null || user.id.isEmpty) {
      throw const ProductAuthException('No authenticated user session found');
    }
    return user.id;
  }

  /// Normalizes and validates the incoming declared MIME type.
  /// Returns standard file extension (e.g. 'jpg', 'png', 'webp').
  ///
  /// Note: This performs strict allowlist validation against declared Content-Type
  /// and bucket configuration. It is NOT cryptographic image byte/content sniffing.
  static String normalizeMimeType(String contentType) {
    final lower = contentType.trim().toLowerCase();
    switch (lower) {
      case 'image/jpeg':
      case 'image/jpg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      default:
        throw ProductOperationException(
          'Unsupported image type: "$contentType". Allowed types: JPEG, PNG, WebP.',
        );
    }
  }

  /// Returns the canonical HTTP MIME string for a validated file extension.
  static String canonicalMimeType(String ext) {
    switch (ext) {
      case 'jpg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  /// Validates that [storagePath] is a stable relative Storage path of the form:
  /// `<user_id>/<product_id>/<filename>`
  ///
  /// Rejects:
  /// - Empty or whitespace strings
  /// - Full URLs (http://, https://)
  /// - Local file paths (file://)
  /// - Base64 data URIs (data:)
  /// - Bucket-prefixed paths (product-images/...)
  /// - Paths with != 3 segments or empty segments
  static void validateStoragePath(String storagePath) {
    final trimmed = storagePath.trim();
    if (trimmed.isEmpty) {
      throw const ProductOperationException('Storage path cannot be empty');
    }

    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('file://') ||
        trimmed.startsWith('data:')) {
      throw ProductOperationException(
        'Invalid storage path: must be a stable relative object path, not a URL or local file ("$storagePath")',
      );
    }

    if (trimmed.startsWith('$bucketName/')) {
      throw ProductOperationException(
        'Invalid storage path: must not include bucket prefix "$bucketName/" ("$storagePath")',
      );
    }

    final segments = trimmed.split('/');
    if (segments.length != 3 || segments.any((s) => s.trim().isEmpty)) {
      throw ProductOperationException(
        'Invalid storage path format. Expected "<user>/<product>/<filename>", got "$storagePath"',
      );
    }
  }

  @override
  Future<String> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final userId = _currentUserId;

    final trimmedProductId = productId.trim();
    if (trimmedProductId.isEmpty) {
      throw const ProductOperationException('Product ID cannot be empty');
    }

    if (bytes.isEmpty) {
      throw const ProductOperationException('Image bytes cannot be empty');
    }

    if (bytes.length > maxFileSizeBytes) {
      throw ProductOperationException(
        'Image exceeds 5 MB limit (${bytes.length} bytes)',
      );
    }

    // Derive extension strictly and canonically from validated MIME type
    final ext = normalizeMimeType(contentType);
    final filename = filenameGenerator.generateFilename(ext);
    final objectPath = '$userId/$trimmedProductId/$filename';
    final canonicalMime = canonicalMimeType(ext);

    try {
      await _supabaseClient.storage.from(bucketName).uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              contentType: canonicalMime,
              upsert: false, // Strict: no overwrites/upserts
            ),
          );

      return objectPath;
    } on ProductAuthException {
      rethrow;
    } on StorageException catch (e) {
      throw ProductOperationException('Storage upload failed: ${e.message}', e);
    } catch (e) {
      throw ProductOperationException('Failed to upload product image', e);
    }
  }

  @override
  Future<void> deleteProductImage(String storagePath) async {
    _currentUserId; // Verify authenticated

    final trimmed = storagePath.trim();
    validateStoragePath(trimmed);

    try {
      await _supabaseClient.storage.from(bucketName).remove([trimmed]);
    } on ProductAuthException {
      rethrow;
    } on StorageException catch (e) {
      throw ProductOperationException('Storage deletion failed: ${e.message}', e);
    } catch (e) {
      throw ProductOperationException('Failed to delete product image', e);
    }
  }

  @override
  Future<String> createSignedImageUrl({
    required String storagePath,
    int expiresInSeconds = 3600,
  }) async {
    _currentUserId; // Verify authenticated

    final trimmed = storagePath.trim();
    validateStoragePath(trimmed);

    try {
      final signedUrl = await _supabaseClient.storage
          .from(bucketName)
          .createSignedUrl(trimmed, expiresInSeconds);
      return signedUrl;
    } on ProductAuthException {
      rethrow;
    } on StorageException catch (e) {
      throw ProductOperationException(
        'Failed to generate signed URL: ${e.message}',
        e,
      );
    } catch (e) {
      throw ProductOperationException('Failed to generate signed image URL', e);
    }
  }
}
