import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'campus_map_service.dart';

enum PositioningMode { wifi, sensors, manual, mock }

class IndoorPositioningService {
  IndoorPositioningService._();
  static final instance = IndoorPositioningService._();

  PositioningMode _mode = PositioningMode.mock;
  
  // Streams for position updates
  final _positionController = StreamController<CampusLocation>.broadcast();
  Stream<CampusLocation> get positionStream => _positionController.stream;

  Timer? _mockTimer;

  void startPositioning({PositioningMode mode = PositioningMode.mock}) {
    _mode = mode;
    if (_mode == PositioningMode.mock) {
      _startMockPositioning();
    }
  }

  void stopPositioning() {
    _mockTimer?.cancel();
  }

  void _startMockPositioning() {
    _mockTimer?.cancel();
    _mockTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Simulate moving between rooms in Liaquat Block
      final rooms = CampusMapService.buildings[0].floors[0].rooms;
      final randomRoom = rooms[Random().nextInt(rooms.length)];
      
      final location = CampusLocation(
        building: 'Liaquat Block',
        floor: 0,
        room: randomRoom.number,
        relativePos: randomRoom.position,
      );
      
      _positionController.add(location);
    });
  }

  /// In a real implementation, this would scan WiFi networks
  /// and compare signal strengths (RSSI) to a database.
  Future<CampusLocation?> getWifiPosition() async {
    // 1. Get BSSIDs of nearby access points
    // 2. Fetch mapped coordinates from backend/local DB
    // 3. Triangulate or use weighted average
    return null; 
  }

  /// Uses Accelerometer + Magnetometer to track steps and direction
  void startSensorFusion() {
    // 1. Listen to Accelerometer (detect steps)
    // 2. Listen to Magnetometer (detect heading)
    // 3. Update relative position based on step length estimate
  }
}
