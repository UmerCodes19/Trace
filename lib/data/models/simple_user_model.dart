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
  final String? fatherName;
  final String? registrationNo;
  final String? currentAddress;
  final String? permanentAddress;
  final String? intakeSemester;


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
    this.fatherName,
    this.registrationNo,
    this.currentAddress,
    this.permanentAddress,
    this.intakeSemester,
  });

  factory SimpleUserModel.fromMap(Map<String, dynamic> map) {
    return SimpleUserModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      department: map['department'] as String?,
      contactNumber: map['contactNumber'] as String?,
      photoURL: map['photoURL'] as String?,
      isCMSVerified: map['isCMSVerified'] as bool? ?? false,
      itemsLost: map['itemsLost'] as int? ?? 0,
      itemsFound: map['itemsFound'] as int? ?? 0,
      itemsReturned: map['itemsReturned'] as int? ?? 0,
      karmaPoints: map['karmaPoints'] as int? ?? 0,
      isAdmin: map['isAdmin'] as bool? ?? false,
      isBanned: map['isBanned'] as bool? ?? false,
      isDarkMode: map['isDarkMode'] as bool? ?? false,
      proximityAlertsEnabled: map['proximityAlertsEnabled'] as bool? ?? true,
      chatNotificationsEnabled: map['chatNotificationsEnabled'] as bool? ?? true,
      cmsStudentId: map['cmsStudentId'] as String?,
      fatherName: map['fatherName'] as String?,
      registrationNo: map['registrationNo'] as String?,
      currentAddress: map['currentAddress'] as String?,
      permanentAddress: map['permanentAddress'] as String?,
      intakeSemester: map['intakeSemester'] as String?,
    );
  }

  SimpleUserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? department,
    String? contactNumber,
    String? photoURL,
    bool? isCMSVerified,
    int? itemsLost,
    int? itemsFound,
    int? itemsReturned,
    int? karmaPoints,
    bool? isAdmin,
    bool? isBanned,
    bool? isDarkMode,
    bool? proximityAlertsEnabled,
    bool? chatNotificationsEnabled,
    String? cmsStudentId,
    String? fatherName,
    String? registrationNo,
    String? currentAddress,
    String? permanentAddress,
    String? intakeSemester,
  }) {
    return SimpleUserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      contactNumber: contactNumber ?? this.contactNumber,
      photoURL: photoURL ?? this.photoURL,
      isCMSVerified: isCMSVerified ?? this.isCMSVerified,
      itemsLost: itemsLost ?? this.itemsLost,
      itemsFound: itemsFound ?? this.itemsFound,
      itemsReturned: itemsReturned ?? this.itemsReturned,
      karmaPoints: karmaPoints ?? this.karmaPoints,
      isAdmin: isAdmin ?? this.isAdmin,
      isBanned: isBanned ?? this.isBanned,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      proximityAlertsEnabled: proximityAlertsEnabled ?? this.proximityAlertsEnabled,
      chatNotificationsEnabled: chatNotificationsEnabled ?? this.chatNotificationsEnabled,
      cmsStudentId: cmsStudentId ?? this.cmsStudentId,
      fatherName: fatherName ?? this.fatherName,
      registrationNo: registrationNo ?? this.registrationNo,
      currentAddress: currentAddress ?? this.currentAddress,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      intakeSemester: intakeSemester ?? this.intakeSemester,
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
      'isCMSVerified': isCMSVerified,
      'itemsLost': itemsLost,
      'itemsFound': itemsFound,
      'itemsReturned': itemsReturned,
      'karmaPoints': karmaPoints,
      'isAdmin': isAdmin,
      'isBanned': isBanned,
      'isDarkMode': isDarkMode,
      'proximityAlertsEnabled': proximityAlertsEnabled,
      'chatNotificationsEnabled': chatNotificationsEnabled,
      'cmsStudentId': cmsStudentId,
      'fatherName': fatherName,
      'registrationNo': registrationNo,
      'currentAddress': currentAddress,
      'permanentAddress': permanentAddress,
      'intakeSemester': intakeSemester,
    };
  }
}