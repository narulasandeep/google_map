import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/themes/app_colors.dart';

class MapControls extends StatelessWidget {
  final VoidCallback onMyLocation;
  final VoidCallback onClearMarkers;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final double currentZoom;

  const MapControls({
    super.key,
    required this.onMyLocation,
    required this.onClearMarkers,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.currentZoom,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Controls
        Row(
          children: [
            _buildControlButton(
              icon: Icons.my_location,
              label: 'My Location',
              onPressed: onMyLocation,
              color: Colors.blue,
            ),
            const SizedBox(width: 12),
            _buildControlButton(
              icon: Icons.delete,
              label: 'Clear All',
              onPressed: onClearMarkers,
              color: Colors.red,
            ),
          ],
        ),

        // Right Controls - Zoom
        Container(
          padding: const EdgeInsets.all(8),
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
            children: [
              _buildZoomButton(
                icon: Icons.add,
                onPressed: onZoomIn,
              ),
              const SizedBox(height: 8),
              Container(
                width: 32,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Center(
                  child: Text(
                    '${currentZoom.toInt()}x',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildZoomButton(
                icon: Icons.remove,
                onPressed: onZoomOut,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }
}