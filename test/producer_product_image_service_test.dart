import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_image_service.dart';
import 'package:buyer_section/producer_section/products/services/producer_product_service.dart';

class DeterministicFilenameGenerator implements IProductImageFilenameGenerator {
  final String fixedName;
  const DeterministicFilenameGenerator(this.fixedName);

  @override
  String generateFilename(String extension) => '$fixedName.$extension';
}

/// In-memory fake of [IProducerProductImageService] for deterministic offline testing.
class FakeProducerProductImageService implements IProducerProductImageService {
  final String currentUserId;
  final Map<String, Uint8List> storage = {};
  bool failNextDelete = false;

  FakeProducerProductImageService({this.currentUserId = 'test-user-123'});

  @override
  Future<String> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (productId.trim().isEmpty) {
      throw const ProductOperationException('Product ID cannot be empty');
    }
    if (bytes.isEmpty) {
      throw const ProductOperationException('Image bytes cannot be empty');
    }
    if (bytes.length > ProducerProductImageService.maxFileSizeBytes) {
      throw ProductOperationException('Image exceeds 5 MB limit (${bytes.length} bytes)');
    }

    final ext = ProducerProductImageService.normalizeMimeType(contentType);
    final filename = 'test_img_001.$ext';
    final path = '$currentUserId/$productId/$filename';

    storage[path] = bytes;
    return path;
  }

  @override
  Future<void> deleteProductImage(String storagePath) async {
    if (failNextDelete) {
      throw const ProductOperationException('Simulated storage delete error');
    }

    final segments = storagePath.split('/');
    if (segments.length != 3) {
      throw ProductOperationException('Invalid storage path format: "$storagePath"');
    }

    storage.remove(storagePath);
  }

  @override
  Future<String> createSignedImageUrl({
    required String storagePath,
    int expiresInSeconds = 3600,
  }) async {
    return 'https://fake-storage.supabase.co/object/sign/product-images/$storagePath?token=fake_sig';
  }
}

