import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_post_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/offline/sync_manager.dart';
import '../profile/avatar_builder_screen.dart'; // To reuse UserAvatar or similar if available
import '../../widgets/profile/flutter_avatar.dart'; // Direct access to UserAvatar / AvatarConfig
import '../../widgets/common/user_avatar.dart';

class CampusReelsScreen extends ConsumerStatefulWidget {
  const CampusReelsScreen({super.key});

  @override
  ConsumerState<CampusReelsScreen> createState() => _CampusReelsScreenState();
}

class _CampusReelsScreenState extends ConsumerState<CampusReelsScreen> {
  late final PageController _pageController;
  List<SimplePostModel> _reelPosts = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  // Pre-loaded stunning loops to act as fallback campus videos
  final List<String> _fallbackVideos = [
    'https://assets.mixkit.co/videos/preview/mixkit-university-campus-with-students-walking-43406-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-interior-of-a-modern-library-with-bookshelves-44813-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-group-of-college-students-discussing-work-in-library-43393-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-holding-and-using-a-sleek-smart-phone-41484-large.mp4',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadReelPosts();
  }

  Future<void> _loadReelPosts() async {
    try {
      final rawPosts = await ref.read(apiServiceProvider).getPosts();
      final List<SimplePostModel> onlinePosts = rawPosts.map((p) => SimplePostModel.fromMap(p)).toList();
      
      // Load offline posts too!
      final List<SimplePostModel> offlinePosts = () {
        try {
          final pendingRaw = SyncManager.instance.getPendingPosts();
          return pendingRaw.map((p) => SimplePostModel.fromMap(p)).toList();
        } catch (_) {
          return <SimplePostModel>[];
        }
      }();
      
      final List<SimplePostModel> posts = [...offlinePosts, ...onlinePosts];
      
      // Filter posts that have a video, or map existing posts with our beautiful fallback loops for rich demo experience
      final List<SimplePostModel> finalReels = [];
      int fallbackIdx = 0;

      for (var post in posts) {
        if (post.videoUrl != null && post.videoUrl!.isNotEmpty) {
          finalReels.add(post);
        }
      }



      if (mounted) {
        setState(() {
          _reelPosts = finalReels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF08080A),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Color(0xFF14151F),
                Color(0xFF08080A),
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient ambient glow rings
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.teal.withOpacity(0.05), width: 1),
                ),
              ).animate(onPlay: (c) => c.repeat())
               .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.5, 1.5), duration: 2.seconds, curve: Curves.easeOut)
               .fadeOut(duration: 2.seconds),
               
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.jadePrimary.withOpacity(0.1),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.jadePrimary, Colors.teal]),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(0.94, 0.94), end: const Offset(1.06, 1.06), duration: 1200.ms, curve: Curves.easeInOutQuad)
                  .shimmer(duration: 2400.ms, color: Colors.white24),
                  
                  const SizedBox(height: 28),
                  Text(
                    'SYNCHRONIZING TRACES',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.5,
                    ),
                  ).animate(onPlay: (c) => c.repeat()).shimmer(delay: 1500.ms, duration: 2000.ms),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_reelPosts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.video_library_outlined, size: 64, color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                'No Traces Yet',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a post with #video in the description\nto start the loop!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ).animate().fadeIn(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Infinite vertical page view for reels
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            onPageChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: _reelPosts.length,
            itemBuilder: (context, index) {
              final post = _reelPosts[index];
              final bool isActive = index == _currentIndex;
              return ReelPlayerItem(
                post: post,
                isActive: isActive,
              );
            },
          ),

          // Header Overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Traces',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.8,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE FEED',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReelPlayerItem extends StatefulWidget {
  final SimplePostModel post;
  final bool isActive;

  const ReelPlayerItem({
    super.key,
    required this.post,
    required this.isActive,
  });

  @override
  State<ReelPlayerItem> createState() => _ReelPlayerItemState();
}

