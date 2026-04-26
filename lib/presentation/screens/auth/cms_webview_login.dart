// lib/presentation/screens/auth/cms_webview_login.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/cms_models.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/cms_auth_service.dart';
import '../../../data/services/api_service.dart';

class CMSWebViewLogin extends ConsumerStatefulWidget {
  const CMSWebViewLogin({super.key});

  @override
  ConsumerState<CMSWebViewLogin> createState() => _CMSWebViewLoginState();
}

class _CMSWebViewLoginState extends ConsumerState<CMSWebViewLogin> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _loginSuccess = false;
  String? _error;

  final TextEditingController _enrollmentController = TextEditingController();

  // Password controller for user input
  final TextEditingController _passwordController = TextEditingController();
  bool _showPasswordDialog = false;

  @override
  void dispose() {
    _enrollmentController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showPasswordDialogAndLogin() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('CMS Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter your CMS portal password to verify your identity.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _enrollmentController,
              decoration: const InputDecoration(
                labelText: 'Enrollment',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              onSubmitted: (_) {
                final password = _passwordController.text.trim();
                final enrollment = _enrollmentController.text.trim();
                if (password.isNotEmpty && enrollment.isNotEmpty) {
                  Navigator.pop(context);
                  _autoFillAndLogin(enrollment, password);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final password = _passwordController.text.trim();
              final enrollment = _enrollmentController.text.trim();
              Navigator.pop(context);
              if (password.isNotEmpty && enrollment.isNotEmpty) {
                _autoFillAndLogin(enrollment, password);
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _autoFillAndLogin(String enrollment, String password) async {
    if (_webViewController == null) return;

    debugPrint('🔐 Auto-filling login form...');

    // Escape password for JavaScript
    final escapedPassword = password
        .replaceAll("'", "\\'")
        .replaceAll('"', '\\"');

    // JavaScript to fill and submit
    final jsCode =
        '''
      (function() {
        // Fill enrollment
        var enrollmentField = document.getElementById('BodyPH_tbEnrollment');
        if (enrollmentField) {
          enrollmentField.value = '$enrollment';
          enrollmentField.dispatchEvent(new Event('input', { bubbles: true }));
          enrollmentField.dispatchEvent(new Event('change', { bubbles: true }));
        }
        
        // Fill password
        var passwordField = document.getElementById('BodyPH_tbPassword');
        if (passwordField) {
          passwordField.value = '$escapedPassword';
          passwordField.dispatchEvent(new Event('input', { bubbles: true }));
          passwordField.dispatchEvent(new Event('change', { bubbles: true }));
        }
        
        // Select institute (Karachi Campus = 2)
        var instituteSelect = document.getElementById('BodyPH_ddlInstituteID');
        if (instituteSelect) {
          instituteSelect.value = '2';
          instituteSelect.dispatchEvent(new Event('change', { bubbles: true }));
        }
        
        // Select role (Student = None)
        var roleSelect = document.getElementById('BodyPH_ddlSubUserType');
        if (roleSelect) {
          roleSelect.value = 'None';
          roleSelect.dispatchEvent(new Event('change', { bubbles: true }));
        }
        
        // Auto-submit after 500ms
        setTimeout(function() {
          var loginButton = document.getElementById('BodyPH_btnLogin');
          if (loginButton) {
            loginButton.click();
          }
        }, 500);
        
        return 'Auto-fill completed';
      })();
    ''';

    try {
      final result = await _webViewController!.evaluateJavascript(
        source: jsCode,
      );
      debugPrint('Auto-fill result: $result');
    } catch (e) {
      debugPrint('Auto-fill error: $e');
    }
  }

  Future<void> _extractAndSaveData() async {
    if (_webViewController == null) return;

    try {
      // Wait for page to fully load
      await Future.delayed(const Duration(seconds: 2));

      // Extract profile data
      final profileData = await _webViewController!.evaluateJavascript(
        source: '''
        (function() {
          const data = {};
          
          // Get from profile info
          const nameEl = document.querySelector('#ProfileInfo_lblName');
          const emailEl = document.querySelector('#ProfileInfo_lblEmail');
          const usernameEl = document.querySelector('#ProfileInfo_lblUsername');
          
          if (nameEl) data.name = nameEl.innerText.trim();
          if (emailEl) data.universityEmail = emailEl.innerText.trim();
          if (usernameEl) data.enrollment = usernameEl.innerText.trim();
          
          // Get from info table
          const rows = document.querySelectorAll('.info tbody tr');
          rows.forEach(row => {
            const ths = row.querySelectorAll('th');
            const tds = row.querySelectorAll('td');
            
            for (let i = 0; i < ths.length; i++) {
              const label = ths[i]?.innerText?.trim().toLowerCase();
              const value = tds[i]?.innerText?.trim();
              
              if (value && value !== '—') {
                if (label === 'program') data.program = value;
                if (label === 'name') data.name = value;
                if (label === 'father name') data.fatherName = value;
                if (label === 'mobile no.') data.mobile = value;
              }
            }
          });
          
          return JSON.stringify(data);
        })();
      ''',
      );

      debugPrint('📋 Profile data: $profileData');

      // Get cookies using JavaScript
      final cookiesJs = await _webViewController!.evaluateJavascript(
        source: 'document.cookie',
      );
      String cookieString = '';
      if (cookiesJs != null && cookiesJs is String) {
        cookieString = cookiesJs;
      }

      // Get additional cookies via CookieManager
      final cookieManager = CookieManager.instance();
      final allCookies = await cookieManager.getCookies(
        url: WebUri('https://cms.bahria.edu.pk/'),
      );

      for (var cookie in allCookies) {
        cookieString += '${cookie.name}=${cookie.value}; ';
      }

      // Parse profile data
      Map<String, dynamic> data = {};
      if (profileData != null &&
          profileData is String &&
          profileData.isNotEmpty) {
        try {
          data = jsonDecode(profileData);
        } catch (e) {
          debugPrint('Parse error: $e');
        }
      }

      final enrollment =
          data['enrollment'] ?? _enrollmentController.text.trim();
      final name = data['name'] ?? 'CMS User';
      final email =
          data['universityEmail'] ?? '$enrollment@student.bahria.edu.pk';
      final program = data['program'] ?? '';
      final department = program.isNotEmpty ? program.split('[')[0] : '';

      // Save to cloud
      final api = ref.read(apiServiceProvider);
      
      // Sync user to cloud
      await api.syncUser({
        'uid': enrollment,
        'name': name,
        'email': email,
        'department': department,
        'photoURL': 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=1B3C53&color=fff',
        'isCMSVerified': 1,
        'cmsStudentId': enrollment,
        'lastActive': DateTime.now().millisecondsSinceEpoch,
        'itemsLost': 0,
        'itemsFound': 0,
        'itemsReturned': 0,
        'karmaPoints': 0,
      });

      // Fetch and store timetable through CMS service so prediction can work.
      final password = _passwordController.text.trim();
      if (password.isNotEmpty) {
        try {
          final cmsService = CMSAuthService();
          final session = await cmsService.login(
            enrollment: enrollment.toString(),
            password: password,
            instituteId: '2',
            role: 'None',
          );
          if (session?.timetable != null && session!.timetable!.isNotEmpty) {
            await api.saveTimetable(
              enrollment.toString(),
              session.timetable!.map((e) => e.toMap()).toList(),
            );
            debugPrint('✅ Saved ${session.timetable!.length} timetable entries to cloud');
          } else {
            debugPrint('Timetable sync returned empty data');
            // Fallback: try scraping timetable via WebView JS
            await _scrapeTimetableViaWebView(api, enrollment.toString());
          }
        } catch (e) {
          debugPrint('Timetable sync failed: $e');
        }
      }

      if (mounted) {
        // Show the professional syncing overlay
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const _SyncingOverlay(),
        );

        await ref.read(authServiceProvider).setCurrentUserFromUid(enrollment);
        
        // Wait a bit to show the nice animation
        await Future.delayed(const Duration(seconds: 3));

        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      debugPrint('Extract error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Fallback: scrape timetable via WebView JS injection on the already
  /// authenticated session. Navigates to the timetable URL, waits for load,
  /// then extracts either the hidden JSON field or the HTML table rows.
  Future<void> _scrapeTimetableViaWebView(
    ApiService api,
    String enrollment,
  ) async {
    if (_webViewController == null) return;

    try {
      debugPrint('📅 Fallback: scraping timetable via WebView...');
      await _webViewController!.loadUrl(
        urlRequest: URLRequest(
          url: WebUri(
            'https://cms.bahria.edu.pk/Sys/Student/CourseRegistration/TimeTable.aspx',
          ),
        ),
      );

      // Wait for page to load
      await Future.delayed(const Duration(seconds: 3));

      // Try extracting the hidden JSON field first, then fall back to table scraping
      final result = await _webViewController!.evaluateJavascript(
        source: '''
        (function() {
          // Strategy 1: Hidden JSON field
          var jsonField = document.getElementById('BodyPH_hfCalendarJson');
          if (jsonField && jsonField.value && jsonField.value.length > 10) {
            return JSON.stringify({ source: 'json', data: jsonField.value });
          }

          // Strategy 2: Parse the timetable table rows
          var rows = document.querySelectorAll('table.table tbody tr, .grid-view tr');
          var entries = [];
          for (var i = 0; i < rows.length; i++) {
            var cells = rows[i].querySelectorAll('td');
            if (cells.length >= 5) {
              entries.push({
                courseCode: cells[0]?.innerText?.trim() || '',
                courseTitle: cells[1]?.innerText?.trim() || '',
                day: cells[2]?.innerText?.trim() || '',
                timeFrom: cells[3]?.innerText?.trim() || '',
                timeTo: cells[4]?.innerText?.trim() || '',
                roomName: cells.length > 5 ? cells[5]?.innerText?.trim() : '',
                buildingName: cells.length > 6 ? cells[6]?.innerText?.trim() : '',
              });
            }
          }
          if (entries.length > 0) {
            return JSON.stringify({ source: 'table', data: entries });
          }

          // Strategy 3: Look for FullCalendar event source
          if (typeof calendarEvents !== 'undefined') {
            return JSON.stringify({ source: 'calendar', data: calendarEvents });
          }

          return JSON.stringify({ source: 'none', data: [] });
        })();
      ''',
      );

      if (result == null || result == 'null') {
        debugPrint('❌ WebView timetable scrape returned null');
        return;
      }

      final parsed = jsonDecode(result is String ? result : result.toString());
      final source = parsed['source'] as String? ?? 'none';
      debugPrint('📅 Timetable source: $source');

      if (source == 'json') {
        // Parse the hidden JSON field
        final jsonStr = (parsed['data'] as String)
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'")
            .replaceAll(r'\/', '/');
        try {
          final jsonData = jsonDecode(jsonStr);
          final events = jsonData['eventsData'] as List? ?? [];
          final timetableEntries = events
              .map((e) => CMSTimetableEntry.fromJson(e as Map<String, dynamic>))
              .toList();
          if (timetableEntries.isNotEmpty) {
            await api.saveTimetable(
              enrollment,
              timetableEntries.map((e) => e.toMap()).toList(),
            );
            debugPrint('✅ Saved ${timetableEntries.length} entries from JSON field to cloud');
          }
        } catch (e) {
          debugPrint('JSON timetable parse error: $e');
        }
      } else if (source == 'table') {
        // Parse scraped table rows
        final data = parsed['data'] as List? ?? [];
        final dayMap = {
          'monday': 1, 'tuesday': 2, 'wednesday': 3,
          'thursday': 4, 'friday': 5, 'saturday': 6, 'sunday': 7,
        };
        final entries = data.map<Map<String, dynamic>>((row) {
          final dayStr = (row['day'] as String? ?? '').toLowerCase();
          return {
            'courseCode': row['courseCode'] ?? '',
            'courseTitle': row['courseTitle'] ?? '',
            'day': dayMap[dayStr] ?? 1,
            'timeFrom': row['timeFrom'] ?? '',
            'timeTo': row['timeTo'] ?? '',
            'roomName': row['roomName'] ?? '',
            'buildingName': row['buildingName'] ?? '',
          };
        }).toList();

        if (entries.isNotEmpty) {
          await api.saveTimetable(enrollment, entries);
          debugPrint('✅ Saved ${entries.length} entries from HTML table to cloud');
        }
      }
    } catch (e) {
      debugPrint('❌ WebView timetable scrape error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CMS Login'),
        backgroundColor: AppColors.navyDarkest,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _isLoading = true;
                        _loginSuccess = false;
                      });
                      _webViewController?.reload();
                    },
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            )
          : InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(
                  'https://cms.bahria.edu.pk/Logins/Student/Login.aspx',
                ),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                supportZoom: true,
                allowFileAccess: true,
                allowContentAccess: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStart: (controller, url) {
                setState(() => _isLoading = true);
                debugPrint('Loading: $url');
              },
              onLoadStop: (controller, url) async {
                setState(() => _isLoading = false);
                debugPrint('Stopped: $url');

                // Check if we're on dashboard (login success)
                if (url?.toString().contains('/Sys/Student/') == true &&
                    !url!.toString().contains('Login.aspx') &&
                    !_loginSuccess) {
                  debugPrint('✅ Login successful! Extracting data...');
                  _loginSuccess = true;
                  await _extractAndSaveData();
                }

                // Show password dialog on login page
                if (url?.toString().contains('Login.aspx') == true &&
                    !_loginSuccess &&
                    !_showPasswordDialog) {
                  _showPasswordDialog = true;
                  await Future.delayed(const Duration(milliseconds: 500));
                  _showPasswordDialogAndLogin();
                }
              },
              onReceivedError: (controller, request, error) {
                setState(() {
                  _error = error.description;
                  _isLoading = false;
                });
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final navUrl = navigationAction.request.url?.toString() ?? '';
                debugPrint('Navigation: $navUrl');
                return NavigationActionPolicy.ALLOW;
              },
            ),
    );
  }
}

class _SyncingOverlay extends StatelessWidget {
  const _SyncingOverlay();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.85),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'Syncing Your Trace Profile...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Getting your timetable & campus data ready.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
