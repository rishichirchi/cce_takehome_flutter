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

  // Face detection related variables
  List<Face> _faces = [];
  late FaceDetector _faceDetector;
  File? _lastImage;
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    // Initialize the face detector
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

    // Start the face detection timer
    _startFaceDetectionTimer();
  }

  void _startFaceDetectionTimer() {
    // Process image every 500ms
    _detectionTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (!_isProcessing && _cameraController.value.isInitialized) {
        _captureAndDetectFaces();
      }
    });
  }

  Future<void> _captureAndDetectFaces() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Take a picture
      final XFile file = await _cameraController.takePicture();

      // Convert to file for processing
      _lastImage = File(file.path);

      // Create InputImage from file
      final inputImage = InputImage.fromFile(_lastImage!);

      // Process the image
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
          // Camera preview
          CameraPreview(_cameraController),

          // Face bounding boxes overlay
          CustomPaint(
            painter: FacePainter(
              faces: _faces,
              imageSize: Size(
                _cameraController.value.previewSize!
                    .height, // Note: might need to swap width/height
                _cameraController
                    .value.previewSize!.width, // depending on orientation
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
    // For camera preview, we need to handle the aspect ratio differences
    // and potential rotation between the camera image and the screen
    final double imageAspectRatio = imageSize.width / imageSize.height;
    final double screenAspectRatio = screenSize.width / screenSize.height;

    double scaleX, scaleY, offsetX = 0, offsetY = 0;

    // Account for the fact that camera preview might be rotated 90 degrees
    final bool isPortraitMode = screenSize.height > screenSize.width;
    final bool needRotation = (isPortraitMode && imageAspectRatio > 1) ||
        (!isPortraitMode && imageAspectRatio < 1);

    if (needRotation) {
      // If image is rotated 90 degrees
      scaleX = screenSize.width / imageSize.height;
      scaleY = screenSize.height / imageSize.width;
    } else {
      scaleX = screenSize.width / imageSize.width;
      scaleY = screenSize.height / imageSize.height;
    }

    // Use the smaller scale to fit the entire image
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

      // Mirror the bounding box horizontally if using front camera
      if (isFrontCamera) {
        final left = imageSize.width - rect.right;
        final right = imageSize.width - rect.left;
        rect = Rect.fromLTRB(left, rect.top, right, rect.bottom);
      }

      // Apply rotation if needed
      Rect scaledRect;
      if (needRotation) {
        // Swap and transform coordinates for 90-degree rotation
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
        // Normal scaling without rotation
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
