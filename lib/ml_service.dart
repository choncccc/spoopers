import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:spoofers/image_converter.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as imglib;
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:tflite_flutter/tflite_flutter.dart';

class MLService {
  var logger = Logger();
  Interpreter? _interpreter;
  double threshold = 0.5;
  List _predictedData = [];
  List get predictedData => _predictedData;
  double dist = 0;

  // = = = = = = = = = = = //
  //  ANTI SPOOFING (ONNX) //
  // = = = = = = = = = = = //

  Future<OrtSession> loadModelFromAssets() async {
    OrtEnv.instance.init();
    final sessionOptions = OrtSessionOptions();
    const assetFileName = 'assets/2.7_80x80_MiniFASNetV2.onnx';

    final rawAssetFile = await rootBundle.load(assetFileName);
    final bytes = rawAssetFile.buffer.asUint8List();
    final session = OrtSession.fromBuffer(bytes, sessionOptions);

    return session;
  }

  Future<List?> MODIFIEDisFaceSpoofedWithModel(
      CameraImage cameraImage, Face? face) async {
    logger.d("===> isFaceSpoofedWithModel Starts");

    try {
      final session = await loadModelFromAssets();

      if (face == null) throw Exception('Face is null');

      final processedData = await _MODIFIEDpreProcess(cameraImage, face);
      final processedImg = processedData[0] as imglib.Image;
      final input = processedData[1] as Float32List;
      final shape = [1, 3, 80, 80];
      final inputOrt = OrtValueTensor.createTensorWithDataList(input, shape);
      final inputName = session.inputNames[0];

      final inputs = {inputName: inputOrt};
      final runOptions = OrtRunOptions();
      final outputs = session.run(runOptions, inputs);

      final FAStensor = outputs[0]?.value;
      logger.d("===> outputs.length: ${outputs.length}");
      logger.d("===> FAStensor: $FAStensor");

      List<double> FASTensorList = [];
      if (FAStensor != null &&
          FAStensor is List<List<double>> &&
          FAStensor.isNotEmpty) {
        FASTensorList = FAStensor[0];
      }

      List<double> probabilities = softmax(FASTensorList);
      print("===> probabilities: $probabilities");

      // Release ONNX components
      inputOrt.release();
      runOptions.release();
      session.release();
      logger.d("===> isFaceSpoofedWithModel Ends");
      return [processedImg, probabilities];
    } catch (e) {
      logger.d('An error occurred: $e');
      return null;
    }
  }

  Future<List> _MODIFIEDpreProcess(CameraImage image, Face faceDetected) async {
    imglib.Image croppedImage = _cropFace(image, faceDetected);
    imglib.Image img = imglib.copyResizeCropSquare(croppedImage, 80);

    final directory = await path.getExternalStorageDirectory();
    final file = File(join(directory!.path, 'resized.png'));

    try {
      await file.writeAsBytes(imglib.encodePng(img));
      logger.d("===> file.path: ${file.path}");
    } catch (e) {
      logger.d('Error: $e');
    }

    Float32List imageAsList = imageToByteListFloat32(croppedImage, 80);
    return [img, imageAsList];
  }

  // = = = = = = = = = = = = = = = //
  //   FACE RECOGNITION (TFLITE)   //
  // = = = = = = = = = = = = = = = //

  Future<void> initialize() async {
    late Delegate delegate;
    try {
      if (Platform.isAndroid) {
        delegate = GpuDelegateV2(
          options: GpuDelegateOptionsV2(isPrecisionLossAllowed: false),
        );
      } else if (Platform.isIOS) {
        delegate = GpuDelegate(
          options: GpuDelegateOptions(
            allowPrecisionLoss: true,
          ),
        );
      }
      var interpreterOptions = InterpreterOptions()..addDelegate(delegate);

      _interpreter = await Interpreter.fromAsset(
          'assets/ep050-loss23.614.tflite',
          options: interpreterOptions);
    } catch (e) {
      logger.d('Failed to load model.');
      print(e);
    }
  }

  Future<void> setCurrentPrediction(CameraImage cameraImage, Face? face) async {
    if (_interpreter == null) throw Exception('Interpreter is null');
    if (face == null) throw Exception('Face is null');

    imglib.Image croppedImage = _cropFace(cameraImage, face);
    imglib.Image img = imglib.copyResizeCropSquare(croppedImage, 112);
    List input = imageToByteListFloat32(img, 112);

    input = input.reshape([1, 112, 112, 3]);
    logger.d("==> input : $input");
    List output = List.generate(1, (index) => List.filled(256, 0));

    _interpreter?.run(input, output);
    output = output.reshape([256]);

    _predictedData = List.from(output);
  }

  List<double> softmax(List<double> scores) {
    double maxScore = scores.reduce(max);
    List<double> expScores =
        scores.map((score) => exp(score - maxScore)).toList();
    double sumExpScores = expScores.reduce((a, b) => a + b);
    return expScores.map((score) => score / sumExpScores).toList();
  }

  imglib.Image _cropFace(CameraImage image, Face faceDetected) {
    imglib.Image convertedImage = _convertCameraImage(image);
    double x = faceDetected.boundingBox.left - 10.0;
    double y = faceDetected.boundingBox.top - 10.0;
    double w = faceDetected.boundingBox.width + 10.0;
    double h = faceDetected.boundingBox.height + 10.0;
    return imglib.copyCrop(
        convertedImage, x.round(), y.round(), w.round(), h.round());
  }

  imglib.Image _convertCameraImage(CameraImage image) {
    var img = convertToImage(image);
    return imglib.copyRotate(img, -90);
  }

  Float32List imageToByteListFloat32(imglib.Image image, int imageSize) {
    var convertedBytes = Float32List(imageSize * imageSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < imageSize; i++) {
      for (var j = 0; j < imageSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = imglib.getRed(pixel) / 1;
        buffer[pixelIndex++] = imglib.getGreen(pixel) / 1;
        buffer[pixelIndex++] = imglib.getBlue(pixel) / 1;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }

  double _euclideanDistance(List? e1, List? e2) {
    if (e1 == null || e2 == null) throw Exception("Null argument");

    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i] - e2[i]), 2);
    }
    return sqrt(sum);
  }

  void setPredictedData(value) {
    _predictedData = value;
  }

  void dispose() {
    _interpreter?.close();
  }
}

extension Precision on double {
  double toFloat() {
    return double.parse(toStringAsFixed(2));
  }
}
