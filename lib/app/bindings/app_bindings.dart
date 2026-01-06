import 'package:get/get.dart';

import '../../services/location_service.dart';
import '../../services/map_service.dart';
import '../../services/permission_service.dart';

class AppBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PermissionService(), fenix: true);
    Get.lazyPut(() => LocationService(), fenix: true);
    Get.lazyPut(() => MapService(), fenix: true);
  }
}