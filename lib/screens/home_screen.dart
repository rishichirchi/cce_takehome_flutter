import 'package:face_detector/screens/enhanced_camera_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Condition Detector'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/face_icon.png',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.face,
                size: 120,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Face Condition Detector',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Analyze facial expressions and adjust to any lighting condition',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 48),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text('Start Detection'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EnhancedCameraScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            TextButton.icon(
              icon: Icon(Icons.bug_report),
              label: Text('Debug Mode'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        EnhancedCameraScreen(showDebugInfo: true),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
