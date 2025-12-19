import 'package:flutter/material.dart';

class AppConstants {
  static const Color primaryColor = Color(0xFF3271a5);
  static const String appTitle = 'Gourd Scanner';
  static const String appSubtitle = 'Scan or upload images for analysis';
  
  // Model paths
  static const String modelPath = 'assets/tflite/squash.tflite';
  static const String labelsPath = 'assets/tflite/labels.txt';
  
  // Image processing
  static const int imageWidth = 224;
  static const int imageHeight = 224;
}
