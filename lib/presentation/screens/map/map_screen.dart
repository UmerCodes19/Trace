// lib/presentation/screens/map/map_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui show Path;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:camera/camera.dart';

import '../../../data/models/map/campus_gis_models.dart';
import '../../../core/utils/tutorial_keys.dart';
import '../../../data/services/map/map_engine_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_post_model.dart';
import '../../../data/services/offline/offline_cache_service.dart';
import '../../../data/services/offline/sync_manager.dart';
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
  bool _isMapReady = false;
  bool _isLoading = true;
  String _selectedFilter = 'all'; 
  
  bool _isIndoorMode = true;
  BuildingModel _activeBuilding = CampusMapService.buildings[0];
  int _activeFloor = 1;
  CampusLocation? _userIndoorPos;
  StreamSubscription? _posSubscription;
  
  // Real-world location state
  LatLng? _userLatLng;
  StreamSubscription<Position>? _geolocatorSubscription;
  SimplePostModel? _navigatingTo;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _startPositioning();
    _initGeolocator();
  }

  Future<void> _initGeolocator() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    // Start listening to live location
    _geolocatorSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // Update every 2 meters
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _userLatLng = LatLng(position.latitude, position.longitude);
        });
        
        // Auto-check geofencing if not in indoor mode
        if (!_isIndoorMode) {
          _checkGeofencing(_userLatLng!);
        }
      }
    });
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
    _geolocatorSubscription?.cancel();
    IndoorPositioningService.instance.stopPositioning();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    final api = ref.read(apiServiceProvider);
    List<dynamic> postsData = [];
    bool loadedFromCache = false;

    try {
      postsData = await api.getPosts(status: 'open');
      // Cache fresh data securely
      await OfflineCacheService.instance.saveEncryptedString('posts_feed_cache', jsonEncode(postsData));
    } catch (e) {
      debugPrint('TRACE: Failed to load posts from API ($e). Falling back to encrypted local cache...');
      try {
        final cachedData = await OfflineCacheService.instance.readDecryptedString('posts_feed_cache');
        if (cachedData != null) {
          postsData = jsonDecode(cachedData);
          loadedFromCache = true;
        }
      } catch (innerEx) {
        debugPrint('TRACE: Error reading local cache: $innerEx');
      }
    }

    if (!mounted) return;

    setState(() {
      final List<SimplePostModel> loadedPosts = postsData.map((p) => SimplePostModel.fromMap(p)).toList();
      
      // Inject local pending posts into the map view instantly!
      final pendingRaw = SyncManager.instance.getPendingPosts();
      final pendingPosts = pendingRaw.map((p) => SimplePostModel.fromMap(p)).toList();
      
      final Map<String, SimplePostModel> uniqueMap = {};
      for (var p in loadedPosts) {
        uniqueMap[p.id] = p;
      }
      for (var p in pendingPosts) {
        uniqueMap[p.id] = p;
      }

      _posts = uniqueMap.values.toList();
      _isLoading = false;
    });

    if (loadedFromCache && mounted) {
      showAppSnack(context, '📡 Showing cached posts (offline mode)');
    }
  }

  List<SimplePostModel> get _filteredPosts {
    if (_selectedFilter == 'lost') {
      return _posts.where((p) => p.isLost).toList();
    } else if (_selectedFilter == 'found') {
      return _posts.where((p) => p.isFound).toList();
    }
    return _posts;
  }

  LatLng _getPostLatLng(SimplePostModel p) {
    if (p.location.latitude != 0.0) return LatLng(p.location.latitude, p.location.longitude);
    final b = CampusMapService.buildings.firstWhere(
      (b) => b.name.toLowerCase().contains(p.location.building.toLowerCase()) || p.location.building.toLowerCase().contains(b.name.toLowerCase()),
      orElse: () => CampusMapService.buildings[0],
    );
    final shiftLat = ((p.id.hashCode % 100) - 50) * 0.0000028;
    final shiftLng = (((p.id.hashCode ~/ 100) % 100) - 50) * 0.0000032;
    return LatLng(b.lat + shiftLat, b.lng + shiftLng);
  }

  void _showPinBottomSheet(SimplePostModel post) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PinPreviewSheet(
        post: post,
        userLocation: _userLatLng,
        onViewPost: () {
          Navigator.pop(context);
          context.push('/post/${post.id}');
        },
        onTrack: () {
          Navigator.pop(context);
          setState(() => _navigatingTo = post);
          if (!_isIndoorMode) {
            _mapController.move(_getPostLatLng(post), 18);
          }
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
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.pageBg(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
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
                        Navigator.of(sheetCtx).pop();
                        _showPinBottomSheet(p);
                      },
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 48, height: 48, 
                          color: AppColors.shimmerBase(context), 
                          child: p.imageUrls.isNotEmpty 
                            ? CachedNetworkImage(
                                imageUrl: p.imageUrls.first, 
                                fit: BoxFit.cover,
                                memCacheWidth: 200,
                                memCacheHeight: 200,
                                placeholder: (context, url) => const Center(child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1))),
                                errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined, size: 16),
                              ) 
                            : Icon(Icons.image),
                        ),
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
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(sheetCtx).pop();
                  _openSpotSelector(room);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.jadePrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Zoom & Explore Room Blueprint', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _openSpotSelector(RoomModel room) {
    Offset selectedSpot = const Offset(0.5, 0.5); // Center by default

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppColors.pageBg(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            children: [
              Text('Mark Spot inside ${room.name}', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Tap anywhere on the blueprint grid to set a precise pin', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary(context))),
            ],
          ),
          content: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final localPos = details.localPosition;
                setModalState(() {
                  selectedSpot = Offset(
                    ((localPos.dx - 30.0) / 240.0).clamp(0.0, 1.0),
                    ((localPos.dy - 30.0) / 240.0).clamp(0.0, 1.0),
                  );
                });
              },
              onPanUpdate: (details) {
                final localPos = details.localPosition;
                setModalState(() {
                  selectedSpot = Offset(
                    ((localPos.dx - 30.0) / 240.0).clamp(0.0, 1.0),
                    ((localPos.dy - 30.0) / 240.0).clamp(0.0, 1.0),
                  );
                });
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BlueprintGridPainter(isDark: Theme.of(context).brightness == Brightness.dark),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RoomBlueprintPainter(
                        polygonPoints: room.polygonPoints,
                        accentColor: AppColors.jadePrimary,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0, top: 12, right: 0,
                    child: Center(
                      child: Text(
                        'Room ${room.number}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.jadePrimary.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  
                  // Interactive tagged items inside the room blueprint
                  ..._filteredPosts.where((p) => p.location.room == room.number && p.location.indoorX != null && p.location.indoorY != null).map((p) {
                    final double pinX = 30.0 + (p.location.indoorX! * 240.0);
                    final double pinY = 30.0 + (p.location.indoorY! * 240.0);
                    return Positioned(
                      left: pinX - 10,
                      top: pinY - 10,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(dialogCtx);
                          _showPinBottomSheet(p);
                        },
                        child: Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            color: p.isLost ? AppColors.lost : AppColors.found,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))],
                          ),
                          child: const Center(
                            child: Icon(Icons.location_on, size: 10, color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  }),

                  Positioned(
                    left: (30.0 + (selectedSpot.dx * 240.0)) - 15,
                    top: (30.0 + (selectedSpot.dy * 240.0)) - 30,
                    child: Icon(Icons.add_location_alt_rounded, color: AppColors.jadePrimary, size: 30),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                context.push('/create', extra: {
                  'building': _activeBuilding.name,
                  'floor': _activeFloor,
                  'room': room.number,
                  'indoorX': selectedSpot.dx,
                  'indoorY': selectedSpot.dy,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.jadePrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Confirm Spot', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
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
        key: TutorialKeys.mapCanvasKey,
        children: [
          // ── Map Layer ──────────────────────────────────────────────
          _isIndoorMode 
            ? (_activeBuilding.id == 'liaquat'
                ? IndoorMapWidget(
                    building: _activeBuilding,
                    floor: _activeFloor,
                    posts: _filteredPosts,
                    userPos: _userIndoorPos?.building == _activeBuilding.name ? _userIndoorPos?.relativePos : null,
                    onPostTap: _showPinBottomSheet,
                    onRoomTap: (room) {
                      if (room is CampusRoom) {
                        final roomNum = room.roomNumber;
                        final exists = _activeBuilding.floors[_activeFloor].rooms.any((r) => r.number == roomNum);
                        if (exists) {
                          final matchedRoom = _activeBuilding.floors[_activeFloor].rooms.firstWhere((r) => r.number == roomNum);
                          _showRoomDetails(matchedRoom);
                        } else {
                          // Dynamically build RoomModel from GIS CampusRoom
                          final tempRoomModel = RoomModel(
                            number: room.roomNumber,
                            name: room.name,
                            position: MapEngineService.instance.getRoomCenter(room),
                            polygonPoints: room.polygonPoints,
                          );
                          _showRoomDetails(tempRoomModel);
                        }
                      } else {
                        try {
                          final roomNum = (room as dynamic).roomNumber as String;
                          final matchedRoom = _activeBuilding.floors[_activeFloor].rooms.firstWhere(
                            (r) => r.number == roomNum,
                            orElse: () => _activeBuilding.floors[_activeFloor].rooms.first,
                          );
                          _showRoomDetails(matchedRoom);
                        } catch (_) {
                          _showRoomDetails(room as RoomModel);
                        }
                      }
                    },
                    onStairTap: (stair) => setState(() => _activeFloor = stair.connectsToFloor),
                    onLongPress: _onLongPressIndoor,
                  ).animate().fadeIn(duration: 400.ms)
                : _buildComingSoonPlaceholder(_activeBuilding))
            : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _bahriaCampus,
                  initialZoom: 17,
                  maxZoom: 19,
                  onMapReady: () => setState(() => _isMapReady = true),
                  onPositionChanged: (pos, hasGesture) {
                    if (hasGesture) _checkGeofencing(pos.center);
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
                  // Navigation Path (Polyline)
                  if (!_isIndoorMode && _navigatingTo != null && _userLatLng != null)
                    PolylineLayer(
                      polylines: <Polyline>[
                        Polyline(
                          points: [
                            _userLatLng!,
                            _getPostLatLng(_navigatingTo!),
                          ],
                          strokeWidth: 4,
                          color: AppColors.jadePrimary,
                        ),
                      ],
                    ),
                  // User Location Marker with Heading Arrow
                  if (!_isIndoorMode && _userLatLng != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userLatLng!,
                          width: 80, height: 80,
                          child: StreamBuilder<CompassEvent>(
                            stream: FlutterCompass.events,
                            builder: (context, snapshot) {
                              double rotation = 0;
                              if (snapshot.hasData && snapshot.data!.heading != null) {
                                rotation = snapshot.data!.heading! * (pi / 180);
                              }
                              return Transform.rotate(
                                angle: rotation,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Field of view cone
                                    Opacity(
                                      opacity: 0.2,
                                      child: CustomPaint(
                                        size: const Size(80, 80),
                                        painter: _FOVCPainter(),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]
                                      ),
                                      child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  // Item Markers
                  MarkerLayer(
                    markers: _filteredPosts.map((p) {
                      var point = _getPostLatLng(p);
                      return Marker(
                        point: point,
                        width: 40, height: 40,
                        child: GestureDetector(
                          onTap: () => _showPinBottomSheet(p),
                          child: RepaintBoundary(child: _PulseMarker(color: p.isLost ? AppColors.lost : AppColors.found)),
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
                      Container(
                        key: TutorialKeys.mapToggleKey,
                        child: _GlassButton(
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
              right: 16,
              top: 155,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.card(context).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border(context)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.jadePrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'F1',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'More floors coming soon!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Navigation Overlay (Floating) ───────────────────────
          if (_navigatingTo != null && _userLatLng != null)
            _NavigationOverlay(
              post: _navigatingTo!,
              userLocation: _userLatLng!,
              onStop: () => setState(() => _navigatingTo = null),
            ),

          // ── Action Buttons ────────────────────────────────────────
          Positioned(
            right: 20,
            bottom: _navigatingTo != null ? 310 : 130,
            child: Column(
              children: [
                _GlassButton(
                  onPressed: () {
                    if (!_isMapReady) return;
                    if (_userLatLng != null) {
                      _mapController.move(_userLatLng!, 17.5);
                    } else {
                      showAppSnack(context, 'Waiting for GPS signal...');
                    }
                  },
                  child: Icon(Icons.my_location_rounded, color: AppColors.jadePrimary),
                ),
                const SizedBox(height: 12),
                _GlassButton(
                  onPressed: () {
                    if (!_isMapReady) return;
                    _mapController.rotate(0);
                  },
                  child: Icon(Icons.explore_outlined, color: AppColors.jadePrimary),
                ),
              ],
            ),
          ),

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
    return Container(
      key: TutorialKeys.mapFilterKey,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card(context).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context).withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PremiumSegmentButton(
            label: 'ALL REPORTS',
            icon: Icons.grid_view_rounded,
            isSelected: _selectedFilter == 'all',
            onTap: () => setState(() => _selectedFilter = 'all'),
          ),
          _PremiumSegmentButton(
            label: 'LOST',
            icon: Icons.search_rounded,
            isSelected: _selectedFilter == 'lost',
            color: AppColors.lost,
            onTap: () => setState(() => _selectedFilter = 'lost'),
          ),
          _PremiumSegmentButton(
            label: 'FOUND',
            icon: Icons.check_circle_outline_rounded,
            isSelected: _selectedFilter == 'found',
            color: AppColors.found,
            onTap: () => setState(() => _selectedFilter = 'found'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0));
  }

  Widget _buildComingSoonPlaceholder(BuildingModel building) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.jadePrimary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.architecture_rounded, size: 48, color: AppColors.jadePrimary),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 1500.ms, curve: Curves.easeInOut),
              const SizedBox(height: 24),
              Text(
                '${building.name} Layout Coming Soon',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context)),
              ),
              const SizedBox(height: 12),
              Text(
                'Our GIS mapping engineers are currently digitizing the architectural layouts and indoor positioning infrastructure for this block. It will be available in later releases!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, height: 1.5, color: AppColors.textSecondary(context)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => setState(() => _activeBuilding = CampusMapService.buildings[0]),
                icon: const Icon(Icons.map_rounded, size: 16),
                label: const Text('Back to Liaquat Block'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.jadePrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  const _PinPreviewSheet({
    required this.post, 
    required this.onViewPost, 
    this.userLocation,
    required this.onTrack,
  });
  final SimplePostModel post;
  final VoidCallback onViewPost;
  final LatLng? userLocation;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) {
    String distanceText = 'Distance unknown';
    if (userLocation != null) {
      final double dist = const Distance().as(
        LengthUnit.Meter, 
        userLocation!, 
        LatLng(post.location.latitude, post.location.longitude)
      );
      if (dist < 1000) {
        distanceText = '${dist.toInt()}m away';
      } else {
        distanceText = '${(dist / 1000).toStringAsFixed(1)}km away';
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.pageBg(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border(context), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: (post.isLost ? AppColors.lost : AppColors.found).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(post.isLost ? 'LOST' : 'FOUND', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: post.isLost ? AppColors.lost : AppColors.found)),
                        ),
                        const SizedBox(width: 8),
                        Text(distanceText, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.jadePrimary)),
                      ],
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
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: onViewPost, 
                    child: const Text('Details'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: onTrack, 
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text('Track Item'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
     ),
    );
  }
}

class _BlueprintGridPainter extends CustomPainter {
  final bool isDark;
  _BlueprintGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)
      ..strokeWidth = 1.0;

    const spacing = 15.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class _PremiumSegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _PremiumSegmentButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.jadePrimary;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? activeColor.withOpacity(0.4) : Colors.transparent, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? activeColor : AppColors.textSecondary(context)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isSelected ? activeColor : AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomBlueprintPainter extends CustomPainter {
  final List<Offset>? polygonPoints;
  final Color accentColor;

  _RoomBlueprintPainter({required this.polygonPoints, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final points = polygonPoints ?? [const Offset(0.1, 0.1), const Offset(0.9, 0.1), const Offset(0.9, 0.9), const Offset(0.1, 0.9)];
    
    // Find min/max bounding box
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;
    
    for (var p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    
    final width = (maxX - minX).clamp(0.01, 1.0);
    final height = (maxY - minY).clamp(0.01, 1.0);
    
    final double margin = 30.0;
    final drawWidth = size.width - (margin * 2);
    final drawHeight = size.height - (margin * 2);
    
    final path = ui.Path();
    final firstLocalX = margin + (((points.first.dx - minX) / width) * drawWidth);
    final firstLocalY = margin + (((points.first.dy - minY) / height) * drawHeight);
    path.moveTo(firstLocalX, firstLocalY);
    
    for (var p in points.skip(1)) {
      final localX = margin + (((p.dx - minX) / width) * drawWidth);
      final localY = margin + (((p.dy - minY) / height) * drawHeight);
      path.lineTo(localX, localY);
    }
    path.close();

    final fillPaint = Paint()
      ..color = accentColor.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _RoomBlueprintPainter oldDelegate) => true;
}

class _NavigationOverlay extends StatelessWidget {
  const _NavigationOverlay({
    required this.post,
    required this.userLocation,
    required this.onStop,
  });
  final SimplePostModel post;
  final LatLng userLocation;
  final VoidCallback onStop;

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
    return '${meters.toInt()}m';
  }

  String _formatDuration(double meters) {
    final minutes = (meters / (1.4 * 60)).ceil();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMins = minutes % 60;
      return '${hours}h ${remainingMins}m';
    }
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final targetLatLng = LatLng(post.location.latitude, post.location.longitude);
    final distance = const Distance().as(LengthUnit.Meter, userLocation, targetLatLng);
    final bearing = const Distance().bearing(userLocation, targetLatLng);
    final itemColor = post.isLost ? AppColors.lost : AppColors.found;

    return Positioned(
      bottom: 120,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [itemColor.withOpacity(0.4), Colors.transparent, itemColor.withOpacity(0.2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.pageBg(context).withOpacity(0.8),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  // Direction Arrow
                  StreamBuilder<CompassEvent>(
                    stream: FlutterCompass.events,
                    builder: (context, snapshot) {
                      double rotation = 0;
                      if (snapshot.hasData && snapshot.data!.heading != null) {
                        rotation = (bearing - snapshot.data!.heading!) * (pi / 180);
                      }
                      return Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: itemColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Transform.rotate(
                          angle: rotation,
                          child: Icon(Icons.navigation_rounded, size: 30, color: itemColor),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  // Info Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          post.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Text(
                                _formatDistance(distance.toDouble()),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: itemColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '•  ~${_formatDuration(distance.toDouble())} walk',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Actions
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: onStop,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ARNavigationScreen(post: post, userLoc: userLocation),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: itemColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.camera_rounded, color: itemColor, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic);
  }
}


class ARNavigationScreen extends StatefulWidget {
  final SimplePostModel post;
  final LatLng userLoc;

  const ARNavigationScreen({super.key, required this.post, required this.userLoc});

  @override
  State<ARNavigationScreen> createState() => _ARNavigationScreenState();
}

class _ARNavigationScreenState extends State<ARNavigationScreen> {
  CameraController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    await _controller!.initialize();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final targetLatLng = LatLng(widget.post.location.latitude, widget.post.location.longitude);
    final bearing = const Distance().bearing(widget.userLoc, targetLatLng);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),
          
          // Overlay UI
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),
          
          Positioned(
            top: 60,
            left: 20,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            ),
          ),
          
          Center(
            child: StreamBuilder<CompassEvent>(
              stream: FlutterCompass.events,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                
                double? direction = snapshot.data!.heading;
                if (direction == null) return const SizedBox.shrink();
                
                double arrowRotation = (bearing - direction) * (pi / 180);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: arrowRotation,
                      child: Icon(
                        Icons.keyboard_double_arrow_up_rounded,
                        size: 150,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        'FOLLOW THE ARROW',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This AR guide uses your phone\'s compass. Hold your phone upright for better accuracy.',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FOVCPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;

    final path = ui.Path();
    path.moveTo(size.width / 2, size.height / 2);
    // Draw a cone starting from center pointing up
    path.lineTo(size.width / 2 - 40, -60);
    path.lineTo(size.width / 2 + 40, -60);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
