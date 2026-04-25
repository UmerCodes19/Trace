// lib/data/services/location_prediction_service.dart
import '../models/cms_models.dart';

class LocationPredictionService {
  final List<CMSTimetableEntry> _timetable;

  LocationPredictionService(this._timetable);

  /// Predict where student lost item based on time
  PredictionResult predictLostLocation({
    required DateTime lostTime,
    required String enrollment,
  }) {
    final dayOfWeek = _getDayNumber(lostTime.weekday);
    final timeOfDay = lostTime.hour + lostTime.minute / 60.0;

    // Find class at that time
    CMSTimetableEntry? currentClass;
    for (final entry in _timetable) {
      if (entry.weekDay == dayOfWeek && _isTimeInRange(timeOfDay, entry)) {
        currentClass = entry;
        break;
      }
    }

    if (currentClass != null) {
      return PredictionResult(
        building: currentClass.buildingName,
        room: currentClass.roomName,
        course: currentClass.courseTitle,
        confidence: 0.92,
        suggestion: "You had ${currentClass.shortTitle} in ${currentClass.roomName} at that time. Check there first.",
      );
    }

    // Check for break times (between classes)
    CMSTimetableEntry? nextClass;
    for (final entry in _timetable) {
      if (entry.weekDay == dayOfWeek && _parseTimeToHour(entry.timeFrom) > timeOfDay) {
        nextClass = entry;
        break;
      }
    }

    if (nextClass != null) {
      return PredictionResult(
        building: nextClass.buildingName,
        room: nextClass.roomName,
        course: null,
        confidence: 0.65,
        suggestion: "You had your next class in ${nextClass.roomName}. The item might be there.",
      );
    }

    // Fallback - common areas
    return PredictionResult(
      building: "Liaquat Block",
      room: null,
      course: null,
      confidence: 0.40,
      suggestion: "Check common areas like Cafeteria, Library, or your department's student lounge.",
    );
  }

  /// Check if a given time falls within a class period
  bool _isTimeInRange(double timeOfDay, CMSTimetableEntry entry) {
    final start = _parseTimeToHour(entry.timeFrom);
    final end = _parseTimeToHour(entry.timeTo);
    return timeOfDay >= start && timeOfDay <= end;
  }

  /// Convert "09:30 AM" to decimal hour (9.5)
  double _parseTimeToHour(String timeStr) {
    if (timeStr.isEmpty) return 0.0;
    
    final parts = timeStr.split(' ');
    if (parts.length < 2) return 0.0;
    
    final timeParts = parts[0].split(':');
    if (timeParts.length < 2) return 0.0;
    
    var hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts[1]) ?? 0;
    final isPM = parts[1].toUpperCase() == 'PM';

    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;

    return hour + minute / 60.0;
  }

  int _getDayNumber(int weekday) {
    // Flutter: 1=Monday, 7=Sunday
    // CMS: 1=Monday, 7=Sunday - same mapping
    return weekday;
  }
}

class PredictionResult {
  final String building;
  final String? room;
  final String? course;
  final double confidence;
  final String suggestion;

  PredictionResult({
    required this.building,
    this.room,
    this.course,
    required this.confidence,
    required this.suggestion,
  });
}