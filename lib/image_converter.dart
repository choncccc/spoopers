import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as imglib;
import 'package:camera/camera.dart';
import 'package:logger/logger.dart';
import 'dart:io';

imglib.Image convertToImage(CameraImage image) {
  var logger = Logger();
  try {
    print('Image format group: ${image.format.group}');
    switch (image.format.group) {
      case ImageFormatGroup.yuv420:
        return _convertYUV420(image);
      case ImageFormatGroup.bgra8888:
        return _convertBGRA8888(image);
      default:
        throw Exception('Image format not supported');
    }
  } catch (e) {
    logger.d("Error during conversion: $e");
    rethrow; // Propagate the error after logging it
  }
}

imglib.Image _convertBGRA8888(CameraImage image) {
  final bytes = image.planes[0].bytes;
  final img = imglib.Image.fromBytes(
    image.width,
    image.height,
    bytes,
    format: imglib.Format.bgra,
  );
  return img;
}

imglib.Image _convertYUV420(CameraImage image) {
  int width = image.width;
  int heighrt = image.height;
  var img = imglib.Image(width, heighrt);

  // UV plane stride and pixel stride
  final int uvRowStride = image.planes[1].bytesPerRow;
  final int uvPixelStride =
      image.planes[1].bytesPerPixel ?? 1; // Handle null case
  const int hexFF = 0xFF000000;

  for (int y = 0; y < heighrt; y++) {
    for (int x = 0; x < width; x++) {
      final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
      final int yIndex = y * width + x;
      final int yp = image.planes[0].bytes[yIndex];
      final int up = image.planes[1].bytes[uvIndex] - 128;
      final int vp = image.planes[2].bytes[uvIndex] - 128;

      int r = (yp + (1.402 * vp)).round().clamp(0, 255);
      int g = (yp - (0.344136 * up) - (0.714136 * vp)).round().clamp(0, 255);
      int b = (yp + (1.772 * up)).round().clamp(0, 255);

      img.data[yIndex] = hexFF | (b << 16) | (g << 8) | r;
    }
  }

  return img;
}
