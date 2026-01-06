import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/map_controller.dart';
import '../widgets/address_input.dart';
import '../widgets/map_controls.dart';
import '../widgets/route_info_card.dart';

class MapScreen extends GetView<MapController> {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map - Full Screen
          _buildMap(),

          // Loading Overlay
          Obx(() => controller.isLoading.value ? _buildLoadingOverlay() : const SizedBox()),

          // Top Controls - Full Width Header
          Obx(() => controller.showTopControls.value
              ? _buildTopControls()
              : _buildMinimizedHeader()),

          // Point Selection UI (Always visible when in route mode and selecting points)
          Obx(() => controller.isRouteMode.value &&
              controller.showTopControls.value &&
              (controller.startPoint.value == null || controller.endPoint.value == null)
              ? Positioned(
            top: 120,
            left: 20,
            right: 20,
            child: _buildPointSelectionCard(),
          )
              : const SizedBox()),

          // Route Info Card - Positioned below header
          Obx(() => controller.showRouteInfo.value && controller.mapService.routeDistance.value.isNotEmpty
              ? Positioned(
            top: controller.showTopControls.value ? 120 : 70,
            left: 20,
            right: 20,
            child: RouteInfoCard(
              distance: controller.mapService.routeDistance.value,
              duration: controller.mapService.routeDuration.value,
              onClose: () {
                controller.showRouteInfo.value = false;
                controller.showTopControls.value = true;
              },
            ),
          )
              : const SizedBox()),

          // Bottom Controls
          _buildBottomControls(),

          // Show Controls Button (when top controls are hidden)
          Obx(() => !controller.showTopControls.value
              ? Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: _buildShowControlsButton(),
          )
              : const SizedBox()),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Obx(() {
      if (controller.errorMessage.value.isNotEmpty) {
        return _buildErrorView();
      }

      return GoogleMap(
        onMapCreated: controller.onMapCreated,
        initialCameraPosition: controller.cameraPosition.value,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: true,
        rotateGesturesEnabled: true,
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
        tiltGesturesEnabled: true,
        markers: controller.mapService.markers,
        polylines: controller.mapService.polylines,
        onTap: controller.onMapTap,
        mapToolbarEnabled: false,
        onCameraMove: (position) {
          controller.mapZoom.value = position.zoom;
        },
      );
    });
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Loading map...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              'Map Unavailable',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: controller.initializeApp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.map,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.isRouteMode.value ? 'Route Mode' : 'Google Maps App',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Obx(() => Text(
                          controller.isRouteMode.value
                              ? 'Select start and end points'
                              : 'Navigate with ease',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        )),
                      ],
                    ),
                  ),
                  Obx(() => Switch(
                    value: controller.isRouteMode.value,
                    onChanged: controller.toggleRouteMode,
                    activeColor: Colors.blue,
                  ))

                  // Obx(() => Switch(
                  //   value: controller.isRouteMode.value,
                  //   onChanged: controller.toggleRouteMode,
                  //   activeColor: Colors.blue,
                  // ))
                ],
              ),
            ),

            // Divider
            Container(
              height: 1,
              color: Colors.grey[200],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.route,
                size: 24,
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              const Text(
                'Select Points',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Obx(() => Text(
                controller.startPoint.value == null ? 'Step 1/2' : 'Step 2/2',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              )),
            ],
          ),
          const SizedBox(height: 12),

          // Start Point Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: controller.startPoint.value != null ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Point',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(() => Text(
                        controller.startPoint.value != null
                            ? 'Lat: ${controller.startPoint.value!.latitude.toStringAsFixed(6)}\nLng: ${controller.startPoint.value!.longitude.toStringAsFixed(6)}'
                            : 'Tap on map to select',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: controller.startPoint.value != null ? FontWeight.w500 : FontWeight.normal,
                          color: controller.startPoint.value != null ? Colors.black : Colors.grey,
                        ),
                      )),
                    ],
                  ),
                ),
                Obx(() => Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: controller.startPoint.value != null ? Colors.green : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: controller.startPoint.value != null
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : const SizedBox(),
                )),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // End Point Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flag,
                  color: controller.endPoint.value != null ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Destination',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(() => Text(
                        controller.endPoint.value != null
                            ? 'Lat: ${controller.endPoint.value!.latitude.toStringAsFixed(6)}\nLng: ${controller.endPoint.value!.longitude.toStringAsFixed(6)}'
                            : 'Tap on map to select',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: controller.endPoint.value != null ? FontWeight.w500 : FontWeight.normal,
                          color: controller.endPoint.value != null ? Colors.black : Colors.grey,
                        ),
                      )),
                    ],
                  ),
                ),
                Obx(() => Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: controller.endPoint.value != null ? Colors.red : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: controller.endPoint.value != null
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : const SizedBox(),
                )),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info,
                  size: 16,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() => Text(
                    controller.startPoint.value == null
                        ? 'Tap anywhere on the map to set start point'
                        : 'Tap anywhere on the map to set destination point',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimizedHeader() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.route,
                size: 24,
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Route Active',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    Obx(() => Text(
                      controller.mapService.routeDistance.value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  controller.showTopControls.value = true;
                },
                icon: const Icon(
                  Icons.expand_less,
                  color: Colors.blue,
                ),
                tooltip: 'Show Controls',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShowControlsButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            controller.showTopControls.value = true;
          },
          borderRadius: BorderRadius.circular(20),
          child: const Center(
            child: Icon(
              Icons.expand_less,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: SafeArea(
        child: Column(
          children: [
            // Show Address Input when both points are selected but route not yet calculated
            Obx(() => controller.isRouteMode.value &&
                controller.showTopControls.value &&
                controller.startPoint.value != null &&
                controller.endPoint.value != null
                ? Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AddressInput(
                startPoint: controller.startPoint.value,
                endPoint: controller.endPoint.value,
                onClear: controller.clearRoute,
              ),
            )
                : const SizedBox()),

            // Map Controls
            MapControls(
              onMyLocation: controller.goToMyLocation,
              onClearMarkers: controller.clearAllMarkers,
              onZoomIn: controller.zoomIn,
              onZoomOut: controller.zoomOut,
              currentZoom: controller.mapZoom.value,
            ),
          ],
        ),
      ),
    );
  }
}