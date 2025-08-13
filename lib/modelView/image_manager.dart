import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class ImageManager {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 768,
        imageQuality: 80,
        requestFullMetadata: false,
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
        requestFullMetadata: false,
      );

      if (image != null) {
        return await _processImage(image);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<File> _processImage(XFile xFile) async {
    File? processedFile;
    Uint8List? bytes;
    img.Image? originalImage;
    img.Image? resizedImage;
    Uint8List? resizedBytes;

    try {
      bytes = await xFile.readAsBytes();
      
      originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        return File(xFile.path);
      }

      double aspectRatio = originalImage.width / originalImage.height;
      int newWidth, newHeight;
      
      if (aspectRatio > 1) {
        newWidth = 800;
        newHeight = (800 / aspectRatio).round();
      } else {
        newHeight = 600;
        newWidth = (600 * aspectRatio).round();
      }

      resizedImage = img.copyResize(
        originalImage, 
        width: newWidth, 
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      resizedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: 75)
      );

      final processedPath = '${xFile.path}_processed.jpg';
      processedFile = File(processedPath);
      await processedFile.writeAsBytes(resizedBytes);

      return processedFile;
    } catch (e) {
      return File(xFile.path);
    } finally {
      bytes = null;
      originalImage = null;
      resizedImage = null;
      resizedBytes = null;
    }
  }

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