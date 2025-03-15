import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:math' as math;

class EnhancedFacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final Size screenSize;
  final bool isFrontCamera;
  final Map<String, String> faceCondition;

  final double xOffsetAdjustment =
      100;
  final double yOffsetAdjustment =
      -400.0;
  final double widthAdjustment = 50.0;
  final double heightAdjustment = 50.0;

  EnhancedFacePainter({
    required this.faces,
    required this.imageSize,
    required this.screenSize,
    required this.isFrontCamera,
    required this.faceCondition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width == 0 || imageSize.height == 0) return;

    final double scaleX = screenSize.width / imageSize.width;
    final double scaleY = screenSize.height / imageSize.height;
    final double scale = math.min(scaleX, scaleY);

    final double offsetX = (screenSize.width - (imageSize.width * scale)) / 2;
    final double offsetY = (screenSize.height - (imageSize.height * scale)) / 2;

    Paint facePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    switch (faceCondition['expression']) {
      case 'Happy':
        facePaint.color = Colors.green;
        break;
      case 'Sad':
        facePaint.color = Colors.blue;
        break;
      case 'Tired':
        facePaint.color = Colors.purple;
        break;
      case 'Stressed':
        facePaint.color = Colors.red;
        break;
      default:
        facePaint.color = Colors.yellow;
    }

    if (faceCondition['lighting'] == 'Too Dark') {
      facePaint.strokeWidth = 3.0;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, screenSize.width, screenSize.height),
        Paint()..color = Colors.blue.withOpacity(0.1),
      );
    }

    if (faceCondition['lighting'] == 'Too Bright') {
      facePaint.strokeWidth = 2.5;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, screenSize.width, screenSize.height),
        Paint()..color = Colors.black.withOpacity(0.05),
      );
    }

    for (final face in faces) {
      Rect originalRect = face.boundingBox;

      double left = originalRect.left;
      double top = originalRect.top;
      double right = originalRect.right;
      double bottom = originalRect.bottom;

      if (isFrontCamera) {
        double tempLeft = left;
        left = imageSize.width - right;
        right = imageSize.width - tempLeft;
      }

      left += xOffsetAdjustment;
      top += yOffsetAdjustment;
      right += xOffsetAdjustment + widthAdjustment;
      bottom += yOffsetAdjustment + heightAdjustment;

      left = math.max(0, left);
      top = math.max(0, top);
      right = math.min(imageSize.width, right);
      bottom = math.min(imageSize.height, bottom);

      final Rect scaledRect = Rect.fromLTRB(
        left * scale + offsetX,
        top * scale + offsetY,
        right * scale + offsetX,
        bottom * scale + offsetY,
      );

      canvas.drawRect(scaledRect, facePaint);

      if (face.landmarks.isNotEmpty) {
        final landmarkPaint = Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.fill
          ..strokeWidth = 2.0;

        face.landmarks.forEach((type, point) {
          if (point != null) {
            double x = point.position.x.toDouble();
            double y = point.position.y.toDouble();

            if (isFrontCamera) {
              x = imageSize.width - x;
            }

            y += yOffsetAdjustment;

            final scaledPoint = Offset(
              x * scale + offsetX,
              y * scale + offsetY,
            );

            canvas.drawCircle(scaledPoint, 2.0, landmarkPaint);
          }
        });
      }
    }
  }

  @override
  bool shouldRepaint(EnhancedFacePainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.screenSize != screenSize ||
        oldDelegate.isFrontCamera != isFrontCamera ||
        oldDelegate.faceCondition != faceCondition;
  }
}

extension ImageProcessingExtensions on InputImage {
  static InputImage enhanceForLighting(
      InputImage image, String lightingCondition) {
    return image;
  }
}