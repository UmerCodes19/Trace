import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OpenStreetMapWidget extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final List<Marker> markers;
  final Function(LatLng)? onTap;

  const OpenStreetMapWidget({
    Key? key,
    this.latitude,
    this.longitude,
    this.markers = const [],
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final center = latitude != null && longitude != null
        ? LatLng(latitude!, longitude!)
        : LatLng(24.8607, 67.0011); // Bahria University Karachi

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15,
        onTap: onTap != null ? (_, point) => onTap!(point) : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'pk.edu.bahria.lostfound',
        ),
        MarkerLayer(
          markers: markers,
        ),
      ],
    );
  }
}