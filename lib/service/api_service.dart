import 'dart:developer';
import 'dart:io';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class ApiService {
  final gemini = Gemini.instance;

  Future<String?> analyzeEmotion(String imagePath, Face face) async {
    Map<String, dynamic> faceData = _extractFaceData(face);

    log("Sending face data to Gemini API: $faceData");
    File imageFile = File(imagePath);

    var response = await gemini.textAndImage(
       text: "Identify the emotion of this face. These are the properties of the image, use it for context: ${faceData.toString()}. The emotions can be either happy, sad, tired, stressed or neutral. Give the output as a single word from one of these emotions.",
       images: [imageFile.readAsBytesSync()]
    );

    log("Received response from Gemini API: ${response!.output}");
    return response.output;
  }

  String _extractEmotion(dynamic response) {
    final validEmotions = ['happy', 'sad', 'tired', 'stressed', 'neutral'];
    String responseText = '';
    if (response != null && response.candidates != null && response.candidates.isNotEmpty) {
      responseText = response.candidates.first.content.parts.first.text ?? '';
    }
    String lowercaseResponse = responseText.toLowerCase();
    for (String emotion in validEmotions) {
      if (lowercaseResponse.contains(emotion)) {
        return emotion;
      }
    }
    return 'neutral';
  }

  Map<String, dynamic> _extractFaceData(Face face) {
    return {
      "boundingBox": _extractBoundingBox(face),
      "headEulerAngles": _extractHeadAngles(face),
      "probabilities": _extractProbabilities(face),
      "contours": _extractContours(face),
      "trackingId": face.trackingId ?? -1,
    };
  }

  Map<String, double> _extractBoundingBox(Face face) {
    return {
      "left": face.boundingBox.left,
      "top": face.boundingBox.top,
      "right": face.boundingBox.right,
      "bottom": face.boundingBox.bottom,
    };
  }

  Map<String, double?> _extractHeadAngles(Face face) {
    return {
      "roll": face.headEulerAngleX,
      "yaw": face.headEulerAngleY, 
      "pitch": face.headEulerAngleZ,
    };
  }

  Map<String, double> _extractProbabilities(Face face) {
    return {
      "smilingProbability": face.smilingProbability ?? 0.0,
      "leftEyeOpenProbability": face.leftEyeOpenProbability ?? 0.0,
      "rightEyeOpenProbability": face.rightEyeOpenProbability ?? 0.0,
    };
  }

  Map<String, List<Map<String, int>>> _extractContours(Face face) {
    return {
      "face": _extractPoints(face.contours[FaceContourType.face]),
      "leftEye": _extractPoints(face.contours[FaceContourType.leftEye]),
      "rightEye": _extractPoints(face.contours[FaceContourType.rightEye]),
      "upperLipTop": _extractPoints(face.contours[FaceContourType.upperLipTop]),
      "lowerLipBottom": _extractPoints(face.contours[FaceContourType.lowerLipBottom]),
      "noseBridge": _extractPoints(face.contours[FaceContourType.noseBridge]),
      "noseBottom": _extractPoints(face.contours[FaceContourType.noseBottom]),
    };
  }

  List<Map<String, int>> _extractPoints(FaceContour? contour) {
    if (contour == null) return [];
    return contour.points.map((point) => {"x": point.x, "y": point.y}).toList();
  }
}
