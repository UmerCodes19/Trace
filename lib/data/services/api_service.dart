import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    // TODO: Replace with your actual Render API URL
    baseUrl: 'https://trace-qybrkad5.b4a.run/api',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  ApiService() {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint(obj.toString()),
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
  }) async {
    try {
      final response = await _dio.get('/posts', queryParameters: {
        if (type != null) 'type': type,
        if (status != null) 'status': status,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
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

  Future<bool> toggleLike(String postId, String userId) async {
    try {
      final response = await _dio.post('/posts/$postId/like', data: {'userId': userId});
      return response.data['liked'] ?? false;
    } catch (e) {
      debugPrint('Error toggling like: $e');
      return false;
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

  // ==================== Chat Operations ====================

  Future<List<dynamic>> getUserChats(String uid) async {
    try {
      final response = await _dio.get('/chats/user/$uid');
      return response.data;
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

  Future<Map<String, dynamic>> createChat(Map<String, dynamic> chatData) async {
    try {
      final response = await _dio.post('/chats', data: chatData);
      return response.data;
    } catch (e) {
      debugPrint('Error creating chat: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getChatMessages(String chatId) async {
    try {
      final response = await _dio.get('/chats/$chatId/messages');
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
}
