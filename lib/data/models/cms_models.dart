// lib/data/models/cms_models.dart
class CMSStudent {
  final String enrollment;
  final String registrationNo;
  final String name;
  final String fatherName;
  final String program;
  final String degreeDuration;
  final String intakeSemester;
  final String maxSemester;
  final String mobileNo;
  final String phoneNo;
  final String personalEmail;
  final String universityEmail;
  final String currentAddress;
  final String permanentAddress;
  final String campus;
  final String department;

  const CMSStudent({
    required this.enrollment,
    required this.registrationNo,
    required this.name,
    required this.fatherName,
    required this.program,
    required this.degreeDuration,
    required this.intakeSemester,
    required this.maxSemester,
    required this.mobileNo,
    required this.phoneNo,
    required this.personalEmail,
    required this.universityEmail,
    required this.currentAddress,
    required this.permanentAddress,
    required this.campus,
    required this.department,
  });
}

class CMSTimetableEntry {
  final String courseCode;
  final String courseTitle;
  final String shortTitle;
  final String className;
  final String facultyName;
  final String shortFacultyName;
  final String roomName;
  final String buildingName;
  final String buildingAlias;
  final int weekDay;
  final String timeFrom;
  final String timeTo;

  const CMSTimetableEntry({
    required this.courseCode,
    required this.courseTitle,
    required this.shortTitle,
    required this.className,
    required this.facultyName,
    required this.shortFacultyName,
    required this.roomName,
    required this.buildingName,
    required this.buildingAlias,
    required this.weekDay,
    required this.timeFrom,
    required this.timeTo,
  });

  factory CMSTimetableEntry.fromJson(Map<String, dynamic> json) {
    final eventData = json['data'] as Map<String, dynamic>? ?? {};

    // Parse timing safely — format may be "09:00 AM - 10:30 AM" or split fields
    String timeFrom = '';
    String timeTo = '';
    final timing = json['timing']?.toString() ?? '';
    if (timing.contains(' - ')) {
      final parts = timing.split(' - ');
      timeFrom = parts[0].trim();
      timeTo = parts.length > 1 ? parts[1].trim() : '';
    } else {
      timeFrom = json['timeFrom']?.toString() ?? eventData['timeFrom']?.toString() ?? '';
      timeTo = json['timeTo']?.toString() ?? eventData['timeTo']?.toString() ?? '';
    }

    return CMSTimetableEntry(
      courseCode: eventData['offeredCourseID']?.toString() ??
          json['courseCode']?.toString() ?? '',
      courseTitle: eventData['courseTitle']?.toString() ??
          json['courseTitle']?.toString() ?? '',
      shortTitle: eventData['shortCourseTitle']?.toString() ??
          json['shortTitle']?.toString() ?? '',
      className: eventData['className']?.toString() ??
          json['className']?.toString() ?? '',
      facultyName: eventData['facultyMemberName']?.toString() ??
          json['facultyName']?.toString() ?? '',
      shortFacultyName: eventData['shortFacultyMemberName']?.toString() ??
          json['shortFacultyName']?.toString() ?? '',
      roomName: eventData['roomName']?.toString() ??
          json['roomName']?.toString() ?? '',
      buildingName: eventData['buildingName']?.toString() ??
          json['buildingName']?.toString() ?? '',
      buildingAlias: eventData['buildingAlias']?.toString() ??
          json['buildingAlias']?.toString() ?? '',
      weekDay: json['weekDay'] as int? ?? json['day'] as int? ?? 1,
      timeFrom: timeFrom,
      timeTo: timeTo,
    );
  }

  /// Serialize to a Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'courseCode': courseCode,
      'courseTitle': courseTitle,
      'day': weekDay,
      'timeFrom': timeFrom,
      'timeTo': timeTo,
      'roomName': roomName,
      'buildingName': buildingName,
    };
  }

  /// Create from a SQLite row
  factory CMSTimetableEntry.fromMap(Map<String, dynamic> map) {
    return CMSTimetableEntry(
      courseCode: map['courseCode'] as String? ?? '',
      courseTitle: map['courseTitle'] as String? ?? '',
      shortTitle:
          map['courseTitle']?.toString().split(' ').take(3).join(' ') ?? '',
      className: '',
      facultyName: '',
      shortFacultyName: '',
      roomName: map['roomName'] as String? ?? '',
      buildingName: map['buildingName'] as String? ?? '',
      buildingAlias: map['buildingName'] as String? ?? '',
      weekDay: map['day'] as int? ?? 1,
      timeFrom: map['timeFrom'] as String? ?? '',
      timeTo: map['timeTo'] as String? ?? '',
    );
  }
}

class CMSAuthSession {
  final String enrollment;
  final String name;
  final String universityEmail;
  final String aspNetAuthCookie;
  final DateTime expiresAt;
  final String? program;
  final String? department;
  final List<CMSTimetableEntry>? timetable;

  CMSAuthSession({
    required this.enrollment,
    required this.name,
    required this.universityEmail,
    required this.aspNetAuthCookie,
    required this.expiresAt,
    this.program,
    this.department,
    this.timetable,
  });

  bool get isValid => DateTime.now().isBefore(expiresAt);
}