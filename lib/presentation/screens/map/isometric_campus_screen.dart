import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

import '../../../core/constants/app_colors.dart';
import '../../widgets/common/glass_card.dart';

class IsometricCampusScreen extends ConsumerStatefulWidget {
  const IsometricCampusScreen({super.key});

  @override
  ConsumerState<IsometricCampusScreen> createState() => _IsometricCampusScreenState();
}

class _IsometricCampusScreenState extends ConsumerState<IsometricCampusScreen> {
  int _currentFloor = 0;
  String? _selectedRoom;
  final List<Map<String, dynamic>> _pins = [];

  // Define a sample building structure
  final List<FloorData> _buildingData = [
    FloorData(
      level: 0,
      name: 'Ground Floor',
      rooms: [
        RoomData(id: 'G1', name: 'Main Lobby', x: 0, y: 0, w: 2, h: 2, color: Colors.blueGrey),
        RoomData(id: 'G2', name: 'Cafeteria', x: 2, y: 0, w: 2, h: 3, color: Colors.orangeAccent),
        RoomData(id: 'G3', name: 'Admin Office', x: 0, y: 2, w: 2, h: 1, color: Colors.teal),
      ],
    ),
    FloorData(
      level: 1,
      name: 'Floor 1',
      rooms: [
        RoomData(id: '101', name: 'Computer Lab 1', x: 0, y: 0, w: 2, h: 2, color: Colors.indigoAccent),
        RoomData(id: '102', name: 'Faculty Lounge', x: 2, y: 0, w: 2, h: 1, color: Colors.pinkAccent),
        RoomData(id: '103', name: 'Lecture Hall A', x: 0, y: 2, w: 4, h: 2, color: Colors.deepPurpleAccent),
      ],
    ),
    FloorData(
      level: 2,
      name: 'Floor 2 (Rooftop)',
      rooms: [
        RoomData(id: 'R1', name: 'Innovation Hub', x: 1, y: 1, w: 2, h: 2, color: AppColors.jadePrimary),
        RoomData(id: 'R2', name: 'Solar Deck', x: 0, y: 0, w: 4, h: 1, color: Colors.amber),
      ],
    ),
  ];

