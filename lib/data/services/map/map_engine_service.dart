import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../models/map/campus_gis_models.dart';

class MapEngineService {
  MapEngineService._();
  static final MapEngineService instance = MapEngineService._();

  bool _initialized = false;
  MapDimensions _dimensions = const MapDimensions(width: 1000.0, height: 1400.0);
  List<CampusRoom> _masterRooms = [];
  final Map<int, List<CampusRoom>> _extrapolatedFloors = {};

  bool get isInitialized => _initialized;
  MapDimensions get dimensions => _dimensions;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      // 1. Load Metadata
      final metaString = await rootBundle.loadString('assets/maps/liaquat/metadata.json');
      final metaJson = jsonDecode(metaString) as Map<String, dynamic>;
      _dimensions = MapDimensions.fromMap(metaJson['dimensions'] as Map<String, dynamic>);

      // 2. Load Master Floor 1 Rooms
      final floor1String = await rootBundle.loadString('assets/maps/liaquat/floor_1.json');
      final List<dynamic> floor1Json = jsonDecode(floor1String);
      _masterRooms = floor1Json.map((e) => CampusRoom.fromMap(e as Map<String, dynamic>)).toList();

      // 3. Procedurally generate floors 0 to 7
      final totalFloors = metaJson['floorCount'] as int? ?? 8;
      for (int f = 0; f < totalFloors; f++) {
        if (f == 1) {
          _extrapolatedFloors[1] = _masterRooms;
        } else {
          _extrapolatedFloors[f] = generateFloorLayout(_masterRooms, f, metaJson['roomPrefix'] as String? ?? 'E');
        }
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing MapEngineService: $e');
      // Dynamic fallback if assets are not bundled in tests/development environment yet
      _dimensions = const MapDimensions(width: 1000.0, height: 1400.0);
      _initialized = true;
    }
  }

  /// Procedural Floor Layout Generator
  /// Clones Floor 1 coordinates and shifts the numbering dynamically based on the target floor level.
  List<CampusRoom> generateFloorLayout(List<CampusRoom> baseFloor, int floorNumber, String roomPrefix) {
    return baseFloor.map((room) {
      final updatedId = room.id.replaceAll('_1_', '_${floorNumber}_');
      String updatedRoomNumber = room.roomNumber;
      String updatedName = room.name;

      if (room.roomNumber.startsWith(roomPrefix) && room.roomNumber.contains('-')) {
        // e.g. E-201 -> E-101 (when floorNumber = 0)
        final parts = room.roomNumber.split('-');
        if (parts.length == 2 && parts[1].length == 3) {
          final numberPart = parts[1].substring(1); // "01"
          updatedRoomNumber = '$roomPrefix-${floorNumber + 1}$numberPart';
          updatedName = room.name.replaceAll(room.roomNumber, updatedRoomNumber);
        }
      }

      final updatedAliases = room.aliases.map((a) {
        if (a.contains('-') && a.startsWith(roomPrefix)) {
          final parts = a.split('-');
          if (parts.length == 2 && parts[1].length == 3) {
            return '$roomPrefix-${floorNumber + 1}${parts[1].substring(1)}';
          }
        }
        return a.replaceAll('1', floorNumber.toString());
      }).toList();

      // Extrapolate anchors
      final updatedAnchors = room.anchorPoints.map((a) {
        final updatedAnchorId = a.id.replaceAll('1', floorNumber.toString());
        return AnchorPoint(
          id: updatedAnchorId,
          label: a.label,
          position: a.position,
          category: a.category,
        );
      }).toList();

      return CampusRoom(
        id: updatedId,
        roomNumber: updatedRoomNumber,
        name: updatedName,
        building: room.building,
        floor: floorNumber,
        polygonPoints: room.polygonPoints, // Preserves identical geometry shape
        type: room.type,
        aliases: updatedAliases,
        connectedRooms: room.connectedRooms.map((id) => id.replaceAll('_1_', '_${floorNumber}_')).toList(),
        nearestHallway: room.nearestHallway?.replaceAll('_1_', '_${floorNumber}_'),
        nearestStair: room.nearestStair?.replaceAll('_1_', '_${floorNumber}_'),
        anchorPoints: updatedAnchors,
      );
    }).toList();
  }

  List<CampusRoom> getRoomsOnFloor(int floor) {
    return _extrapolatedFloors[floor] ?? [];
  }

  /// Dynamic Centroid Calculation Algorithm for Room Pins
  Offset getRoomCenter(CampusRoom room) {
    if (room.polygonPoints.isEmpty) return const Offset(0.5, 0.5);
    if (room.polygonPoints.length < 3) {
      // Bounding Box fallback
      double minX = 1.0, maxX = 0.0, minY = 1.0, maxY = 0.0;
      for (final p in room.polygonPoints) {
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }
      return Offset((minX + maxX) / 2, (minY + maxY) / 2);
    }

    // Precise Polygon Centroid Math
    double area = 0.0;
    double cx = 0.0;
    double cy = 0.0;

    final points = List<Offset>.from(room.polygonPoints)..add(room.polygonPoints.first);

    for (int i = 0; i < room.polygonPoints.length; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final factor = (p1.dx * p2.dy - p2.dx * p1.dy);
      area += factor;
      cx += (p1.dx + p2.dx) * factor;
      cy += (p1.dy + p2.dy) * factor;
    }

    area = area / 2.0;
    if (area == 0.0) {
      // Fallback to average coordinate midpoint
      double sx = 0.0, sy = 0.0;
      for (final p in room.polygonPoints) {
        sx += p.dx;
        sy += p.dy;
      }
      return Offset(sx / room.polygonPoints.length, sy / room.polygonPoints.length);
    }

    cx = cx / (6.0 * area);
    cy = cy / (6.0 * area);

    return Offset(cx.clamp(0.0, 1.0), cy.clamp(0.0, 1.0));
  }

  /// Coordinate Hit-Detection / Ray Casting hit tester
  CampusRoom? detectRoomFromCoordinate(Offset point, int floor) {
    final rooms = getRoomsOnFloor(floor);
    for (final room in rooms) {
      if (room.polygonPoints.isEmpty) continue;
      if (_isPointInPolygon(point, room.polygonPoints)) {
        return room;
      }
    }
    return null;
  }

  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy) &&
          (point.dx < (polygon[j].dx - polygon[i].dx) * (point.dy - polygon[i].dy) / (polygon[j].dy - polygon[i].dy) + polygon[i].dx)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  /// Spatial Search Engine Core
  List<CampusRoom> searchRooms(String query, int floor) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return [];

    final rooms = getRoomsOnFloor(floor);
    return rooms.where((room) {
      if (room.roomNumber.toLowerCase().contains(normalizedQuery)) return true;
      if (room.name.toLowerCase().contains(normalizedQuery)) return true;
      if (room.aliases.any((a) => a.toLowerCase().contains(normalizedQuery))) return true;
      if (room.type.name.toLowerCase().contains(normalizedQuery)) return true;
      return false;
    }).toList();
  }

  /// Nearby Locations Radius Finder
  List<CampusRoom> searchNearbyLocations(Offset position, int floor, double maxDistance) {
    final rooms = getRoomsOnFloor(floor);
    return rooms.where((room) {
      final center = getRoomCenter(room);
      final dx = center.dx - position.dx;
      final dy = center.dy - position.dy;
      final distance = dx * dx + dy * dy; // Squared distance for fast compute
      return distance <= (maxDistance * maxDistance);
    }).toList();
  }

  /// Fetch Rooms by Specific Alias
  CampusRoom? searchByAlias(String alias, int floor) {
    final normalizedAlias = alias.trim().toLowerCase();
    final rooms = getRoomsOnFloor(floor);
    for (final room in rooms) {
      if (room.aliases.any((a) => a.toLowerCase() == normalizedAlias)) {
        return room;
      }
    }
    return null;
  }

  /// Find a specific CampusRoom by ID across all extrapolated floors
  CampusRoom? getRoomById(String id) {
    for (var rooms in _extrapolatedFloors.values) {
      for (var r in rooms) {
        if (r.id == id) return r;
      }
    }
    return null;
  }

  /// Calculates turn-by-turn routing using A* Search Algorithm
  List<CampusRoom> calculateAStarPath(String startRoomId, String endRoomId) {
    debugPrint('A* SOLVER: Starting search from "$startRoomId" to "$endRoomId"');
    final startRoom = getRoomById(startRoomId);
    final endRoom = getRoomById(endRoomId);
    if (startRoom == null) {
      debugPrint('A* SOLVER ERROR: Start room "$startRoomId" not found in memory!');
      return [];
    }
    if (endRoom == null) {
      debugPrint('A* SOLVER ERROR: End room "$endRoomId" not found in memory!');
      return [];
    }

    final List<_AStarNode> openSet = [];
    final Set<String> closedSet = {};

    openSet.add(_AStarNode(
      room: startRoom,
      gCost: 0,
      hCost: _calculateHeuristic(startRoom, endRoom),
    ));

    int iterations = 0;
    while (openSet.isNotEmpty) {
      iterations++;
      if (iterations > 200) {
        debugPrint('A* SOLVER WARNING: Pathfinding exceeded 200 iterations, aborting.');
        break;
      }

      openSet.sort((a, b) => a.fCost.compareTo(b.fCost));
      final current = openSet.removeAt(0);

      debugPrint('A* SOLVER STEP $iterations: Evaluating current room "${current.room.id}" (F-cost: ${current.fCost})');

      if (current.room.id == endRoom.id) {
        final List<CampusRoom> path = [];
        _AStarNode? temp = current;
        while (temp != null) {
          path.insert(0, temp.room);
          temp = temp.parent;
        }
        debugPrint('A* SOLVER SUCCESS: Path found with ${path.length} nodes: ${path.map((r) => r.roomNumber).toList()}');
        return path;
      }

      closedSet.add(current.room.id);

      for (final neighborId in current.room.connectedRooms) {
        if (closedSet.contains(neighborId)) continue;

        final neighborRoom = getRoomById(neighborId);
        if (neighborRoom == null) {
          debugPrint('A* SOLVER NEIGHBOR WARNING: Connection "$neighborId" defined in "${current.room.id}" was not found in database!');
          continue;
        }

        final transitionCost = _calculateHeuristic(current.room, neighborRoom);
        final tentativeGCost = current.gCost + transitionCost;

        final existingIndex = openSet.indexWhere((node) => node.room.id == neighborRoom.id);
        if (existingIndex != -1) {
          if (tentativeGCost >= openSet[existingIndex].gCost) continue;
          openSet.removeAt(existingIndex);
        }

        openSet.add(_AStarNode(
          room: neighborRoom,
          parent: current,
          gCost: tentativeGCost,
          hCost: _calculateHeuristic(neighborRoom, endRoom),
        ));
      }
    }

    debugPrint('A* SOLVER FAILURE: No path exists between "$startRoomId" and "$endRoomId" (OpenSet was empty)');
    return [];
  }

  double _calculateHeuristic(CampusRoom a, CampusRoom b) {
    final cA = getRoomCenter(a);
    final cB = getRoomCenter(b);
    final dx = cA.dx - cB.dx;
    final dy = cA.dy - cB.dy;
    final floorDiff = (a.floor - b.floor).abs();
    return (dx * dx + dy * dy) + (floorDiff * 100.0);
  }
}

class _AStarNode {
  final CampusRoom room;
  final _AStarNode? parent;
  final double gCost;
  final double hCost;
  double get fCost => gCost + hCost;

  _AStarNode({
    required this.room,
    this.parent,
    required this.gCost,
    required this.hCost,
  });
}

