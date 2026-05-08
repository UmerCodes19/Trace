import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../api_service.dart';
import 'offline_cache_service.dart';
import 'dart:io';
import '../storage_service.dart';

class SyncManager {
  SyncManager._();
  static final instance = SyncManager._();

  final _syncStatusController = StreamController<bool>.broadcast();
  Stream<bool> get syncStatusStream => _syncStatusController.stream;

  List<Map<String, dynamic>> _pendingQueue = [];
  bool _isSyncing = false;

  Future<void> initialize() async {
    await loadQueue();
    
    // Register global connectivity monitor
    Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((result) => result != ConnectivityResult.none);
      if (hasConnection && !_isSyncing) {
        syncQueue();
      }
    });
  }

  Future<void> loadQueue() async {
    try {
      final data = await OfflineCacheService.instance.readDecryptedString('pending_posts_queue');
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        _pendingQueue = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {
      _pendingQueue = [];
    }
  }

  Future<void> saveQueue() async {
    try {
      final jsonStr = jsonEncode(_pendingQueue);
      await OfflineCacheService.instance.saveEncryptedString('pending_posts_queue', jsonStr);
    } catch (_) {}
  }

  Future<void> addPostToQueue(Map<String, dynamic> postData) async {
    // Add unique temp id for reference
    final item = Map<String, dynamic>.from(postData);
    if (!item.containsKey('id')) {
      item['id'] = 'pending_${DateTime.now().millisecondsSinceEpoch}';
    }
    _pendingQueue.add(item);
    await saveQueue();
    _syncStatusController.add(true); // Notify UI that queue changed
  }

  List<Map<String, dynamic>> getPendingPosts() => List.unmodifiable(_pendingQueue);

  Future<void> syncQueue() async {
    if (_isSyncing || _pendingQueue.isEmpty) return;

    _isSyncing = true;
    _syncStatusController.add(true);
    
    debugPrint('TRACE SYNC: Starting background upload of ${_pendingQueue.length} pending posts...');

    final List<Map<String, dynamic>> failedItems = [];

    for (var post in _pendingQueue) {
      try {
        final uploadData = Map<String, dynamic>.from(post);
        
        // Upload queued local images to Cloudinary first
        if (uploadData['imageUrls'] != null) {
          final List<dynamic> localUrls = uploadData['imageUrls'];
          final List<String> uploadedUrls = [];
          final String userId = uploadData['userId'] ?? 'anonymous';
          
          for (var img in localUrls) {
            final pathStr = img.toString();
            if (!pathStr.startsWith('http') && File(pathStr).existsSync()) {
              debugPrint('TRACE SYNC: Uploading queued local image to Cloudinary: $pathStr');
              final cloudUrl = await StorageService().uploadPostImage(File(pathStr), userId);
              uploadedUrls.add(cloudUrl);
            } else {
              uploadedUrls.add(pathStr);
            }
          }
          
          uploadData['imageUrls'] = uploadedUrls;
        }

        if (uploadData['imageUrl'] != null) {
          final pathStr = uploadData['imageUrl'].toString();
          if (!pathStr.startsWith('http') && File(pathStr).existsSync()) {
            debugPrint('TRACE SYNC: Uploading singular local image to Cloudinary: $pathStr');
            final String userId = uploadData['userId'] ?? 'anonymous';
            final cloudUrl = await StorageService().uploadPostImage(File(pathStr), userId);
            uploadData['imageUrl'] = cloudUrl;
          }
        }

        // Strip out the temp pending ID before sending to server so Vercel can generate real DB UUIDs
        if (uploadData['id']?.toString().startsWith('pending_') ?? false) {
          uploadData.remove('id');
        }
        
        await ApiService().createPost(uploadData);
        debugPrint('TRACE SYNC: Successfully synced pending post: "${post['title']}"');
      } catch (e) {
        debugPrint('TRACE SYNC: Failed to sync pending post: $e');
        failedItems.add(post); // Keep it in the queue for retry later
      }
    }

    _pendingQueue = failedItems;
    await saveQueue();
    
    _isSyncing = false;
    _syncStatusController.add(false);
  }
}
