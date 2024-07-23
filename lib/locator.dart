import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:spoofers/ml_service.dart';
import 'camera.service.dart';
import 'face_detector_service.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  try {
    // await Future.delayed(Duration(seconds: 1));

    // Register services as lazy singletons
    locator.registerLazySingleton(() => CameraService());
    locator.registerLazySingleton(() => FaceDetectorService());
    locator.registerLazySingleton(() => MLService());

    // Initialize any services if needed
    //await locator<FaceDetectorService>().initialize(basisImage);
  } catch (e) {
    debugPrint("Error setting up locator: $e");
  }
}
