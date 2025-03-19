import 'dart:async';
import 'dart:io';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:face_detector/provider/emotion_provider.dart';
import 'package:face_detector/service/api_service.dart';
import 'package:face_detector/utils/enhanced_face_painter.dart';
import 'package:face_detector/widget/face_condition_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../utils/face_condition_detector.dart';

class EnhancedCameraScreen extends ConsumerStatefulWidget {
  final bool showDebugInfo;

  const EnhancedCameraScreen({
    super.key,
    this.showDebugInfo = false,
  });

  @override
  EnhancedCameraScreenState createState() => EnhancedCameraScreenState();
}

class EnhancedCameraScreenState extends ConsumerState<EnhancedCameraScreen>
    with WidgetsBindingObserver {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  ApiService apiService = ApiService();

  List<Face> _faces = [];
  late FaceDetector _faceDetector;
  File? _lastImage;
  Timer? _detectionTimer;

  final FaceConditionDetector _conditionDetector = FaceConditionDetector();
  Map<String, String> _faceCondition = {
    'expression': 'Neutral',
    'lighting': 'Normal'
  };

  Map<String, String> emotionCondition = {
    'expression': 'Neutral',
    'lighting': 'Normal',
  };

  double _avgBrightness = 0.5;

  bool _autoAdjustBrightness = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final options = FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.accurate,
    );
    _faceDetector = FaceDetector(options: options);

    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _detectionTimer?.cancel();
      _cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    final frontCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController.initialize();

      if (_cameraController.value.isInitialized) {
        await _cameraController.setExposureMode(ExposureMode.auto);
        await _cameraController.setFlashMode(FlashMode.off);
        await _cameraController.setFocusMode(FocusMode.auto);
      }

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      _startFaceDetectionTimer();
    } catch (e) {
      log("Error initializing camera: $e");
    }
  }

  void _startFaceDetectionTimer() {
    _detectionTimer = Timer.periodic(Duration(milliseconds: 300), (timer) {
      if (!_isProcessing && _cameraController.value.isInitialized) {
        _captureAndAnalyzeFace();
      }
    });
  }

  Future<void> _captureAndAnalyzeFace() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final XFile file = await _cameraController.takePicture();

      _lastImage = File(file.path);

      final inputImage = InputImage.fromFile(_lastImage!);

      _avgBrightness =
          await FaceConditionDetector.calculateImageBrightness(inputImage);

      await _detectAndAnalyzeFace(inputImage, file.path);
    } catch (e) {
      log("Error capturing image: $e");
    } finally {
      _isProcessing = false;

      if (_lastImage != null && await _lastImage!.exists()) {
        try {
          await _lastImage!.delete();
        } catch (e) {
          log("Error deleting temporary file: $e");
        }
      }
    }
  }

  Future<void> _detectAndAnalyzeFace(
      InputImage inputImage, String imagePath) async {
    try {
      final enhancedInputImage = ImageProcessingExtensions.enhanceForLighting(
          inputImage, _faceCondition['lighting'] ?? 'Normal');

      final faces = await _faceDetector.processImage(enhancedInputImage);

      var emotion = await apiService.analyzeEmotion(imagePath, faces.first);

      ref.read(emotionProvider.notifier).setEmotion(emotion!);

      setState(() {
        emotionCondition['expression'] = ref.watch(emotionProvider);
      });

      if (mounted) {
        setState(() {
          _faces = faces;

          if (faces.isNotEmpty) {
            _faceCondition = _conditionDetector.analyzeFaceCondition(
                faces.first, _avgBrightness);
          }
        });
      }

      if (_autoAdjustBrightness) {
        _adjustForLightingConditions(_faceCondition['lighting'] ?? 'Normal');
      }

      log("Detected ${faces.length} faces");
      if (widget.showDebugInfo && faces.isNotEmpty) {
        _logFaceDetails(faces.first);
      }
    } catch (e) {
      log("Error detecting faces: $e");
    }
  }

  void _logFaceDetails(Face face) {
    log("Face details:");
    log("- Bounding box: ${face.boundingBox}");
    log("- Smiling probability: ${face.smilingProbability}");
    log("- Left eye open probability: ${face.leftEyeOpenProbability}");
    log("- Right eye open probability: ${face.rightEyeOpenProbability}");
    log("- Tracking ID: ${face.trackingId}");
    log("- Head euler angle Y: ${face.headEulerAngleY}");
    log("- Head euler angle Z: ${face.headEulerAngleZ}");
    log("- Number of landmarks: ${face.landmarks.length}");
  }

  void _adjustForLightingConditions(String lighting) {
    switch (lighting) {
      case 'Too Dark':
        try {
          _cameraController.setExposureOffset(1.5);
        } catch (e) {
          log("Error adjusting for dark lighting: $e");
        }
        break;
      case 'Too Bright':
        try {
          _cameraController.setExposureOffset(-1.5);
        } catch (e) {
          log("Error adjusting for bright lighting: $e");
        }
        break;
      default:
        try {
          _cameraController.setExposureOffset(0.0);
        } catch (e) {
          log("Error resetting exposure: $e");
        }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detectionTimer?.cancel();
    _cameraController.dispose();
    _faceDetector.close();
    _lastImage?.delete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera...'),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Condition Detection'),
        actions: [
          // Toggle debug info
          IconButton(
            icon: Icon(widget.showDebugInfo
                ? Icons.bug_report
                : Icons.bug_report_outlined),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => EnhancedCameraScreen(
                    showDebugInfo: !widget.showDebugInfo,
                  ),
                ),
              );
            },
            tooltip: 'Toggle Debug Info',
          ),
          IconButton(
            icon: Icon(_autoAdjustBrightness
                ? Icons.brightness_auto
                : Icons.brightness_medium),
            onPressed: () {
              setState(() {
                _autoAdjustBrightness = !_autoAdjustBrightness;
              });
            },
            tooltip: 'Toggle Auto Brightness',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController),
          CustomPaint(
            painter: EnhancedFacePainter(
              faces: _faces,
              imageSize: Size(
                _cameraController.value.previewSize!.width,
                _cameraController.value.previewSize!.height,
              ),
              screenSize: MediaQuery.of(context).size,
              isFrontCamera: _cameraController.description.lensDirection ==
                  CameraLensDirection.front,
              faceCondition: _faceCondition,
            ),
          ),
          FaceConditionOverlay(
            condition: emotionCondition,
            showDebugInfo: widget.showDebugInfo,
          ),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Light: ${(_avgBrightness * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          if (widget.showDebugInfo)
            Positioned(
              bottom: 60,
              left: 16,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Mode Active',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Camera: ${_cameraController.description.name}',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Resolution: ${_cameraController.value.previewSize?.width}x${_cameraController.value.previewSize?.height}',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Auto-adjust: ${_autoAdjustBrightness ? "ON" : "OFF"}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
