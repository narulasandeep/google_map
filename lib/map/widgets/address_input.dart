import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../controllers/map_controller.dart';

class AddressInput extends StatelessWidget {
  final LatLng? startPoint;
  final LatLng? endPoint;
  final VoidCallback onClear;

  const AddressInput({
    super.key,
    required this.startPoint,
    required this.endPoint,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MapController>();

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
          const Row(
            children: [
              Icon(
                Icons.directions,
                size: 20,
                color: Colors.blue,
              ),
              SizedBox(width: 8),
              Text(
                'Route Ready',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Start Point
          _buildPointRow(
            icon: Icons.location_on,
            iconColor: Colors.green,
            label: 'Start Point',
            point: startPoint,
          ),

          const SizedBox(height: 8),

          // End Point
          _buildPointRow(
            icon: Icons.flag,
            iconColor: Colors.red,
            label: 'Destination',
            point: endPoint,
          ),

          const SizedBox(height: 16),

          // Action Button
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: startPoint != null && endPoint != null
                      ? () async {
                    await controller.calculateAndDrawRoute();
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Obx(() => controller.mapService.isCalculatingRoute.value
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Calculate Route',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.clear),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                ),
                tooltip: 'Clear Points',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPointRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required LatLng? point,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: point != null ? iconColor.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: point != null ? iconColor.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: point != null ? iconColor : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  point != null
                      ? '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}'
                      : 'Not selected',
                  style: TextStyle(
                    fontSize: 14,
                    color: point != null ? Colors.black : Colors.grey,
                    fontWeight: point != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}