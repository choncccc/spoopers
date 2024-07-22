import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;
import 'locator.dart';
import 'services/camera.service.dart';
import 'services/face_detector_service.dart';
import 'utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator(); // Await the Future returned by setupLocator
  imglib.Image basisImage = await loadBasisImage();
  locator<FaceDetectorService>().initialize();
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
  final FaceDetectorService _faceDetectorService = locator<FaceDetectorService>();

  @override
  void initState() {
    super.initState();
    _startUp();
  }

  void _startUp() async {
    await _cameraService.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _faceDetectorService.dispose();
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
                  const Center(
                    child: Text(
                      'Face Detected',
                      style: TextStyle(
                        color: Colors.green,
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
