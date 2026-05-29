import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<void> requestCameraPermission() async {
    await Permission.camera.request();
  }

  Future<void> requestBluetoothPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location, // Location is often needed for Bluetooth scanning on older Android versions
    ].request();
  }
}
