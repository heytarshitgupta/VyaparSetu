import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'picker_web_stub.dart' if (dart.library.js_interop) 'picker_web.dart';
import 'producer_product_image_service.dart';
import 'producer_product_service.dart';

/// Choice of source when selecting an image.
enum ImageSourceOption {
  camera,
  gallery,
}

/// Domain representation of an image picked by the user prior to upload.
class PickedProductImage {
  final Uint8List bytes;
  final String originalFilename;
  final String contentType;
  final int sizeBytes;

  const PickedProductImage({
    required this.bytes,
    required this.originalFilename,
    required this.contentType,
    required this.sizeBytes,
  });
}

/// Thrown when device/platform photo picker cannot be initialized or accessed.
class PhotoPickerUnavailableException extends ProductOperationException {
  const PhotoPickerUnavailableException([
    super.message = 'Photo picker is not available on this device.',
    super.originalError,
  ]);
}

/// Thrown when an image picked by the user has an unsupported format/mime type (e.g. HEIC, GIF, BMP).
class UnsupportedImageFormatException extends ProductOperationException {
  final String detectedType;

  const UnsupportedImageFormatException(
    super.message, {
    this.detectedType = 'unknown',
  });
}

/// Thrown when an image exceeds the 5 MB maximum file size limit.
class ImageTooLargeException extends ProductOperationException {
  final int actualSizeBytes;

  const ImageTooLargeException(
    super.message, {
    this.actualSizeBytes = 0,
  });
}

/// Injectable abstraction over image selection hardware/APIs.
/// Enables deterministic widget testing without physical cameras or native pickers.
abstract class IProducerImagePickerService {
  /// Whether camera capture is supported on the current device/platform.
  bool get isCameraSupported;

  /// Prompts the user to pick an image from [source] (camera or gallery).
  ///
  /// Returns [PickedProductImage] if selected and validated, or `null` if cancelled by user.
  /// Throws [UnsupportedImageFormatException] if format is unsupported.
  /// Throws [ImageTooLargeException] if image size exceeds 5 MB.
  Future<PickedProductImage?> pickImage(ImageSourceOption source);
}

/// Production implementation of [IProducerImagePickerService] using `image_picker`.
class ProducerImagePickerService implements IProducerImagePickerService {
  static const double targetMaxWidth = 1280.0;
  static const double targetMaxHeight = 1280.0;
  static const int targetQuality = 80;
  static const int maxFileSizeBytes = 5242880; // 5 MB

  final ImagePicker _picker;

  ProducerImagePickerService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  @override
  bool get isCameraSupported => !kIsWeb;

  @override
  Future<PickedProductImage?> pickImage(ImageSourceOption source) async {
    // Web does not reliably support direct camera hardware capture via image_picker;
    // route to gallery file picker if camera was requested on web.
    final effectiveSource = (kIsWeb && source == ImageSourceOption.camera)
        ? ImageSourceOption.gallery
        : source;

    final pickerSource = effectiveSource == ImageSourceOption.camera
        ? ImageSource.camera
        : ImageSource.gallery;

    final XFile? xFile;
    try {
      if (kIsWeb) {
        ensureWebPluginRegistered();
      }
      xFile = await _picker.pickImage(
        source: pickerSource,
        maxWidth: targetMaxWidth,
        maxHeight: targetMaxHeight,
        imageQuality: targetQuality,
      );
    } on MissingPluginException catch (e) {
      throw PhotoPickerUnavailableException(
        'Photo picker is not available on this device. Please restart the application.',
        e,
      );
    } on PlatformException catch (e) {
      throw PhotoPickerUnavailableException(
        'Photo picker error: ${e.message ?? 'Picker unavailable or permission denied.'}',
        e,
      );
    } catch (e) {
      if (e is ProductOperationException) rethrow;
      throw PhotoPickerUnavailableException('Could not access image picker: $e', e);
    }

    if (xFile == null) {
      return null; // User cancelled
    }

    final bytes = await xFile.readAsBytes();
    final size = bytes.length;

    if (size == 0) {
      throw const ProductOperationException('Selected image is empty.');
    }

    if (size > maxFileSizeBytes) {
      throw ImageTooLargeException(
        'Image exceeds 5 MB limit ($size bytes)',
        actualSizeBytes: size,
      );
    }

    // MIME detection and allowlist verification
    final resolvedContentType = resolveAndValidateContentType(
      xFile.mimeType,
      xFile.name,
    );

    return PickedProductImage(
      bytes: bytes,
      originalFilename: xFile.name,
      contentType: resolvedContentType,
      sizeBytes: size,
    );
  }

  /// Resolves the Content-Type from declared mime or file extension,
  /// strictly verifying against the allowed formats (JPEG, PNG, WebP).
  ///
  /// Rejects unsupported formats (e.g. HEIC, HEIF, GIF, BMP, TIFF) with
  /// an [UnsupportedImageFormatException].
  static String resolveAndValidateContentType(String? declaredMime, String filename) {
    String candidateMime = '';

    if (declaredMime != null && declaredMime.trim().isNotEmpty) {
      candidateMime = declaredMime.trim().toLowerCase();
    } else {
      final ext = filename.contains('.')
          ? filename.split('.').last.trim().toLowerCase()
          : '';
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          candidateMime = 'image/jpeg';
          break;
        case 'png':
          candidateMime = 'image/png';
          break;
        case 'webp':
          candidateMime = 'image/webp';
          break;
        case 'heic':
        case 'heif':
          throw const UnsupportedImageFormatException(
            'HEIC/HEIF photos are not supported. Please select a JPEG, PNG, or WebP photo.',
            detectedType: 'heic',
          );
        default:
          candidateMime = 'application/octet-stream';
          break;
      }
    }

    // Verify through canonical service normalizer
    try {
      ProducerProductImageService.normalizeMimeType(candidateMime);
      return candidateMime == 'image/jpg' ? 'image/jpeg' : candidateMime;
    } on ProductOperationException {
      throw UnsupportedImageFormatException(
        'Unsupported image type: "$candidateMime". Allowed types: JPEG, PNG, WebP.',
        detectedType: candidateMime,
      );
    }
  }
}
