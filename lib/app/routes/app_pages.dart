import 'package:get/get.dart';

import '../../map/views/map_screen.dart';
import '../bindings/map_binding.dart';

class AppPages {
  static const String initial = '/map';

  static final routes = [
    GetPage(
      name: initial,
      page: () => const MapScreen(),
      binding: MapBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}