void main() {
  group('SecureRandomFilenameGenerator', () {
    test('generates 32-character hexadecimal filename with given extension', () {
      final generator = SecureRandomFilenameGenerator();
      final filename = generator.generateFilename('jpg');

      expect(filename, endsWith('.jpg'));
      final hexPart = filename.split('.')[0];
      expect(hexPart.length, 32);
      expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(hexPart), isTrue);
    });

    test('normalizes leading dot in extension', () {
      final generator = SecureRandomFilenameGenerator();
      final filename = generator.generateFilename('.png');

      expect(filename, endsWith('.png'));
      expect(filename.contains('..'), isFalse);
    });

    test('generates distinct filenames on repeated calls', () {
      final generator = SecureRandomFilenameGenerator();
      final file1 = generator.generateFilename('webp');
      final file2 = generator.generateFilename('webp');

      expect(file1, isNot(equals(file2)));
    });
  });

  group('ProducerProductImageService - MIME Type Normalization', () {
    test('accepts valid MIME types: jpeg, png, webp', () {
      expect(ProducerProductImageService.normalizeMimeType('image/jpeg'), 'jpg');
      expect(ProducerProductImageService.normalizeMimeType('image/jpg'), 'jpg');
      expect(ProducerProductImageService.normalizeMimeType('image/png'), 'png');
      expect(ProducerProductImageService.normalizeMimeType('image/webp'), 'webp');
      expect(ProducerProductImageService.normalizeMimeType('  IMAGE/JPEG  '), 'jpg');
    });

    test('rejects unsupported MIME types explicitly', () {
      expect(
        () => ProducerProductImageService.normalizeMimeType('application/pdf'),
        throwsA(isA<ProductOperationException>()),
      );
      expect(
        () => ProducerProductImageService.normalizeMimeType('text/plain'),
        throwsA(isA<ProductOperationException>()),
      );
      expect(
        () => ProducerProductImageService.normalizeMimeType('image/gif'),
        throwsA(isA<ProductOperationException>()),
      );
    });
  });

  group('FakeProducerProductImageService Contract & Boundaries', () {
    late FakeProducerProductImageService service;

    setUp(() {
      service = FakeProducerProductImageService();
    });

    test('uploads image and returns stable relative Storage path without signed URL', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final path = await service.uploadProductImage(
        productId: 'prod-456',
        bytes: bytes,
        contentType: 'image/jpeg',
      );

      expect(path, 'test-user-123/prod-456/test_img_001.jpg');
      expect(path, isNot(startsWith('http')));
      expect(service.storage.containsKey(path), isTrue);
    });

    test('rejects upload with empty bytes', () async {
      expect(
        () => service.uploadProductImage(
          productId: 'prod-456',
          bytes: Uint8List(0),
          contentType: 'image/jpeg',
        ),
        throwsA(isA<ProductOperationException>()),
      );
    });

    test('rejects upload exceeding 5 MB limit', () async {
      final oversizedBytes = Uint8List(5242880 + 1); // 5 MB + 1 byte
      expect(
        () => service.uploadProductImage(
          productId: 'prod-456',
          bytes: oversizedBytes,
          contentType: 'image/jpeg',
        ),
        throwsA(isA<ProductOperationException>()),
      );
    });

    test('generates short-lived signed URL for an existing storage path', () async {
      final path = 'test-user-123/prod-456/test_img_001.jpg';
      final signedUrl = await service.createSignedImageUrl(storagePath: path);

      expect(signedUrl, contains('product-images/test-user-123/prod-456/test_img_001.jpg'));
      expect(signedUrl, startsWith('https://'));
    });

    test('deletes image by path successfully', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final path = await service.uploadProductImage(
        productId: 'prod-456',
        bytes: bytes,
        contentType: 'image/png',
      );

      expect(service.storage.containsKey(path), isTrue);
      await service.deleteProductImage(path);
      expect(service.storage.containsKey(path), isFalse);
    });

    test('rejects delete with malformed path shape', () async {
      expect(
        () => service.deleteProductImage('shallow-file.jpg'),
        throwsA(isA<ProductOperationException>()),
      );
    });
  });

  group('ProducerProductImageService - Path & MIME Validation Contracts', () {
    test('canonicalMimeType maps extensions correctly', () {
      expect(ProducerProductImageService.canonicalMimeType('jpg'), 'image/jpeg');
      expect(ProducerProductImageService.canonicalMimeType('png'), 'image/png');
      expect(ProducerProductImageService.canonicalMimeType('webp'), 'image/webp');
      expect(ProducerProductImageService.canonicalMimeType('unknown'), 'application/octet-stream');
    });

    test('validateStoragePath accepts valid 3-segment relative object paths', () {
      // Must not throw for valid paths
      expect(
        () => ProducerProductImageService.validateStoragePath('user-uuid-123/prod-uuid-456/photo.jpg'),
        returnsNormally,
      );
      expect(
        () => ProducerProductImageService.validateStoragePath('u1/p1/abc_123.png'),
        returnsNormally,
      );
    });

    test('validateStoragePath rejects empty or whitespace paths', () {
      expect(
        () => ProducerProductImageService.validateStoragePath(''),
        throwsA(isA<ProductOperationException>()),
      );
      expect(
        () => ProducerProductImageService.validateStoragePath('   '),
        throwsA(isA<ProductOperationException>()),
      );
    });

    test('validateStoragePath rejects public and signed URLs', () {
      expect(
        () => ProducerProductImageService.validateStoragePath(
          'https://xyz.supabase.co/storage/v1/object/public/product-images/u/p/f.jpg',
        ),
        throwsA(isA<ProductOperationException>()),
      );
      expect(
        () => ProducerProductImageService.validateStoragePath(
          'http://xyz.supabase.co/storage/v1/object/sign/product-images/u/p/f.jpg?token=abc',
        ),
        throwsA(isA<ProductOperationException>()),
      );
    });

    test('validateStoragePath rejects local file paths and data URIs', () {
      expect(
        () => ProducerProductImageService.validateStoragePath('file:///storage/emulated/0/photo.jpg'),
        throwsA(isA<ProductOperationException>()),
      );
      expect(
        () => ProducerProductImageService.validateStoragePath('data:image/jpeg;base64,/9j/4AAQSkZJRg=='),
        throwsA(isA<ProductOperationException>()),
      );
    });

    test('validateStoragePath rejects bucket-prefixed paths', () {
      expect(
        () => ProducerProductImageService.validateStoragePath('product-images/user/prod/photo.jpg'),
        throwsA(isA<ProductOperationException>()),
      );
    });

    test('validateStoragePath rejects invalid segment counts or empty segments', () {
      // 1 segment
      expect(
        () => ProducerProductImageService.validateStoragePath('photo.jpg'),
        throwsA(isA<ProductOperationException>()),
      );
      // 2 segments
      expect(
        () => ProducerProductImageService.validateStoragePath('user/photo.jpg'),
        throwsA(isA<ProductOperationException>()),
      );
      // 4 segments
      expect(
        () => ProducerProductImageService.validateStoragePath('custom/user/prod/photo.jpg'),
        throwsA(isA<ProductOperationException>()),
      );
      // Empty segment in middle
      expect(
        () => ProducerProductImageService.validateStoragePath('user//photo.jpg'),
        throwsA(isA<ProductOperationException>()),
      );
    });
  });
}

