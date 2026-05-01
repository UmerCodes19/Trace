import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/simple_post_model.dart';
import '../../../data/services/campus_map_service.dart';

class IndoorMapWidget extends StatefulWidget {
  const IndoorMapWidget({
    super.key,
    required this.building,
    required this.floor,
    required this.posts,
    this.userPos,
    this.onRoomTap,
    this.onPostTap,
    this.onStairTap,
    this.onLongPress,
  });

  final BuildingModel building;
  final int floor;
  final List<SimplePostModel> posts;
  final Offset? userPos;
  final Function(RoomModel)? onRoomTap;
  final Function(SimplePostModel)? onPostTap;
  final Function(StairModel)? onStairTap;
  final Function(Offset normalizedPos)? onLongPress;

  @override
  State<IndoorMapWidget> createState() => _IndoorMapWidgetState();
}

class _IndoorMapWidgetState extends State<IndoorMapWidget> {
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;
  RoomModel? _hoveredRoom;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(() {
      final scale = _transformationController.value.getMaxScaleOnAxis();
      if ((scale - _currentScale).abs() > 0.05) {
        setState(() => _currentScale = scale);
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleTap(Offset localPos, Size mapSize) {
    final floorData = widget.building.floors.firstWhere((f) => f.level == widget.floor);
    final normalizedPos = Offset(localPos.dx / mapSize.width, localPos.dy / mapSize.height);

    for (var room in floorData.rooms) {
      final path = _getRoomPath(room, mapSize);
      if (path.contains(localPos)) {
        widget.onRoomTap?.call(room);
        return;
      }
    }
  }

  Path _getRoomPath(RoomModel room, Size mapSize) {
    final path = Path();
    if (room.polygonPoints != null && room.polygonPoints!.isNotEmpty) {
      path.moveTo(room.polygonPoints!.first.dx * mapSize.width, room.polygonPoints!.first.dy * mapSize.height);
      for (var point in room.polygonPoints!.skip(1)) {
        path.lineTo(point.dx * mapSize.width, point.dy * mapSize.height);
      }
      path.close();
    } else {
      final rect = Rect.fromCenter(
        center: Offset(room.position.dx * mapSize.width, room.position.dy * mapSize.height),
        width: room.size.width * mapSize.width,
        height: room.size.height * mapSize.height,
      );
      path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)));
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final floorData = widget.building.floors.firstWhere((f) => f.level == widget.floor);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.jadePrimary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mapSize = Size(constraints.maxWidth * 2.5, constraints.maxHeight * 2.5);

        return GestureDetector(
          onTapUp: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPos = box.globalToLocal(details.globalPosition);
            final scenePos = _transformationController.toScene(localPos);
            _handleTap(scenePos, mapSize);
          },
          onLongPressStart: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPos = box.globalToLocal(details.globalPosition);
            final scenePos = _transformationController.toScene(localPos);
            
            final normalizedX = (scenePos.dx / mapSize.width).clamp(0.0, 1.0);
            final normalizedY = (scenePos.dy / mapSize.height).clamp(0.0, 1.0);
            widget.onLongPress?.call(Offset(normalizedX, normalizedY));
          },
          child: InteractiveViewer(
            transformationController: _transformationController,
            maxScale: 5.0,
            minScale: 0.2,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            constrained: false,
            child: SizedBox(
              width: mapSize.width,
              height: mapSize.height,
              child: Stack(
                children: [
                  // 1. Vector Map Layer
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _VectorMapPainter(
                        floor: floorData,
                        isDark: isDark,
                        accent: accent,
                        scale: _currentScale,
                      ),
                    ),
                  ),

                  // 2. Interactive Item Layer (Pins, User, Stairs)
                  _buildInteractiveLayer(floorData, mapSize, accent),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractiveLayer(FloorModel floor, Size mapSize, Color accent) {
    return Stack(
      children: [
        // Room Labels (Procedural)
        ...floor.rooms.map((room) {
          final showLabel = _currentScale > 0.7;
          if (!showLabel) return const SizedBox.shrink();

          return Positioned(
            left: room.position.dx * mapSize.width,
            top: room.position.dy * mapSize.height,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: IgnorePointer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      room.number,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16 / _currentScale.clamp(0.5, 2.0),
                        fontWeight: FontWeight.w900,
                        color: accent.withOpacity(0.6),
                        letterSpacing: 1,
                      ),
                    ),
                    if (_currentScale > 1.2)
                      Text(
                        room.name.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10 / _currentScale.clamp(0.5, 2.0),
                          fontWeight: FontWeight.bold,
                          color: accent.withOpacity(0.3),
                          letterSpacing: 2,
                        ),
                      ).animate().fadeIn(),
                  ],
                ),
              ),
            ),
          );
        }),

        // Stairs
        ...floor.stairs.map((stair) {
          return Positioned(
            left: stair.position.dx * mapSize.width,
            top: stair.position.dy * mapSize.height,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: GestureDetector(
                onTap: () => widget.onStairTap?.call(stair),
                child: Container(
                  width: 44 / _currentScale.clamp(0.8, 2.0),
                  height: 44 / _currentScale.clamp(0.8, 2.0),
                  decoration: BoxDecoration(
                    color: AppColors.jadePrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.jadePrimary.withOpacity(0.4), blurRadius: 12, spreadRadius: 2),
                    ],
                  ),
                  child: Icon(Icons.stairs_rounded, size: 22 / _currentScale.clamp(0.8, 2.0), color: Colors.white),
                ),
              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
            ),
          );
        }),

        // Pins
        ...widget.posts.where((p) {
          return p.location.building == widget.building.name && p.location.floor == widget.floor;
        }).map((post) {
          Offset pos;
          if (post.location.indoorX != null && post.location.indoorY != null) {
            pos = Offset(post.location.indoorX!, post.location.indoorY!);
          } else {
            final room = post.location.room != null ? CampusMapService.findRoom(post.location.room!) : null;
            pos = room?.position ?? const Offset(0.5, 0.5);
          }

          final showPreview = _currentScale > 1.8;

          return Positioned(
            left: pos.dx * mapSize.width,
            top: pos.dy * mapSize.height,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -1.0),
              child: GestureDetector(
                onTap: () => widget.onPostTap?.call(post),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showPreview)
                      _MiniPostPreview(post: post).animate().scale(curve: Curves.easeOutBack),
                    RepaintBoundary(
                      child: _IndoorPin(
                        color: post.isLost ? AppColors.lost : AppColors.found,
                        scale: 1.0 / _currentScale.clamp(0.5, 2.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        // User
        if (widget.userPos != null)
          Positioned(
            left: widget.userPos!.dx * mapSize.width,
            top: widget.userPos!.dy * mapSize.height,
            child: const FractionalTranslation(
              translation: Offset(-0.5, -0.5),
              child: _UserLocationRadar(),
            ),
          ),
      ],
    );
  }
}

class _VectorMapPainter extends CustomPainter {
  final FloorModel floor;
  final bool isDark;
  final Color accent;
  final double scale;

  _VectorMapPainter({
    required this.floor,
    required this.isDark,
    required this.accent,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = isDark ? const Color(0xFF0A0F0D) : const Color(0xFFF5F7F6);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw Grid
    _drawGrid(canvas, size);

    // Draw Rooms
    for (var room in floor.rooms) {
      _drawRoom(canvas, size, room);
    }

    // Draw Walls
    _drawWalls(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = accent.withOpacity(isDark ? 0.05 : 0.1)
      ..strokeWidth = 1.0;

    const spacing = 50.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
  }

  void _drawRoom(Canvas canvas, Size size, RoomModel room) {
    final path = Path();
    if (room.polygonPoints != null && room.polygonPoints!.isNotEmpty) {
      path.moveTo(room.polygonPoints!.first.dx * size.width, room.polygonPoints!.first.dy * size.height);
      for (var point in room.polygonPoints!.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      path.close();
    } else {
      final rect = Rect.fromCenter(
        center: Offset(room.position.dx * size.width, room.position.dy * size.height),
        width: room.size.width * size.width,
        height: room.size.height * size.height,
      );
      path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)));
    }

    // Room Fill (Glass effect)
    final fillPaint = Paint()
      ..color = accent.withOpacity(isDark ? 0.08 : 0.12)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, fillPaint);

    // Room Border
    final borderPaint = Paint()
      ..color = accent.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / scale.clamp(0.5, 2.0);
    
    canvas.drawPath(path, borderPaint);

    // Subtle Glow
    if (scale > 1.0) {
      canvas.drawPath(path, Paint()
        ..color = accent.withOpacity(0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10));
    }
  }

  void _drawWalls(Canvas canvas, Size size) {
    final wallPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 / scale.clamp(0.5, 2.0)
      ..strokeCap = StrokeCap.round;

    for (var poly in floor.wallPolygons) {
      if (poly.isEmpty) continue;
      final path = Path();
      path.moveTo(poly.first.dx * size.width, poly.first.dy * size.height);
      for (var point in poly.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      canvas.drawPath(path, wallPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VectorMapPainter oldDelegate) => 
    oldDelegate.floor != floor || oldDelegate.scale != scale || oldDelegate.isDark != isDark;
}

class _MiniPostPreview extends StatelessWidget {
  const _MiniPostPreview({required this.post});
  final SimplePostModel post;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 34, height: 34,
              color: AppColors.shimmerBase(context),
              child: post.imageUrls.isNotEmpty 
                ? Image.network(post.imageUrls.first, fit: BoxFit.cover)
                : const Icon(Icons.image, size: 16),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(post.isLost ? 'LOST' : 'FOUND', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: post.isLost ? AppColors.lost : AppColors.found)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndoorPin extends StatelessWidget {
  const _IndoorPin({required this.color, this.scale = 1.0});
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, color: color, size: 32)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: -4, duration: 800.ms, curve: Curves.easeInOut),
          Container(
            width: 10, height: 3,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2), 
              borderRadius: BorderRadius.circular(2),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, spreadRadius: 1)]
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleX(begin: 0.8, end: 1.2, duration: 800.ms),
        ],
      ),
    );
  }
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
          width: 50, height: 50,
          decoration: BoxDecoration(color: accent.withOpacity(0.2), shape: BoxShape.circle),
        ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0, 0), end: const Offset(1, 1)).fadeOut(),
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            color: accent, 
            shape: BoxShape.circle, 
            border: Border.all(color: Colors.white, width: 2.5), 
            boxShadow: [BoxShadow(color: accent.withOpacity(0.5), blurRadius: 12, spreadRadius: 3)]
          ),
        ),
      ],
    );
  }
}
