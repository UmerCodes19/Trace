import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/simple_post_model.dart';
import '../../../data/models/map/campus_gis_models.dart';
import '../../../data/services/map/map_engine_service.dart';

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

  final dynamic building;
  final int floor;
  final List<SimplePostModel> posts;
  final Offset? userPos;
  final Function(dynamic)? onRoomTap;
  final Function(SimplePostModel)? onPostTap;
  final Function(dynamic)? onStairTap;
  final Function(Offset normalizedPos)? onLongPress;

  @override
  State<IndoorMapWidget> createState() => _IndoorMapWidgetState();
}

class _IndoorMapWidgetState extends State<IndoorMapWidget> {
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;
  CampusRoom? _hoveredRoom;
  bool _engineReady = false;
  List<CampusRoom>? _activePath;

  @override
  void initState() {
    super.initState();
    _initEngine();
    _transformationController.addListener(() {
      final scale = _transformationController.value.getMaxScaleOnAxis();
      // PERF: Only rebuild when crossing visibility thresholds, not on every minor delta.
      // Labels toggle at 0.6, post previews at 0.8 — no need to rebuild between thresholds.
      final bool crossedThreshold = (_currentScale > 0.6) != (scale > 0.6) ||
                                     (_currentScale > 0.8) != (scale > 0.8);
      if (crossedThreshold) {
        setState(() => _currentScale = scale);
      } else {
        _currentScale = scale; // Update value without rebuild
      }
    });
  }

