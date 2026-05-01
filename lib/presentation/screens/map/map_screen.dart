// lib/presentation/screens/map/map_screen.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_post_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/campus_map_service.dart';
import '../../../data/services/indoor_positioning_service.dart';
import '../../widgets/map/indoor_map_widget.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/pressable_scale.dart';

const _bahriaCampus = LatLng(24.893240, 67.088235);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  List<SimplePostModel> _posts = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; 
  
  bool _isIndoorMode = true;
  BuildingModel _activeBuilding = CampusMapService.buildings[0];
  int _activeFloor = 0;
  CampusLocation? _userIndoorPos;
  StreamSubscription? _posSubscription;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _startPositioning();
  }

  void _startPositioning() {
    IndoorPositioningService.instance.startPositioning();
    _posSubscription = IndoorPositioningService.instance.positionStream.listen((loc) {
      if (mounted) {
        setState(() {
          _userIndoorPos = loc;
          if (loc.building == _activeBuilding.name) {
            _activeFloor = loc.floor;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _posSubscription?.cancel();
    IndoorPositioningService.instance.stopPositioning();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    final api = ref.read(apiServiceProvider);
    final postsData = await api.getPosts(status: 'open');
    if (!mounted) return;
    setState(() {
      _posts = postsData.map((p) => SimplePostModel.fromMap(p)).toList();
      _isLoading = false;
    });
  }

  List<SimplePostModel> get _filteredPosts {
    if (_selectedFilter == 'lost') {
      return _posts.where((p) => p.isLost).toList();
    } else if (_selectedFilter == 'found') {
      return _posts.where((p) => p.isFound).toList();
    }
    return _posts;
  }

  void _showPinBottomSheet(SimplePostModel post) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PinPreviewSheet(
        post: post,
        onViewPost: () {
          Navigator.pop(context);
          context.push('/post/${post.id}');
        },
      ),
    );
  }

  Future<void> _enterBuilding(BuildingModel building) async {
    HapticFeedback.mediumImpact();
    
    // 1. Zoom in animation
    _mapController.move(LatLng(building.lat, building.lng), 18.5);
    
    await Future.delayed(300.ms);
    
    if (mounted) {
      setState(() {
        _activeBuilding = building;
        _activeFloor = 0;
        _isIndoorMode = true;
      });
    }
  }

  void _checkGeofencing(LatLng userPos) {
    for (var b in CampusMapService.buildings) {
      final distance = const Distance().as(LengthUnit.Meter, userPos, LatLng(b.lat, b.lng));
      if (distance < 60 && !_isIndoorMode && _activeBuilding.id != b.id) {
        _showGeofencePrompt(b);
        break;
      }
    }
  }

  void _showGeofencePrompt(BuildingModel building) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.location_on_rounded, color: AppColors.jadePrimary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You are near ${building.name}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context))),
                    Text('Enter indoor map to find/post items?', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary(context))),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  _enterBuilding(building);
                },
                child: Text('ENTER', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.jadePrimary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onLongPressIndoor(Offset normalizedPos) {
    HapticFeedback.heavyImpact();
    // Pre-fill location data for creation
    final room = _findRoomAt(normalizedPos);
    context.push('/post/create', extra: {
      'building': _activeBuilding.name,
      'floor': _activeFloor,
      'room': room?.number,
      'indoorX': normalizedPos.dx,
      'indoorY': normalizedPos.dy,
    });
  }

  RoomModel? _findRoomAt(Offset pos) {
    for (var room in _activeBuilding.floors[_activeFloor].rooms) {
      final rect = Rect.fromCenter(center: room.position, width: room.size.width, height: room.size.height);
      if (rect.contains(pos)) return room;
    }
    return null;
  }

  void _showRoomDetails(RoomModel room) {
    final roomPosts = _filteredPosts.where((p) => p.location.room == room.number).toList();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.pageBg(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.jadePrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.meeting_room_rounded, color: AppColors.jadePrimary, size: 20),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.name, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('Room ${room.number}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (roomPosts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No items reported in this room', style: GoogleFonts.inter(color: AppColors.textSecondary(context)))),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: roomPosts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = roomPosts[index];
                    return ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        _showPinBottomSheet(p);
                      },
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(width: 48, height: 48, color: AppColors.shimmerBase(context), child: p.imageUrls.isNotEmpty ? Image.network(p.imageUrls.first, fit: BoxFit.cover) : Icon(Icons.image)),
                      ),
                      title: Text(p.title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
                      subtitle: Text(p.isLost ? 'Lost' : 'Found', style: GoogleFonts.inter(fontSize: 12, color: p.isLost ? AppColors.lost : AppColors.found)),
                      trailing: Icon(Icons.chevron_right_rounded),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _onLongPressIndoor(room.position);
                },
                child: Text('Post Item Here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.jadePrimary;

    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      body: Stack(
        children: [
          // ── Map Layer ──────────────────────────────────────────────
          _isIndoorMode 
            ? IndoorMapWidget(
                building: _activeBuilding,
                floor: _activeFloor,
                posts: _filteredPosts,
                userPos: _userIndoorPos?.building == _activeBuilding.name ? _userIndoorPos?.relativePos : null,
                onPostTap: _showPinBottomSheet,
                onRoomTap: _showRoomDetails,
                onStairTap: (stair) => setState(() => _activeFloor = stair.connectsToFloor),
                onLongPress: _onLongPressIndoor,
              ).animate().fadeIn(duration: 400.ms)
            : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _bahriaCampus,
                  initialZoom: 17,
                  maxZoom: 19,
                  onPositionChanged: (pos, hasGesture) {
                    if (hasGesture && pos.center != null) {
                      _checkGeofencing(pos.center!);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: isDark 
                      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                      : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                    userAgentPackageName: 'pk.edu.bahria.lostfound',
                  ),
                  // Building Markers (Interactive)
                  MarkerLayer(
                    markers: CampusMapService.buildings.map((b) {
                      return Marker(
                        point: LatLng(b.lat, b.lng),
                        width: 100, height: 100,
                        child: GestureDetector(
                          onTap: () => _enterBuilding(b),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.card(context), borderRadius: BorderRadius.circular(8), border: Border.all(color: accent.withOpacity(0.5))),
                                child: Text(b.name.split(' ')[0], style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 12, height: 12,
                                decoration: BoxDecoration(color: accent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                              ).animate(onPlay: (c) => c.repeat()).scale(begin: Offset(1,1), end: Offset(1.5, 1.5)).fadeOut(),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // Item Markers
                  MarkerLayer(
                    markers: _filteredPosts.map((p) {
                      var point = LatLng(p.location.latitude, p.location.longitude);
                      if (p.location.latitude == 0) {
                        final b = CampusMapService.buildings.firstWhere((b) => b.name == p.location.building, orElse: () => CampusMapService.buildings[0]);
                        point = LatLng(b.lat, b.lng);
                      }
                      return Marker(
                        point: point,
                        width: 40, height: 40,
                        child: GestureDetector(
                          onTap: () => _showPinBottomSheet(p),
                          child: _PulseMarker(color: p.isLost ? AppColors.lost : AppColors.found),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

          // ── Header Overlay ────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      _GlassButton(
                        onPressed: () => setState(() => _isIndoorMode = !_isIndoorMode),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_isIndoorMode ? Icons.apartment_rounded : Icons.public_rounded, size: 18, color: accent),
                            const SizedBox(width: 8),
                            Text(
                              _isIndoorMode ? 'INDOOR: ${_activeBuilding.name}' : 'CAMPUS VIEW',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _GlassButton(
                        onPressed: _loadPosts,
                        child: Icon(Icons.refresh_rounded, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFilters(),
                ],
              ),
            ),
          ),

          // ── Building & Floor Controls (Indoor Only) ────────────────
          if (_isIndoorMode) ...[
            Positioned(
              right: 20,
              top: 180,
              child: _FloorController(
                maxFloor: _activeBuilding.floors.length - 1,
                active: _activeFloor,
                onChanged: (f) => setState(() => _activeFloor = f),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 120,
              child: _BuildingController(
                active: _activeBuilding,
                onChanged: (b) => setState(() {
                  _activeBuilding = b;
                  _activeFloor = 0;
                }),
              ),
            ),
          ],

          // ── Loading Overlay ──────────────────────────────────────
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: AppColors.pageBg(context).withOpacity(0.5),
                child: Center(
                  child: const CircularProgressIndicator(strokeWidth: 2).animate().scale(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ChipFilter(
            label: 'All Items',
            isSelected: _selectedFilter == 'all',
            onTap: () => setState(() => _selectedFilter = 'all'),
          ),
          const SizedBox(width: 8),
          _ChipFilter(
            label: '🔴 Lost',
            isSelected: _selectedFilter == 'lost',
            onTap: () => setState(() => _selectedFilter = 'lost'),
          ),
          const SizedBox(width: 8),
          _ChipFilter(
            label: '🟢 Found',
            isSelected: _selectedFilter == 'found',
            onTap: () => setState(() => _selectedFilter = 'found'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2, end: 0);
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.onPressed, required this.child});
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.card(context).withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context).withOpacity(0.5)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ChipFilter extends StatelessWidget {
  const _ChipFilter({required this.label, required this.isSelected, required this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.jadePrimary : AppColors.card(context).withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : AppColors.border(context)),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.jadePrimary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12, 
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary(context),
          ),
        ),
      ),
    );
  }
}

class _FloorController extends StatelessWidget {
  const _FloorController({required this.maxFloor, required this.active, required this.onChanged});
  final int maxFloor;
  final int active;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(maxFloor + 1, (index) {
        final f = maxFloor - index;
        final isSelected = active == f;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PressableScale(
            onTap: () => onChanged(f),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.jadePrimary : AppColors.card(context).withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? Colors.transparent : AppColors.border(context)),
              ),
              child: Center(
                child: Text(
                  'F$f',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textPrimary(context)),
                ),
              ),
            ),
          ),
        );
      }),
    ).animate().fadeIn().slideX(begin: 0.5, end: 0);
  }
}

class _BuildingController extends StatelessWidget {
  const _BuildingController({required this.active, required this.onChanged});
  final BuildingModel active;
  final ValueChanged<BuildingModel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: CampusMapService.buildings.map((b) {
        final isSelected = active.name == b.name;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PressableScale(
            onTap: () => onChanged(b),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.jadePrimary : AppColors.card(context).withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? Colors.transparent : AppColors.border(context)),
              ),
              child: Text(
                b.name,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppColors.textPrimary(context)),
              ),
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn().slideX(begin: -0.5, end: 0);
  }
}

class _PulseMarker extends StatelessWidget {
  const _PulseMarker({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: color.withOpacity(0.3), shape: BoxShape.circle),
        ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1, 1), end: const Offset(2, 2), duration: 1.seconds).fadeOut(),
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)),
        ),
      ],
    );
  }
}

class _PinPreviewSheet extends StatelessWidget {
  const _PinPreviewSheet({required this.post, required this.onViewPost});
  final SimplePostModel post;
  final VoidCallback onViewPost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      decoration: BoxDecoration(
        color: AppColors.pageBg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border(context), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 80, height: 80,
                  color: AppColors.shimmerBase(context),
                  child: post.imageUrls.isNotEmpty 
                    ? Image.network(post.imageUrls.first, fit: BoxFit.cover)
                    : Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary(context)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: (post.isLost ? AppColors.lost : AppColors.found).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(post.isLost ? 'LOST' : 'FOUND', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: post.isLost ? AppColors.lost : AppColors.found)),
                    ),
                    const SizedBox(height: 8),
                    Text(post.title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context))),
                    Text('${post.location.building} • ${AppDateUtils.timeAgo(post.timestamp)}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(onPressed: onViewPost, child: const Text('View Full Details')),
          ),
        ],
      ),
    );
  }
}