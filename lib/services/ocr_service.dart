import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _imagePicker = ImagePicker();

  // Process text recognition from image file
  Future<String> recognizeTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      print('Error recognizing text: $e');
      throw Exception('Failed to recognize text from image: $e');
    }
  }

  // Process text recognition from camera image
  Future<String> recognizeTextFromCamera(CameraImage cameraImage, CameraDescription camera) async {
    try {
      final inputImage = _inputImageFromCameraImage(cameraImage, camera);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      print('Error recognizing text from camera: $e');
      throw Exception('Failed to recognize text from camera: $e');
    }
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      throw Exception('Failed to pick image from camera: $e');
    }
  }

  // Save camera image to temporary file
  Future<File> saveCameraImage(CameraImage cameraImage, CameraDescription camera) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = path.join(tempDir.path, 'ocr_image_$timestamp.jpg');
      
      final File imageFile = File(filePath);
      await imageFile.writeAsBytes(_convertCameraImageToBytes(cameraImage));
      
      return imageFile;
    } catch (e) {
      print('Error saving camera image: $e');
      throw Exception('Failed to save camera image: $e');
    }
  }

  // Convert CameraImage to InputImage
  InputImage _inputImageFromCameraImage(CameraImage cameraImage, CameraDescription camera) {
    final sensorOrientation = camera.sensorOrientation;
    
    // Convert camera image to bytes
    final bytes = _convertCameraImageToBytes(cameraImage);
    
    // Create InputImage from bytes
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        rotation: InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg,
        format: InputImageFormatValue.fromRawValue(cameraImage.format.raw) ?? InputImageFormat.nv21,
        bytesPerRow: cameraImage.planes.first.bytesPerRow,
      ),
    );
  }

  // Convert CameraImage to bytes
  Uint8List _convertCameraImageToBytes(CameraImage cameraImage) {
    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      return _convertYUV420ToBytes(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888ToBytes(cameraImage);
    } else {
      throw Exception('Unsupported image format: ${cameraImage.format}');
    }
  }

  // Convert YUV420 format to bytes
  Uint8List _convertYUV420ToBytes(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;
    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;
    
    final bytes = Uint8List(width * height * 3);
    int idx = 0;
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int yIndex = y * width + x;
        
        final int yValue = cameraImage.planes[0].bytes[yIndex];
        final int uValue = cameraImage.planes[1].bytes[uvIndex];
        final int vValue = cameraImage.planes[2].bytes[uvIndex];
        
        // Convert YUV to RGB
        int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).round().clamp(0, 255);
        int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);
        
        bytes[idx++] = r;
        bytes[idx++] = g;
        bytes[idx++] = b;
      }
    }
    
    return bytes;
  }

  // Convert BGRA8888 format to bytes
  Uint8List _convertBGRA8888ToBytes(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;
    final bytes = Uint8List(width * height * 3);
    int idx = 0;
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int pixelIndex = y * width + x;
        final int byteIndex = pixelIndex * 4;
        
        // BGRA to RGB
        bytes[idx++] = cameraImage.planes[0].bytes[byteIndex + 2]; // R
        bytes[idx++] = cameraImage.planes[0].bytes[byteIndex + 1]; // G
        bytes[idx++] = cameraImage.planes[0].bytes[byteIndex];     // B
      }
    }
    
    return bytes;
  }

  // Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}
