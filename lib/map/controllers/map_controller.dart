import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/location_service.dart';
import '../../services/map_service.dart';
import '../../services/permission_service.dart';

class MapController extends GetxController {
  // Services
  final PermissionService _permissionService = Get.find();
  final LocationService _locationService = Get.find();
  final MapService mapService = Get.find();

  // Map Controller
  final Completer<GoogleMapController> mapController = Completer();

  // UI States
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isRouteMode = false.obs;
  final RxBool showRouteInfo = false.obs;
  final RxBool showTopControls = true.obs;
  final RxDouble mapZoom = 15.0.obs;

  // Route Points
  final Rx<LatLng?> startPoint = Rx<LatLng?>(null);
  final Rx<LatLng?> endPoint = Rx<LatLng?>(null);

  // Camera Position
  final Rx<CameraPosition> cameraPosition = const CameraPosition(
    target: LatLng(28.6139, 77.2090), // Default: Delhi
    zoom: 12,
  ).obs;

  @override
  void onInit() async {
    super.onInit();
    await initializeApp();
  }

  Future<void> initializeApp() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      showTopControls.value = true;

      // Check and request location permission
      final hasPermission = await _permissionService.checkLocationPermission();

      if (!hasPermission) {
        final granted = await _permissionService.requestLocationPermission();
        if (!granted) {
          errorMessage.value = 'Location permission is required for full functionality.';
        }
      }

      // Get current location
      await _locationService.getCurrentLocation();

      // Set initial camera position
      if (_locationService.currentLocation.value != null) {
        final currentLoc = _locationService.currentLocation.value!;
        cameraPosition.value = CameraPosition(
          target: currentLoc,
          zoom: 15,
        );

        mapService.addMarker(
          position: currentLoc,
          id: 'current_location',
          title: 'Your Location',
          snippet: 'Current position',
        );
      }

