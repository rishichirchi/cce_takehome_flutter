import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class FaceConditionDetector {
  static const double _smileThreshold = 0.6;
  static const double _eyeOpenThreshold = 0.5;
  static const double _tiredEyeThreshold = 0.3;

  static const int _dimLightThreshold = 30;
  static const int _brightLightThreshold = 75;

  int _lastLightingLevel = 50;
  String _lastLightingCondition = "Normal";

  String _lastExpression = "Neutral";
  int _expressionCounter = 0;
  static const int _expressionCounterThreshold = 3;

  Map<String, String> analyzeFaceCondition(Face face, double avgBrightness) {
    String expression = "Neutral";
    String lighting = "Normal";

    lighting = _analyzeLightingCondition(avgBrightness);

    if (face.leftEyeOpenProbability != null &&
        face.rightEyeOpenProbability != null &&
        face.smilingProbability != null) {
      log("Face detected: Left eye: ${face.leftEyeOpenProbability}, Right eye: ${face.rightEyeOpenProbability}, Smile: ${face.smilingProbability}");
      expression = _analyzeExpression(face.leftEyeOpenProbability!,
          face.rightEyeOpenProbability!, face.smilingProbability!);
    }

    return {
      'expression': expression,
      'lighting': lighting,
    };
  }

  String _analyzeExpression(
      double leftEyeOpen, double rightEyeOpen, double smileProb) {
    String currentExpression;

    double avgEyeOpen = (leftEyeOpen + rightEyeOpen) / 2;

    if (smileProb >= _smileThreshold && avgEyeOpen >= _eyeOpenThreshold) {
      currentExpression = "Happy";
    } else if (smileProb < 0.1 && avgEyeOpen >= 0.8) {
      currentExpression = "Neutral";
    } else if (smileProb < 0.2 &&
        avgEyeOpen >= _eyeOpenThreshold &&
        avgEyeOpen < 0.8) {
      currentExpression = "Sad";
    } else if (avgEyeOpen < _tiredEyeThreshold) {
      currentExpression = "Tired";
    } else if (avgEyeOpen < _eyeOpenThreshold && smileProb < _smileThreshold) {
      currentExpression = "Stressed";
    } else {
      currentExpression = "Neutral";
    }

    if (currentExpression == _lastExpression) {
      _expressionCounter++;
    } else {
      _expressionCounter = 0;
    }

    if (_expressionCounter >= _expressionCounterThreshold ||
        _lastExpression == "Neutral") {
      _lastExpression = currentExpression;
    }

    return _lastExpression;
  }

  String _analyzeLightingCondition(double brightness) {
    int lightingLevel = (brightness * 100).round();

    _lastLightingLevel =
        (_lastLightingLevel * 0.7 + lightingLevel * 0.3).round();

    String currentLighting;
    if (_lastLightingLevel <= _dimLightThreshold) {
      currentLighting = "Too Dark";
    } else if (_lastLightingLevel >= _brightLightThreshold) {
      currentLighting = "Too Bright";
    } else {
      currentLighting = "Normal";
    }

    if (currentLighting != _lastLightingCondition) {
      _lastLightingCondition = currentLighting;
    }

    return _lastLightingCondition;
  }

  static Future<double> calculateImageBrightness(InputImage inputImage) async {
    try {
      Uint8List? bytes;

      if (inputImage.bytes != null) {
        bytes = inputImage.bytes;
      } else if (inputImage.filePath != null) {
        final file = File(inputImage.filePath!);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        }
      }

      if (bytes == null) {
        return 0.5;
      }

      final img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        return 0.5;
      }

      int totalPixels = image.width * image.height;
      double totalBrightness = 0;

      int sampleRate = image.width > 1000 ? 10 : 5;
      int sampledPixels = 0;

      for (int y = 0; y < image.height; y += sampleRate) {
        for (int x = 0; x < image.width; x += sampleRate) {
          final img.Pixel pixel = image.getPixel(x, y);

          int r = pixel.r.toInt();
          int g = pixel.g.toInt();
          int b = pixel.b.toInt();
          double lumi = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;

          totalBrightness += lumi;
          sampledPixels++;
        }
      }

      double avgBrightness =
          sampledPixels > 0 ? totalBrightness / sampledPixels : 0.5;

      return avgBrightness;
    } catch (e) {
      log('Error calculating image brightness: $e');
      return 0.5;
    }
  }
}




