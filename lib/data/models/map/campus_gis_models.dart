import 'package:flutter/material.dart';

enum RoomType {
  classroom,
  laboratory,
  office,
  washroom,
  hallway,
  staircase,
  elevator,
  faculty,
  serverRoom,
  lounge,
  unknown
}

enum MapLayer {
  background,
  hallways,
  rooms,
  walls,
  heatmap,
  pins,
  labels,
  overlays
}

class MapDimensions {
  final double width;
  final double height;

  const MapDimensions({required this.width, required this.height});

  factory MapDimensions.fromMap(Map<String, dynamic> map) {
    return MapDimensions(
      width: (map['width'] as num?)?.toDouble() ?? 800.0,
      height: (map['height'] as num?)?.toDouble() ?? 1200.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'width': width,
      'height': height,
    };
  }
}

class AnchorPoint {
  final String id;
  final String label;
  final Offset position; // Normalized 0.0 - 1.0
  final String category; // e.g. "water_cooler", "notice_board"

  const AnchorPoint({
    required this.id,
    required this.label,
    required this.position,
    required this.category,
  });

  factory AnchorPoint.fromMap(Map<String, dynamic> map) {
    return AnchorPoint(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      position: Offset(
        (map['x'] as num?)?.toDouble() ?? 0.0,
        (map['y'] as num?)?.toDouble() ?? 0.0,
      ),
      category: map['category'] as String? ?? 'general',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'x': position.dx,
      'y': position.dy,
      'category': category,
    };
  }
}

class CampusRoom {
  final String id;
  final String roomNumber;
  final String name;
  final String building;
  final int floor;
  final List<Offset> polygonPoints; // Normalized 0.0 - 1.0
  final RoomType type;
  final List<String> aliases;

  // Connectivity
  final List<String> connectedRooms;
  final String? nearestHallway;
  final String? nearestStair;
  final List<AnchorPoint> anchorPoints;

  const CampusRoom({
    required this.id,
    required this.roomNumber,
    required this.name,
    required this.building,
    required this.floor,
    required this.polygonPoints,
    required this.type,
    this.aliases = const [],
    this.connectedRooms = const [],
    this.nearestHallway,
    this.nearestStair,
    this.anchorPoints = const [],
  });

  factory CampusRoom.fromMap(Map<String, dynamic> map) {
    final rawPoints = map['polygonPoints'] as List? ?? [];
    final points = rawPoints.map((p) {
      if (p is List && p.length >= 2) {
        return Offset((p[0] as num).toDouble(), (p[1] as num).toDouble());
      } else if (p is Map) {
        return Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble());
      }
      return Offset.zero;
    }).toList();

    final rawType = map['type'] as String? ?? 'unknown';
    final type = RoomType.values.firstWhere(
      (e) => e.name == rawType,
      orElse: () => RoomType.unknown,
    );

    final rawAnchors = map['anchorPoints'] as List? ?? [];
    final anchors = rawAnchors.map((a) => AnchorPoint.fromMap(a as Map<String, dynamic>)).toList();

    return CampusRoom(
      id: map['id'] as String? ?? '',
      roomNumber: map['roomNumber'] as String? ?? '',
      name: map['name'] as String? ?? '',
      building: map['building'] as String? ?? '',
      floor: map['floor'] as int? ?? 0,
      polygonPoints: points,
      type: type,
      aliases: (map['aliases'] as List?)?.cast<String>() ?? [],
      connectedRooms: (map['connectedRooms'] as List?)?.cast<String>() ?? [],
      nearestHallway: map['nearestHallway'] as String?,
      nearestStair: map['nearestStair'] as String?,
      anchorPoints: anchors,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomNumber': roomNumber,
      'name': name,
      'building': building,
      'floor': floor,
      'polygonPoints': polygonPoints.map((p) => [p.dx, p.dy]).toList(),
      'type': type.name,
      'aliases': aliases,
      'connectedRooms': connectedRooms,
      'nearestHallway': nearestHallway,
      'nearestStair': nearestStair,
      'anchorPoints': anchorPoints.map((a) => a.toMap()).toList(),
    };
  }
}