      isLoading.value = false;

    } catch (e) {
      errorMessage.value = 'Failed to initialize app: ${e.toString()}';
      isLoading.value = false;
      Get.log('Initialization error: $e');
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController.complete(controller);
    Get.log('Map controller initialized');
  }

  void onMapTap(LatLng position) {
    if (isRouteMode.value) {
      _handleRoutePointTap(position);
    } else {
      _handleRegularTap(position);
    }
  }

  void _handleRegularTap(LatLng position) {
    mapService.addMarker(
      position: position,
      id: 'marker_${mapService.markers.length}',
      title: 'Location',
      snippet: 'Tap to remove',
    );

    Get.snackbar(
      'Marker Added',
      'Tap the marker to remove it',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _handleRoutePointTap(LatLng position) {
    if (startPoint.value == null) {
      // Set start point
      startPoint.value = position;
      showTopControls.value = true;

      // Add marker for start point
      mapService.addMarker(
        position: position,
        id: 'start_point',
        title: 'Start Point',
        snippet: 'Tap to change',
      );

      Get.snackbar(
        'Start Point Selected',
        'Now tap on map for destination',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } else if (endPoint.value == null) {
      // Set end point
      endPoint.value = position;

      // Add marker for end point
      mapService.addMarker(
        position: position,
        id: 'end_point',
        title: 'Destination',
        snippet: 'Tap to change',
      );

      Get.snackbar(
        'Destination Selected',
        'Calculating route...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Automatically calculate route after short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        calculateAndDrawRoute();
      });
    }
  }

  Future<void> calculateAndDrawRoute() async {
    if (startPoint.value == null || endPoint.value == null) {
      Get.snackbar(
        'Error',
        'Please select both start and end points',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF44336),
        colorText: Colors.white,
      );
      return;
    }

    Get.log('Calculating route from ${startPoint.value} to ${endPoint.value}');

    // Show loading
    Get.dialog(
      const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Calculating route...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    try {
      await mapService.drawRoute(startPoint.value!, endPoint.value!);

      if (mapService.routeError.value.isEmpty) {
        showRouteInfo.value = true;
        showTopControls.value = false; // Hide controls when route is shown

        await _adjustCameraForRoute();

        Get.back(); // Close loading dialog

        Get.snackbar(
          'Route Calculated',
          'Distance: ${mapService.routeDistance.value}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF2196F3),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.back();
        showTopControls.value = true;
        Get.snackbar(
          'Route Error',
          mapService.routeError.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFF44336),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back();
      showTopControls.value = true;
      Get.snackbar(
        'Error',
        'Failed to calculate route: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF44336),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _adjustCameraForRoute() async {
    try {
      final controller = await mapController.future;
      final routePoints = mapService.routePoints;

      if (routePoints.isNotEmpty && routePoints.length > 1) {
        final bounds = mapService.calculateBounds(routePoints.toList());

        await Future.delayed(const Duration(milliseconds: 500));

        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      }
    } catch (e) {
      Get.log('Camera adjustment error: $e');
    }
  }

  Future<void> goToMyLocation() async {
    try {
      if (_locationService.currentLocation.value != null) {
        final controller = await mapController.future;
        await controller.animateCamera(
          CameraUpdate.newLatLng(_locationService.currentLocation.value!),
        );

        Get.snackbar(
          'Location Updated',
          'Centered on your location',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 1),
        );
      } else {
        await _locationService.getCurrentLocation();
        if (_locationService.currentLocation.value != null) {
          goToMyLocation();
        }
      }
    } catch (e) {
      Get.snackbar(
        'Location Error',
        'Unable to get current location',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF44336),
        colorText: Colors.white,
      );
    }
  }

  void toggleRouteMode(bool value) {
    isRouteMode.value = value;
    showTopControls.value = true;

    if (value) {
      // ENTER route mode
      clearRoute();
      Get.snackbar(
        'Route Mode Active',
        'Tap on map to set start and end points',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } else {
      // EXIT route mode
      clearRoute();
    }
  }

  // void toggleRouteMode(bool value) {
  //   isRouteMode.value = value;
  //   showTopControls.value = true;
  //
  //   if (value) {
  //     // Enter route mode
  //     clearRoute();
  //     Get.snackbar(
  //       'Route Mode Enabled',
  //       'Tap on map to select points',
  //       snackPosition: SnackPosition.BOTTOM,
  //       duration: const Duration(seconds: 2),
  //       backgroundColor: Colors.blue,
  //       colorText: Colors.white,
  //     );
  //   } else {
  //     // Exit route mode
  //     clearRoute();
  //     Get.snackbar(
  //       'Route Mode Disabled',
  //       'You can now add regular markers',
  //       snackPosition: SnackPosition.BOTTOM,
  //       duration: const Duration(seconds: 1),
  //     );
  //   }
  // }

  void clearRoute() {
    mapService.clearRoute();
    startPoint.value = null;
    endPoint.value = null;
    showRouteInfo.value = false;
    showTopControls.value = true;

    Get.snackbar(
      'Route Cleared',
      'All route points removed',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  //
  // void clearRoute() {
  //   // Clear route markers
  //   mapService.markers.removeWhere((marker) =>
  //   marker.markerId.value == 'start_point' ||
  //       marker.markerId.value == 'end_point' ||
  //       marker.markerId.value == 'route_start' ||
  //       marker.markerId.value == 'route_end'
  //   );
  //
  //   // Clear route data
  //   mapService.clearRoute();
  //   startPoint.value = null;
  //   endPoint.value = null;
  //   showRouteInfo.value = false;
  //   showTopControls.value = true;
  //   isRouteMode.value = false;
  //
  //   Get.snackbar(
  //     'Route Cleared',
  //     'All route points removed',
  //     snackPosition: SnackPosition.BOTTOM,
  //     duration: const Duration(seconds: 1),
  //   );
  // }

  void clearAllMarkers() {
    mapService.clearMarkers();
    clearRoute();

    Get.snackbar(
      'Cleared',
      'All markers removed',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  Future<void> zoomIn() async {
    try {
      mapZoom.value = mapZoom.value + 1;
      final controller = await mapController.future;
      await controller.animateCamera(
        CameraUpdate.zoomTo(mapZoom.value),
      );
    } catch (e) {
      Get.log('Zoom in error: $e');
    }
  }

  Future<void> zoomOut() async {
    try {
      mapZoom.value = mapZoom.value - 1;
      final controller = await mapController.future;
      await controller.animateCamera(
        CameraUpdate.zoomTo(mapZoom.value),
      );
    } catch (e) {
      Get.log('Zoom out error: $e');
    }
  }

  @override
  void onClose() {
    _locationService.stopLocationUpdates();
    super.onClose();
  }
}