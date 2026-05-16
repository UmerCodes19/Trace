import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

import '../../../core/constants/app_colors.dart';
import '../../../data/models/map/campus_gis_models.dart';
import '../../../data/services/map/map_engine_service.dart';
import '../../widgets/common/glass_card.dart';

class IsometricCampusScreen extends ConsumerStatefulWidget {
  const IsometricCampusScreen({super.key});

  @override
  ConsumerState<IsometricCampusScreen> createState() => _IsometricCampusScreenState();
}

class _IsometricCampusScreenState extends ConsumerState<IsometricCampusScreen> {
  int _currentFloor = 1; // Default to 1st floor (digitized master)
  String? _selectedRoomId;
  final List<Map<String, dynamic>> _pins = [];
  bool _engineReady = false;
  List<CampusRoom>? _activeNavigationPath;
  List<FloorData> _cachedFloors = [];

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    await MapEngineService.instance.initialize();
    if (mounted) {
      final data = _getBuildingFloors(); // Compute only ONCE
      setState(() {
        _cachedFloors = data;
        _engineReady = true;
      });
    }
  }

  List<FloorData> _getBuildingFloors() {
    if (!_engineReady) return [];

    final List<FloorData> floors = [];
    for (int f = 0; f < 8; f++) {
      final gisRooms = MapEngineService.instance.getRoomsOnFloor(f);
      final roomDataList = gisRooms.where((r) => r.type != RoomType.hallway).map((room) {
        // Compute bounding box coordinates for isometric grid mapping
        double minX = 1.0, maxX = 0.0, minY = 1.0, maxY = 0.0;
        for (final p in room.polygonPoints) {
          if (p.dx < minX) minX = p.dx;
          if (p.dx > maxX) maxX = p.dx;
          if (p.dy < minY) minY = p.dy;
          if (p.dy > maxY) maxY = p.dy;
        }

        // Multiply by 6 for beautiful grid visualization spacing
        final gridX = minX * 6.0;
        final gridY = minY * 6.0;
        final gridW = (maxX - minX).clamp(0.05, 1.0) * 6.0;
        final gridH = (maxY - minY).clamp(0.05, 1.0) * 6.0;

        Color roomColor = Colors.deepPurpleAccent;
        if (room.type == RoomType.laboratory) {
          roomColor = Colors.indigoAccent;
        } else if (room.type == RoomType.washroom) {
          roomColor = Colors.blueGrey;
        } else if (room.type == RoomType.faculty) {
          roomColor = Colors.teal;
        } else if (room.type == RoomType.staircase || room.type == RoomType.elevator) {
          roomColor = Colors.orangeAccent;
        }

        return RoomData(
          id: room.id,
          roomNumber: room.roomNumber,
          name: room.name,
          x: gridX,
          y: gridY,
          w: gridW,
          h: gridH,
          color: roomColor,
        );
      }).toList();

      floors.add(
        FloorData(
          level: f,
          name: f == 0 ? 'Ground Floor' : 'Floor $f',
          rooms: roomDataList,
        ),
      );
    }
    return floors;
  }

  void _addPin(Offset localPos) {
    setState(() {
      _pins.add({
        'floor': _currentFloor,
        'pos': localPos,
        'timestamp': DateTime.now(),
      });
    });
  }

  void _handleCanvasTap(Offset localPos, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height * 0.7);
    final floors = _cachedFloors;
    if (floors.isEmpty) return;

    final floor = floors[_currentFloor];
    for (var room in floor.rooms) {
      final p1 = _toIsoLocal(room.x, room.y, 0.0);
      final p2 = _toIsoLocal(room.x + room.w, room.y, 0.0);
      final p3 = _toIsoLocal(room.x + room.w, room.y + room.h, 0.0);
      final p4 = _toIsoLocal(room.x, room.y + room.h, 0.0);

      final path = Path()
        ..moveTo(center.dx + p1.dx, center.dy + p1.dy)
        ..lineTo(center.dx + p2.dx, center.dy + p2.dy)
        ..lineTo(center.dx + p3.dx, center.dy + p3.dy)
        ..lineTo(center.dx + p4.dx, center.dy + p4.dy)
        ..close();

      if (path.contains(localPos)) {
        setState(() {
          _selectedRoomId = room.id;
          _activeNavigationPath = null;
        });
        return;
      }
    }

    _addPin(localPos);
  }

  Offset _toIsoLocal(double x, double y, double z) {
    const double gridUnit = 50.0;
    final cartX = x * gridUnit;
    final cartY = y * gridUnit;
    final isoX = (cartX - cartY) * math.cos(math.pi / 6);
    final isoY = (cartX + cartY) * math.sin(math.pi / 6) - z;
    return Offset(isoX, isoY);
  }

  @override
  Widget build(BuildContext context) {
    if (!_engineReady) {
      return const Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.jadePrimary),
        ),
      );
    }

    final floors = _cachedFloors;
    final floor = floors[_currentFloor];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // Isometric Canvas
          GestureDetector(
            onTapDown: (details) {
              _handleCanvasTap(details.localPosition, const Size(400, 500));
            },
            child: InteractiveViewer(
              maxScale: 3.0,
              minScale: 0.5,
              child: Center(
                child: CustomPaint(
                  size: const Size(400, 500),
                  painter: IsometricCampusPainter(
                    currentFloor: _currentFloor,
                    floors: floors,
                    selectedRoomId: _selectedRoomId,
                    pins: _pins,
                    activePath: _activeNavigationPath,
                    onRoomTap: (roomId) {
                      setState(() {
                        _selectedRoomId = roomId;
                        _activeNavigationPath = null; // Reset path on new selection
                      });
                    },
                  ),
                ),
              ),
            ),
          ),

          // Top Header
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liaquat Block',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Bahria University · ${floor.name}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.sageSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.2),

          // Floor Selector (Vertical)
          Positioned(
            right: 20,
            top: 160,
            child: GlassCard(
              borderRadius: 30,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                child: Column(
                  children: List.generate(floors.length, (index) {
                    final reversedIndex = floors.length - 1 - index;
                    final isSelected = _currentFloor == reversedIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentFloor = reversedIndex;
                          _selectedRoomId = null;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppColors.jadePrimary : Colors.white10,
                          boxShadow: isSelected
                              ? [BoxShadow(color: AppColors.jadePrimary.withOpacity(0.5), blurRadius: 12)]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            '$reversedIndex',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white60,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ).animate().fadeIn().slideX(begin: 0.2),

          // Selected Room Info Card
          if (_selectedRoomId != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: _RoomInfoCard(
                room: floors[_currentFloor].rooms.firstWhere((r) => r.id == _selectedRoomId),
                onClose: () => setState(() => _selectedRoomId = null),
                onNavigate: () async {
                  final destId = _selectedRoomId;
                  if (destId != null) {
                    final startId = _currentFloor == 1 ? "liaquat_1_201" : "liaquat_${_currentFloor}_201";
                    final path = await MapEngineService.instance.calculateAStarPath(startId, destId);
                    if (!mounted) return;
                    setState(() {
                      _activeNavigationPath = path;
                      _selectedRoomId = null; // Close card when navigating
                    });
                  }
                },
              ),
            ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutBack),

          // Glowing Turn-by-Turn Navigation Overlay
          if (_activeNavigationPath != null && _activeNavigationPath!.isNotEmpty)
            Positioned(
              top: 140,
              left: 20,
              right: 80,
              child: GlassCard(
                borderRadius: 16,
                borderGlow: Colors.cyanAccent.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.navigation, color: Colors.cyanAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Navigation Active',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Route: ${_activeNavigationPath!.map((r) => r.roomNumber).join(' → ')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.white54, size: 20),
                        onPressed: () {
                          setState(() {
                            _activeNavigationPath = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn().slideY(begin: -0.1),

          // Legend / Hint
          Positioned(
            bottom: 40,
            left: 20,
            child: _selectedRoomId == null ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app_outlined, color: AppColors.sageSecondary, size: 16),
                  SizedBox(width: 8),
                  Text('Tap rooms on current floor level', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ) : const SizedBox(),
          ).animate().fadeIn(delay: 1.seconds),
        ],
      ),
    );
  }
}

class FloorData {
  final int level;
  final String name;
  final List<RoomData> rooms;
  FloorData({required this.level, required this.name, required this.rooms});
}

class RoomData {
  final String id;
  final String roomNumber;
  final String name;
  final double x;
  final double y;
  final double w;
  final double h;
  final Color color;
  RoomData({
    required this.id,
    required this.roomNumber,
    required this.name,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.color,
  });
}

class IsometricCampusPainter extends CustomPainter {
  final int currentFloor;
  final List<FloorData> floors;
  final String? selectedRoomId;
  final List<Map<String, dynamic>> pins;
  final List<CampusRoom>? activePath;
  final Function(String) onRoomTap;

  IsometricCampusPainter({
    required this.currentFloor,
    required this.floors,
    required this.selectedRoomId,
    required this.pins,
    this.activePath,
    required this.onRoomTap,
  });

  static const double gridUnit = 50.0;
  static const double roomHeight = 30.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.7);

    // Draw floors below as ghost layers
    for (int i = 0; i < currentFloor; i++) {
      _drawFloor(canvas, center, floors[i], opacity: 0.15, elevation: (i - currentFloor) * 100.0);
    }

    // Draw current floor
    _drawFloor(canvas, center, floors[currentFloor], opacity: 1.0, elevation: 0.0, isInteractive: true);

    // Draw pins
    for (var pin in pins) {
      if (pin['floor'] == currentFloor) {
        _drawPin(canvas, center, pin['pos'] - center);
      }
    }

    // Draw A* active path routing
    if (activePath != null && activePath!.isNotEmpty) {
      final pathPoints = <Offset>[];
      for (final room in activePath!) {
        if (room.floor == currentFloor) {
          final roomCenter = MapEngineService.instance.getRoomCenter(room);
          final gridX = roomCenter.dx * 6.0;
          final gridY = roomCenter.dy * 6.0;
          final pIso = _toIso(gridX, gridY, 0.0);
          pathPoints.add(center + pIso);
        }
      }

      if (pathPoints.length > 1) {
        final pathPaint = Paint()
          ..color = Colors.cyanAccent.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round;

        final path = Path()..moveTo(pathPoints.first.dx, pathPoints.first.dy);
        for (int i = 1; i < pathPoints.length; i++) {
          path.lineTo(pathPoints[i].dx, pathPoints[i].dy);
        }
        canvas.drawPath(path, pathPaint);

        final pulsePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawPath(path, pulsePaint);

        final startCirclePaint = Paint()..color = Colors.greenAccent;
        final endCirclePaint = Paint()..color = Colors.redAccent;
        canvas.drawCircle(pathPoints.first, 6, startCirclePaint);
        canvas.drawCircle(pathPoints.last, 6, endCirclePaint);
      }
    }
  }

  void _drawFloor(Canvas canvas, Offset center, FloorData floor, {required double opacity, required double elevation, bool isInteractive = false}) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0;

    for (var room in floor.rooms) {
      final isSelected = room.id == selectedRoomId;
      final roomColor = isSelected ? AppColors.jadePrimary : room.color;

      final p1 = _toIso(room.x, room.y, elevation);
      final p2 = _toIso(room.x + room.w, room.y, elevation);
      final p3 = _toIso(room.x + room.w, room.y + room.h, elevation);
      final p4 = _toIso(room.x, room.y + room.h, elevation);

      final path = Path()
        ..moveTo(center.dx + p1.dx, center.dy + p1.dy)
        ..lineTo(center.dx + p2.dx, center.dy + p2.dy)
        ..lineTo(center.dx + p3.dx, center.dy + p3.dy)
        ..lineTo(center.dx + p4.dx, center.dy + p4.dy)
        ..close();

      // Draw shadow/depth
      if (opacity > 0.5) {
        final wallPaint = Paint()..color = roomColor.withOpacity(0.4 * opacity);
        final p1h = _toIso(room.x, room.y, elevation - roomHeight);
        final p2h = _toIso(room.x + room.w, room.y, elevation - roomHeight);

        final wallPath = Path()
          ..moveTo(center.dx + p1.dx, center.dy + p1.dy)
          ..lineTo(center.dx + p2.dx, center.dy + p2.dy)
          ..lineTo(center.dx + p2h.dx, center.dy + p2h.dy)
          ..lineTo(center.dx + p1h.dx, center.dy + p1h.dy)
          ..close();
        canvas.drawPath(wallPath, wallPaint);
      }

      // Draw top face
      canvas.drawPath(path, paint..color = roomColor.withOpacity(0.8 * opacity));

      // Draw border
      canvas.drawPath(path, Paint()..color = Colors.white.withOpacity(0.2 * opacity)..style = PaintingStyle.stroke);
    }
  }

  void _drawPin(Canvas canvas, Offset center, Offset localPos) {
    final p = Paint()..color = Colors.redAccent;
    canvas.drawCircle(center + localPos, 8, p);
    canvas.drawCircle(center + localPos, 12, p..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  Offset _toIso(double x, double y, double z) {
    final cartX = x * gridUnit;
    final cartY = y * gridUnit;
    final isoX = (cartX - cartY) * math.cos(math.pi / 6);
    final isoY = (cartX + cartY) * math.sin(math.pi / 6) - z;
    return Offset(isoX, isoY);
  }

  @override
  bool shouldRepaint(covariant IsometricCampusPainter oldDelegate) {
    return oldDelegate.currentFloor != currentFloor ||
           oldDelegate.selectedRoomId != selectedRoomId ||
           oldDelegate.pins.length != pins.length ||
           oldDelegate.activePath?.length != activePath?.length;
  }

  @override
  bool? hitTest(Offset position) => true;
}

class _RoomInfoCard extends StatelessWidget {
  const _RoomInfoCard({required this.room, required this.onClose, required this.onNavigate});
  final RoomData room;
  final VoidCallback onClose;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      borderGlow: AppColors.jadePrimary.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: room.color),
                ),
                const SizedBox(width: 8),
                Text(
                  'ROOM ${room.roomNumber}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.sageSecondary, letterSpacing: 1),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              room.name,
              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _QuickAction(
                  icon: Icons.directions_rounded, 
                  label: 'Navigate', 
                  color: AppColors.jadePrimary,
                  onTap: onNavigate,
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.chat_bubble_outline, 
                  label: 'Room Chat', 
                  color: Colors.white10,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPrimary = color == AppColors.jadePrimary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isPrimary ? Colors.white : Colors.white70),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isPrimary ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
