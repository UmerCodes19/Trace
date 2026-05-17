import 'dart:convert';

class SimplePostModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String description;
  final List<String> imageUrls;
  final SimplePostLocation location;
  final DateTime timestamp;
  final String status;
  final List<String> aiTags;
  final int reportCount;
  final int viewCount;
  final int likesCount;
  final String posterName;
  final String posterAvatarUrl;
  final bool isCMSVerified;
  final String? secretDetailQuestion;
  final String? videoUrl;
  final String? custodyLocation;

  SimplePostModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.location,
    required this.timestamp,
    this.status = 'open',
    this.aiTags = const [],
    this.reportCount = 0,
    this.viewCount = 0,
    this.likesCount = 0,
    this.posterName = '',
    this.posterAvatarUrl = '',
    this.isCMSVerified = false,
    this.secretDetailQuestion,
    this.videoUrl,
    this.custodyLocation,
  });

  factory SimplePostModel.fromMap(Map<String, dynamic> map) {
    List<String> parseList(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        return data.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      if (data is String) {
        final trimmed = data.trim();
        if (trimmed.isEmpty) return [];
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) {
            return decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
          }
        } catch (_) {}
        return [trimmed];
      }
      return [];
    }

    final rawDesc = map['description'] as String? ?? '';
    String cleanDesc = rawDesc;
    String? extractedVideoUrl;
    String? extractedCustody;

    // Parse [video:...]
    if (cleanDesc.contains('[video:')) {
      final startIndex = cleanDesc.indexOf('[video:');
      final endIndex = cleanDesc.indexOf(']', startIndex);
      if (endIndex != -1) {
        extractedVideoUrl = cleanDesc.substring(startIndex + 7, endIndex).trim();
        cleanDesc = (cleanDesc.substring(0, startIndex) + cleanDesc.substring(endIndex + 1)).trim();
      }
    }

    // Parse [Custody:...]
    if (cleanDesc.contains('[Custody:')) {
      final startIndex = cleanDesc.indexOf('[Custody:');
      final endIndex = cleanDesc.indexOf(']', startIndex);
      if (endIndex != -1) {
        extractedCustody = cleanDesc.substring(startIndex + 9, endIndex).trim();
        cleanDesc = (cleanDesc.substring(0, startIndex) + cleanDesc.substring(endIndex + 1)).trim();
      }
    }

    String? extractedSecretQuestion;
    // Parse [SecretQuestion:...]
    if (cleanDesc.contains('[SecretQuestion:')) {
      final startIndex = cleanDesc.indexOf('[SecretQuestion:');
      final endIndex = cleanDesc.indexOf(']', startIndex);
      if (endIndex != -1) {
        extractedSecretQuestion = cleanDesc.substring(startIndex + 16, endIndex).trim();
        cleanDesc = (cleanDesc.substring(0, startIndex) + cleanDesc.substring(endIndex + 1)).trim();
      }
    }

    // Parse [imageUrls:...] (Multiple images serialized inside the description field)
    List<String> extractedImageUrls = [];
    if (cleanDesc.contains('[imageUrls:')) {
      final startIndex = cleanDesc.indexOf('[imageUrls:');
      final endIndex = cleanDesc.indexOf(']', startIndex);
      if (endIndex != -1) {
        final urlsStr = cleanDesc.substring(startIndex + 11, endIndex).trim();
        extractedImageUrls = urlsStr.split(',').map((u) => u.trim()).where((u) => u.isNotEmpty).toList();
        cleanDesc = (cleanDesc.substring(0, startIndex) + cleanDesc.substring(endIndex + 1)).trim();
      }
    }

    final imageUrlVal = map['imageUrl'] ?? map['image_url'] ?? map['imageurl'];
    final mainImageUrl = imageUrlVal?.toString() ?? '';
    final isVideoUrl = mainImageUrl.endsWith('.mp4') || mainImageUrl.contains('.mp4?');

    return SimplePostModel(
      id: map['id'] as String,
      userId: (map['userId'] ?? map['user_id'] ?? map['userid']) as String? ?? '',
      type: map['type'] as String? ?? 'lost',
      title: map['title'] as String? ?? '',
      description: cleanDesc,
      imageUrls: extractedImageUrls.isNotEmpty ? extractedImageUrls : parseList(imageUrlVal),
      location: SimplePostLocation(
        name: map['location_name'] as String? ?? '',
        building: map['location_building'] as String? ?? map['buildingName'] as String? ?? '',
        floor: (map['location_floor'] as num? ?? map['floor'] as num? ?? 0).toInt(),
        room: map['location_room'] as String?,
        latitude: (map['location_latitude'] as num? ?? map['location_lat'] as num? ?? 0.0).toDouble(),
        longitude: (map['location_longitude'] as num? ?? map['location_lng'] as num? ?? 0.0).toDouble(),
        indoorX: (map['location_indoor_x'] as num?)?.toDouble(),
        indoorY: (map['location_indoor_y'] as num?)?.toDouble(),
      ),
      timestamp: map['timestamp'] != null 
          ? (map['timestamp'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
              : DateTime.parse(map['timestamp'].toString()))
          : DateTime.now(),
      status: map['status'] as String? ?? 'open',
      aiTags: parseList(map['aiTags'] ?? map['ai_tags'] ?? map['aitags']),
      reportCount: (map['reportCount'] as num? ?? map['report_count'] as num? ?? map['reportcount'] as num? ?? 0).toInt(),
      viewCount: (map['viewCount'] as num? ?? map['view_id'] as num? ?? map['view_count'] as num? ?? map['viewcount'] as num? ?? 0).toInt(),
      likesCount: (map['likesCount'] as num? ?? map['likeCount'] as num? ?? map['like_count'] as num? ?? map['likecount'] as num? ?? 0).toInt(),
      posterName: (map['posterName'] ?? map['poster_name'] ?? map['postername']) as String? ?? '',
      posterAvatarUrl: (map['posterAvatarUrl'] ?? map['poster_avatar_url'] ?? map['posteravatarurl']) as String? ?? '',
      secretDetailQuestion: extractedSecretQuestion ?? (map['secretQuestion'] as String? ?? map['secret_detail_question'] as String? ?? map['secretQuestionText'] as String? ?? map['secretquestion'] as String?),
      custodyLocation: extractedCustody,
      videoUrl: () {
        final rawUrl = extractedVideoUrl ?? (isVideoUrl ? mainImageUrl : (map['videoUrl'] as String? ?? map['video_url'] as String? ?? map['videourl'] as String?));
        if (rawUrl == null) return null;
        final trimmed = rawUrl.trim();
        if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
          return trimmed;
        }
        return null;
      }(),
    );
  }

  SimplePostModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? description,
    List<String>? imageUrls,
    SimplePostLocation? location,
    DateTime? timestamp,
    String? status,
    List<String>? aiTags,
    int? reportCount,
    int? viewCount,
    int? likesCount,
    String? posterName,
    String? posterAvatarUrl,
    bool? isCMSVerified,
    String? videoUrl,
    String? custodyLocation,
  }) {
    return SimplePostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      aiTags: aiTags ?? this.aiTags,
      reportCount: reportCount ?? this.reportCount,
      viewCount: viewCount ?? this.viewCount,
      likesCount: likesCount ?? this.likesCount,
      posterName: posterName ?? this.posterName,
      posterAvatarUrl: posterAvatarUrl ?? this.posterAvatarUrl,
      isCMSVerified: isCMSVerified ?? this.isCMSVerified,
      videoUrl: videoUrl ?? this.videoUrl,
      custodyLocation: custodyLocation ?? this.custodyLocation,
    );
  }

  Map<String, dynamic> toMap() {
    var finalDesc = description;
    if (custodyLocation != null && custodyLocation!.isNotEmpty) {
      finalDesc = '$finalDesc\n[Custody:$custodyLocation]';
    }
    if (videoUrl != null && videoUrl!.isNotEmpty) {
      finalDesc = '$finalDesc\n[video:$videoUrl]';
    }
    if (secretDetailQuestion != null && secretDetailQuestion!.isNotEmpty) {
      finalDesc = '$finalDesc\n[SecretQuestion:$secretDetailQuestion]';
    }
    if (imageUrls.length > 1) {
      finalDesc = '$finalDesc\n[imageUrls:${imageUrls.join(',')}]';
    }
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'description': finalDesc,
      'imageUrl': imageUrls.isNotEmpty ? imageUrls[0] : null,
      'imageUrls': imageUrls, // Retain raw list locally for offline sync
      'location_name': location.name,
      'buildingName': location.building,
      'floor': location.floor,
      'location_room': location.room,
      'location_lat': location.latitude,
      'location_lng': location.longitude,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'aiTags': aiTags,
      'reportCount': reportCount,
      'viewCount': viewCount,
      'likeCount': likesCount,
      'isCMSVerified': isCMSVerified,
    };
  }

  bool get isLost => type == 'lost';
  bool get isFound => type == 'found';
  bool get isOpen => status == 'open';
}

class SimplePostLocation {
  final String name;
  final String building;
  final int floor;
  final String? room;
  final double latitude;
  final double longitude;
  final double? indoorX;
  final double? indoorY;

  SimplePostLocation({
    required this.name,
    required this.building,
    required this.floor,
    this.room,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.indoorX,
    this.indoorY,
  });
}