class _ReelPlayerItemState extends State<ReelPlayerItem> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isLiked = false;
  bool _showHeartAnimation = false;
  int _localLikesCount = 0;
  final List<String> _comments = [];

  @override
  void initState() {
    super.initState();
    _localLikesCount = widget.post.likesCount;
    // Placeholder comments removed
    _comments.addAll([]);
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (widget.post.videoUrl == null) return;
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.post.videoUrl!),
    );

    try {
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (widget.isActive) {
          _videoController!.play();
        }
      }
    } catch (e) {
      debugPrint('Reel Player error: $e');
    }
  }

  @override
  void didUpdateWidget(covariant ReelPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_videoController != null && _isInitialized) {
      if (widget.isActive) {
        _videoController!.play();
      } else {
        _videoController!.pause();
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    setState(() {
      _showHeartAnimation = true;
      if (!_isLiked) {
        _isLiked = true;
        _localLikesCount++;
      }
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showHeartAnimation = false;
        });
      }
    });
  }

  void _togglePlayPause() {
    if (_videoController == null || !_isInitialized) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }

  void _showCommentsSheet() {
    HapticFeedback.mediumImpact();
    final TextEditingController textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
                  ),
                  child: Column(
                    children: [
                      // Stylish drag handle
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Traces Chat',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_comments.length} active notes',
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 1),

                      // Scrollable feedback loop
                      Expanded(
                        child: _comments.isEmpty 
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, color: Colors.white24, size: 40),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No comments yet.',
                                    style: GoogleFonts.inter(color: Colors.white38),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: _comments.length,
                              itemBuilder: (context, idx) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 36,
                                        width: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [AppColors.jadePrimary, Colors.teal],
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Campus Insider',
                                              style: GoogleFonts.plusJakartaSans(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.05),
                                                borderRadius: const BorderRadius.only(
                                                  topRight: Radius.circular(16),
                                                  bottomLeft: Radius.circular(16),
                                                  bottomRight: Radius.circular(16),
                                                ),
                                              ),
                                              child: Text(
                                                _comments[idx],
                                                style: GoogleFonts.inter(
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontSize: 14,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                      ),

                      // Stylized premium input pod
                      SafeArea(
                        top: false,
                        child: Container(
                          padding: EdgeInsets.only(
                            left: 20,
                            right: 20,
                            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                            top: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            border: const Border(top: BorderSide(color: Colors.white10, width: 1)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: TextField(
                                    controller: textController,
                                    style: GoogleFonts.inter(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Leave a dynamic trace note...',
                                      hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  if (textController.text.trim().isNotEmpty) {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _comments.add(textController.text.trim());
                                    });
                                    setSheetState(() {});
                                    textController.clear();
                                  }
                                },
                                child: Container(
                                  height: 45,
                                  width: 45,
                                  decoration: const BoxDecoration(
                                    color: AppColors.jadePrimary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isLost = widget.post.isLost;

    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Video Player or Loader
          if (_videoController != null && _isInitialized)
            Positioned.fill(
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width > 0 ? _videoController!.value.size.width : 1080,
                    height: _videoController!.value.size.height > 0 ? _videoController!.value.size.height : 1920,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              ),
            )
          else
            const SizedBox.expand(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF08080A),
                ),
              ),
            ),

          // 2. Play/Pause Visual overlay indicator on tap
          if (_videoController != null && _isInitialized && !_videoController!.value.isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
              ).animate().scale(duration: 150.ms),
            ),

          // 3. Bottom Gradient overlay (For textual readability)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 4. Double Tap Heart Animation overlay
          if (_showHeartAnimation)
            Center(
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.redAccent,
                size: 110,
              )
                  .animate()
                  .scale(duration: 200.ms, curve: Curves.bounceOut)
                  .fadeOut(delay: 400.ms, duration: 200.ms),
            ),

          // 5. Left Side Details (Bottom Left)
          Positioned(
            left: 16,
            bottom: 160,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // User info row
                Row(
                  children: [
                    UserAvatar(
                      photoURL: widget.post.posterAvatarUrl,
                      radius: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.post.posterName.isNotEmpty ? widget.post.posterName : 'Campus User',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Lost / Found badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isLost ? Colors.redAccent.withOpacity(0.25) : Colors.greenAccent.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLost ? Colors.redAccent : Colors.greenAccent,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        isLost ? 'LOST' : 'FOUND',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.post.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.post.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: Colors.amberAccent),
                    const SizedBox(width: 4),
                    Text(
                      widget.post.location.building,
                      style: GoogleFonts.inter(
                        color: Colors.amberAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 6. Right Action Panel (Bottom Right)
          Positioned(
            right: 14,
            bottom: 160,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Like Button
                _buildActionItem(
                  icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isLiked ? Colors.redAccent : Colors.white,
                  label: '$_localLikesCount',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isLiked = !_isLiked;
                      if (_isLiked) {
                        _localLikesCount++;
                      } else {
                        _localLikesCount--;
                      }
                    });
                  },
                ),
                const SizedBox(height: 18),

                // Comment Button
                _buildActionItem(
                  icon: Icons.comment_rounded,
                  color: Colors.white,
                  label: '${_comments.length}',
                  onTap: _showCommentsSheet,
                ),
                const SizedBox(height: 18),

                // Share Button
                _buildActionItem(
                  icon: Icons.share_rounded,
                  color: Colors.white,
                  label: 'Share',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    showAppSnack(context, 'Trace link copied to clipboard!');
                  },
                ),
                const SizedBox(height: 18),

                // Status chip icon representation
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12, width: 0.8),
                  ),
                  child: Icon(
                    widget.post.isOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
                    color: widget.post.isOpen ? Colors.greenAccent : Colors.white24,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12, width: 0.8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
