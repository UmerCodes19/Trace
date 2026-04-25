import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_post_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/campus_map_service.dart';
import '../../../data/services/indoor_positioning_service.dart';
import '../../widgets/map/indoor_map_widget.dart';
import '../../widgets/common/glass_card.dart';

// ─── Bahria University Karachi Main Campus ───────────────────────────────
const _bahriaCampus = LatLng(24.893240, 67.088235);

// ─── Map Screen ───────────────────────────────────────────────────────────────
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  List<SimplePostModel> _posts = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, lost, found
  
  // Indoor State
  bool _isIndoorMode = true;
  BuildingModel _activeBuilding = CampusMapService.buildings[0];
  int _activeFloor = 0;
  CampusLocation? _userIndoorPos;
  StreamSubscription? _posSubscription;

  // Cached markers to avoid rebuilding on every setState
  List<Marker>? _cachedMarkers;
  String? _cachedFilterKey;

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
          // Optionally auto-switch floor if user moves
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
      _invalidateMarkerCache();
    });
  }

  void _invalidateMarkerCache() {
    _cachedMarkers = null;
    _cachedFilterKey = null;
  }

  List<SimplePostModel> get _filteredPosts {
    if (_selectedFilter == 'lost') {
      return _posts.where((p) => p.isLost).toList();
    } else if (_selectedFilter == 'found') {
      return _posts.where((p) => p.isFound).toList();
    }
    return _posts;
  }

  List<Marker> _buildMarkers() {
    // Use cached markers if filter hasn't changed
    final filterKey = '$_selectedFilter-${_posts.length}';
    if (_cachedMarkers != null && _cachedFilterKey == filterKey) {
      return _cachedMarkers!;
    }

    final markers = <Marker>[];
    final filtered = _filteredPosts;

    // Group nearby posts for clustering
    final clusters = _clusterPosts(filtered, distanceThresholdMeters: 50);

    for (final cluster in clusters) {
      if (cluster.length == 1) {
        // Single marker
        final post = cluster.first;
        final lat = post.location.latitude != 0
            ? post.location.latitude
            : _bahriaCampus.latitude;
        final lng = post.location.longitude != 0
            ? post.location.longitude
            : _bahriaCampus.longitude;

        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () => _showPinBottomSheet(post),
              child: _SingleMarker(post: post),
            ),
          ),
        );
      } else {
        // Cluster marker
        final avgLat = cluster.fold<double>(0, (sum, p) {
              final lat =
                  p.location.latitude != 0 ? p.location.latitude : _bahriaCampus.latitude;
              return sum + lat;
            }) /
            cluster.length;
        final avgLng = cluster.fold<double>(0, (sum, p) {
              final lng =
                  p.location.longitude != 0 ? p.location.longitude : _bahriaCampus.longitude;
              return sum + lng;
            }) /
            cluster.length;

        markers.add(
          Marker(
            point: LatLng(avgLat, avgLng),
            width: 56,
            height: 56,
            child: GestureDetector(
              onTap: () {
                // Zoom into cluster
                _mapController.move(LatLng(avgLat, avgLng), 18);
              },
              child: _ClusterMarker(count: cluster.length),
            ),
          ),
        );
      }
    }

    _cachedMarkers = markers;
    _cachedFilterKey = filterKey;
    return markers;
  }

  /// Simple grid-based clustering
  List<List<SimplePostModel>> _clusterPosts(
    List<SimplePostModel> posts, {
    required double distanceThresholdMeters,
  }) {
    if (posts.isEmpty) return [];

    // Grid cell size in degrees (approximate: 50m ≈ 0.00045 degrees)
    const gridSize = 0.0005;
    final grid = <String, List<SimplePostModel>>{};

    for (final post in posts) {
      final lat = post.location.latitude != 0
          ? post.location.latitude
          : _bahriaCampus.latitude;
      final lng = post.location.longitude != 0
          ? post.location.longitude
          : _bahriaCampus.longitude;

      final cellKey =
          '${(lat / gridSize).floor()}_${(lng / gridSize).floor()}';
      grid.putIfAbsent(cellKey, () => []).add(post);
    }

    return grid.values.toList();
  }

  // Heatmap visualization - density overlay using circles
  List<CircleMarker> _buildHeatmapCircles() {
    final circles = <CircleMarker>[];

    // Group posts by location
    final locationGroups = <String, List<SimplePostModel>>{};
    for (final post in _filteredPosts) {
      final key =
          '${post.location.latitude.toStringAsFixed(3)}_${post.location.longitude.toStringAsFixed(3)}';
      locationGroups.putIfAbsent(key, () => []).add(post);
    }

    for (final entry in locationGroups.entries) {
      final count = entry.value.length;
      if (count > 1) {
        final post = entry.value.first;
        final lat = post.location.latitude != 0
            ? post.location.latitude
            : _bahriaCampus.latitude;
        final lng = post.location.longitude != 0
            ? post.location.longitude
            : _bahriaCampus.longitude;

        // Radius and opacity scale with density
        final radius = 30.0 + (count * 15).clamp(0, 80).toDouble();
        final opacity = (0.08 + count * 0.04).clamp(0.08, 0.3);
        final hasLost = entry.value.any((p) => p.isLost);
        final color = hasLost ? AppColors.lostAlert : AppColors.foundSuccess;

        circles.add(
          CircleMarker(
            point: LatLng(lat, lng),
            radius: radius,
            color: color.withOpacity(opacity),
            borderColor: color.withOpacity(opacity * 2),
            borderStrokeWidth: 1.5,
          ),
        );
      }
    }

    return circles;
  }

  void _showPinBottomSheet(SimplePostModel post) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.pageBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _PinPreviewSheet(
        post: post,
        onViewPost: () {
          Navigator.pop(context);
          context.push('/post/${post.id}');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPostsCount = _filteredPosts.length;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map Layer ──────────────────────────────────────────────
          _isIndoorMode 
            ? IndoorMapWidget(
                building: _activeBuilding,
                floor: _activeFloor,
                posts: _posts,
                userPos: _userIndoorPos?.building == _activeBuilding.name ? _userIndoorPos?.relativePos : null,
                onPostTap: _showPinBottomSheet,
                onRoomTap: (room) {
                  showAppSnack(context, 'Room ${room.number}: ${room.name}');
                },
              )
            : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _bahriaCampus,
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'pk.edu.bahria.lostfound',
                  ),
                  CircleLayer(circles: _buildHeatmapCircles()),
                  MarkerLayer(markers: _buildMarkers()),
                ],
              ),

          // ── Loading indicator ───────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
            
          // ── Building & Floor Selectors (Indoor Only) ────────────────
          if (_isIndoorMode) ...[
             Positioned(
               left: 20,
               top: 140,
               child: _BuildingSelector(
                 active: _activeBuilding,
                 onChanged: (b) => setState(() {
                   _activeBuilding = b;
                   _activeFloor = 0;
                 }),
               ),
             ),
             Positioned(
               right: 20,
               top: 140,
               child: _FloorSelector(
                 maxFloor: _activeBuilding.floors.length - 1,
                 active: _activeFloor,
                 onChanged: (f) => setState(() => _activeFloor = f),
               ),
             ),
          ],

          // ── Top bar overlay ────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.navyDarkest,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.navyDarkest.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.map_rounded,
                                color: AppColors.beigeWarm, size: 18),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _isIndoorMode = !_isIndoorMode),
                              child: Text(
                                _isIndoorMode ? 'CAMPUS VIEW' : 'WORLD VIEW',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (_isIndoorMode)
                        _MyIndoorLocationButton(
                          onPressed: () {
                            if (_userIndoorPos != null) {
                              setState(() {
                                _activeBuilding = CampusMapService.buildings.firstWhere(
                                  (b) => b.name == _userIndoorPos!.building,
                                  orElse: () => _activeBuilding,
                                );
                                _activeFloor = _userIndoorPos!.floor;
                              });
                            }
                          },
                        ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          filteredPostsCount > 0
                              ? '$filteredPostsCount items'
                              : 'No items',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Filter buttons
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterButton(
                          label: 'All',
                          isSelected: _selectedFilter == 'all',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedFilter = 'all';
                              _invalidateMarkerCache();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterButton(
                          label: '🔴 Lost',
                          isSelected: _selectedFilter == 'lost',
                          color: AppColors.lostAlert,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedFilter = 'lost';
                              _invalidateMarkerCache();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterButton(
                          label: '🟢 Found',
                          isSelected: _selectedFilter == 'found',
                          color: AppColors.foundSuccess,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedFilter = 'found';
                              _invalidateMarkerCache();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Legend ──────────────────────────────────────────────
          Positioned(
            left: 20,
            bottom: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendItem(
                  color: AppColors.lostAlert,
                  label: 'Lost Items',
                  icon: Icons.warning_rounded,
                ),
                const SizedBox(height: 6),
                _LegendItem(
                  color: AppColors.foundSuccess,
                  label: 'Found Items',
                  icon: Icons.check_circle_rounded,
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg(context).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color:
                              AppColors.lostAlert.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.lostAlert.withOpacity(0.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('High Density',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Refresh Button ──────────────────────────────────────
          Positioned(
            right: 20,
            bottom: 140,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              onPressed: () {
                HapticFeedback.lightImpact();
                _invalidateMarkerCache();
                _loadPosts();
              },
              child: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Single Marker ──────────────────────────────────────────────────────────
class _SingleMarker extends StatelessWidget {
  const _SingleMarker({required this.post});
  final SimplePostModel post;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: post.isLost ? AppColors.lostAlert : AppColors.foundSuccess,
          boxShadow: [
            BoxShadow(
              color: (post.isLost
                      ? AppColors.lostAlert
                      : AppColors.foundSuccess)
                  .withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          post.isLost
              ? Icons.warning_rounded
              : Icons.check_circle_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// ─── Cluster Marker ─────────────────────────────────────────────────────────
class _ClusterMarker extends StatelessWidget {
  const _ClusterMarker({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return RepaintBoundary(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [accent, accent.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Legend Item ────────────────────────────────────────────────────────────
class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.icon,
  });
  final Color color;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Filter Button ──────────────────────────────────────────────────────────
class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? btnColor : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border(context),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: btnColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }
}

// ─── Pin Preview Bottom Sheet ───────────────────────────────────────────────
class _PinPreviewSheet extends StatelessWidget {
  const _PinPreviewSheet({required this.post, required this.onViewPost});
  final SimplePostModel post;
  final VoidCallback onViewPost;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: post.isLost ? AppColors.lostAlertBg : AppColors.foundBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  post.isLost ? '🔴 Lost Item' : '🟢 Found Item',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: post.isLost
                        ? AppColors.lostAlert
                        : AppColors.foundSuccess,
                  ),
                ),
              ),
              const Spacer(),
              // AI Tags preview
              if (post.aiTags.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 12,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        post.aiTags.take(2).join(', '),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (post.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              post.description,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary(context),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  color: AppColors.navyLight, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  post.location.building.isNotEmpty
                      ? '${post.location.building} · Floor ${post.location.floor}'
                      : 'Campus Location',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: post.isLost
                    ? AppColors.lostAlert
                    : AppColors.foundSuccess,
              ),
              child: const Text('View Full Details'),
            ),
          ),
        ],
      ),
    );
  }
}

extension LatLngTrig on LatLng {
  double get latitudeInRad => latitude * math.pi / 180;
  double get longitudeInRad => longitude * math.pi / 180;
}

extension RadToDeg on double {
  double get toDeg => this * 180 / math.pi;
}

class _BuildingSelector extends StatelessWidget {
  const _BuildingSelector({required this.active, required this.onChanged});
  final BuildingModel active;
  final Function(BuildingModel) onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButton<BuildingModel>(
          value: active,
          underline: const SizedBox(),
          dropdownColor: AppColors.navyDarkest,
          items: CampusMapService.buildings.map((b) {
            return DropdownMenuItem(
              value: b,
              child: Text(b.name, style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
            );
          }).toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}

class _FloorSelector extends StatelessWidget {
  const _FloorSelector({required this.maxFloor, required this.active, required this.onChanged});
  final int maxFloor;
  final int active;
  final Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 16,
      child: Column(
        children: List.generate(maxFloor + 1, (index) {
          final isSelected = active == index;
          return IconButton(
            icon: Text('F$index', style: GoogleFonts.inter(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Theme.of(context).colorScheme.primary : AppColors.textSecondary(context),
            )),
            onPressed: () => onChanged(index),
          );
        }).reversed.toList(),
      ),
    );
  }
}

class _MyIndoorLocationButton extends StatelessWidget {
  const _MyIndoorLocationButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      onPressed: onPressed,
      backgroundColor: AppColors.navyDarkest,
      child: const Icon(Icons.my_location_rounded, color: Colors.white),
    );
  }
}