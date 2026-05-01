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
  });

  factory SimplePostModel.fromMap(Map<String, dynamic> map) {
    List<String> _parseList(dynamic data) {
      if (data == null) return [];
      if (data is List) return data.cast<String>();
      if (data is String) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is List) return decoded.cast<String>();
        } catch (_) {}
        return [data];
      }
      return [];
    }

    return SimplePostModel(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? 'lost',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrls: _parseList(map['imageUrl']), // Supabase column is imageUrl
      location: SimplePostLocation(
        name: map['location_name'] as String? ?? '',
        building: map['location_building'] as String? ?? map['buildingName'] as String? ?? '',
        floor: map['location_floor'] as int? ?? map['floor'] as int? ?? 0,
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
      aiTags: _parseList(map['aiTags']),
      reportCount: map['reportCount'] as int? ?? 0,
      viewCount: map['viewCount'] as int? ?? 0,
      likesCount: map['likesCount'] as int? ?? map['likeCount'] as int? ?? 0,
      posterName: map['posterName'] as String? ?? '',
      posterAvatarUrl: map['posterAvatarUrl'] as String? ?? '',
      isCMSVerified: map['isCMSVerified'] as bool? ?? false,
      secretDetailQuestion: map['secret_detail_question'] as String?,
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
      'imageUrl': imageUrls.isNotEmpty ? imageUrls[0] : null, // Store main image in single column
      'location_name': location.name,
      'buildingName': location.building,
      'floor': location.floor,
      'location_room': location.room,
      'location_lat': location.latitude,
      'location_lng': location.longitude,
      'location_indoor_x': location.indoorX,
      'location_indoor_y': location.indoorY,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'aiTags': aiTags, // Supabase handles list/array directly
      'reportCount': reportCount,
      'viewCount': viewCount,
      'likeCount': likesCount,
      'isCMSVerified': isCMSVerified,
      'secret_detail_question': secretDetailQuestion,
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