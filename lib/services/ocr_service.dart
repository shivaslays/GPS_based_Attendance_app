import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'; // Temporarily disabled for iOS compatibility
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class OcrService {
  // final TextRecognizer _textRecognizer = TextRecognizer(); // Temporarily disabled for iOS compatibility
  final ImagePicker _imagePicker = ImagePicker();

  // Process text recognition from image file
  Future<String> recognizeTextFromImage(File imageFile) async {
    try {
      // Temporarily disabled for iOS compatibility - returns placeholder text
      await Future.delayed(const Duration(seconds: 2)); // Simulate processing time
      return 'OCR functionality temporarily disabled for iOS compatibility. Please use manual note entry.\n\nImage path: ${imageFile.path}';
      
      // Original code (commented out):
      // final inputImage = InputImage.fromFile(imageFile);
      // final recognizedText = await _textRecognizer.processImage(inputImage);
      // return recognizedText.text;
    } catch (e) {
      throw Exception('Failed to recognize text: $e');
    }
  }

  // Process text recognition from camera image
  Future<String> recognizeTextFromCamera(CameraImage cameraImage, CameraDescription camera) async {
    try {
      // Temporarily disabled for iOS compatibility - returns placeholder text
      await Future.delayed(const Duration(seconds: 2)); // Simulate processing time
      return 'OCR functionality temporarily disabled for iOS compatibility. Please use manual note entry.\n\nCamera image captured successfully.';
      
      // Original code (commented out):
      // final inputImage = _inputImageFromCameraImage(cameraImage, camera);
      // final recognizedText = await _textRecognizer.processImage(inputImage);
      // return recognizedText.text;
    } catch (e) {
      throw Exception('Failed to recognize text from camera: $e');
    }
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  // Save camera image to file
  Future<File> saveCameraImage(CameraImage cameraImage, String fileName) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = path.join(tempDir.path, fileName);
      final File file = File(filePath);
      
      // Convert CameraImage to bytes and save
      final Uint8List bytes = _convertCameraImageToBytes(cameraImage);
      await file.writeAsBytes(bytes);
      
      return file;
    } catch (e) {
      throw Exception('Failed to save camera image: $e');
    }
  }

  // Convert camera image to input image (stub implementation)
  // InputImage _inputImageFromCameraImage(CameraImage cameraImage, CameraDescription camera) {
  //   // Temporarily disabled for iOS compatibility
  //   throw UnimplementedError('OCR temporarily disabled for iOS compatibility');
  // }

  // Convert camera image to bytes
  Uint8List _convertCameraImageToBytes(CameraImage cameraImage) {
    // Convert YUV420 format to RGB
    final int width = cameraImage.width;
    final int height = cameraImage.height;
    
    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;
    
    final Uint8List bytes = Uint8List(width * height * 3);
    int bytesOffset = 0;
    
    // Convert Y plane
    for (int y = 0; y < height; y++) {
      final int yRowStride = cameraImage.planes[0].bytesPerRow;
      final int yPixelStride = cameraImage.planes[0].bytesPerPixel!;
      
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yRowStride + x * yPixelStride;
        final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;
        
        final int yValue = cameraImage.planes[0].bytes[yIndex];
        final int uValue = cameraImage.planes[1].bytes[uvIndex];
        final int vValue = cameraImage.planes[2].bytes[uvIndex];
        
        // Convert YUV to RGB
        final int r = (yValue + (1.402 * (vValue - 128))).round().clamp(0, 255);
        final int g = (yValue - (0.344136 * (uValue - 128)) - (0.714136 * (vValue - 128))).round().clamp(0, 255);
        final int b = (yValue + (1.772 * (uValue - 128))).round().clamp(0, 255);
        
        bytes[bytesOffset++] = r;
        bytes[bytesOffset++] = g;
        bytes[bytesOffset++] = b;
      }
    }
    
    return bytes;
  }

  // Dispose resources
  void dispose() {
    // _textRecognizer.close(); // Temporarily disabled for iOS compatibility
  }
}