import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';

/// Image utilities for compression, resizing, and processing
class ImageUtils {
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  static const int thumbnailSize = 300;
  static const int quality = 85;

  /// Compress and resize image
  static Future<File?> compressImage(
    File imageFile, {
    int? maxWidth,
    int? maxHeight,
    int? quality,
    String? outputPath,
  }) async {
    try {
      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      
      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate new dimensions
      final newDimensions = _calculateDimensions(
        image.width,
        image.height,
        maxWidth ?? maxImageWidth,
        maxHeight ?? maxImageHeight,
      );

      // Resize image if needed
      img.Image resizedImage = image;
      if (newDimensions.width != image.width || newDimensions.height != image.height) {
        resizedImage = img.copyResize(
          image,
          width: newDimensions.width,
          height: newDimensions.height,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode image with compression
      final compressedBytes = img.encodeJpg(
        resizedImage,
        quality: quality ?? ImageUtils.quality,
      );

      // Save compressed image
      final outputFile = outputPath != null 
          ? File(outputPath)
          : await _createTempFile('compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await outputFile.writeAsBytes(compressedBytes);

      if (kDebugMode) {
        final originalSize = bytes.length;
        final compressedSize = compressedBytes.length;
        final compressionRatio = ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1);
        print('🖼️ Image compressed: ${originalSize ~/ 1024}KB → ${compressedSize ~/ 1024}KB ($compressionRatio% reduction)');
      }

      return outputFile;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Image compression failed: $e');
      }
      return null;
    }
  }

  /// Create thumbnail from image
  static Future<File?> createThumbnail(
    File imageFile, {
    int size = thumbnailSize,
    String? outputPath,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Create square thumbnail
      final thumbnail = img.copyResizeCropSquare(image, size: size);
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 80);

      final outputFile = outputPath != null 
          ? File(outputPath)
          : await _createTempFile('thumb_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await outputFile.writeAsBytes(thumbnailBytes);
      return outputFile;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Thumbnail creation failed: $e');
      }
      return null;
    }
  }

  /// Pick image from gallery or camera
  static Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    bool compress = true,
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: compress ? (maxWidth?.toDouble() ?? maxImageWidth.toDouble()) : null,
        maxHeight: compress ? (maxHeight?.toDouble() ?? maxImageHeight.toDouble()) : null,
        imageQuality: compress ? (quality ?? ImageUtils.quality) : null,
      );

      if (pickedFile == null) return null;

      final file = File(pickedFile.path);
      
      // Additional compression if needed
      if (compress) {
        final compressedFile = await compressImage(file);
        return compressedFile ?? file;
      }

      return file;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Image picking failed: $e');
      }
      return null;
    }
  }

  /// Pick multiple images
  static Future<List<File>> pickMultipleImages({
    bool compress = true,
    int maxImages = 5,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        maxWidth: compress ? maxImageWidth.toDouble() : null,
        maxHeight: compress ? maxImageHeight.toDouble() : null,
        imageQuality: compress ? quality : null,
      );

      if (pickedFiles.isEmpty) return [];

      // Limit number of images
      final limitedFiles = pickedFiles.take(maxImages).toList();
      final files = <File>[];

      for (final pickedFile in limitedFiles) {
        final file = File(pickedFile.path);
        
        if (compress) {
          final compressedFile = await compressImage(file);
          files.add(compressedFile ?? file);
        } else {
          files.add(file);
        }
      }

      return files;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Multiple image picking failed: $e');
      }
      return [];
    }
  }

  /// Validate image file
  static Future<bool> validateImage(File imageFile) async {
    try {
      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > AppConfig.maxImageSizeBytes) {
        if (kDebugMode) {
          print('❌ Image too large: ${fileSize ~/ 1024}KB > ${AppConfig.maxImageSizeBytes ~/ 1024}KB');
        }
        return false;
      }

      // Check file format
      final extension = imageFile.path.split('.').last.toLowerCase();
      if (!AppConfig.supportedImageFormats.contains(extension)) {
        if (kDebugMode) {
          print('❌ Unsupported image format: $extension');
        }
        return false;
      }

      // Try to decode image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        if (kDebugMode) {
          print('❌ Invalid image file');
        }
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Image validation failed: $e');
      }
      return false;
    }
  }

  /// Get image dimensions
  static Future<({int width, int height})?> getImageDimensions(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      return (width: image.width, height: image.height);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get image dimensions: $e');
      }
      return null;
    }
  }

  /// Convert image to different format
  static Future<File?> convertImage(
    File imageFile,
    String targetFormat, {
    int? quality,
    String? outputPath,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      Uint8List convertedBytes;
      String extension;

      switch (targetFormat.toLowerCase()) {
        case 'jpg':
        case 'jpeg':
          convertedBytes = img.encodeJpg(image, quality: quality ?? ImageUtils.quality);
          extension = 'jpg';
          break;
        case 'png':
          convertedBytes = img.encodePng(image);
          extension = 'png';
          break;
        case 'webp':
          convertedBytes = img.encodeWebP(image, quality: quality ?? ImageUtils.quality);
          extension = 'webp';
          break;
        default:
          throw Exception('Unsupported format: $targetFormat');
      }

      final outputFile = outputPath != null 
          ? File(outputPath)
          : await _createTempFile('converted_${DateTime.now().millisecondsSinceEpoch}.$extension');
      
      await outputFile.writeAsBytes(convertedBytes);
      return outputFile;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Image conversion failed: $e');
      }
      return null;
    }
  }

  /// Calculate optimal dimensions while maintaining aspect ratio
  static ({int width, int height}) _calculateDimensions(
    int originalWidth,
    int originalHeight,
    int maxWidth,
    int maxHeight,
  ) {
    if (originalWidth <= maxWidth && originalHeight <= maxHeight) {
      return (width: originalWidth, height: originalHeight);
    }

    final aspectRatio = originalWidth / originalHeight;

    int newWidth = maxWidth;
    int newHeight = (newWidth / aspectRatio).round();

    if (newHeight > maxHeight) {
      newHeight = maxHeight;
      newWidth = (newHeight * aspectRatio).round();
    }

    return (width: newWidth, height: newHeight);
  }

  /// Create temporary file
  static Future<File> _createTempFile(String fileName) async {
    final tempDir = await getTemporaryDirectory();
    return File('${tempDir.path}/$fileName');
  }

  /// Clean up temporary files
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      
      for (final file in files) {
        if (file is File && 
            (file.path.contains('compressed_') || 
             file.path.contains('thumb_') || 
             file.path.contains('converted_'))) {
          await file.delete();
        }
      }
      
      if (kDebugMode) {
        print('🧹 Temporary image files cleaned up');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to cleanup temp files: $e');
      }
    }
  }
}
