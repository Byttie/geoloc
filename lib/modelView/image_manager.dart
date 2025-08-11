import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class ImageManager {
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // Slightly larger to maintain quality
        maxHeight: 768,
        imageQuality: 80,
        requestFullMetadata: false, // Reduce memory usage
      );

      if (image != null) {
        return await _processImage(image);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Take photo with camera
  Future<File?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 768,
        imageQuality: 80,
        requestFullMetadata: false, // Reduce memory usage
      );

      if (image != null) {
        return await _processImage(image);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Process and resize image with proper memory management
  Future<File> _processImage(XFile xFile) async {
    File? processedFile;
    Uint8List? bytes;
    img.Image? originalImage;
    img.Image? resizedImage;
    Uint8List? resizedBytes;

    try {
      // Read file
      bytes = await xFile.readAsBytes();
      
      // Decode image
      originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        return File(xFile.path);
      }

      // Calculate new dimensions maintaining aspect ratio
      double aspectRatio = originalImage.width / originalImage.height;
      int newWidth, newHeight;
      
      if (aspectRatio > 1) {
        // Landscape
        newWidth = 800;
        newHeight = (800 / aspectRatio).round();
      } else {
        // Portrait or square
        newHeight = 600;
        newWidth = (600 * aspectRatio).round();
      }

      // Resize image
      resizedImage = img.copyResize(
        originalImage, 
        width: newWidth, 
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // Encode to JPEG with compression
      resizedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: 75)
      );

      // Create processed file
      final processedPath = '${xFile.path}_processed.jpg';
      processedFile = File(processedPath);
      await processedFile.writeAsBytes(resizedBytes);

      return processedFile;
    } catch (e) {
      return File(xFile.path);
    } finally {
      // Clean up memory
      bytes = null;
      originalImage = null;
      resizedImage = null;
      resizedBytes = null;
    }
  }

  // Clean up temporary files
  Future<void> cleanupTempFiles(File? imageFile) async {
    if (imageFile != null && await imageFile.exists()) {
      try {
        await imageFile.delete();
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }
} 