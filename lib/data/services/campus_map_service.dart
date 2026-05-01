import 'package:flutter/material.dart';

class CampusLocation {
  final String building;
  final int floor;
  final String room;
  final Offset relativePos; // Position on the 2D grid/projection

  CampusLocation({
    required this.building,
    required this.floor,
    required this.room,
    required this.relativePos,
  });
}

class BuildingModel {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final List<FloorModel> floors;

  BuildingModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.floors,
  });
}

class RoomModel {
  final String number;
  final String name;
  final Offset position; // normalized coordinates 0.0 - 1.0 (center)
  final Size size;       // fallback relative size (0.0 - 1.0)
  final List<Offset>? polygonPoints; // normalized points for custom shape

  RoomModel({
    required this.number,
    required this.name,
    required this.position,
    this.size = const Size(0.1, 0.1),
    this.polygonPoints,
  });
}

class StairModel {
  final String id;
  final Offset position; // normalized coordinates 0.0 - 1.0
  final int connectsToFloor;

  StairModel({
    required this.id,
    required this.position,
    required this.connectsToFloor,
  });
}

class FloorModel {
  final int level;
  final List<RoomModel> rooms;
  final List<StairModel> stairs;
  final List<List<Offset>> wallPolygons; // normalized lines for walls

  FloorModel({
    required this.level, 
    required this.rooms, 
    this.stairs = const [],
    this.wallPolygons = const [],
  });
}

class CampusMapService {
  static final List<BuildingModel> buildings = [
    BuildingModel(
      id: 'liaquat',
      name: 'Liaquat Block',
      lat: 24.892661,
      lng: 67.088732,
      floors: [
        FloorModel(
          level: 0, 
          wallPolygons: [
            // Outer boundary
            [Offset(0.1, 0.1), Offset(0.9, 0.1), Offset(0.9, 0.9), Offset(0.1, 0.9), Offset(0.1, 0.1)],
            // Main Corridor
            [Offset(0.1, 0.45), Offset(0.9, 0.45)],
            [Offset(0.1, 0.55), Offset(0.9, 0.55)],
          ],
          rooms: [
            RoomModel(
              number: 'L-001', 
              name: 'Main Lobby', 
              position: const Offset(0.5, 0.5),
              polygonPoints: [Offset(0.4, 0.45), Offset(0.6, 0.45), Offset(0.6, 0.55), Offset(0.4, 0.55)],
            ),
            RoomModel(
              number: 'L-002', 
              name: 'Admin Office', 
              position: const Offset(0.2, 0.25),
              polygonPoints: [Offset(0.1, 0.1), Offset(0.4, 0.1), Offset(0.4, 0.45), Offset(0.1, 0.45)],
            ),
            RoomModel(
              number: 'L-003', 
              name: 'Faculty Room', 
              position: const Offset(0.8, 0.25),
              polygonPoints: [Offset(0.6, 0.1), Offset(0.9, 0.1), Offset(0.9, 0.45), Offset(0.6, 0.45)],
            ),
            RoomModel(
              number: 'L-004', 
              name: 'Student Center', 
              position: const Offset(0.2, 0.75),
              polygonPoints: [Offset(0.1, 0.55), Offset(0.4, 0.55), Offset(0.4, 0.9), Offset(0.1, 0.9)],
            ),
            RoomModel(
              number: 'L-005', 
              name: 'Conference Hall', 
              position: const Offset(0.8, 0.75),
              polygonPoints: [Offset(0.6, 0.55), Offset(0.9, 0.55), Offset(0.9, 0.9), Offset(0.6, 0.9)],
            ),
          ],
          stairs: [
            StairModel(id: 'L0_ST1', position: const Offset(0.95, 0.5), connectsToFloor: 1),
          ],
        ),
        FloorModel(
          level: 1, 
          wallPolygons: [
            [Offset(0.1, 0.1), Offset(0.9, 0.1), Offset(0.9, 0.9), Offset(0.1, 0.9), Offset(0.1, 0.1)],
          ],
          rooms: [
            RoomModel(
              number: 'L-101', 
              name: 'Lecture Hall 1', 
              position: const Offset(0.3, 0.5),
              polygonPoints: [Offset(0.15, 0.2), Offset(0.45, 0.2), Offset(0.45, 0.8), Offset(0.15, 0.8)],
            ),
            RoomModel(
              number: 'L-102', 
              name: 'Lecture Hall 2', 
              position: const Offset(0.7, 0.5),
              polygonPoints: [Offset(0.55, 0.2), Offset(0.85, 0.2), Offset(0.85, 0.8), Offset(0.55, 0.8)],
            ),
          ],
          stairs: [
            StairModel(id: 'L1_ST1', position: const Offset(0.9, 0.1), connectsToFloor: 0),
          ],
        ),
      ],
    ),
    BuildingModel(
      id: 'academic',
      name: 'Academic Block',
      lat: 24.893240, // Assuming Academic is Quaid for this logic if name matches later
      lng: 67.088235,
      floors: [
        FloorModel(level: 0, rooms: [
          RoomModel(number: 'A-001', name: 'Computer Lab 1', position: const Offset(0.4, 0.5), size: const Size(0.2, 0.3)),
          RoomModel(number: 'A-002', name: 'Hardware Lab', position: const Offset(0.6, 0.5), size: const Size(0.2, 0.3)),
        ]),
      ],
    ),
    BuildingModel(
      id: 'quaid',
      name: 'Quaid Block',
      lat: 24.893240,
      lng: 67.088235,
      floors: [
        FloorModel(level: 0, rooms: [
          RoomModel(number: 'Q-001', name: 'Student Affairs', position: const Offset(0.3, 0.4)),
          RoomModel(number: 'Q-002', name: 'Finance Office', position: const Offset(0.7, 0.4)),
        ]),
        FloorModel(level: 1, rooms: [
          RoomModel(number: 'Q-101', name: 'Exam Hall', position: const Offset(0.5, 0.5), size: const Size(0.4, 0.3)),
        ]),
      ],
    ),
    BuildingModel(
      id: 'iqbal',
      name: 'Iqbal Block',
      lat: 24.892799,
      lng: 67.087586,
      floors: [
        FloorModel(level: 0, rooms: [
          RoomModel(number: 'I-001', name: 'Law Dept Library', position: const Offset(0.5, 0.5), size: const Size(0.3, 0.3)),
        ]),
      ],
    ),
    BuildingModel(
      id: 'cafe',
      name: 'Cafeteria / Student Center',
      lat: 24.893237,
      lng: 67.088026,
      floors: [
        FloorModel(level: 0, rooms: [
          RoomModel(number: 'C-001', name: 'Main Cafeteria', position: const Offset(0.4, 0.6), size: const Size(0.5, 0.4)),
          RoomModel(number: 'C-002', name: 'Auditorium Entrance', position: const Offset(0.8, 0.3)),
        ]),
      ],
    ),
  ];

  static RoomModel? findRoom(String roomNumber) {
    for (var b in buildings) {
      for (var f in b.floors) {
        for (var r in f.rooms) {
          if (r.number == roomNumber) return r;
        }
      }
    }
    return null;
  }

  static CampusLocation? getLocation(String roomNumber) {
    for (var b in buildings) {
      for (var f in b.floors) {
        for (var r in f.rooms) {
          if (r.number == roomNumber) {
            return CampusLocation(
              building: b.name,
              floor: f.level,
              room: r.number,
              relativePos: r.position,
            );
          }
        }
      }
    }
    return null;
  }
}
