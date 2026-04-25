// lib/data/services/cms_auth_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/cms_models.dart';
import 'cms_parser_service.dart';

class CMSAuthService {
  static const String baseUrl = 'https://cms.bahria.edu.pk';
  static const String loginUrl = '$baseUrl/Logins/Student/Login.aspx';
  static const String dashboardUrl = '$baseUrl/Sys/Student/Dashboard.aspx';
  static const String profileUrl = '$baseUrl/Sys/Student/Profile.aspx';
  static const String timetableUrl = '$baseUrl/Sys/Student/CourseRegistration/TimeTable.aspx';

  final Map<String, String> _cookies = {};

  HttpClient _createClient() {
    final client = HttpClient();
    client.autoUncompress = true;
    client.connectionTimeout = const Duration(seconds: 30);
    // Allow self-signed certificates for CMS
    client.badCertificateCallback = (cert, host, port) => host.contains('bahria.edu.pk');
    return client;
  }

  String _getCookieHeader() {
    return _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  void _setCookies(List<String>? cookieHeaders) {
    if (cookieHeaders == null) return;
    for (var raw in cookieHeaders) {
      final cookie = raw.split(';')[0].trim();
      final eqIndex = cookie.indexOf('=');
      if (eqIndex != -1) {
        final key = cookie.substring(0, eqIndex);
        final value = cookie.substring(eqIndex + 1);
        _cookies[key] = value;
        debugPrint('Cookie set: $key');
      }
    }
  }

  Future<String> _get(String url, {int maxRetries = 2}) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final client = _createClient();
        final request = await client.getUrl(Uri.parse(url));
        
        request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
        request.headers.set('Accept', 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8');
        request.headers.set('Accept-Language', 'en-US,en;q=0.9');
        
        final cookieHeader = _getCookieHeader();
        if (cookieHeader.isNotEmpty) {
          request.headers.set('Cookie', cookieHeader);
        }
        
        final response = await request.close();
        _setCookies(response.headers['set-cookie']);

        // Follow redirects manually to capture cookies
        if (response.statusCode == 302 || response.statusCode == 301) {
          final location = response.headers['location']?.first;
          await response.drain<void>();
          client.close();
          if (location != null) {
            final redirectUrl = location.startsWith('http') ? location : '$baseUrl$location';
            debugPrint('↪️ Following redirect to: $redirectUrl');
            return _get(redirectUrl, maxRetries: maxRetries - 1);
          }
        }
        
        final body = await response.transform(utf8.decoder).join();
        client.close();
        return body;
      } catch (e) {
        debugPrint('⚠️ Request attempt ${attempt + 1} failed for $url: $e');
        if (attempt == maxRetries) rethrow;
        // Exponential backoff
        await Future.delayed(Duration(seconds: (attempt + 1) * 2));
      }
    }
    throw Exception('Failed to fetch $url after $maxRetries retries');
  }

  Future<Map<String, String>> _getLoginPageFields() async {
    debugPrint('📥 Fetching login page...');
    final client = _createClient();
    final request = await client.getUrl(Uri.parse(loginUrl));
    
    request.headers.set('User-Agent', 'Mozilla/5.0');
    request.headers.set('Accept', 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8');
    
    final response = await request.close();
    _setCookies(response.headers['set-cookie']);
    
    final html = await response.transform(utf8.decoder).join();
    client.close();
    
    String extract(String name) {
      final pattern = RegExp('id="$name"\\s+value="([^"]*)"');
      return pattern.firstMatch(html)?.group(1) ?? '';
    }
    
    return {
      '__VIEWSTATE': extract('__VIEWSTATE'),
      '__EVENTVALIDATION': extract('__EVENTVALIDATION'),
      '__VIEWSTATEGENERATOR': extract('__VIEWSTATEGENERATOR'),
    };
  }

  Future<CMSAuthSession?> login({
    required String enrollment,
    required String password,
    required String instituteId,
    required String role,
  }) async {
    try {
      debugPrint('\n🔐 CMS LOGIN START');
      debugPrint('   Enrollment: $enrollment');
      debugPrint('   Institute: $instituteId');
      
      // Step 1: Get login page fields
      final fields = await _getLoginPageFields();
      
      if (fields['__VIEWSTATE'] == null || fields['__VIEWSTATE']!.isEmpty) {
        debugPrint('❌ Failed to get VIEWSTATE');
        return null;
      }
      
      // Step 2: Post login
      debugPrint('📤 Posting login...');
      final client = _createClient();
      final request = await client.postUrl(Uri.parse(loginUrl));
      
      request.headers.set('User-Agent', 'Mozilla/5.0');
      request.headers.set('Accept', 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8');
      request.headers.set('Content-Type', 'application/x-www-form-urlencoded');
      request.headers.set('Origin', baseUrl);
      request.headers.set('Referer', loginUrl);
      request.headers.set('Cookie', _getCookieHeader());
      
      final postData = {
        '__VIEWSTATE': fields['__VIEWSTATE']!,
        '__EVENTVALIDATION': fields['__EVENTVALIDATION']!,
        '__VIEWSTATEGENERATOR': fields['__VIEWSTATEGENERATOR'] ?? '',
        '__EVENTTARGET': '',
        '__EVENTARGUMENT': '',
        '__LASTFOCUS': '',
        'ctl00\$BodyPH\$tbEnrollment': enrollment.toUpperCase(),
        'ctl00\$BodyPH\$tbPassword': password,
        'ctl00\$BodyPH\$ddlInstituteID': instituteId,
        'ctl00\$BodyPH\$ddlSubUserType': role,
        'ctl00\$BodyPH\$btnLogin': 'Sign In',
      };
      
      final body = postData.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      request.add(utf8.encode(body));
      
      final response = await request.close();
      _setCookies(response.headers['set-cookie']);
      final location = response.headers['location']?.first;
      client.close();
      
      debugPrint('📥 Login response: ${response.statusCode}');
      debugPrint('   Location: $location');
      
      if (response.statusCode != 302 || location == null) {
        debugPrint('❌ No redirect - login failed');
        return null;
      }
      
      // Step 3: Follow redirect to PrepareSession
      debugPrint('🔄 Following redirect to PrepareSession...');
      final prepareUrl = location.startsWith('http') ? location : '$baseUrl$location';
      await _get(prepareUrl);
      
      // Step 4: Try to access Dashboard
      debugPrint('🏠 Accessing Dashboard...');
      final dashboardHtml = await _get(dashboardUrl);
      
      // Verify login success
      if (dashboardHtml.contains('Login')) {
        debugPrint('❌ Still on login page - authentication failed');
        return null;
      }
      
      debugPrint('✅ Login successful!');
      
      // Step 5: Fetch profile
      debugPrint('👤 Fetching profile...');
      final profileHtml = await _get(profileUrl);
      final student = CMSParserService.parseProfile(profileHtml);
      debugPrint('   Name: ${student.name}');
      debugPrint('   Program: ${student.program}');
      
      // Step 6: Fetch timetable
      debugPrint('📅 Fetching timetable...');
      List<CMSTimetableEntry> timetable = [];
      
      try {
        final timetableHtml = await _get(timetableUrl);
        
        // Strategy 1: Try hidden JSON field
        final jsonStr = CMSParserService.extractTimetableJson(timetableHtml);
        if (jsonStr != null) {
          try {
            final data = jsonDecode(jsonStr);
            timetable = CMSParserService.parseTimetable(data);
            debugPrint('   Found ${timetable.length} courses from JSON');
          } catch (e) {
            debugPrint('   JSON timetable parse error: $e');
          }
        }
        
        // Strategy 2: Try HTML table parsing if JSON failed
        if (timetable.isEmpty) {
          debugPrint('   Trying HTML table fallback...');
          final tableEntries = CMSParserService.extractTimetableFromTable(timetableHtml);
          if (tableEntries.isNotEmpty) {
            timetable = tableEntries
                .map((e) => CMSTimetableEntry.fromMap(e))
                .toList();
            debugPrint('   Found ${timetable.length} courses from HTML table');
          }
        }
        
        if (timetable.isEmpty) {
          debugPrint('   ⚠️ No timetable data found from any strategy');
        }
      } catch (e) {
        debugPrint('   ❌ Timetable fetch error: $e');
      }
      
      return CMSAuthSession(
        enrollment: enrollment,
        name: student.name,
        universityEmail: student.universityEmail,
        aspNetAuthCookie: _getCookieHeader(),
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
        program: student.program,
        department: student.department,
        timetable: timetable,
      );
      
    } catch (e) {
      debugPrint('❌ CMS Login error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _get('$baseUrl/Sys/Student/Logoff.aspx');
    } catch (_) {}
    _cookies.clear();
    debugPrint('🔓 Logged out');
  }
}