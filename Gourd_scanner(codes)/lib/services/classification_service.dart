import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class ClassificationService {
  late tfl.Interpreter _interpreter;
  late List<String> _labels;

  Future<void> loadModel() async {
    _interpreter = await tfl.Interpreter.fromAsset(AppConstants.modelPath);
    _labels = await rootBundle
        .loadString(AppConstants.labelsPath)
        .then(
          (v) => v
              .split('\n')
              .where((e) => e.isNotEmpty)
              .map((e) => e.trim())
              .toList(),
        );
  }

  Future<List<double>> classifyImage(File imageFile) async {
    final image = img.decodeImage(imageFile.readAsBytesSync())!;
    final resized = img.copyResize(image, width: AppConstants.imageWidth, height: AppConstants.imageHeight);

    final input = List.generate(
      1,
      (_) => List.generate(
        AppConstants.imageHeight,
        (y) => List.generate(AppConstants.imageWidth, (x) {
          final p = resized.getPixel(x, y);
          return [p.r / 255, p.g / 255, p.b / 255];
        }),
      ),
    );

    final output = [List.filled(_labels.length, 0.0)];
    _interpreter.run(input, output);

    return List<double>.from(output[0]);
  }

  List<String> get labels => _labels;

  void dispose() {
    _interpreter.close();
  }
}
