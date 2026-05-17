// lib/presentation/screens/auth/cms_webview_login.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import '../../widgets/common/falling_pattern_background.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/cms_models.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/cms_auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/local_settings_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/cms_parser_service.dart';

class CMSWebViewLogin extends ConsumerStatefulWidget {
  const CMSWebViewLogin({super.key});

  @override
  ConsumerState<CMSWebViewLogin> createState() => _CMSWebViewLoginState();
}

class _CMSWebViewLoginState extends ConsumerState<CMSWebViewLogin> {
  InAppWebViewController? _webViewController;
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _loginSuccess = false;
  bool _isExtracting = false;
  String? _error;
  String _loadingStatus = '';
  
  Map<String, dynamic>? _cachedProfileData;
  bool _waitingForTimetable = false;
  bool _isTimetableProcessing = false;

  final TextEditingController _enrollmentController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  List<Map<String, String>> _savedAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  Future<void> _loadSavedAccounts() async {
    final settings = ref.read(localSettingsProvider);
    final accounts = await settings.getSavedCMSAccounts();
    if (mounted) {
      setState(() {
        _savedAccounts = accounts;
      });
    }
  }

  @override
  void dispose() {
    _enrollmentController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleVerify() {
    final enrollment = _enrollmentController.text.trim();
    final password = _passwordController.text.trim();

    if (enrollment.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    debugPrint('🚀 Starting CMS Verification for: $enrollment');
    setState(() {
      _isLoading = true;
      _error = null;
      _loadingStatus = 'Opening CMS...';
    });

    // Handle Web Platform Limitations
    if (kIsWeb) {
      debugPrint('🌐 Web Platform Detected: Bypassing CMS WebView (Not supported in browsers due to iframe security).');
      setState(() {
        _loadingStatus = 'Web Bypass: Authenticating...';
      });
      Future.delayed(const Duration(seconds: 2), () {
        _simulateWebBypassLogin(enrollment, password);
      });
      return;
    }

    _webViewController?.getUrl().then((url) {
      if (url?.toString().contains('Login.aspx') == true) {
        _autoFillAndLogin(enrollment, password);
      } else {
        debugPrint('🌐 Loading student login URL...');
        _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri("https://cms.bahria.edu.pk/Logins/Student/Login.aspx")));
      }
    });

    // Timeout if nothing happens for 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _isLoading && !_loginSuccess) {
        setState(() {
          _isLoading = false;
          _error = 'Login timed out. Please try again or check your internet connection.';
        });
      }
    });
  }

  Future<void> _simulateWebBypassLogin(String enrollment, String password) async {
    try {
      setState(() => _loadingStatus = 'Simulating Data Sync...');
      
      final api = ref.read(apiServiceProvider);
      final localSettings = ref.read(localSettingsProvider);
      
      final name = enrollment;
      final email = '$enrollment@student.bahria.edu.pk';
      
      await localSettings.saveCMSAccount(enrollment, password);
      _loadSavedAccounts();
      
      await api.syncUser({
        'uid': enrollment,
        'name': name,
        'email': email,
        'department': 'Web Test Department',
        'isCMSVerified': true,
        'cmsStudentId': enrollment,
        'lastActive': DateTime.now().millisecondsSinceEpoch,
      });

      await ref.read(authServiceProvider).setCurrentUserFromUid(enrollment);
      
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Web Bypass Failed: $e';
        });
      }
    }
  }

  Future<void> _autoFillAndLogin(String enrollment, String password) async {
    if (_webViewController == null) return;
    
    // JS to fill and submit
    final jsCode = '''
      (function() {
        var enrollmentField = document.getElementById('BodyPH_tbEnrollment');
        var passwordField = document.getElementById('BodyPH_tbPassword');
        var instituteSelect = document.getElementById('BodyPH_ddlInstituteID');
        var roleSelect = document.getElementById('BodyPH_ddlSubUserType');
        var loginButton = document.getElementById('BodyPH_btnLogin');

        if (enrollmentField && passwordField && loginButton) {
          enrollmentField.value = '$enrollment';
          passwordField.value = '$password';
          if (instituteSelect) instituteSelect.value = '2';
          if (roleSelect) roleSelect.value = 'None';
          
          setTimeout(() => loginButton.click(), 500);
          return true;
        }
        return false;
      })();
    ''';

    setState(() => _loadingStatus = 'Entering credentials...');
    final result = await _webViewController?.evaluateJavascript(source: jsCode);
    debugPrint('🧪 JS Injection Result: $result');
  }

  Future<void> _checkExistingAndNavigate(InAppWebViewController controller) async {
    setState(() {
      _isLoading = true;
      _loadingStatus = 'Checking identity...';
    });

    try {
      // Get enrollment from the top bar first
      final enrollmentData = await controller.evaluateJavascript(source: "document.querySelector('#ProfileInfo_lblUsername')?.innerText.trim()");
      final enrollment = enrollmentData?.toString() ?? _enrollmentController.text.trim();

      if (enrollment.isNotEmpty) {
        final api = ref.read(apiServiceProvider);
        final existingUser = await api.getUser(enrollment);
        
        if (existingUser != null && 
            existingUser['isCMSVerified'] == true && 
            existingUser['fatherName'] != null) {
          debugPrint('💎 User fully verified with deep data, skipping sync.');
          setState(() => _loadingStatus = 'Welcome back!');
          final localSettings = ref.read(localSettingsProvider);
          await localSettings.saveCMSAccount(enrollment, _passwordController.text.trim());
          _loadSavedAccounts(); // Refresh list asynchronously
          await ref.read(authServiceProvider).setCurrentUserFromUid(enrollment);
          if (mounted) context.go('/home');
          return;
        }
      }
      
      // If not found or not verified, go to Profile.aspx for full sync
      debugPrint('🆕 New or unverified user, starting full sync...');
      controller.loadUrl(urlRequest: URLRequest(url: WebUri("https://cms.bahria.edu.pk/Sys/Student/Profile.aspx")));
    } catch (e) {
      debugPrint('⚠️ Check failed, falling back to full sync: $e');
      controller.loadUrl(urlRequest: URLRequest(url: WebUri("https://cms.bahria.edu.pk/Sys/Student/Profile.aspx")));
    }
  }

  Future<void> _extractAndSaveData() async {
    if (_isExtracting || _webViewController == null || !mounted) return;
    
    _isExtracting = true;
    debugPrint('📥 Starting phase 1: Profile extraction...');

    try {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      final profileData = await _webViewController?.evaluateJavascript(
        source: '''
        (function() {
          const data = {};
          
          if (window.location.href.includes('Profile.aspx')) {
            const table = document.querySelector('.tableCol4');
            if (table) {
              const rows = table.querySelectorAll('tr');
              rows.forEach(row => {
                const ths = row.querySelectorAll('th');
                const tds = row.querySelectorAll('td');
                for (let i = 0; i < ths.length; i++) {
                  if (ths[i] && tds[i]) {
                    const key = ths[i].innerText.trim();
                    const val = tds[i].innerText.trim();
                    if (key === 'Registration No.') data.registrationNo = val;
                    else if (key === 'Name') data.name = val;
                    else if (key === 'Father Name') data.fatherName = val;
                    else if (key === 'Program') data.program = val;
                    else if (key === 'Mobile No.') data.phone = val;
                    else if (key === 'Enrollment') data.enrollment = val;
                    else if (key === 'University Email') data.universityEmail = val;
                    else if (key === 'Current Address') data.currentAddress = val;
                    else if (key === 'Permanent Address') data.permanentAddress = val;
                    else if (key === 'Intake Semester') data.intakeSemester = val;
                  }
                }
              });
            }
          }
          
          // Fallback/Supplemental: Top bar info
          const nameEl = document.querySelector('#ProfileInfo_lblName');
          const emailEl = document.querySelector('#ProfileInfo_lblEmail');
          const usernameEl = document.querySelector('#ProfileInfo_lblUsername');
          
          if (nameEl && !data.name) data.name = nameEl.innerText.trim();
          if (emailEl && !data.universityEmail) data.universityEmail = emailEl.innerText.trim();
          if (usernameEl && !data.enrollment) data.enrollment = usernameEl.innerText.trim();
          
          return JSON.stringify(data);
        })();
      ''',
      );

      Map<String, dynamic> data = {};
      if (profileData != null && profileData is String && profileData.isNotEmpty) {
        data = jsonDecode(profileData);
      }
      
      _cachedProfileData = data;

      // Advance to step 2: Timetable sync in the active session
      debugPrint('📋 Profile step completed, routing to Timetable...');
      setState(() {
        _loadingStatus = 'Fetching Schedule...';
        _waitingForTimetable = true;
      });

      _webViewController?.loadUrl(
        urlRequest: URLRequest(
          url: WebUri("https://cms.bahria.edu.pk/Sys/Student/CourseRegistration/TimeTable.aspx")
        )
      );

    } catch (e) {
      debugPrint('❌ Profile Extraction Error: $e');
      if (mounted) {
        setState(() { 
          _error = 'Details extraction failed: $e'; 
          _isLoading = false; 
          _isSyncing = false; 
        });
      }
    } finally {
      _isExtracting = false;
    }
  }

  Future<void> _extractTimetableAndFinalize() async {
    if (_isTimetableProcessing || _webViewController == null || !mounted) return;
    
    _isTimetableProcessing = true;
    debugPrint('📥 Starting phase 2: Timetable Extraction...');
    
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      // Step 1: Scrape whole HTML directly from the logged-in WebView to leverage our existing parsers!
      final rawHtml = await _webViewController?.evaluateJavascript(
        source: "document.documentElement.outerHTML"
      );

      List<CMSTimetableEntry> timetable = [];

      if (rawHtml != null && rawHtml is String) {
        debugPrint('🔎 Sending HTML to CMSParserService...');
        // Strategy 1: Hidden JSON field via existing parser
        final jsonStr = CMSParserService.extractTimetableJson(rawHtml);
        if (jsonStr != null) {
          try {
            final decoded = jsonDecode(jsonStr);
            timetable = CMSParserService.parseTimetable(decoded);
            debugPrint('📅 Found ${timetable.length} courses via dynamic extraction');
          } catch (e) {
             debugPrint('JSON parse error during sync: $e');
          }
        }
        // Fallback to HTML table scraping via existing parser
        if (timetable.isEmpty) {
          debugPrint('⏳ Trying table fallback...');
          final tableEntries = CMSParserService.extractTimetableFromTable(rawHtml);
          if (tableEntries.isNotEmpty) {
            timetable = tableEntries
                .map((e) => CMSTimetableEntry.fromMap(e))
                .toList();
            debugPrint('📅 Found ${timetable.length} courses via table extraction');
          }
        }
      }

      // Step 2: Consolidate Profile & Save
      final data = _cachedProfileData ?? {};
      final enrollment = data['enrollment'] ?? _enrollmentController.text.trim();
      
      // TASK: Remove CMS User string mapping! Replace with enrollment number if found placeholder
      final rawName = data['name']?.toString().trim() ?? '';
      final name = rawName.isNotEmpty ? rawName : enrollment;

      final email = data['universityEmail'] ?? '$enrollment@student.bahria.edu.pk';
      final fatherName = data['fatherName'] ?? '';
      final phone = data['phone'] ?? '';
      final program = data['program'] ?? '';
      final regNo = data['registrationNo'] ?? '';
      final curAddr = data['currentAddress'] ?? '';
      final permAddr = data['permanentAddress'] ?? '';
      final intake = data['intakeSemester'] ?? '';
      
      String dept = program;
      if (program.contains('BSE')) dept = 'Software Engineering';
      else if (program.contains('BCE')) dept = 'Computer Engineering';
      else if (program.contains('BCS')) dept = 'Computer Science';
      else if (program.contains('BIT')) dept = 'Information Technology';
      else if (program.contains('BBA')) dept = 'Business Administration';
      else if (program.contains('BEE')) dept = 'Electrical Engineering';

      setState(() => _loadingStatus = 'Finalizing Profile...');
      
      final localSettings = ref.read(localSettingsProvider);
      await localSettings.setFatherName(fatherName);
      await localSettings.setRegistrationNo(regNo);
      await localSettings.setCurrentAddress(curAddr);
      await localSettings.setPermanentAddress(permAddr);
      await localSettings.setIntakeSemester(intake);
      await localSettings.saveCMSAccount(enrollment, _passwordController.text.trim());
      _loadSavedAccounts(); // Refresh list asynchronously

      final api = ref.read(apiServiceProvider);
      await api.syncUser({
        'uid': enrollment,
        'name': name,
        'email': email,
        'contactNumber': phone,
        'department': dept,
        'isCMSVerified': true,
        'cmsStudentId': enrollment,
        'lastActive': DateTime.now().millisecondsSinceEpoch,
        'fatherName': fatherName,
        'registrationNo': regNo,
        'currentAddress': curAddr,
        'permanentAddress': permAddr,
        'intakeSemester': intake,
      });

      // Save final scraped timetable
      if (timetable.isNotEmpty) {
        debugPrint('💾 Persisting timetable to cloud store...');
        await api.saveTimetable(enrollment, timetable.map((e) => e.toMap()).toList());
      }

      await ref.read(authServiceProvider).setCurrentUserFromUid(enrollment);
      await NotificationService().registerDevice(enrollment, name: name, email: email);
      
      debugPrint('🎉 Done! Navigation underway...');
      if (mounted) {
        context.go('/home');
      }

    } catch (e) {
      debugPrint('❌ Sync Error: $e');
      if (mounted) {
        setState(() { 
          _error = 'Final sync failed: $e'; 
          _isLoading = false; 
          _isSyncing = false; 
        });
      }
    } finally {
      _isTimetableProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);

    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Campus Verification', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: FallingPatternBackground(
        child: Stack(
        children: [
          // Background WebView (Positioned off-screen so it is 100% invisible but fully active in the widget tree)
          Positioned(
            left: -1000,
            top: -1000,
            child: SizedBox(
              width: 100,
              height: 100,
              child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri("https://cms.bahria.edu.pk/Logins/Student/Login.aspx")),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                    cacheEnabled: true,
                    useHybridComposition: true,
                  ),
                  onWebViewCreated: (controller) => _webViewController = controller,
                  onLoadStop: (controller, url) async {
                    final urlStr = url?.toString() ?? '';
                    debugPrint('🌐 WebView Loaded: $urlStr');
                    
                    if (urlStr.contains('Dashboard.aspx')) {
                      debugPrint('✅ Login Success! Checking for existing profile...');
                      _checkExistingAndNavigate(controller);
                    } 
                    else if (urlStr.contains('Profile.aspx')) {
                      debugPrint('📄 Profile page loaded, extracting deep data...');
                      setState(() { 
                        _loginSuccess = true; 
                        _isSyncing = true; 
                        _loadingStatus = 'Extracting Details...';
                      });
                      _extractAndSaveData();
                    } 
                    else if (urlStr.contains('TimeTable.aspx') && _waitingForTimetable) {
                      debugPrint('📅 Timetable page ready! Proceeding to finalize...');
                      _extractTimetableAndFinalize();
                    }
                    else if (urlStr.contains('Login.aspx') && _isLoading) {
                      debugPrint('📍 Still on login page, checking for errors...');
                      setState(() => _loadingStatus = 'Authenticating...');
                      final errorMsg = await controller.evaluateJavascript(source: "document.querySelector('.alert-danger')?.innerText");
                      if (errorMsg != null && errorMsg.toString().trim().isNotEmpty) {
                        debugPrint('❌ CMS Error: $errorMsg');
                        setState(() { _error = errorMsg.toString(); _isLoading = false; });
                      } else {
                        debugPrint('🔁 Retrying autofill...');
                        _autoFillAndLogin(_enrollmentController.text, _passwordController.text);
                      }
                    }
                  },
                ),
              ),
            ),

          // Scrollable UI Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Icon(Icons.school_rounded, size: 64, color: AppColors.jadePrimary),
                  const SizedBox(height: 24),
                  Text(
                    'Verify Student Identity',
                    style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use your official CMS credentials to link your campus profile.',
                    style: GoogleFonts.inter(fontSize: 14, color: subColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  _buildPresetsRow(context),
                  _CustomField(
                    controller: _enrollmentController,
                    label: 'Enrollment ID',
                    hint: 'e.g. 01-134212-001',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),
                  _CustomField(
                    controller: _passwordController,
                    label: 'CMS Password',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.jadePrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            const SizedBox(width: 12),
                            Text(_loadingStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        )
                      : const Text('Verify & Sync Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 40), // Bottom padding for scroll
                ],
              ),
            ),
          ),
          if (_isSyncing) _SyncingOverlay(status: _loadingStatus),
        ],
      ),
     ),
    );
  }

  Widget _buildPresetsRow(BuildContext context) {
    final presets = _savedAccounts;
    if (presets.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Accounts',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.jadePrimary),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: presets.length,
            itemBuilder: (context, i) {
              final preset = presets[i];
              final enrollment = preset['enrollment'] ?? '';
              final password = preset['password'] ?? '';
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.jadePrimary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _enrollmentController.text = enrollment;
                          _passwordController.text = password;
                        });
                        _handleVerify();
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.badge_rounded, size: 14, color: AppColors.jadePrimary),
                          const SizedBox(width: 8),
                          Text(
                            enrollment,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        await ref.read(localSettingsProvider).deleteCMSAccount(enrollment);
                        _loadSavedAccounts();
                      },
                      child: Icon(Icons.close_rounded, size: 14, color: subColor.withOpacity(0.6)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _CustomField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;

  const _CustomField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
  });

  @override
  State<_CustomField> createState() => _CustomFieldState();
}

class _CustomFieldState extends State<_CustomField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: subColor)),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: _obscureText,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: subColor.withOpacity(0.3)),
            prefixIcon: Icon(widget.icon, color: AppColors.jadePrimary, size: 20),
            suffixIcon: widget.isPassword 
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.jadePrimary.withOpacity(0.7),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                )
              : null,
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.jadePrimary)),
          ),
        ),
      ],
    );
  }
}

class _SyncingOverlay extends StatelessWidget {
  final String status;
  const _SyncingOverlay({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.textPrimary(context);
    final subColor = AppColors.textSecondary(context);

    return Container(
      color: isDark ? AppColors.navyDarkest : Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.jadePrimary),
            const SizedBox(height: 24),
            Text(
              status,
              style: GoogleFonts.plusJakartaSans(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Getting your timetable & campus data ready.',
              style: GoogleFonts.inter(
                color: subColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
