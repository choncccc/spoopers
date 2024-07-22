import 'package:flutter/services.dart';
import 'package:image/image.dart' as imglib;

Future<imglib.Image> loadBasisImage() async {
  try {
    // Load the image from assets
    final ByteData data = await rootBundle.load('assets/img.png');
    final Uint8List bytes = data.buffer.asUint8List();
    
    // Decode image using the image package
    final imglib.Image image = imglib.decodeImage(Uint8List.fromList(bytes))!;
    
    return image;
  } catch (e) {
    print('Error loading basis image: $e');
    rethrow;
  }
}
