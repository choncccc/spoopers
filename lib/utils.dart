import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:developer';
import 'package:image/image.dart' as imglib;

Future<imglib.Image?> loadBasisImage() async {
  try {
    // load the image from assets
    final ByteData data = await rootBundle.load('assets/img.jpg');
    final Uint8List bytes = data.buffer.asUint8List();

    final imglib.Image? image = imglib.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    return image;
  } catch (e) {
    log('Error loading basis image: $e');
    return null; // null if error
  }
}
