import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  List<Face> _faces = [];
  late FaceDetector _faceDetector;
  File? _lastImage;
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    final options = FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
    );
    _faceDetector = FaceDetector(options: options);

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    final frontCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _cameraController.initialize();
    if (!mounted) return;

    setState(() {
      _isCameraInitialized = true;
    });

    _startFaceDetectionTimer();
  }

  void _startFaceDetectionTimer() {
    _detectionTimer = Timer.periodic(Duration(milliseconds: 300), (timer) {
      if (!_isProcessing && _cameraController.value.isInitialized) {
        _captureAndDetectFaces();
      }
    });
  }

  Future<void> _captureAndDetectFaces() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final XFile file = await _cameraController.takePicture();

      _lastImage = File(file.path);

      final inputImage = InputImage.fromFile(_lastImage!);

      await _detectFaces(inputImage);
    } catch (e) {
      log("Error capturing image: $e");
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _detectFaces(InputImage inputImage) async {
    try {
      final faces = await _faceDetector.processImage(inputImage);

      if (mounted) {
        setState(() {
          _faces = faces;
        });
      }

      log("Detected ${faces.length} faces");
      for (Face face in faces) {
        log("Face bounding box: ${face.boundingBox}");
      }
    } catch (e) {
      log("Error detecting faces: $e");
    }
  }

  void switchCamera() {
    if (_cameras.length < 2) return;

    final CameraDescription newCamera = _cameraController.description == _cameras.first
      ? _cameras.last
      : _cameras.first;

    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _cameraController.dispose();
    _faceDetector.close();
    // Delete any temporary files
    _lastImage?.delete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Face Detection')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController),

          CustomPaint(
            painter: FacePainter(
              faces: _faces,
              imageSize: Size(
                _cameraController.value.previewSize!
                    .height, 
                _cameraController
                    .value.previewSize!.width, 
              ),
              screenSize: MediaQuery.of(context).size,
              isFrontCamera: _cameraController.description.lensDirection ==
                  CameraLensDirection.front,
            ),
          ),
          // Face count indicator
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Faces detected: ${_faces.length}',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton.filled(onPressed: switchCamera, icon: Icon(Icons.switch_camera_outlined))
            ),
          ),
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final Size screenSize;
  final bool isFrontCamera;

  FacePainter({
    required this.faces,
    required this.imageSize,
    required this.screenSize,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width == 0 || imageSize.height == 0) return;

    final double imageAspectRatio = imageSize.width / imageSize.height;
    final double screenAspectRatio = screenSize.width / screenSize.height;

    double scaleX, scaleY, offsetX = 0, offsetY = 0;

    final bool isPortraitMode = screenSize.height > screenSize.width;
    final bool needRotation = (isPortraitMode && imageAspectRatio > 1) ||
        (!isPortraitMode && imageAspectRatio < 1);

    if (needRotation) {
      scaleX = screenSize.width / imageSize.height;
      scaleY = screenSize.height / imageSize.width;
    } else {
      scaleX = screenSize.width / imageSize.width;
      scaleY = screenSize.height / imageSize.height;
    }

    final double scale = math.min(scaleX, scaleY);

    // Center the image
    if (scaleX > scaleY) {
      offsetX = (screenSize.width - (imageSize.width * scale)) / 2;
    } else {
      offsetY = (screenSize.height - (imageSize.height * scale)) / 2;
    }

    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final face in faces) {
      Rect rect = face.boundingBox;

      if (isFrontCamera) {
        final left = imageSize.width - rect.right;
        final right = imageSize.width - rect.left;
        rect = Rect.fromLTRB(left, rect.top, right, rect.bottom);
      }

      Rect scaledRect;
      if (needRotation) {
        final double rotatedLeft = rect.top;
        final double rotatedTop = imageSize.width - rect.right;
        final double rotatedWidth = rect.height;
        final double rotatedHeight = rect.width;

        scaledRect = Rect.fromLTWH(
          rotatedLeft * scale + offsetX,
          rotatedTop * scale + offsetY,
          rotatedWidth * scale,
          rotatedHeight * scale,
        );
      } else {
        scaledRect = Rect.fromLTWH(
          rect.left * scale + offsetX,
          rect.top * scale + offsetY,
          rect.width * scale,
          rect.height * scale,
        );
      }

      canvas.drawRect(scaledRect, paint);
    }
  }


  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.screenSize != screenSize ||
        oldDelegate.isFrontCamera != isFrontCamera;
  }
}
