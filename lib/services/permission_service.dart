import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<void> requestCameraPermission() async {
    await Permission.camera.request();
  }
}
