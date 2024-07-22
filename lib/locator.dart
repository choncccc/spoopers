import 'package:get_it/get_it.dart';
import 'services/camera.service.dart';
import 'services/face_detector_service.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  // Simulate async work
  await Future.delayed(Duration(seconds: 1));

  locator.registerLazySingleton(() => CameraService());
  locator.registerLazySingleton(() => FaceDetectorService());
}
