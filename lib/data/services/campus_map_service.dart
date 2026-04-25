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

class FloorModel {
  final int level;
  final List<RoomModel> rooms;
  final String? svgAsset; // Path to floor layout SVG if we use it

  FloorModel({required this.level, required this.rooms, this.svgAsset});
}

class RoomModel {
  final String number;
  final String name;
  final Offset position; // normalized coordinates 0.0 - 1.0
  final Size size;       // relative size

  RoomModel({
    required this.number,
    required this.name,
    required this.position,
    this.size = const Size(0.1, 0.1),
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
        FloorModel(level: 0, rooms: [
          RoomModel(number: 'L-001', name: 'Main Lobby', position: const Offset(0.5, 0.5), size: const Size(0.3, 0.2)),
          RoomModel(number: 'L-002', name: 'Admin Office', position: const Offset(0.2, 0.3)),
          RoomModel(number: 'L-003', name: 'Faculty Room', position: const Offset(0.8, 0.3)),
        ]),
        FloorModel(level: 1, rooms: [
          RoomModel(number: 'L-101', name: 'Lecture Hall 1', position: const Offset(0.3, 0.4), size: const Size(0.2, 0.2)),
          RoomModel(number: 'L-102', name: 'Lecture Hall 2', position: const Offset(0.7, 0.4), size: const Size(0.2, 0.2)),
        ]),
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
      floors: [],
    ),
    BuildingModel(
      id: 'iqbal',
      name: 'Iqbal Block',
      lat: 24.892799,
      lng: 67.087586,
      floors: [],
    ),
    BuildingModel(
      id: 'cafe',
      name: 'Cafe and Al Beruni Auditorium',
      lat: 24.893237,
      lng: 67.088026,
      floors: [],
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