  void _addPin(Offset localPos) {
    // Basic hit detection and pin placement
    setState(() {
      _pins.add({
        'floor': _currentFloor,
        'pos': localPos,
        'timestamp': DateTime.now(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final floor = _buildingData[_currentFloor];

    return Scaffold(
      backgroundColor: AppColors.darkBg, // Deep dark for a "Tech" feel
      body: Stack(
        children: [
          // ─── The Isometric Canvas ──────────────────────────────────────────
          GestureDetector(
            onTapDown: (details) {
              // In a real app, we'd map this to grid coords
              _addPin(details.localPosition);
            },
            child: InteractiveViewer(
              maxScale: 3.0,
              minScale: 0.5,
              child: Center(
                child: CustomPaint(
                  size: const Size(400, 500),
                  painter: IsometricCampusPainter(
                    currentFloor: _currentFloor,
                    floors: _buildingData,
                    selectedRoomId: _selectedRoom,
                    pins: _pins,
                    onRoomTap: (roomId) {
                      setState(() => _selectedRoom = roomId);
                    },
                  ),
                ),
              ),
            ),
          ),

          // ─── Top Header ──────────────────────────────────────────────────
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
                      'Ibn Khaldun Block',
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

          // ─── Floor Selector (Vertical) ───────────────────────────────────
          Positioned(
            right: 20,
            top: 200,
            child: GlassCard(
              borderRadius: 30,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                child: Column(
                  children: List.generate(_buildingData.length, (index) {
                    final reversedIndex = _buildingData.length - 1 - index;
                    final isSelected = _currentFloor == reversedIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentFloor = reversedIndex;
                          _selectedRoom = null;
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

          // ─── Selected Room Info Card ──────────────────────────────────────
          if (_selectedRoom != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: _RoomInfoCard(
                room: _getRoomData(_selectedRoom!),
                onClose: () => setState(() => _selectedRoom = null),
              ),
            ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutBack),
          
          // ─── Legend / Hint ────────────────────────────────────────────────
          Positioned(
            bottom: 40,
            left: 20,
            child: _selectedRoom == null ? Container(
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
                  Text('Tap a room to see details', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ) : const SizedBox(),
          ).animate().fadeIn(delay: 1.seconds),
        ],
      ),
    );
  }

  RoomData _getRoomData(String id) {
    for (var f in _buildingData) {
      for (var r in f.rooms) {
        if (r.id == id) return r;
      }
    }
    return _buildingData[0].rooms[0];
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
  final String name;
  final double x; // grid x
  final double y; // grid y
  final double w; // grid width
  final double h; // grid height
  final Color color;
  RoomData({required this.id, required this.name, required this.x, required this.y, required this.w, required this.h, required this.color});
}

class IsometricCampusPainter extends CustomPainter {
  final int currentFloor;
  final List<FloorData> floors;
  final String? selectedRoomId;
  final List<Map<String, dynamic>> pins;
  final Function(String) onRoomTap;

  IsometricCampusPainter({
    required this.currentFloor,
    required this.floors,
    required this.selectedRoomId,
    required this.pins,
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
  }

  void _drawFloor(Canvas canvas, Offset center, FloorData floor, {required double opacity, required double elevation, bool isInteractive = false}) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0;

    for (var room in floor.rooms) {
      final isSelected = room.id == selectedRoomId;
      final roomColor = isSelected ? AppColors.jadePrimary : room.color;
      
      // Calculate isometric points for the floor polygon
      final p1 = _toIso(room.x, room.y, elevation);
      final p2 = _toIso(room.x + room.w, room.y, elevation);
      final p3 = _toIso(room.x + room.w, room.y + room.h, elevation);
      final p4 = _toIso(room.x, room.y + room.h, elevation);

      final path = Path()..moveTo(center.dx + p1.dx, center.dy + p1.dy)
        ..lineTo(center.dx + p2.dx, center.dy + p2.dy)
        ..lineTo(center.dx + p3.dx, center.dy + p3.dy)
        ..lineTo(center.dx + p4.dx, center.dy + p4.dy)
        ..close();

      // Draw shadow/depth
      if (opacity > 0.5) {
        final wallPaint = Paint()..color = roomColor.withOpacity(0.4 * opacity);
        final p1h = _toIso(room.x, room.y, elevation - roomHeight);
        final p2h = _toIso(room.x + room.w, room.y, elevation - roomHeight);
        
        final wallPath = Path()..moveTo(center.dx + p1.dx, center.dy + p1.dy)
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
    // Isometric projection math
    final cartX = x * gridUnit;
    final cartY = y * gridUnit;
    final isoX = (cartX - cartY) * math.cos(math.pi / 6);
    final isoY = (cartX + cartY) * math.sin(math.pi / 6) - z;
    return Offset(isoX, isoY);
  }

  @override
  bool shouldRepaint(covariant IsometricCampusPainter oldDelegate) => true;

  @override
  bool? hitTest(Offset position) {
    // Here we'd implement real hit testing for room selection
    // For the demo, we'll let the parent handle the interaction logic
    return true; 
  }
}

class _RoomInfoCard extends StatelessWidget {
  const _RoomInfoCard({required this.room, required this.onClose});
  final RoomData room;
  final VoidCallback onClose;

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
                  'ROOM ${room.id}',
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
                _QuickAction(icon: Icons.add_location_alt_rounded, label: 'Report Found', color: AppColors.jadePrimary),
                const SizedBox(width: 12),
                _QuickAction(icon: Icons.chat_bubble_outline, label: 'Room Chat', color: Colors.white10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isPrimary = color == AppColors.jadePrimary;
    return Expanded(
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
    );
  }
}
