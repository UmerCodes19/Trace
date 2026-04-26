// lib/data/models/simple_user_model.dart
class SimpleUserModel {
  final String uid;
  final String name;
  final String email;
  final String? department;
  final String? contactNumber;
  final String? photoURL;
  final bool isCMSVerified;
  final int itemsLost;
  final int itemsFound;
  final int itemsReturned;
  final int karmaPoints;
  final bool isAdmin;
  final bool isBanned;
  final bool isDarkMode;
  final bool proximityAlertsEnabled;
  final bool chatNotificationsEnabled;
  final String? cmsStudentId;


  SimpleUserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.department,
    this.contactNumber,
    this.photoURL,
    this.isCMSVerified = false,
    this.itemsLost = 0,
    this.itemsFound = 0,
    this.itemsReturned = 0,
    this.karmaPoints = 0,
    this.isAdmin = false,
    this.isBanned = false,
    this.isDarkMode = false,
    this.proximityAlertsEnabled = true,
    this.chatNotificationsEnabled = true,
    this.cmsStudentId,
  });

  factory SimpleUserModel.fromMap(Map<String, dynamic> map) {
    return SimpleUserModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      department: map['department'] as String?,
      contactNumber: map['contactNumber'] as String?,
      photoURL: map['photoURL'] as String?,
      isCMSVerified: (map['isCMSVerified'] as int? ?? 0) == 1,
      itemsLost: map['itemsLost'] as int? ?? 0,
      itemsFound: map['itemsFound'] as int? ?? 0,
      itemsReturned: map['itemsReturned'] as int? ?? 0,
      karmaPoints: map['karmaPoints'] as int? ?? 0,
      isAdmin: (map['isAdmin'] as int? ?? 0) == 1,
      isBanned: (map['isBanned'] as int? ?? 0) == 1,
      isDarkMode: (map['isDarkMode'] as int? ?? 0) == 1,
      proximityAlertsEnabled: (map['proximityAlertsEnabled'] as int? ?? 1) == 1,
      chatNotificationsEnabled: (map['chatNotificationsEnabled'] as int? ?? 1) == 1,
      cmsStudentId: map['cmsStudentId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'department': department,
      'contactNumber': contactNumber,
      'photoURL': photoURL,
      'isCMSVerified': isCMSVerified ? 1 : 0,
      'itemsLost': itemsLost,
      'itemsFound': itemsFound,
      'itemsReturned': itemsReturned,
      'karmaPoints': karmaPoints,
      'isAdmin': isAdmin ? 1 : 0,
      'isBanned': isBanned ? 1 : 0,
      'isDarkMode': isDarkMode ? 1 : 0,
      'proximityAlertsEnabled': proximityAlertsEnabled ? 1 : 0,
      'chatNotificationsEnabled': chatNotificationsEnabled ? 1 : 0,
      'cmsStudentId': cmsStudentId,
    };
  }
}