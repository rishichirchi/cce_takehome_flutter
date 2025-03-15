# Face Condition Detector

The Face Condition Detector is a Flutter application that uses the device's camera to detect faces and analyze facial expressions. It leverages the Google ML Kit for face detection and provides features such as automatic brightness adjustment and debug mode for developers.

## Task: Face Condition Detection in Any Lighting
Language: Flutter
Must work in: Android, iOS (OK if you can just test in one, but we will test in both and if it doesn't work, we'll send you the debug info so you can fix it).

Write a Flutter app that detects a person's face and analyzes its condition in real-time, even in different lighting environments.

For example: The app should identify if the person looks tired, stressed, happy, or sad. It should also detect if the lighting is too bright or too dim and adjust the face detection accordingly.

It must be fast and work in all lighting conditions!

## Features

- **Face Detection**: Detects faces using the device's camera.
- **Facial Expression Analysis**: Analyzes facial expressions and provides feedback.
- **Lighting Adjustment**: Automatically adjusts to different lighting conditions.
- **Debug Mode**: Provides additional information for developers to debug the face detection process.

## Project Structure

```
.
├── .dart_tool/
├── .idea/
├── android/
├── build/
├── ios/
├── lib/
│   ├── screens/
│   │   ├── camera_screen.dart
│   │   ├── enhanced_camera_screen.dart
│   │   └── home_screen.dart
│   ├── utils/
│   │   └── enhanced_face_painter.dart
│   └── widget/
│       └── face_condition_overlay.dart
├── linux/
├── macos/
├── test/
├── web/
├── windows/
├── .flutter-plugins
├── .flutter-plugins-dependencies
├── .gitignore
├── .metadata
├── analysis_options.yaml
├── pubspec.lock
├── pubspec.yaml
└── README.md
```

## Getting Started

### Prerequisites

- **Flutter SDK**: Install Flutter
- **Dart SDK**: Included with Flutter
- **Android Studio or Xcode**: For running on Android or iOS devices

### Installation

Clone the repository:

```sh
git clone https://github.com/yourusername/face_condition_detector.git
cd face_condition_detector
```

Install dependencies:

```sh
flutter pub get
```

Run the app:

```sh
flutter run
```

## Usage

### Home Screen

The home screen provides an introduction to the app and options to start face detection or enter debug mode.

### Camera Screen

The camera screen initializes the camera and starts face detection. It captures images periodically and processes them to detect faces.

### Enhanced Camera Screen

The enhanced camera screen provides additional features such as automatic brightness adjustment and debug information. It uses different image formats and camera settings for improved performance.

## Code Overview

- **home_screen.dart**: The home screen of the app. It provides buttons to navigate to the camera screen or the enhanced camera screen.
- **camera_screen.dart**: Handles camera initialization and face detection. It uses the camera package to control the device's camera and the google_mlkit_face_detection package for face detection.
- **enhanced_camera_screen.dart**: An enhanced version of the camera screen with additional features such as automatic brightness adjustment and debug mode.
- **enhanced_face_painter.dart**: A custom painter that draws detected faces and their conditions on the screen.
- **face_condition_overlay.dart**: A widget that overlays face condition information on the camera preview.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgements

- Flutter
- Google ML Kit
- camera package