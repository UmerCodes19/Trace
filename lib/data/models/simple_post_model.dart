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
  });

  factory SimplePostModel.fromMap(Map<String, dynamic> map) {
    // Helper function to parse AI tags safely
    List<String> _parseAiTags(dynamic tags) {
      if (tags == null) return [];
      if (tags is List) return tags.cast<String>();
      if (tags is String) {
        if (tags.isEmpty) return [];
        try {
          final decoded = jsonDecode(tags);
          if (decoded is List) {
            return decoded.cast<String>();
          }
          if (decoded is String) {
            return [decoded];
          }
          return [];
        } catch (e) {
          // If JSON parsing fails, treat as plain string or comma-separated
          if (tags.contains(',')) {
            return tags.split(',').map((s) => s.trim()).toList();
          }
          return [tags];
        }
      }
      return [];
    }

    // Helper function to parse image URLs safely
    List<String> _parseImageUrls(dynamic urls) {
      if (urls == null) return [];
      if (urls is List) return urls.cast<String>();
      if (urls is String) {
        if (urls.isEmpty) return [];
        try {
          final decoded = jsonDecode(urls);
          if (decoded is List) {
            return decoded.cast<String>();
          }
          return [];
        } catch (e) {
          return [];
        }
      }
      return [];
    }

    return SimplePostModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      imageUrls: _parseImageUrls(map['imageUrls']),
      location: SimplePostLocation(
        name: map['location_name'] as String? ?? '',
        building: map['location_building'] as String? ?? '',
        floor: map['location_floor'] as int? ?? 0,
        room: map['location_room'] as String?,
        latitude: (map['location_latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (map['location_longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      status: map['status'] as String? ?? 'open',
      aiTags: _parseAiTags(map['aiTags']),
      reportCount: map['reportCount'] as int? ?? 0,
      viewCount: map['viewCount'] as int? ?? 0,
      likesCount: map['likesCount'] as int? ?? 0,
      posterName: map['posterName'] as String? ?? '',
      posterAvatarUrl: map['posterAvatarUrl'] as String? ?? '',
      isCMSVerified: (map['isCMSVerified'] as int? ?? 0) == 1,
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
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'description': description,
      'imageUrls': jsonEncode(imageUrls),
      'location_name': location.name,
      'location_building': location.building,
      'location_floor': location.floor,
      'location_room': location.room,
      'location_latitude': location.latitude,
      'location_longitude': location.longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
      'aiTags': jsonEncode(aiTags),
      'reportCount': reportCount,
      'viewCount': viewCount,
      'likesCount': likesCount,
      'posterName': posterName,
      'posterAvatarUrl': posterAvatarUrl,
      'isCMSVerified': isCMSVerified ? 1 : 0,
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

  SimplePostLocation({
    required this.name,
    required this.building,
    required this.floor,
    this.room,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });
}