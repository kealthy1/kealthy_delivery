import 'package:permission_handler/permission_handler.dart';

class LocationPermissionService {
  Future<bool> requestPermissions() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      return true;
    } else {
      return false;
    }
  }
}
