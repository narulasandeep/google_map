import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService extends GetxService {
  final Rx<PermissionStatus> locationStatus = PermissionStatus.denied.obs;

  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      locationStatus.value = status;

      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        // Request again
        final secondRequest = await Permission.location.request();
        locationStatus.value = secondRequest;
        return secondRequest.isGranted;
      }
      return false;
    } catch (e) {
      Get.log('Permission error: $e');
      return false;
    }
  }

  Future<bool> checkLocationPermission() async {
    try {
      final status = await Permission.location.status;
      locationStatus.value = status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}