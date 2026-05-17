import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/simple_post_model.dart';
import './auth_service.dart';
import './offline/sync_manager.dart';

/// Configuration class for Riverpod caching and memoized filtering
class FeedFilterConfig {
  final String query;
  final String filter;
  final String? building;
  final String? category;
  final String? recency;

  const FeedFilterConfig({
    required this.query,
    required this.filter,
    this.building,
    this.category,
    this.recency,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedFilterConfig &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          filter == other.filter &&
          building == other.building &&
          category == other.category &&
          recency == other.recency;

  @override
  int get hashCode => query.hashCode ^ filter.hashCode ^ building.hashCode ^ category.hashCode ^ recency.hashCode;
}

/// ISOLATE HARDWARE WORKER FUNCTION:
/// Processes computationally-heavy string scoring and recursive tagging logic off the main thread.
List<String> _executeBackgroundFilter(Map<String, dynamic> input) {
  final List<dynamic> rawPosts = input['posts'] ?? [];
  final Map<String, dynamic> config = input['config'] ?? {};
  
  final query = (config['query'] as String? ?? '').trim();
  final filter = config['filter'] as String? ?? 'all';
  final building = config['building'] as String?;
  final category = config['category'] as String?;
  final recency = config['recency'] as String?;

  final now = DateTime.now();
  final matchingIds = <String>[];

  for (var p in rawPosts) {
    try {
      final String id = p['id']?.toString() ?? '';
      final String type = p['type']?.toString() ?? 'lost';
      final String status = p['status']?.toString() ?? 'open';
      final String bName = (p['location_building'] ?? p['buildingName'] ?? '').toString();
      final String title = p['title']?.toString() ?? '';
      final String desc = p['description']?.toString() ?? '';
      
      dynamic rawTags = p['aiTags'] ?? [];
      final List<String> tags = rawTags is List ? rawTags.map((t) => t.toString().toLowerCase()).toList() : [];

      // 1. Tab Pre-Filtering
      if (filter == 'lost') {
        if (type != 'lost' || status == 'resolved') continue;
      } else if (filter == 'found') {
        if (type != 'found' || status == 'resolved') continue;
      } else if (filter == 'resolved') {
        if (status != 'resolved') continue;
      }

      // 2. Campus Building Filtering
      if (building != null && bName.toLowerCase() != building.toLowerCase()) {
        continue;
      }

      // 3. Category Semantic Filtering
      if (category != null) {
        final catLow = category.toLowerCase();
        final tLow = title.toLowerCase();
        final dLow = desc.toLowerCase();

        bool match = false;
        if (catLow == 'electronics') {
          final kw = ['electronics', 'phone', 'laptop', 'charger', 'earbuds', 'device', 'cable', 'usb', 'calculator', 'watch', 'camera'];
          match = kw.any((k) => tLow.contains(k) || dLow.contains(k) || tags.contains(k));
        } else if (catLow == 'keys & cards') {
          final kw = ['key', 'keys', 'card', 'id', 'student card', 'atm', 'license', 'badge', 'cnic'];
          match = kw.any((k) => tLow.contains(k) || dLow.contains(k) || tags.contains(k));
        } else if (catLow == 'bags & wallets') {
          final kw = ['bag', 'wallet', 'purse', 'backpack', 'pouch', 'handbag', 'suede', 'pocketbook'];
          match = kw.any((k) => tLow.contains(k) || dLow.contains(k) || tags.contains(k));
        } else if (catLow == 'documents') {
          final kw = ['document', 'paper', 'file', 'cnic', 'passport', 'booklet', 'degree', 'certificate'];
          match = kw.any((k) => tLow.contains(k) || dLow.contains(k) || tags.contains(k));
        } else if (catLow == 'books & stationery') {
          final kw = ['book', 'stationery', 'pen', 'pencil', 'notebook', 'register', 'binder', 'calculator'];
          match = kw.any((k) => tLow.contains(k) || dLow.contains(k) || tags.contains(k));
        } else if (catLow == 'others') {
          final kw = ['electronics', 'phone', 'laptop', 'charger', 'earbuds', 'device', 'cable', 'usb', 'key', 'keys', 'card', 'id', 'bag', 'wallet', 'document', 'book'];
          match = !kw.any((k) => tLow.contains(k) || dLow.contains(k) || tags.contains(k));
        }
        if (!match) continue;
      }

      // 4. Date Recency
      if (recency != null && p['timestamp'] != null) {
        final tsStr = p['timestamp'].toString();
        DateTime? tDate;
        try { tDate = DateTime.tryParse(tsStr); } catch (_) {}
        
        if (tDate != null) {
          final diffDays = now.difference(tDate).inDays;
          if (recency == 'Today' && diffDays >= 1) continue;
          if (recency == 'Last 3 Days' && diffDays >= 3) continue;
          if (recency == 'This Week' && diffDays >= 7) continue;
          if (recency == 'This Month' && diffDays >= 30) continue;
        }
      }

      // 5. Tokenized Search Score (Computational Intensity)
      if (query.isNotEmpty) {
        final qLow = query.toLowerCase();
        final tLow = title.toLowerCase();
        final dLow = desc.toLowerCase();
        final bLow = bName.toLowerCase();

        if (tLow.contains(qLow) || dLow.contains(qLow) || bLow.contains(qLow)) {
          matchingIds.add(id);
          continue;
        }

        final words = qLow.split(' ').where((w) => w.length > 1).toList();
        if (words.isEmpty) continue;

        int score = 0;
        for (var word in words) {
          if (tLow.contains(word)) score += 2;
          if (dLow.contains(word)) score += 1;
          if (bLow.contains(word)) score += 1;
          if (tags.any((tg) => tg.contains(word) || word.contains(tg))) score += 2;
        }
        
        if (score >= 2) {
          matchingIds.add(id);
        }
      } else {
        // No search query, passes everything else
        matchingIds.add(id);
      }

    } catch (_) {
      // Skip corrupt post entries gracefully in background
    }
  }

  return matchingIds;
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// PERF: Disabled 30s polling timer — was triggering 4 network requests + full rebuild
// every 30s even when backgrounded. Use pull-to-refresh + future Realtime subscriptions.
// final liveRefreshProvider = StreamProvider<int>((ref) {
//   return Stream.periodic(const Duration(seconds: 30), (count) => count);
// });

// Optimistic local tracking for deleted/resolved posts to collapse grid instantly
final removedPostIdsProvider = StateProvider<Set<String>>((ref) => {});

final postsProvider = FutureProvider<List<SimplePostModel>>((ref) async {
  final removedIds = ref.watch(removedPostIdsProvider);
  
  final api = ref.watch(apiServiceProvider);
  final data = await api.getPosts();
  final List<SimplePostModel> onlinePosts = data.map((p) => SimplePostModel.fromMap(p)).toList();
  
  List<SimplePostModel> combined;
  try {
    final pendingRaw = SyncManager.instance.getPendingPosts();
    final pendingPosts = pendingRaw.map((p) => SimplePostModel.fromMap(p)).toList();
    combined = [...pendingPosts, ...onlinePosts];
  } catch (e) {
    debugPrint('Offline posts loading error: $e');
    combined = onlinePosts;
  }

  // Optimistic local filter applied seamlessly here!
  return combined.where((post) => !removedIds.contains(post.id)).toList();
});

/// Reactive state manager for contextual comment feeds.
final commentsProvider = FutureProvider.family.autoDispose<List<dynamic>, String>((ref, postId) async {
  final api = ref.watch(apiServiceProvider);
  return await api.getCommentsForPost(postId);
});

/// Struct tracking context for global Reply-to overlay mechanisms.
class ActiveReply {
  final String commentId;
  final String userName;
  ActiveReply({required this.commentId, required this.userName});
}
/// Real-time dispatcher tracking the actively engaged reply target globally.
final activeReplyProvider = StateProvider.autoDispose<ActiveReply?>((ref) => null);


/// High Performance Filtered Provider:
/// Memoizes based on configurations, and routes algorithmic searches to Background Isolates.
final filteredPostsProvider = FutureProvider.family<List<SimplePostModel>, FeedFilterConfig>((ref, config) async {
  // Step 1: Grab the base feed data (auto-cached by postsProvider)
  final postsAsync = ref.watch(postsProvider);
  final posts = postsAsync.asData?.value ?? [];

  if (posts.isEmpty) return [];

  // Step 2: Extract minimum necessary attributes for zero-friction cross-isolate transmission.
  // We ONLY serialize identification + searchable fields, avoiding photo URLs memory bloat.
  final payload = posts.map((p) => {
    'id': p.id,
    'type': p.type,
    'status': p.status,
    'title': p.title,
    'description': p.description,
    'location_building': p.location.building,
    'aiTags': p.aiTags,
    'timestamp': p.timestamp.toIso8601String(),
  }).toList();

  final workerPayload = {
    'posts': payload,
    'config': {
      'query': config.query,
      'filter': config.filter,
      'building': config.building,
      'category': config.category,
      'recency': config.recency,
    }
  };

  // Step 3: Spawn hardware isolate worker for complex scoring without pausing UI renderer.
  final List<String> matchedIds = await compute(_executeBackgroundFilter, workerPayload);

  // Step 4: Map IDs back to original objects at O(N) speed.
  final idSet = Set<String>.from(matchedIds);
  return posts.where((p) => idSet.contains(p.id)).toList();
});

/// ========================================================
/// PHASE 3: ENTERPRISE-GRADE PAGINATED FEED CONTROLLER
/// ========================================================

class PaginatedFeedState {
  final List<SimplePostModel> posts;
  final bool hasMore;
  final bool isLoadingMore;

  PaginatedFeedState({
    required this.posts,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  PaginatedFeedState copyWith({
    List<SimplePostModel>? posts,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PaginatedFeedState(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Smart notifier that orchestrates progressive chunk fetching from the backend.
class PaginatedFeedNotifier extends AutoDisposeFamilyAsyncNotifier<PaginatedFeedState, FeedFilterConfig> {
  static const int _pageSize = 15;

  @override
  Future<PaginatedFeedState> build(FeedFilterConfig arg) async {
    // Fetch initial chunk instantly when widget mounts
    final results = await _fetchChunk(offset: 0);
    
    // Sift in any local pending sync posts only for the very first initial page
    List<SimplePostModel> initialList = results;
    if (arg.query.isEmpty && arg.filter == 'all') {
      try {
         final pendingRaw = SyncManager.instance.getPendingPosts();
         final pending = pendingRaw.map((p) => SimplePostModel.fromMap(p)).toList();
         initialList = [...pending, ...results];
      } catch (_) {}
    }

    return PaginatedFeedState(
      posts: initialList,
      hasMore: results.length >= _pageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    // Update state to show loading bubble at bottom of list
    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      // Offset should be the count of ACTUAL fetched posts (excluding pending syncs)
      final existingPostCount = current.posts.where((p) => !p.id.startsWith('pending_')).length;
      final nextChunk = await _fetchChunk(offset: existingPostCount);
      
      // Deduplicate just in case items shifted order in real-time DB
      final existingIds = current.posts.map((p) => p.id).toSet();
      final uniqueNew = nextChunk.where((p) => !existingIds.contains(p.id)).toList();

      state = AsyncData(PaginatedFeedState(
        posts: [...current.posts, ...uniqueNew],
        hasMore: nextChunk.length >= _pageSize,
        isLoadingMore: false,
      ));
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<List<SimplePostModel>> _fetchChunk({required int offset}) async {
    final api = ref.read(apiServiceProvider);
    
    final response = await api.getPosts(
      limit: _pageSize,
      offset: offset,
      type: arg.filter == 'lost' ? 'lost' : (arg.filter == 'found' ? 'found' : null),
      status: arg.filter == 'resolved' ? 'resolved' : 'open', // Only resolved if selected, else active
      building: arg.building,
      category: arg.category,
      search: arg.query.isNotEmpty ? arg.query : null,
      recency: arg.recency,
    );

    return response.map((m) => SimplePostModel.fromMap(m)).toList();
  }
}

final paginatedFeedProvider = AsyncNotifierProvider.family.autoDispose<PaginatedFeedNotifier, PaginatedFeedState, FeedFilterConfig>(() {
  return PaginatedFeedNotifier();
});

final myClaimsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getMyClaims();
});

final forYouPostsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getForYouPosts();
});

final notificationsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final user = ref.watch(authServiceProvider).currentUser;
  if (user == null) return [];
  
  try {
    final response = await api._dio.get('/notifications/${user.uid}');
    final list = response.data as List;
    // Explicitly filter to matching user ID on client side for added security
    return list.where((notif) => notif != null && (notif['userId'] == user.uid || notif['user_id'] == user.uid)).toList();
  } catch (e) {
    return [];
  }
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final user = ref.watch(authServiceProvider).currentUser;
  if (user == null) return 0;
  return api.getUnreadCountForUser(user.uid);
});

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: dotenv.env['VERCEL_URL'] ?? 'https://trace-self.vercel.app/api',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Reusable client for direct Supabase side-loading with connection pooling
  late final Dio _supabaseDio;

  Dio get dio => _dio;

  ApiService() {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://xmtyxfsqhvywvszlinur.supabase.co';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    _supabaseDio = Dio(BaseOptions(
      baseUrl: '$supabaseUrl/rest/v1',
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
      },
      connectTimeout: const Duration(seconds: 10),
    ));

    // Smart Logging Interceptor to filter out noisy background polling logs
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final path = options.path.toLowerCase();
        final isNoisy = (path.contains('/chats') && !path.contains('/messages')) || path.contains('/unread');
        if (!isNoisy) {
          debugPrint('📡 [API Request] ${options.method} -> ${options.uri}');
          if (options.data != null) debugPrint('   Payload: ${options.data}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final path = response.requestOptions.path.toLowerCase();
        final isNoisy = (path.contains('/chats') && !path.contains('/messages')) || path.contains('/unread');
        if (!isNoisy) {
          debugPrint('✅ [API Response] ${response.statusCode} <- ${response.requestOptions.uri}');
        }
        return handler.next(response);
      },
      onError: (err, handler) {
        debugPrint('❌ [API Error] ${err.requestOptions.method} -> ${err.requestOptions.uri}');
        debugPrint('   Message: ${err.message}');
        if (err.response != null) debugPrint('   Response: ${err.response?.data}');
        return handler.next(err);
      },
    ));

    // Add Auth Interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
        if (token == null) {
          try {
            const storage = FlutterSecureStorage();
            final value = await storage.read(key: 'session_user');
            if (value != null) {
              final Map<String, dynamic> map = jsonDecode(value);
              if (map['uid'] != null) {
                token = map['uid'];
              }
            }
          } catch (_) {}
        }
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          await FirebaseAuth.instance.signOut();
        }
        return handler.next(e);
      },
    ));
  }

  // ==================== User Operations ====================

  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final response = await _dio.get('/users/$uid');
      return response.data;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> syncUser(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post('/users/sync', data: userData);
      return response.data;
    } catch (e) {
      debugPrint('Error syncing user: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getLeaderboard() async {
    try {
      // Direct fetch to Supabase bypasses Vercel deployment delays!
      final response = await _supabaseDio.get(
        '/users',
        queryParameters: {
          'select': 'uid,name,email,karmaPoints,photoURL,itemsReturned',
          'order': 'karmaPoints.desc',
          'limit': '50',
        },
      );
      return response.data as List<dynamic>;
    } catch (e) {
      debugPrint('Direct Supabase fetch failed, falling back to Node backend: $e');
      try {
        final response = await _dio.get('/users/leaderboard');
        return response.data;
      } catch (err) {
        debugPrint('Backup backend fetch failed: $err');
        return [];
      }
    }
  }

  Future<void> updateUserStats(String uid, Map<String, int> stats) async {
    try {
      await _dio.post('/users/$uid/stats', data: stats);
    } catch (e) {
      debugPrint('Error updating user stats: $e');
    }
  }

  // ==================== Post Operations ====================

  Future<List<dynamic>> getPosts({
    String? type,
    String? status,
    int? limit,
    int? offset,
    String? building,
    String? category,
    String? search,
    String? recency,
  }) async {
    try {
      final response = await _dio.get('/posts', queryParameters: {
        if (type != null) 'type': type,
        if (status != null) 'status': status,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
        if (building != null) 'building': building,
        if (category != null) 'category': category,
        if (search != null) 'search': search,
        if (recency != null) 'recency': recency,
      });
      return response.data;
    } catch (e) {
      debugPrint('Error getting posts: $e');
      return [];
    }
  }

  Future<void> incrementViewCount(String postId) async {
    try {
      await _dio.post('/posts/$postId/view');
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  Future<bool> hasLikedPost(String postId, String userId) async {
    try {
      final response = await _dio.get('/posts/$postId/liked/$userId');
      return response.data['liked'] ?? false;
    } catch (e) {
      debugPrint('Error checking like status: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> toggleLike(String postId, String userId) async {
    try {
      final response = await _dio.post('/posts/$postId/like', data: {'userId': userId});
      return response.data;
    } catch (e) {
      debugPrint('Error toggling like: $e');
      return {'liked': false, 'likeCount': 0};
    }
  }

  Future<void> reportPost(String postId) async {
    try {
      await _dio.post('/posts/$postId/report');
    } catch (e) {
      debugPrint('Error reporting post: $e');
    }
  }



  Future<Map<String, dynamic>?> getPost(String id) async {
    try {
      final response = await _dio.get('/posts/$id');
      return response.data;
    } catch (e) {
      debugPrint('Error getting post: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> postData) async {
    try {
      final response = await _dio.post('/posts', data: postData);
      return response.data;
    } catch (e) {
      debugPrint('Error creating post: $e');
      rethrow;
    }
  }

  Future<void> updatePost(String id, Map<String, dynamic> updates) async {
    try {
      await _dio.put('/posts/$id', data: updates);
    } catch (e) {
      debugPrint('Error updating post: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String id) async {
    try {
      await _dio.delete('/posts/$id');
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getForYouPosts() async {
    try {
      final response = await _dio.get('/posts/for-you');
      return response.data;
    } catch (e) {
      debugPrint('Error getting for-you posts: $e');
      return [];
    }
  }

  // ==================== Chat Operations ====================

  Future<List<dynamic>> getUserChats(String uid) async {
    try {
      final response = await _dio.get('/chats/user/$uid');
      final List<dynamic> rawChats = response.data;
      if (rawChats.isEmpty) return [];

      // EXTREME PERFORMANCE FIX: Collate distinct user IDs for a SINGLE batch query
      final Set<String> distinctUids = {};
      for (var chat in rawChats) {
        final participants = chat['participants'] as List?;
        final otherUid = participants?.firstWhere((p) => p != uid, orElse: () => null) as String?;
        if (otherUid != null) distinctUids.add(otherUid);
      }

      // Map storing the resolved profile data
      Map<String, dynamic> userProfileMap = {};

      if (distinctUids.isNotEmpty) {
        try {
          // Direct Supabase Batch Fetch in ONE CALL
          // Direct Supabase Batch Fetch via reusable pooled client
          final batchResp = await _supabaseDio.get(
            '/users',
            queryParameters: {
              'uid': 'in.(${distinctUids.join(',')})',
              'select': 'uid,name,photoURL',
            },
          );

          final List<dynamic> profiles = batchResp.data;
          for (var prof in profiles) {
            if (prof['uid'] != null) userProfileMap[prof['uid']] = prof;
          }
        } catch (e) {
          debugPrint('Batch user fetch failed, fallback to single fetches: $e');
        }
      }

      // Hydrate the final list instantly with zero blocking network delays
      final List<dynamic> enrichedChats = rawChats.map((chat) {
        final participants = chat['participants'] as List?;
        final otherUid = participants?.firstWhere((p) => p != uid, orElse: () => null) as String?;
        
        final matchedProfile = otherUid != null ? userProfileMap[otherUid] : null;

        return <String, dynamic>{
          ...chat,
          'otherUserName': matchedProfile?['name'] ?? chat['otherUserName'] ?? 'Campus User',
          'otherUserAvatar': matchedProfile?['photoURL'] ?? chat['otherUserAvatar'],
        };
      }).toList();

      return enrichedChats;
    } catch (e) {
      debugPrint('Error getting chats: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getChat(String chatId) async {
    try {
      final response = await _dio.get('/chats/$chatId');
      return response.data;
    } catch (e) {
      debugPrint('Error getting chat: $e');
      return null;
    }
  }

  Future<bool> deleteChat(String chatId) async {
    try {
      final response = await _dio.delete('/chats/$chatId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> createChat(Map<String, dynamic> chatData) async {
    try {
      final response = await _dio.post('/chats', data: chatData);
      return response.data;
    } catch (e) {
      debugPrint('Error creating chat: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getChatMessages(String chatId, {int? limit, int? before}) async {
    try {
      final response = await _dio.get('/chats/$chatId/messages', queryParameters: {
        if (limit != null) 'limit': limit,
        if (before != null) 'before': before,
      });
      return response.data;
    } catch (e) {
      debugPrint('Error getting messages: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> messageData) async {
    try {
      final response = await _dio.post('/chats/messages', data: messageData);
      return response.data;
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getCommentsForPost(String postId) async {
    try {
      final response = await _dio.get('/posts/$postId/comments');
      return response.data;
    } catch (e) {
      debugPrint('Error getting comments: $e');
      return [];
    }
  }

  Future<void> addComment(Map<String, dynamic> commentData) async {
    try {
      await _dio.post('/posts/${commentData['postId']}/comments', data: commentData);
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  Future<void> markMessagesRead(String chatId, String userId) async {
    try {
      await _dio.post('/chats/$chatId/read', data: {'userId': userId});
    } catch (e) {
      debugPrint('Error marking messages read: $e');
    }
  }

  Future<int> getUnreadCountForUser(String uid) async {
    try {
      final response = await _dio.get('/chats/user/$uid/unread');
      return response.data['count'] ?? 0;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  // ==================== CMS Operations ====================

  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final response = await _dio.get('/admin/stats');
      // Map to the format expected by DebugScreen
      return {
        'users': response.data['totalUsers'] ?? 0,
        'posts': response.data['totalPosts'] ?? 0,
        'chats': 0, // Not explicitly provided by stats yet
        'messages': 0, // Not explicitly provided by stats yet
      };
    } catch (e) {
      debugPrint('Error getting database stats: $e');
      return {};
    }
  }

  Future<List<dynamic>> getTimetable(String enrollment) async {
    try {
      final response = await _dio.get('/cms/$enrollment');
      return response.data;
    } catch (e) {
      debugPrint('Error getting timetable: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await _dio.get('/admin/stats');
      return response.data;
    } catch (e) {
      debugPrint('Error getting admin stats: $e');
      return {};
    }
  }

  Future<List<dynamic>> getFlaggedPosts() async {
    try {
      final response = await _dio.get('/admin/flagged-posts');
      return response.data;
    } catch (e) {
      debugPrint('Error getting flagged posts: $e');
      return [];
    }
  }

  Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await _dio.get('/admin/users');
      return response.data;
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  Future<void> setUserBanStatus(String uid, bool isBanned) async {
    try {
      await _dio.post('/admin/users/$uid/ban', data: {'isBanned': isBanned});
    } catch (e) {
      debugPrint('Error setting ban status: $e');
    }
  }

  Future<void> clearPostReports(String postId) async {
    try {
      await _dio.post('/admin/posts/$postId/clear-reports');
    } catch (e) {
      debugPrint('Error clearing reports: $e');
    }
  }

  Future<void> saveTimetable(String enrollment, List<Map<String, dynamic>> timetable) async {
    try {
      await _dio.post('/cms', data: {
        'enrollment': enrollment,
        'timetable': timetable,
      });
    } catch (e) {
      debugPrint('Error saving timetable: $e');
      rethrow;
    }
  }
  Future<void> markAllNotificationsRead(String uid) async {
    try {
      await _dio.post('/notifications/user/$uid/read-all');
    } catch (e) {
      debugPrint('Error marking all notifications read: $e');
    }
  }

  Future<void> markNotificationRead(String id) async {
    try {
      await _dio.post('/notifications/$id/read');
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      // Force direct delete to bypass production Node server delay
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://xmtyxfsqhvywvszlinur.supabase.co';
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      
      final directDio = Dio();
      await directDio.delete(
        '$supabaseUrl/rest/v1/notifications',
        queryParameters: { 'id': 'eq.$id' },
        options: Options(
          headers: {
            'apikey': anonKey,
            'Authorization': 'Bearer $anonKey',
            'Prefer': 'return=minimal'
          },
        ),
      );
    } catch (e) {
      debugPrint('Direct notification delete failed, falling back to node: $e');
      try {
        await _dio.delete('/notifications/$id');
      } catch (err) {
        debugPrint('Error deleting notification: $err');
      }
    }
  }

  Future<void> clearAllNotifications(String uid) async {
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://xmtyxfsqhvywvszlinur.supabase.co';
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      
      final directDio = Dio();
      await directDio.delete(
        '$supabaseUrl/rest/v1/notifications',
        queryParameters: { 'user_id': 'eq.$uid' },
        options: Options(
          headers: {
            'apikey': anonKey,
            'Authorization': 'Bearer $anonKey',
            'Prefer': 'return=minimal'
          },
        ),
      );
    } catch (e) {
      debugPrint('Direct clear notifications failed: $e');
      try {
        await _dio.delete('/notifications/user/$uid/clear');
      } catch (err) {
        debugPrint('Error clearing all notifications: $err');
      }
    }
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://xmtyxfsqhvywvszlinur.supabase.co';
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      final directDio = Dio();
      await directDio.post(
        '$supabaseUrl/rest/v1/notifications',
        data: {
          'user_id': userId,
          'title': title,
          'body': body,
          'type': type,
          'is_read': false,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': data ?? {},
        },
        options: Options(
          headers: {
            'apikey': anonKey,
            'Authorization': 'Bearer $anonKey',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal',
          },
        ),
      );
    } catch (e) {
      debugPrint('Failed to send notification: $e');
    }
  }

  // ==================== Claim Operations (The Gatekeeper) ====================

  Future<Map<String, dynamic>> requestClaim({
    required String postId,
    required String proofText,
    String? proofImageUrl,
  }) async {
    try {
      final response = await _dio.post('/claims/request', data: {
        'postId': postId,
        'proofText': proofText,
        'proofImageUrl': proofImageUrl,
      });
      return response.data;
    } catch (e) {
      debugPrint('Error requesting claim: $e');
      rethrow;
    }
  }

  Future<void> respondToClaim(String claimId, String status) async {
    try {
      await _dio.put('/claims/respond/$claimId', data: {'status': status});
    } catch (e) {
      debugPrint('Error responding to claim: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyHandshake(String claimId) async {
    try {
      final response = await _dio.post('/claims/handshake/verify', data: {
        'claimId': claimId,
      });
      return response.data;
    } catch (e) {
      debugPrint('Error verifying handshake: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getClaimsForPost(String postId) async {
    try {
      final response = await _dio.get('/claims/post/$postId');
      return response.data;
    } catch (e) {
      debugPrint('Error getting claims for post: $e');
      return [];
    }
  }

  Future<List<dynamic>> getMyClaims() async {
    try {
      final response = await _dio.get('/claims/my');
      return response.data;
    } catch (e) {
      debugPrint('Error getting my claims: $e');
      return [];
    }
  }
}
