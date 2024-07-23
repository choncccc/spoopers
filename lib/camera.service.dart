import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:logger/logger.dart';

class CameraService {
  var logger = Logger();
  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;

  InputImageRotation? _cameraRotation;
  InputImageRotation? get cameraRotation => _cameraRotation;

  Function(CameraImage)? onLatestImageAvailable;

  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      CameraDescription description = await _getCameraDescription();
      await _setupCameraController(description: description);
      _cameraRotation = rotationIntToImageRotation(
        description.sensorOrientation,
      );
      _isInitialized = true;
    } catch (e) {
      logger.d('Error initializing camera: $e');
      // Handle errorsf    
      }
  }

  Future<CameraDescription> _getCameraDescription() async {
    try {
      List<CameraDescription> cameras = await availableCameras();
      return cameras.firstWhere((CameraDescription camera) =>
          camera.lensDirection == CameraLensDirection.front);
    } catch (e) {
      logger.d('Error getting camera description: $e');
      throw Exception('No front-facing camera found');
    }
  }

  Future _setupCameraController({
    required CameraDescription description,
  }) async {
    try {
      _cameraController = CameraController(
        description,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController?.initialize();
      _cameraController?.startImageStream((image) {
        if (onLatestImageAvailable != null) {
          onLatestImageAvailable!(image);
        }
      });
    } catch (e) {
      logger.d('Error setting up camera controller: $e');
      throw Exception('Failed to set up camera controller');
    }
  }

  InputImageRotation rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  void dispose() async {
    try {
      await _cameraController?.dispose();
      _cameraController = null;
      _isInitialized = false;
    } catch (e) {
      logger.d('Error disposing camera controller: $e');
    }
  }
}
