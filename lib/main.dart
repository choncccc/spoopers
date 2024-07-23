import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;
import 'locator.dart';
import 'camera.service.dart';
import 'face_detector_service.dart';
import 'utils.dart';
import 'dart:developer';
import 'ml_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  final imglib.Image? basisImage = await loadBasisImage();
  if (basisImage == null) {
    print('Failed to load basis image. Exiting...');
    return;
  }
  await locator<FaceDetectorService>().initialize(basisImage);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Detection App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FaceDetectionScreen(),
    );
  }
}

class FaceDetectionScreen extends StatefulWidget {
  @override
  _FaceDetectionScreenState createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  final CameraService _cameraService = locator<CameraService>();
  final FaceDetectorService _faceDetectorService =
      locator<FaceDetectorService>();
  final MLService _mlService = locator<MLService>();

  @override
  void initState() {
    super.initState();
    _startUp();
  }

  void _startUp() async {
    await _cameraService.initialize();
    await _mlService.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _faceDetectorService.dispose();
    _mlService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Detection'),
      ),
      body: _cameraService.cameraController != null &&
              _cameraService.cameraController!.value.isInitialized
          ? Stack(
              children: [
                CameraPreview(_cameraService.cameraController!),
                if (_faceDetectorService.faceDetected)
                  Center(
                    child: Text(
                      _faceDetectorService.isSpoofed
                          ? 'Face Detected (Spoofed)'
                          : 'Face Detected (Live)',
                      style: TextStyle(
                        color: _faceDetectorService.isSpoofed
                            ? Colors.red
                            : Colors.green,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (!_faceDetectorService.faceDetected)
                  const Center(
                    child: Text(
                      'No Face Detected',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
