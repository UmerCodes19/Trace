import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../data/models/simple_post_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/offline/sync_manager.dart';
// To reuse UserAvatar or similar if available
// Direct access to UserAvatar / AvatarConfig
import '../../widgets/common/user_avatar.dart';
import '../../../data/services/local_settings_service.dart';
import '../../widgets/common/skeleton.dart';
import '../../../core/utils/tutorial_keys.dart';
import '../../../core/utils/app_guide_orchestrator.dart';
import '../../../core/services/tutorial_service.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/services/auth_service.dart';



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
    // Activate precise safety polling loop on view mounting
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkReelsTour());
  }



  Future<void> _checkReelsTour() async {
    if (!mounted) return;
    final notifier = ref.read(activeTourStateProvider.notifier);
    if (notifier.state != ActiveTourState.reels) return;
    notifier.state = ActiveTourState.none; // Consume token immediately to lock out race conditions

    int retryCount = 0;
    while (_isLoading && mounted && retryCount < 30) {
      await Future.delayed(const Duration(milliseconds: 200));
      retryCount++;
    }

    if (mounted && !_isLoading) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _launchReelsTour();
    }
  }

  Future<void> _launchReelsTour() async {
    final service = ref.read(tutorialServiceProvider);
    if (await service.isFeatureTourCompleted('reels_tour')) return;

    final targets = <TargetFocus>[
      AppGuideOrchestrator.buildTarget(
        key: TutorialKeys.reelsContentKey,
        title: 'Video Feed',
        description: 'Swipe up to watch lost and found campus videos.',
        stepLabel: 'Reels',
        align: ContentAlign.bottom,
        radius: 20,
      ),
    ];

    final notifier = ref.read(activeTourStateProvider.notifier);
    final router = GoRouter.of(context);

    AppGuideOrchestrator.showTutorial(
      context: context,
      featureKey: 'reels_tour',
      targets: targets,
      tutorialService: service,
      onFinish: () {
        notifier.state = ActiveTourState.inbox;
        router.go('/chats');
      },
    );
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
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkReelsTour());
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
    final isDarkMode = ref.watch(themeProvider);

    if (!_isLoading && _reelPosts.isEmpty) {
      return Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: Center(
          child: Container(
            key: TutorialKeys.reelsContentKey,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_library_outlined, size: 64, color: isDarkMode ? Colors.white24 : Colors.black26),
              const SizedBox(height: 16),
              Text(
                'No Traces Yet',
                style: GoogleFonts.plusJakartaSans(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a post with a video to start the loop!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                  fontSize: 13,
                ),
              ),
            ],
          ).animate().fadeIn(),
        ),),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // Infinite vertical page view for reels
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            onPageChanged: (index) {
              if (!_isLoading) {
                HapticFeedback.selectionClick();
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            itemCount: _isLoading ? 2 : _reelPosts.length,
            itemBuilder: (context, index) {
              if (_isLoading) {
                return const ReelSkeletonItem();
              }
              final post = _reelPosts[index];
              final bool isActive = index == _currentIndex;
              // Critical Mem Fix: Only initialize items adjacent to current view (max 3 loaded at once)
              final bool shouldLoad = (index - _currentIndex).abs() <= 1;
              
              return ReelPlayerItem(
                post: post,
                isActive: isActive,
                shouldLoad: shouldLoad,
                isDarkMode: isDarkMode,
              );
            },
          ),

          // Header Overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 20,
            right: 20,
            child: Container(
              key: TutorialKeys.reelsContentKey,
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
          ),
        ],
      ),
    );
  }
}

class ReelPlayerItem extends ConsumerStatefulWidget {
  const ReelPlayerItem({
    super.key,
    required this.post,
    required this.isActive,
    required this.shouldLoad,
    required this.isDarkMode,
  });

  final SimplePostModel post;
  final bool isActive;
  final bool shouldLoad;
  final bool isDarkMode;

  @override
  ConsumerState<ReelPlayerItem> createState() => _ReelPlayerItemState();
}

class _ReelPlayerItemState extends ConsumerState<ReelPlayerItem> {

  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isLiked = false;
  bool _showHeartAnimation = false;
  bool _isMuted = false; // Add explicit mute state controller
  int _localLikesCount = 0;
  List<CommentModel> _comments = [];

