import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as imglib;
import 'package:logger/logger.dart';
import 'ml_service.dart';
import 'package:logger/logger.dart';
import 'dart:io';

class FaceDetectorService {
  var logger = Logger();
  late FaceDetector _faceDetector;
  final MLService _mlService = MLService();

  bool _faceDetected = false;
  bool get faceDetected => _faceDetected;
  bool _isSpoofed = false;
  bool get isSpoofed => _isSpoofed;

  Future<void> initialize(imglib.Image basisImage) async {
    try {
      _faceDetector = GoogleMlKit.vision.faceDetector(
        FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableClassification: true,
          enableTracking: true,
        ),
      );
      await _mlService.initialize();
    } catch (e) {
      logger.d('Error initializing FaceDetectorService: $e');
      // handle error here
    }
  }

  Future<void> detectFaces(CameraImage image) async {
    try {
      const InputImageRotation rotation = InputImageRotation.rotation0deg;

      final InputImageData inputImageData = InputImageData(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        imageRotation: rotation,
        inputImageFormat: _getInputImageFormat(image.format.group),
        planeData: image.planes.map(
          (plane) {
            return InputImagePlaneMetadata(
              bytesPerRow: plane.bytesPerRow,
              height: plane.height,
              width: plane.width,
            );
          },
        ).toList(),
      );

      final InputImage inputImage = InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        inputImageData: inputImageData,
      );

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        _faceDetected = true;
        final face = faces.first; // change this if there are more faces
        final result =
            await _mlService.MODIFIEDisFaceSpoofedWithModel(image, face);
        if (result != null) {
          final probabilities = result[1] as List<double>;
          _isSpoofed = probabilities[0] > _mlService.threshold;
        }
      } else {
        _faceDetected = false;
        _isSpoofed = false;
      }
    } catch (e) {
      debugPrint('Error detecting faces: $e');
      _faceDetected = false;
      _isSpoofed = false;
    }
  }

  InputImageFormat _getInputImageFormat(ImageFormatGroup formatGroup) {
    switch (formatGroup) {
      case ImageFormatGroup.yuv420:
        return InputImageFormat.yuv420;
      case ImageFormatGroup.bgra8888:
        return InputImageFormat.bgra8888;
      default:
        throw Exception('Image format not supported');
    }
  }

  void dispose() {
    try {
      _faceDetector.close();
    } catch (e) {
      //print for debugging.
      logger.d('Error disposing FaceDetectorService: $e');
    }
  }
}