  Future<void> _initEngine() async {
    await MapEngineService.instance.initialize();
    if (mounted) {
      setState(() {
        _engineReady = true;
        // Center-zoom initial view so the entire map is visible and beautiful
        _transformationController.value = Matrix4.identity()
          ..translate(-200.0, -100.0)
          ..scale(0.6);
      });
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap(Offset localPos, Size mapSize) async {
    if (!_engineReady) return;
    final normalizedPos = Offset(localPos.dx / mapSize.width, localPos.dy / mapSize.height);
    final room = MapEngineService.instance.detectRoomFromCoordinate(normalizedPos, widget.floor);

    debugPrint('TRACE DEBUG: Tapped localPos=$localPos, normalizedPos=$normalizedPos, room detected=${room?.id} (${room?.roomNumber})');

    if (room != null) {
      final startId = widget.floor == 1 ? "liaquat_1_201" : "liaquat_${widget.floor}_201";
      debugPrint('TRACE DEBUG: Calculating path on background thread from startId=$startId to endId=${room.id}');
      final path = await MapEngineService.instance.calculateAStarPath(startId, room.id);
      debugPrint('TRACE DEBUG: Isolate result count = ${path.length}');
      
      if (!mounted) return;
      setState(() {
        _activePath = path;
      });
      widget.onRoomTap?.call(room);
    }
  }

  void _handleHover(Offset localPos, Size mapSize) {
    if (!_engineReady) return;
    final normalizedPos = Offset(localPos.dx / mapSize.width, localPos.dy / mapSize.height);
    final room = MapEngineService.instance.detectRoomFromCoordinate(normalizedPos, widget.floor);

    if (room != _hoveredRoom) {
      setState(() {
        _hoveredRoom = room;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_engineReady) {
      return Center(
        child: const CircularProgressIndicator(strokeWidth: 2).animate().scale(),
      );
    }

    final gisRooms = MapEngineService.instance.getRoomsOnFloor(widget.floor);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.jadePrimary;

    // Spacious 1200 x 1680 virtual layout canvas giving room vectors huge breathing room
    const mapSize = Size(1200.0, 1680.0);

    return MouseRegion(
      onHover: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPos = box.globalToLocal(details.position);
        final scenePos = _transformationController.toScene(localPos);
        _handleHover(scenePos, mapSize);
      },
      child: Container(
        color: Colors.transparent,
        child: InteractiveViewer(
          transformationController: _transformationController,
          maxScale: 3.0,
          minScale: 0.3,
          boundaryMargin: const EdgeInsets.symmetric(horizontal: 300.0, vertical: 400.0), // Restrict panning tightly
          panEnabled: true,
          scaleEnabled: true,
          constrained: false, // Large unconstrained canvas for spacious placement
          child: SizedBox(
            width: mapSize.width,
            height: mapSize.height,
            child: Stack(
              children: [
                // Layer 0: Background Tap Target for Room Selection
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
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
                  ),
                ),
                // Layer 1-4: Map Custom Painters
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _VectorMapPainter(
                        rooms: gisRooms,
                        isDark: isDark,
                        accent: accent,
                        scale: _currentScale,
                        hoveredRoomId: _hoveredRoom?.id,
                        activePath: _activePath,
                      ),
                    ),
                  ),
                ),

                  // Layer 5: Heatmaps (wrapped in RepaintBoundary)
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _HeatmapPainter(
                            posts: widget.posts,
                            rooms: gisRooms,
                            scale: _currentScale,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Layer 6-8: Badges, Markers, Overlays
                  _buildInteractiveLayer(gisRooms, mapSize, accent, isDark),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildInteractiveLayer(List<CampusRoom> rooms, Size mapSize, Color accent, bool isDark) {
    return Stack(
      children: [
        // Pill-Badge Room Labels (Incredibly spacious and clear on a 1200x1680 canvas!)
        ...rooms.where((r) => r.type != RoomType.hallway).map((room) {
          final center = MapEngineService.instance.getRoomCenter(room);

          final isHovered = room.id == _hoveredRoom?.id;
          final isWashroom = room.type == RoomType.washroom;
          final isStairs = room.type == RoomType.staircase || room.type == RoomType.elevator;

          Color badgeBorderColor = accent.withOpacity(0.35);
          Color textColor = isDark ? Colors.white : Colors.black87;
          
          if (isHovered) {
            badgeBorderColor = accent;
          } else if (isWashroom) {
            badgeBorderColor = Colors.blueAccent.withOpacity(0.4);
          } else if (isStairs) {
            badgeBorderColor = Colors.orangeAccent.withOpacity(0.4);
          }

          // Fixed readable text sizes on spacious canvas
          final fontSize = isHovered ? 15.0 : 13.5;

          return Positioned(
            left: center.dx * mapSize.width,
            top: center.dy * mapSize.height,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161F1B).withOpacity(0.92) : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: badgeBorderColor, width: isHovered ? 1.8 : 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        room.roomNumber,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (_currentScale > 0.6 && room.name != room.roomNumber)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            room.name.split(' ').take(2).join(' ').toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9.0,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white54 : Colors.black54,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        // Semantic Landmarks
        ...rooms.expand((room) => room.anchorPoints).map((anchor) {
          return Positioned(
            left: anchor.position.dx * mapSize.width,
            top: anchor.position.dy * mapSize.height,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orangeAccent.withOpacity(0.5), width: 1.0),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.orangeAccent,
                  ),
                ),
              ),
            ),
          );
        }),

        // Active Post Pins
        ...widget.posts.where((p) {
          final isLiaquat = p.location.building.toLowerCase().contains("liaquat");
          final isCorrectFloor = p.location.floor == widget.floor || 
                                (widget.floor == 1 && (p.location.room?.toLowerCase().contains("lab") ?? false));
          return isLiaquat && isCorrectFloor;
        }).map((post) {
          Offset pos;
          if (post.location.indoorX != null && post.location.indoorY != null) {
            pos = Offset(post.location.indoorX!, post.location.indoorY!);
          } else {
            final matchedRoom = rooms.firstWhere(
              (r) {
                final rNum = r.roomNumber.toLowerCase();
                final postRoom = (post.location.room ?? '').toLowerCase();
                return rNum == postRoom ||
                       rNum.replaceAll('e-', '') == postRoom.replaceAll('e-', '') ||
                       r.name.toLowerCase().contains(postRoom) ||
                       postRoom.contains(r.name.toLowerCase()) ||
                       postRoom.contains(rNum);
              },
              orElse: () => rooms.first,
            );
            pos = MapEngineService.instance.getRoomCenter(matchedRoom);
          }

          final showPreview = _currentScale > 0.8;

          return Positioned(
            left: pos.dx * mapSize.width,
            top: pos.dy * mapSize.height,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -1.0),
              child: GestureDetector(
                onTap: () => widget.onPostTap?.call(post),
                child: RepaintBoundary(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showPreview)
                        _MiniPostPreview(post: post).animate().scale(curve: Curves.easeOutBack),
                      _IndoorPin(
                        color: post.isLost ? AppColors.lost : AppColors.found,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        // User Radar Dot
        if (widget.userPos != null)
          Positioned(
            left: widget.userPos!.dx * mapSize.width,
            top: widget.userPos!.dy * mapSize.height,
            child: const RepaintBoundary(
              child: FractionalTranslation(
                translation: Offset(-0.5, -0.5),
                child: _UserLocationRadar(),
              ),
            ),
          ),
      ],
    );
  }
}

class _VectorMapPainter extends CustomPainter {
  final List<CampusRoom> rooms;
  final bool isDark;
  final Color accent;
  final double scale;
  final String? hoveredRoomId;
  final List<CampusRoom>? activePath;

  _VectorMapPainter({
    required this.rooms,
    required this.isDark,
    required this.accent,
    required this.scale,
    this.hoveredRoomId,
    this.activePath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Layer: Background
    final bgPaint = Paint()..color = isDark ? const Color(0xFF0F1412) : const Color(0xFFECEFEF);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Layer: Unified structural floor plan outline
    final floorBoundaryPaint = Paint()
      ..color = isDark ? const Color(0xFF161F1B) : Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.02 * size.width, 0.02 * size.height, 0.96 * size.width, 0.96 * size.height),
        const Radius.circular(20),
      ),
      floorBoundaryPaint,
    );

    // Draw grid lines inside the boundary
    final gridPaint = Paint()
      ..color = accent.withOpacity(isDark ? 0.03 : 0.06)
      ..strokeWidth = 1.0;
    const spacing = 45.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // 3. Layer: Main Corridor/Hallway connecting pathways
    final corridorPaint = Paint()
      ..color = isDark ? const Color(0xFF1E2724) : const Color(0xFFECEFEF)
      ..style = PaintingStyle.fill;

    // Symmetrical vertical spine corridor (width 0.30 spanning from 0.35 to 0.65)
    canvas.drawRect(
      Rect.fromLTRB(0.35 * size.width, 0.02 * size.height, 0.65 * size.width, 0.98 * size.height),
      corridorPaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(0.02 * size.width, 0.18 * size.height, 0.98 * size.width, 0.22 * size.height),
      corridorPaint,
    );

    // 4. Layer: Rooms rendering
    for (var room in rooms.where((room) => room.type != RoomType.hallway)) {
      final isHovered = room.id == hoveredRoomId;
      final isWashroom = room.type == RoomType.washroom;
      final isStairs = room.type == RoomType.staircase || room.type == RoomType.elevator;

      Color roomColor = accent.withOpacity(isDark ? 0.09 : 0.06);
      if (isWashroom) {
        roomColor = Colors.blueAccent.withOpacity(isDark ? 0.08 : 0.05);
      } else if (isStairs) {
        roomColor = Colors.orangeAccent.withOpacity(isDark ? 0.08 : 0.05);
      }

      if (isHovered) {
        roomColor = accent.withOpacity(0.20);
      }

      final fillPaint = Paint()
        ..color = roomColor
        ..style = PaintingStyle.fill;

      _drawPolygon(canvas, size, room, fillPaint);

      // Dividing room walls
      final borderPaint = Paint()
        ..color = isHovered 
            ? accent 
            : (isStairs ? Colors.orangeAccent.withOpacity(0.4) : accent.withOpacity(0.22))
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 2.2 : 1.2;

      _drawPolygon(canvas, size, room, borderPaint);

      if (isHovered) {
        final glowPath = _getPath(size, room);
        canvas.drawPath(glowPath, Paint()
          ..color = accent.withOpacity(0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8));
      }
    }

    // Outer structural building wall outline
    final outerWallPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.02 * size.width, 0.02 * size.height, 0.96 * size.width, 0.96 * size.height),
        const Radius.circular(20),
      ),
      outerWallPaint,
    );

    // 5. Layer: Draw A* Navigation Path
    if (activePath != null && activePath!.isNotEmpty) {
      final pathPaint = Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;

      final path = Path();
      bool first = true;

      for (var room in activePath!) {
        final centerPoint = MapEngineService.instance.getRoomCenter(room);
        final drawX = centerPoint.dx * size.width;
        final drawY = centerPoint.dy * size.height;

        if (first) {
          path.moveTo(drawX, drawY);
          first = false;
        } else {
          path.lineTo(drawX, drawY);
        }
      }

      if (!first) {
        canvas.drawPath(path, pathPaint);

        final pulsePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawPath(path, pulsePaint);
      }
    }
  }

  Path _getPath(Size size, CampusRoom room) {
    final path = Path();
    path.moveTo(room.polygonPoints.first.dx * size.width, room.polygonPoints.first.dy * size.height);
    for (var point in room.polygonPoints.skip(1)) {
      path.lineTo(point.dx * size.width, point.dy * size.height);
    }
    path.close();
    return path;
  }

  void _drawPolygon(Canvas canvas, Size size, CampusRoom room, Paint paint) {
    if (room.polygonPoints.isEmpty) return;
    final path = _getPath(size, room);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _VectorMapPainter oldDelegate) =>
      oldDelegate.hoveredRoomId != hoveredRoomId ||
      oldDelegate.scale != scale ||
      oldDelegate.isDark != isDark ||
      oldDelegate.activePath != activePath;
}

class _HeatmapPainter extends CustomPainter {
  final List<SimplePostModel> posts;
  final List<CampusRoom> rooms;
  final double scale;

  _HeatmapPainter({
    required this.posts,
    required this.rooms,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Map<String, int> roomHeatCounts = {};
    final List<Offset> coordinateHeatPoints = [];

    for (var post in posts) {
      if (post.location.indoorX != null && post.location.indoorY != null) {
        coordinateHeatPoints.add(Offset(post.location.indoorX!, post.location.indoorY!));
      } else if (post.location.room != null) {
        final roomNum = post.location.room!;
        roomHeatCounts[roomNum] = (roomHeatCounts[roomNum] ?? 0) + 1;
      }
    }

    // Room heat overlays
    for (var entry in roomHeatCounts.entries) {
      final matchedRoom = rooms.firstWhere(
        (r) => r.roomNumber.toLowerCase() == entry.key.toLowerCase(),
        orElse: () => const CampusRoom(id: '', roomNumber: '', name: '', building: '', floor: 0, polygonPoints: [], type: RoomType.unknown),
      );

      if (matchedRoom.id.isNotEmpty && matchedRoom.polygonPoints.isNotEmpty) {
        final intensity = (entry.value * 0.15).clamp(0.12, 0.45);
        final heatPaint = Paint()
          ..color = Colors.redAccent.withOpacity(intensity)
          ..style = PaintingStyle.fill;

        final path = Path();
        path.moveTo(matchedRoom.polygonPoints.first.dx * size.width, matchedRoom.polygonPoints.first.dy * size.height);
        for (var point in matchedRoom.polygonPoints.skip(1)) {
          path.lineTo(point.dx * size.width, point.dy * size.height);
        }
        path.close();

        canvas.drawPath(path, heatPaint);

        canvas.drawPath(path, Paint()
          ..color = Colors.redAccent.withOpacity(intensity * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12));
      }
    }

    // Coordinate heat rings
    for (var point in coordinateHeatPoints) {
      final center = Offset(point.dx * size.width, point.dy * size.height);
      final radius = 30.0;

      final Paint ringPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.redAccent.withOpacity(0.35),
            Colors.redAccent.withOpacity(0.12),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) =>
      oldDelegate.posts.length != posts.length ||
      oldDelegate.rooms.length != rooms.length ||
      oldDelegate.scale != scale;
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
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
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
  const _IndoorPin({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on_rounded, color: color, size: 28)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -4, duration: 800.ms, curve: Curves.easeInOut),
        Container(
          width: 8, height: 3,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2), 
            borderRadius: BorderRadius.circular(2),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleX(begin: 0.8, end: 1.2, duration: 800.ms),
      ],
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
          width: 40, height: 40,
          decoration: BoxDecoration(color: accent.withOpacity(0.2), shape: BoxShape.circle),
        ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0, 0), end: const Offset(1, 1)).fadeOut(),
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color: accent, 
            shape: BoxShape.circle, 
            border: Border.all(color: Colors.white, width: 2), 
            boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 6, spreadRadius: 1)]
          ),
        ),
      ],
    );
  }
}
