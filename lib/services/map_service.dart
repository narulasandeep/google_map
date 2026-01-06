import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapService extends GetxService {
  final String apiKey = 'Your_google_api_key';

  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;
  final RxList<LatLng> routePoints = <LatLng>[].obs;

  final RxString routeDistance = ''.obs;
  final RxString routeDuration = ''.obs;
  final RxBool isCalculatingRoute = false.obs;
  final RxString routeError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    Get.log('MapService initialized');
  }

  void addMarker({
    required LatLng position,
    required String id,
    String? title,
    String? snippet,
    BitmapDescriptor? icon,
  }) {
    final marker = Marker(
      markerId: MarkerId(id),
      position: position,
      infoWindow: InfoWindow(
        title: title ?? 'Marker',
        snippet: snippet,
      ),
      icon: icon ?? BitmapDescriptor.defaultMarker,
    );

    markers.add(marker);
    Get.log('Marker added: $id at ${position.latitude}, ${position.longitude}');
  }

  void clearMarkers() {
    markers.clear();
    Get.log('All markers cleared');
  }

  void clearRoute() {
    polylines.clear();
    routePoints.clear();
    routeDistance.value = '';
    routeDuration.value = '';
    routeError.value = '';

    markers.removeWhere((marker) {
      return marker.markerId.value == 'route_start' ||
          marker.markerId.value == 'route_end';
    });
    Get.log('Route cleared');
  }

  Future<void> drawRoute(LatLng origin, LatLng destination) async {
    try {
      isCalculatingRoute.value = true;
      routeError.value = '';

      // Clear previous route
      clearRoute();

      // Add markers for start and end points
      addMarker(
        position: origin,
        id: 'route_start',
        title: 'Start Point',
        snippet: 'Route begins here',
      );

      addMarker(
        position: destination,
        id: 'route_end',
        title: 'End Point',
        snippet: 'Route ends here',
      );

      // Try to get route from Google Directions API
      final routeData = await _getRouteFromDirectionsApi(origin, destination);

      if (routeData['points'].isEmpty) {
        throw Exception('No route found between points');
      }

      // Update route information
      routeDistance.value = routeData['distance'] ?? '';
      routeDuration.value = routeData['duration'] ?? '';

      // Create polyline
      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        color: const Color(0xFF4361EE),
        width: 5,
        points: routeData['points'],
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      );

      polylines.add(polyline);
      routePoints.assignAll(routeData['points']);

      Get.log('Route drawn successfully: ${routeData['distance']} - ${routeData['duration']}');

    } catch (e) {
      routeError.value = 'Failed to draw route: ${e.toString()}';
      Get.log('Route drawing error: $e');

      // Show error snackbar
      Get.snackbar(
        'Route Error',
        'Could not calculate route. Make sure Directions API is enabled in Google Cloud Console.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF44336),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isCalculatingRoute.value = false;
    }
  }

  Future<Map<String, dynamic>> _getRouteFromDirectionsApi(
      LatLng origin,
      LatLng destination
      ) async {
    try {
      // Construct the URL for Directions API
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?'
              'origin=${origin.latitude},${origin.longitude}&'
              'destination=${destination.latitude},${destination.longitude}&'
              'key=$apiKey'
      );

      Get.log('Requesting route from Directions API...');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Extract polyline points using flutter_polyline_points
          final polylinePoints = PolylinePoints();
          final points = polylinePoints.decodePolyline(
              route['overview_polyline']['points']
          );

          final List<LatLng> routePoints = points.map((point) =>
              LatLng(point.latitude, point.longitude)
          ).toList();

          // Extract distance and duration
          final distance = leg['distance']['text'];
          final duration = leg['duration']['text'];

          Get.log('Directions API success: $distance, $duration');

          return {
            'points': routePoints,
            'distance': distance,
            'duration': duration,
          };
        } else {
          throw Exception('Directions API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      Get.log('Directions API failed: $e');
      // Fallback to simple line if API fails
      return _getFallbackRoute(origin, destination);
    }
  }

  Map<String, dynamic> _getFallbackRoute(LatLng origin, LatLng destination) {
    // Simple straight line between points
    final points = [origin, destination];

    // Calculate approximate distance
    final distance = _calculateDistance(origin, destination);
    final duration = '${(distance / 50 * 60).round()} min';

    Get.log('Using fallback route: ${distance.toStringAsFixed(1)} km');

    return {
      'points': points,
      'distance': '${distance.toStringAsFixed(1)} km',
      'duration': duration,
    };
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371;

    double lat1 = start.latitude * pi / 180;
    double lon1 = start.longitude * pi / 180;
    double lat2 = end.latitude * pi / 180;
    double lon2 = end.longitude * pi / 180;

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  LatLngBounds calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
