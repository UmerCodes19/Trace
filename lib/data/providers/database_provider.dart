import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simple_post_model.dart';
import '../models/simple_chat_model.dart';
import '../services/api_service.dart';

// Convenience providers for posts
final allPostsProvider = FutureProvider<List<SimplePostModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final posts = await api.getPosts();
  return posts.map((p) => SimplePostModel.fromMap(p)).toList();
});

final lostPostsProvider = FutureProvider<List<SimplePostModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final posts = await api.getPosts(type: 'lost');
  return posts.map((p) => SimplePostModel.fromMap(p)).toList();
});

final foundPostsProvider = FutureProvider<List<SimplePostModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final posts = await api.getPosts(type: 'found');
  return posts.map((p) => SimplePostModel.fromMap(p)).toList();
});

final userChatsProvider = FutureProvider.family<List<SimpleChatModel>, String>((ref, userId) async {
  final api = ref.read(apiServiceProvider);
  final chats = await api.getUserChats(userId);
  return chats.map((c) => SimpleChatModel.fromMap(c)).toList();
});