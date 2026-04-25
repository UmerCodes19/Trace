import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
                  accentColor: Theme.of(context).colorScheme.primary,
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

              // Pins
              ...posts.where((p) {
                // Filter posts that belong to this building and floor
                // For now we match by room number string starting with building initial
                return p.location.room != null && 
                       p.location.room!.startsWith(building.name[0]) &&
                       p.location.floor == floor;
              }).map((post) {
                final room = CampusMapService.findRoom(post.location.room!);
                if (room == null) return const SizedBox();

                return Positioned(
                  left: room.position.dx * constraints.maxWidth,
                  top: room.position.dy * constraints.maxHeight,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -1.0),
                    child: GestureDetector(
                      onTap: () => onPostTap?.call(post),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: post.isLost ? AppColors.lostAlert : AppColors.foundSuccess,
                        size: 30,
                      ),
                    ),
                  ),
                );
              }),

              // User Location
              if (userPos != null)
                Positioned(
                  left: userPos!.dx * constraints.maxWidth,
                  top: userPos!.dy * constraints.maxHeight,
                  child: const FractionalTranslation(
                    translation: Offset(-0.5, -0.5),
                    child: _UserLocationIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
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
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = isDark ? Colors.white24 : Colors.black12
      ..strokeWidth = 1.0;

    for (var room in rooms) {
      final rect = Rect.fromCenter(
        center: Offset(room.position.dx * size.width, room.position.dy * size.height),
        width: room.size.width * size.width,
        height: room.size.height * size.height,
      );

      // Room Fill
      paint.color = accentColor.withOpacity(0.1);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
      
      // Room Border
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), borderPaint);

      // Room Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: room.number,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white38 : Colors.black38,
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

class _UserLocationIndicator extends StatelessWidget {
  const _UserLocationIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
