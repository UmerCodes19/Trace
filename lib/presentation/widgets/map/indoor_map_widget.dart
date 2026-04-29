// lib/presentation/widgets/map/indoor_map_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/simple_post_model.dart';
import '../../../data/services/campus_map_service.dart';

class IndoorMapWidget extends StatelessWidget {
  const IndoorMapWidget({
    super.key,
    required this.building,
    required this.floor,
    required this.posts,
    this.userPos,
    this.onRoomTap,
    this.onPostTap,
  });

  final BuildingModel building;
  final int floor;
  final List<SimplePostModel> posts;
  final Offset? userPos;
  final Function(RoomModel)? onRoomTap;
  final Function(SimplePostModel)? onPostTap;

  @override
  Widget build(BuildContext context) {
    final floorData = building.floors.firstWhere((f) => f.level == floor);
    final accent = Theme.of(context).colorScheme.primary;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          maxScale: 5.0,
          minScale: 0.5,
          child: Stack(
            children: [
              // Map Background / Rooms
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _IndoorMapPainter(
                  rooms: floorData.rooms,
                  accentColor: accent,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
              ),
              
              // Room Tappable Areas
              ...floorData.rooms.map((room) {
                return Positioned(
                  left: room.position.dx * constraints.maxWidth - (room.size.width * constraints.maxWidth / 2),
                  top: room.position.dy * constraints.maxHeight - (room.size.height * constraints.maxHeight / 2),
                  child: GestureDetector(
                    onTap: () => onRoomTap?.call(room),
                    child: Container(
                      width: room.size.width * constraints.maxWidth,
                      height: room.size.height * constraints.maxHeight,
                      color: Colors.transparent,
                    ),
                  ),
                );
              }),

              // Pins with Lively Pulse
              ...posts.where((p) {
                // Show if it belongs to this building and floor
                final inThisBuilding = p.location.building == building.name || 
                                     (p.location.room != null && p.location.room!.startsWith(building.id[0].toUpperCase()));
                return inThisBuilding && p.location.floor == floor;
              }).map((post) {
                // Try to find specific room position
                RoomModel? room;
                if (post.location.room != null) {
                  room = CampusMapService.findRoom(post.location.room!);
                }
                
                // Fallback to lobby or center if room not found or not specified
                final pos = room?.position ?? const Offset(0.5, 0.5);

                return Positioned(
                  left: pos.dx * constraints.maxWidth,
                  top: pos.dy * constraints.maxHeight,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -1.0),
                    child: GestureDetector(
                      onTap: () => onPostTap?.call(post),
                      child: _IndoorPin(color: post.isLost ? AppColors.lost : AppColors.found),
                    ),
                  ),
                );
              }),

              // User Location with Dynamic Radar
              if (userPos != null)
                Positioned(
                  left: userPos!.dx * constraints.maxWidth,
                  top: userPos!.dy * constraints.maxHeight,
                  child: const FractionalTranslation(
                    translation: Offset(-0.5, -0.5),
                    child: _UserLocationRadar(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _IndoorPin extends StatelessWidget {
  const _IndoorPin({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on_rounded, color: color, size: 30)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -4, duration: 600.ms, curve: Curves.easeInOut),
        Container(
          width: 8, height: 2,
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleX(begin: 1, end: 1.5, duration: 600.ms),
      ],
    );
  }
}

class _IndoorMapPainter extends CustomPainter {
  _IndoorMapPainter({
    required this.rooms,
    required this.accentColor,
    required this.isDark,
  });

  final List<RoomModel> rooms;
  final Color accentColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = isDark ? Colors.white10 : Colors.black12
      ..strokeWidth = 1.0;

    for (var room in rooms) {
      final rect = Rect.fromCenter(
        center: Offset(room.position.dx * size.width, room.position.dy * size.height),
        width: room.size.width * size.width,
        height: room.size.height * size.height,
      );

      // Room Fill
      paint.color = accentColor.withOpacity(0.08);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), paint);
      
      // Room Border
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), borderPaint);

      // Room Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: room.number,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, rect.center - Offset(textPainter.width / 2, textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UserLocationRadar extends StatelessWidget {
  const _UserLocationRadar();

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.jadePrimary;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: accent.withOpacity(0.2), shape: BoxShape.circle),
        ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0, 0), end: const Offset(1, 1)).fadeOut(),
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: accent.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)]),
        ),
      ],
    );
  }
}
