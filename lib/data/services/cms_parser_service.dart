// lib/data/services/cms_parser_service.dart
import 'package:flutter/foundation.dart';
import '../models/cms_models.dart';

class CMSParserService {
  /// Parse student profile from Profile.aspx HTML
  static CMSStudent parseProfile(String html) {
    // Helper to extract table values
    String extractValue(String label) {
      // Multiple patterns to handle different HTML structures
      final patterns = [
        RegExp('<th[^>]*>$label</th>\\s*<td[^>]*>(.*?)</td>', caseSensitive: false),
        RegExp('<th[^>]*>.*?$label.*?</th>\\s*<td[^>]*>(.*?)</td>', caseSensitive: false),
        RegExp('$label\\s*[:]?\\s*</th>\\s*<td[^>]*>(.*?)</td>', caseSensitive: false),
      ];
      
      for (final pattern in patterns) {
        final match = pattern.firstMatch(html);
        if (match != null) {
          var value = match.group(1)?.trim() ?? '';
          value = value.replaceAll('&nbsp;', '')
                     .replaceAll(RegExp(r'<[^>]*>'), '')
                     .replaceAll(RegExp(r'\s+'), ' ')
                     .trim();
          if (value.isNotEmpty && !value.contains('nbsp')) {
            return value;
          }
        }
      }
      return '';
    }
    
    // Also try to extract from specific elements
    String extractFromElement(String id) {
      final pattern = RegExp('id="$id"[^>]*>(.*?)</span>', caseSensitive: false);
      final match = pattern.firstMatch(html);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
      return '';
    }
    
    // Try to get from profile info section
    final nameFromProfile = extractFromElement('ProfileInfo_lblName');
    final emailFromProfile = extractFromElement('ProfileInfo_lblEmail');
    
    return CMSStudent(
      enrollment: extractValue('Enrollment'),
      registrationNo: extractValue('Registration No'),
      name: nameFromProfile.isNotEmpty ? nameFromProfile : extractValue('Name'),
      fatherName: extractValue('Father Name'),
      program: extractValue('Program'),
      degreeDuration: extractValue('Degree Duration'),
      intakeSemester: extractValue('Intake Semester'),
      maxSemester: extractValue('Max Semester'),
      mobileNo: extractValue('Mobile No'),
      phoneNo: extractValue('Phone No'),
      personalEmail: extractValue('Personal Email'),
      universityEmail: emailFromProfile.isNotEmpty ? emailFromProfile : extractValue('University Email'),
      currentAddress: extractValue('Current Address'),
      permanentAddress: extractValue('Permanent Address'),
      campus: 'Karachi Campus',
      department: extractValue('Program').split('[')[0],
    );
  }
  
  /// Parse timetable from JSON data
  static List<CMSTimetableEntry> parseTimetable(Map<String, dynamic> jsonData) {
    final events = jsonData['eventsData'] as List? ?? [];
    return events
        .map((e) {
          try {
            return CMSTimetableEntry.fromJson(e as Map<String, dynamic>);
          } catch (err) {
            debugPrint('Skipping malformed timetable entry: $err');
            return null;
          }
        })
        .where((e) => e != null)
        .cast<CMSTimetableEntry>()
        .toList();
  }
  
  /// Extract JSON from timetable page HTML (hidden field strategy)
  static String? extractTimetableJson(String html) {
    // Strategy 1: Standard hidden field
    final match = RegExp(r'id="BodyPH_hfCalendarJson"\s+value="([^"]+)"').firstMatch(html);
    if (match != null) {
      final raw = match.group(1)!;
      if (raw.length > 10) {
        return raw
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'")
            .replaceAll(r'\/', '/');
      }
    }

    // Strategy 2: Look for inline JSON assignment (some CMS versions)
    final inlineMatch = RegExp(r'var\s+calendarData\s*=\s*(\{.*?\});', dotAll: true).firstMatch(html);
    if (inlineMatch != null) {
      return inlineMatch.group(1);
    }

    return null;
  }

  /// Fallback: Parse timetable from HTML table rows.
  /// Returns a list of maps ready for SQLite insertion.
  static List<Map<String, dynamic>> extractTimetableFromTable(String html) {
    final entries = <Map<String, dynamic>>[];

    // Day name → int mapping
    const dayMap = {
      'monday': 1, 'mon': 1,
      'tuesday': 2, 'tue': 2,
      'wednesday': 3, 'wed': 3,
      'thursday': 4, 'thu': 4,
      'friday': 5, 'fri': 5,
      'saturday': 6, 'sat': 6,
      'sunday': 7, 'sun': 7,
    };

    // Match table rows with 5+ cells
    final rowPattern = RegExp(r'<tr[^>]*>(.*?)</tr>', dotAll: true);
    final cellPattern = RegExp(r'<td[^>]*>(.*?)</td>', dotAll: true);

    for (final rowMatch in rowPattern.allMatches(html)) {
      final rowHtml = rowMatch.group(1) ?? '';
      final cells = cellPattern.allMatches(rowHtml).map((m) {
        return (m.group(1) ?? '')
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll('&nbsp;', ' ')
            .trim();
      }).toList();

      if (cells.length >= 5 && cells.any((c) => c.isNotEmpty)) {
        // Skip header rows
        final firstCellLower = cells[0].toLowerCase();
        if (firstCellLower == 'course code' ||
            firstCellLower == 'sr' ||
            firstCellLower == '#') {
          continue;
        }

        final dayStr = cells.length > 2 ? cells[2].toLowerCase() : '';
        entries.add({
          'courseCode': cells[0],
          'courseTitle': cells[1],
          'day': dayMap[dayStr] ?? _parseDayNumber(dayStr),
          'timeFrom': cells[3],
          'timeTo': cells[4],
          'roomName': cells.length > 5 ? cells[5] : '',
          'buildingName': cells.length > 6 ? cells[6] : '',
        });
      }
    }

    debugPrint('📅 Extracted ${entries.length} entries from HTML table');
    return entries;
  }

  /// Try to parse a day string as a number (e.g. "1", "2").
  static int _parseDayNumber(String s) {
    return int.tryParse(s) ?? 1;
  }
}