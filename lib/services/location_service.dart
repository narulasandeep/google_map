import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService extends GetxService {
  // Current location
  final Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  final RxDouble currentHeading = 0.0.obs;

  // Location status
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Stream for continuous updates
  StreamSubscription<Position>? _positionStream;
  final RxBool isTracking = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Start listening to location updates when service initializes
    startLocationUpdates();
  }

  Future<void> getCurrentLocation() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage.value = 'Location services are disabled. Please enable location services.';
        isLoading.value = false;
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Update current location
      currentLocation.value = LatLng(position.latitude, position.longitude);

      // Update heading if available
      if (position.heading != null && position.heading! >= 0) {
        currentHeading.value = position.heading!;
      }

      isLoading.value = false;
      Get.log('Current location: ${position.latitude}, ${position.longitude}');

    } on LocationServiceDisabledException {
      errorMessage.value = 'Location services are disabled. Please enable location services.';
      isLoading.value = false;
    } on TimeoutException {
      errorMessage.value = 'Location request timed out. Please try again.';
      isLoading.value = false;
    } catch (e) {
      errorMessage.value = 'Error getting location: ${e.toString()}';
      isLoading.value = false;
    }
  }

  void startLocationUpdates() {
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // meters
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
            (Position position) {
          currentLocation.value = LatLng(position.latitude, position.longitude);

          if (position.heading != null && position.heading! >= 0) {
            currentHeading.value = position.heading!;
          }

          isTracking.value = true;
        },
        onError: (e) {
          errorMessage.value = 'Location update error: ${e.toString()}';
          isTracking.value = false;
        },
      );
    } catch (e) {
      errorMessage.value = 'Failed to start location updates: ${e.toString()}';
    }
  }

  void stopLocationUpdates() {
    _positionStream?.cancel();
    isTracking.value = false;
  }

  Future<double> calculateDistance(LatLng start, LatLng end) async {
    try {
      return Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      ) / 1000; // Convert to kilometers
    } catch (e) {
      return 0.0;
    }
  }

  @override
  void onClose() {
    stopLocationUpdates();
    super.onClose();
  }
}