  @override
  void initState() {
    super.initState();
    _localLikesCount = widget.post.likesCount;
    if (widget.shouldLoad) {
      _initializePlayer();
    }
    // Proactive hydrate from real DB backend logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInteractions();
    });
  }

  Future<void> _loadInteractions() async {
    try {
      final api = ref.read(apiServiceProvider);
      final currentUid = ref.read(authServiceProvider).currentUser?.uid;
      
      // 1. Load Like Status concurrently
      if (currentUid != null) {
         final hasLiked = await api.hasLikedPost(widget.post.id, currentUid);
         if (mounted) setState(() => _isLiked = hasLiked);
      }

      // 2. Load Real Comments Array
      final rawComments = await api.getCommentsForPost(widget.post.id);
      if (mounted) {
        setState(() {
          _comments = rawComments.map((m) => CommentModel.fromMap(m)).toList();
        });
      }
    } catch (e) {
      debugPrint('Reels interactions load failed: $e');
    }
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
    
    // Condition A: Node transitioned into loading window
    if (widget.shouldLoad && !oldWidget.shouldLoad && _videoController == null) {
      _initializePlayer();
    } 
    // Condition B: Node scrolled out of loading window — Kill hardware resources immediately
    else if (!widget.shouldLoad && oldWidget.shouldLoad) {
      _disposeController();
    }
    // Condition C: Node is loaded and changed active state
    else if (_videoController != null && _isInitialized) {
      if (widget.isActive) {
        _videoController!.play();
      } else {
        _videoController!.pause();
      }
    }
  }

  void _disposeController() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    if (mounted) {
      setState(() {
        _isInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _toggleLike({bool onlyLikeIfUnliked = false}) async {
    final currentUid = ref.read(authServiceProvider).currentUser?.uid;
    if (currentUid == null) return;
    
    if (onlyLikeIfUnliked && _isLiked) return; // prevent untoggling if double-tapping
    
    final oldLiked = _isLiked;
    final oldLikesCount = _localLikesCount;

    HapticFeedback.mediumImpact();
    setState(() {
      _isLiked = !_isLiked;
      _localLikesCount += _isLiked ? 1 : -1;
      if (_isLiked) _showHeartAnimation = true;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.toggleLike(widget.post.id, currentUid);
      if (mounted) {
        setState(() {
          _isLiked = result['liked'] ?? _isLiked;
          // If API returns a new count we use it, otherwise we trust local sync count!
          if (result['likeCount'] != null) _localLikesCount = result['likeCount'];
        });
      }

      final postOwnerId = widget.post.userId;
      if (result['liked'] == true && currentUid != postOwnerId) {
        final currentUserName = ref.read(authServiceProvider).currentUser?.name ?? 'Someone';
        await api.sendNotification(
          userId: postOwnerId,
          title: 'New Reel Like ❤️',
          body: '$currentUserName liked your reel: "${widget.post.title}"',
          type: 'general',
          data: {
            'postId': widget.post.id,
          },
        );
      }
    } catch (_) {
      // Revert on connection breakage
      if (mounted) {
        setState(() {
          _isLiked = oldLiked;
          _localLikesCount = oldLikesCount;
        });
      }
    }

    if (_showHeartAnimation) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _showHeartAnimation = false);
      });
    }
  }

  void _handleDoubleTap() {
    // On double tap, ONLY trigger if not already liked, else just play heart animation!
    if (!_isLiked) {
       _toggleLike(onlyLikeIfUnliked: true);
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _showHeartAnimation = true;
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _showHeartAnimation = false);
      });
    }
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
    final isDark = widget.isDarkMode;

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
                    color: isDark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.95),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08), width: 0.5),
                  ),
                  child: Column(
                    children: [
                      // Stylish drag handle
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black26,
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
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_comments.length} active notes',
                                  style: GoogleFonts.inter(
                                    color: isDark ? Colors.white54 : Colors.black54,
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
                                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close, color: isDark ? Colors.white : Colors.black, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),

                      // Scrollable feedback loop
                      Expanded(
                        child: _comments.isEmpty 
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, color: isDark ? Colors.white24 : Colors.black26, size: 40),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No comments yet.',
                                    style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: _comments.length,
                              itemBuilder: (context, idx) {
                                final c = _comments[idx];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      UserAvatar(photoURL: c.userAvatarUrl, radius: 18),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    cleanCMSUsername(c.userName),
                                                    style: GoogleFonts.plusJakartaSans(
                                                      color: isDark ? Colors.white : Colors.black87,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                   AppDateUtils.timeAgo(c.timestamp),
                                                   style: GoogleFonts.inter(
                                                     color: isDark ? Colors.white30 : Colors.black38,
                                                     fontSize: 10,
                                                   ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                                                borderRadius: const BorderRadius.only(
                                                  topRight: Radius.circular(16),
                                                  bottomLeft: Radius.circular(16),
                                                  bottomRight: Radius.circular(16),
                                                ),
                                              ),
                                              child: Text(
                                                c.text,
                                                style: GoogleFonts.inter(
                                                  color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
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
                            color: isDark ? Colors.black.withOpacity(0.4) : Colors.grey.shade50,
                            border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), width: 1)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: TextField(
                                    controller: textController,
                                    style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87),
                                    decoration: InputDecoration(
                                      hintText: 'Leave a dynamic trace note...',
                                      hintStyle: GoogleFonts.inter(color: isDark ? Colors.white30 : Colors.black38, fontSize: 13),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () async {
                                  final txt = textController.text.trim();
                                  if (txt.isEmpty) return;
                                  
                                  final user = ref.read(authServiceProvider).currentUser;
                                  if (user == null) return;

                                  HapticFeedback.lightImpact();
                                  textController.clear();

                                  // Construct genuine domain model
                                  final comment = CommentModel(
                                    id: const Uuid().v4(),
                                    postId: widget.post.id,
                                    userId: user.uid,
                                    userName: user.name,
                                    userAvatarUrl: user.photoURL ?? '',
                                    text: txt,
                                    timestamp: DateTime.now(),
                                  );

                                  // Optimistic Local Push
                                  setState(() {
                                    _comments.insert(0, comment); // Add at TOP for instant feedback!
                                  });
                                  setSheetState(() {}); // Refresh Modal State immediately

                                  try {
                                    final api = ref.read(apiServiceProvider);
                                    await api.addComment(comment.toMap());

                                    final postOwnerId = widget.post.userId;
                                    if (user.uid != postOwnerId) {
                                      await api.sendNotification(
                                        userId: postOwnerId,
                                        title: 'New Comment 💬',
                                        body: '${cleanCMSUsername(user.name)} commented on your reel: "$txt"',
                                        type: 'general',
                                        data: {
                                          'postId': widget.post.id,
                                        },
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint('Failed to propagate comment: $e');
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
                    Flexible(
                      child: Text(
                        widget.post.posterName.isNotEmpty ? widget.post.posterName : 'Campus User',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                    Expanded(
                      child: Text(
                        widget.post.location.building,
                        style: GoogleFonts.inter(
                          color: Colors.amberAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  onTap: () => _toggleLike(),
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
                    // Real share targeting deployment server!
                    final text = 'Check out this Trace by ${widget.post.posterName.isNotEmpty ? widget.post.posterName : "Campus User"}:\n'
                        '${widget.post.title}\n\n'
                        'View details here: https://trace-self.vercel.app/post/${widget.post.id}';
                    Share.share(text);
                  },
                ),

                const SizedBox(height: 18),

                // Volume / Mute Button
                _buildActionItem(
                  icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  label: _isMuted ? 'Muted' : 'Sound',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _isMuted = !_isMuted;
                      _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
                    });
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


class ReelSkeletonItem extends StatelessWidget {
  const ReelSkeletonItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        SkeletonBox(height: double.infinity, width: double.infinity),
        Positioned(
          left: 16,
          bottom: 160,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(height: 40, width: 40, radius: 20),
                  const SizedBox(width: 12),
                  SkeletonBox(height: 20, width: 120),
                ],
              ),
              const SizedBox(height: 16),
              SkeletonBox(height: 18, width: 200),
              const SizedBox(height: 8),
              SkeletonBox(height: 14, width: 140),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 160,
          child: Column(
            children: [
              SkeletonBox(height: 48, width: 48, radius: 24),
              const SizedBox(height: 24),
              SkeletonBox(height: 48, width: 48, radius: 24),
              const SizedBox(height: 24),
              SkeletonBox(height: 48, width: 48, radius: 24),
            ],
          ),
        ),
      ],
    );
  }
}

