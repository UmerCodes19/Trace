import 'dart:io';

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:image_picker/image_picker.dart';

import 'package:uuid/uuid.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/services/location_prediction_service.dart';

import '../../../core/constants/app_colors.dart';

import '../../../core/utils/app_utils.dart';

import '../../../data/models/simple_post_model.dart';

import '../../../data/services/auth_service.dart';

import '../../../data/services/ai_service.dart';

import '../../../data/services/api_service.dart';

import '../../../data/services/storage_service.dart';

import '../../../data/models/cms_models.dart';

import '../../../data/services/campus_map_service.dart';

import '../../../data/services/map/map_engine_service.dart';

import '../../../data/models/map/campus_gis_models.dart';

import '../../../data/services/offline/sync_manager.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:permission_handler/permission_handler.dart';



class CreatePostScreen extends ConsumerStatefulWidget {

  const CreatePostScreen({super.key, this.postToEdit});

  final SimplePostModel? postToEdit;



  @override

  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();

}



class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {

  final _formKey = GlobalKey<FormState>();



  String _type = 'lost';

  final _titleCtrl = TextEditingController();

  final _descCtrl = TextEditingController();

  final _buildingCtrl = TextEditingController();

  final _roomCtrl = TextEditingController();

  final _secretQuestionCtrl = TextEditingController();

  int _floor = 0;

  double? _indoorX;

  double? _indoorY;

  List<String> _existingImageUrls = [];



  // Date and Time fields

  DateTime? _lostDateTime;

  TimeOfDay? _lostTime;



  final List<File> _images = [];

  File? _video;

  List<String> _aiTags = [];

  bool _analyzingImages = false;

  bool _isSubmitting = false;



  // Speech-to-text fields

  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;

  String _speechText = '';

  bool _speechParsing = false;

  // Wizard fields
  final PageController _pageCtrl = PageController();
  int _currentStep = 0;



  @override

  void initState() {

    super.initState();

    _roomCtrl.addListener(_onRoomChanged);

    _titleCtrl.addListener(_saveDraft);

    _descCtrl.addListener(_saveDraft);

    _buildingCtrl.addListener(_saveDraft);

    _roomCtrl.addListener(_saveDraft);

    _secretQuestionCtrl.addListener(_saveDraft);



    // Keyword categories listener

    _titleCtrl.addListener(_suggestCategoryTags);



    if (widget.postToEdit != null) {

      _type = widget.postToEdit!.type;

      _titleCtrl.text = widget.postToEdit!.title;

      _descCtrl.text = widget.postToEdit!.description;

      _buildingCtrl.text = widget.postToEdit!.location.building;

      _roomCtrl.text = widget.postToEdit!.location.room ?? '';

      _floor = widget.postToEdit!.location.floor;

      _lostDateTime = widget.postToEdit!.timestamp;

      _secretQuestionCtrl.text = widget.postToEdit!.secretDetailQuestion ?? '';

      _aiTags = List<String>.from(widget.postToEdit!.aiTags);

      _existingImageUrls = List<String>.from(widget.postToEdit!.imageUrls);

    } else {

      _loadDraft();

    }



    // Handle pre-filled data from map long-press or room tap

    WidgetsBinding.instance.addPostFrameCallback((_) {

      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;

      if (extra != null) {

        setState(() {

          if (extra['building'] != null) _buildingCtrl.text = extra['building'];

          if (extra['floor'] != null) _floor = extra['floor'];

          if (extra['room'] != null) _roomCtrl.text = extra['room'];

          if (extra['indoorX'] != null) _indoorX = extra['indoorX'];

          if (extra['indoorY'] != null) _indoorY = extra['indoorY'];

        });

      }

    });

  }



  void _onRoomChanged() {

    final roomNum = _roomCtrl.text.toUpperCase();

    if (MapEngineService.instance.isInitialized) {

      final matchedRooms = MapEngineService.instance.searchRooms(roomNum, _floor);

      if (matchedRooms.isNotEmpty) {

        final room = matchedRooms.first;

        final center = MapEngineService.instance.getRoomCenter(room);

        setState(() {

          _buildingCtrl.text = "Liaquat Block";

          _floor = room.floor;

          _indoorX = center.dx;

          _indoorY = center.dy;

        });

        return;

      }

    }



    final location = CampusMapService.getLocation(roomNum);

    if (location != null) {

      setState(() {

        _buildingCtrl.text = location.building;

        _floor = location.floor;

      });

    }

  }



  void _suggestCategoryTags() {

    final text = _titleCtrl.text.toLowerCase();

    final Map<String, String> keywordsToTags = {

      'wallet': 'finance',

      'money': 'finance',

      'cash': 'finance',

      'phone': 'electronics',

      'laptop': 'electronics',

      'airpods': 'electronics',

      'headphone': 'electronics',

      'charger': 'electronics',

      'cnic': 'documents',

      'card': 'documents',

      'id': 'documents',

      'license': 'documents',

      'passport': 'documents',

      'key': 'keys',

      'bottle': 'utilities',

      'flask': 'utilities',

      'bag': 'bags',

      'backpack': 'bags',

      'book': 'books',

      'notebook': 'books',

    };



    bool updated = false;

    keywordsToTags.forEach((kw, tag) {

      if (text.contains(kw) && !_aiTags.contains(tag)) {

        _aiTags.add(tag);

        updated = true;

      }

    });



    if (updated) {

      setState(() {});

    }

  }



  void _saveDraft() {

    if (widget.postToEdit != null) return;

    const storage = FlutterSecureStorage();

    final draft = {

      'type': _type,

      'title': _titleCtrl.text,

      'description': _descCtrl.text,

      'building': _buildingCtrl.text,

      'room': _roomCtrl.text,

      'floor': _floor,

      'secretQuestion': _secretQuestionCtrl.text,

      'aiTags': _aiTags,

    };

    storage.write(key: 'create_post_draft', value: jsonEncode(draft));

  }



  Future<void> _loadDraft() async {

    try {

      const storage = FlutterSecureStorage();

      final val = await storage.read(key: 'create_post_draft');

      if (val != null) {

        final map = jsonDecode(val) as Map<String, dynamic>;

        if (mounted) {

          final restore = await showDialog<bool>(

            context: context,

            builder: (ctx) => AlertDialog(

              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

              title: Text('Restore Draft?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),

              content: Text('Would you like to restore your previously saved draft for this report?', style: GoogleFonts.inter()),

              actions: [

                TextButton(

                  onPressed: () {

                    storage.delete(key: 'create_post_draft');

                    Navigator.of(ctx).pop(false);

                  },

                  child: Text('Clear'),

                ),

                ElevatedButton(

                  onPressed: () => Navigator.of(ctx).pop(true),

                  style: ElevatedButton.styleFrom(

                    backgroundColor: AppColors.jadePrimary,

                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                  ),

                  child: const Text('Restore'),

                ),

              ],

            ),

          );



          if (restore == true && mounted) {

            setState(() {

              _type = map['type'] ?? 'lost';

              _titleCtrl.text = map['title'] ?? '';

              _descCtrl.text = map['description'] ?? '';

              _buildingCtrl.text = map['building'] ?? '';

              _roomCtrl.text = map['room'] ?? '';

              _floor = map['floor'] ?? 0;

              _secretQuestionCtrl.text = map['secretQuestion'] ?? '';

              if (map['aiTags'] != null) {

                _aiTags = List<String>.from(map['aiTags']);

              }

            });

          }

        }

      }

    } catch (_) {}

  }



  bool _hasStartedTyping() {

    if (widget.postToEdit != null) return false;

    return _titleCtrl.text.isNotEmpty ||

        _descCtrl.text.isNotEmpty ||

        _buildingCtrl.text.isNotEmpty ||

        _roomCtrl.text.isNotEmpty ||

        _secretQuestionCtrl.text.isNotEmpty ||
        _images.isNotEmpty ||
        _video != null;

  }



  Future<bool?> _showDiscardConfirm() {

    return showDialog<bool>(

      context: context,

      builder: (ctx) => AlertDialog(

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        title: Text(

          'Discard changes?',

          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),

        ),

        content: Text(

          'Are you sure you want to discard this report? Any unsaved changes will be lost.',

          style: GoogleFonts.inter(),

        ),

        actions: [

          TextButton(

            onPressed: () => Navigator.of(ctx).pop(false),

            child: const Text('Cancel'),

          ),

          ElevatedButton(

            onPressed: () => Navigator.of(ctx).pop(true),

            style: ElevatedButton.styleFrom(

              backgroundColor: AppColors.lostAlert,

              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

            ),

            child: const Text('Discard'),

          ),

        ],

      ),

    );

  }



  @override

  void dispose() {

    _pageCtrl.dispose();
    _titleCtrl.dispose();

    _descCtrl.dispose();

    _buildingCtrl.dispose();

    _roomCtrl.dispose();

    _secretQuestionCtrl.dispose();

    super.dispose();

  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 15),
      );

      if (picked != null) {
        final file = File(picked.path);
        final int sizeInBytes = await file.length();
        final double sizeInMb = sizeInBytes / (1024 * 1024);

        if (sizeInMb > 15.0) {
          if (mounted) {
            showAppSnack(
              context,
              'Video size must be less than 15MB (Selected: ${sizeInMb.toStringAsFixed(1)}MB)',
              isError: true,
            );
          }
          return;
        }

        setState(() {
          _video = file;
          if (!_descCtrl.text.toLowerCase().contains('#video')) {
            if (_descCtrl.text.isEmpty) {
              _descCtrl.text = '#video';
            } else {
              _descCtrl.text = '${_descCtrl.text}\n#video';
            }
          }
        });

        if (mounted) {
          showAppSnack(context, 'Video selected successfully! (#video hashtag auto-added)');
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(context, 'Error picking video: $e', isError: true);
      }
    }
  }


  Future<void> _pickImages(ImageSource source) async {

    if (_images.length >= 4) {

      if (mounted) showAppSnack(context, 'Maximum 4 images allowed');

      return;

    }



    try {

      final picker = ImagePicker();

      if (source == ImageSource.gallery) {

        final picked = await picker.pickMultiImage(imageQuality: 80);

        final toAdd = picked.take(4 - _images.length).map((x) => File(x.path));

        if (mounted) {

          setState(() => _images.addAll(toAdd));

          _analyzeImages();

        }

      } else {

        final picked = await picker.pickImage(source: source, imageQuality: 80);

        if (picked != null) {

          if (mounted) {

            setState(() => _images.add(File(picked.path)));

            _analyzeImages();

          }

        }

      }

    } catch (e) {

      if (mounted) {

        showAppSnack(context, 'Error picking image: $e', isError: true);

      }

    }

  }



  Future<void> _analyzeImages() async {

    if (_images.isEmpty) return;

    if (mounted) setState(() => _analyzingImages = true);



    try {

      final aiSvc = ref.read(aiServiceProvider);

      final result = await aiSvc.analyzeItemImage(_images.first);

      

      if (result != null && mounted) {

        setState(() {

          if (_titleCtrl.text.isEmpty && result['title'] != null) {

            _titleCtrl.text = result['title'];

          }

          if (_descCtrl.text.isEmpty && result['description'] != null) {

            _descCtrl.text = result['description'];

          }

          if (result['tags'] != null) {

            final List<dynamic> tags = result['tags'];

            final newTags = tags.map((e) => e.toString().toLowerCase()).toSet();

            newTags.addAll(_aiTags);

            _aiTags = newTags.toList();

          }

        });

        

        showAppSnack(context, '✨ AI generated details from your image!');

      }

    } catch (e) {

      debugPrint('Error analyzing image with AI: $e');

    }



    if (mounted) setState(() => _analyzingImages = false);

  }



  Future<void> _selectDateTime() async {

    final date = await showDatePicker(

      context: context,

      initialDate: DateTime.now(),

      firstDate: DateTime.now().subtract(const Duration(days: 30)),

      lastDate: DateTime.now(),

    );



    if (date == null) return;



    final time = await showTimePicker(

      context: context,

      initialTime: TimeOfDay.now(),

    );



    if (time == null) return;



    if (mounted) {

      setState(() {

        _lostDateTime = DateTime(

          date.year,

          date.month,

          date.day,

          time.hour,

          time.minute,

        );

        _lostTime = time;

      });



      await _showPrediction(_lostDateTime!);

    }

  }



  Future<void> _showPrediction(DateTime lostTime) async {

    final authService = ref.read(authServiceProvider);

    final user = await authService.getCurrentUser();

    if (user == null) return;



    final api = ref.read(apiServiceProvider);

    final timetableData = await api.getTimetable(user.uid);

    

    if (timetableData.isEmpty) {

      debugPrint('No timetable found for ${user.uid} - prediction skipped');

      await _showFallbackPrediction();

      return;

    }



    final entries = (timetableData as List).map<CMSTimetableEntry>((e) => CMSTimetableEntry.fromMap(e as Map<String, dynamic>)).toList();

    final predictor = LocationPredictionService(entries);



    final result = predictor.predictLostLocation(

      lostTime: lostTime,

      enrollment: user.email,

    );



    if (mounted && result.confidence > 0.6) {

      showDialog(

        context: context,

        builder: (dialogContext) => AlertDialog(

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

          title: Row(

            children: [

              Icon(Icons.location_on, color: AppColors.lostAlert),

              const SizedBox(width: 8),

              Text('📍 Location Prediction', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),

            ],

          ),

          content: Column(

            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(

                result.suggestion,

                style: GoogleFonts.inter(fontSize: 14, height: 1.4),

              ),

              const SizedBox(height: 12),

              Container(

                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(

                  color: AppColors.lostAlertBg,

                  borderRadius: BorderRadius.circular(10),

                ),

                child: Row(

                  children: [

                    Icon(

                      Icons.analytics_outlined,

                      size: 16,

                      color: AppColors.lostAlert,

                    ),

                    const SizedBox(width: 8),

                    Text(

                      'Confidence: ${(result.confidence * 100).toInt()}%',

                      style: GoogleFonts.inter(

                        fontSize: 13,

                        fontWeight: FontWeight.w600,

                        color: AppColors.lostAlert,

                      ),

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 12),

              Text(

                'Would you like to use this predicted location?',

                style: GoogleFonts.inter(

                  fontSize: 13,

                  color: AppColors.textSecondary(context),

                ),

              ),

            ],

          ),

          actions: [

            TextButton(

              onPressed: () => Navigator.of(dialogContext).pop(),

              child: const Text('No, skip'),

            ),

            ElevatedButton(

              onPressed: () {

                setState(() {

                  _buildingCtrl.text = result.building;

                  if (result.room != null) {

                    _roomCtrl.text = result.room!;

                  }

                });

                Navigator.of(dialogContext).pop();

                showAppSnack(context, '✓ Location updated from prediction');

              },

              style: ElevatedButton.styleFrom(

                backgroundColor: AppColors.jadePrimary,

                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

              ),

              child: const Text('Use Location'),

            ),

          ],

        ),

      );

    }

  }



  Future<void> _showFallbackPrediction() async {

    if (!mounted || _lostDateTime == null) return;



    final hour = _lostDateTime!.hour;

    final building = hour < 12

        ? 'Main Library'

        : hour < 16

        ? 'Cafeteria / Student Center'

        : 'Department Block';



    showDialog(

      context: context,

      builder: (dialogContext) => AlertDialog(

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        title: Text('Location Suggestion', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),

        content: Text(

          'CMS timetable was not available, so this is a smart fallback suggestion.\n\nTry checking: $building',

          style: GoogleFonts.inter(fontSize: 14, height: 1.4),

        ),

        actions: [

          TextButton(

            onPressed: () => Navigator.of(dialogContext).pop(),

            child: const Text('Skip'),

          ),

          ElevatedButton(

            onPressed: () {

              setState(() {

                _buildingCtrl.text = building;

              });

              Navigator.of(dialogContext).pop();

              showAppSnack(context, 'Location updated from fallback prediction');

            },

            style: ElevatedButton.styleFrom(

              backgroundColor: AppColors.jadePrimary,

              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

            ),

            child: const Text('Use'),

          ),

        ],

      ),

    );

  }



  void _removeImage(int i) {

    if (mounted) setState(() => _images.removeAt(i));

  }



  void _removeTag(String tag) {

    if (mounted) setState(() => _aiTags.remove(tag));

  }



  Future<void> _submit() async {

    if (!_formKey.currentState!.validate()) {

      return;

    }



    if (_images.isEmpty && _existingImageUrls.isEmpty && _video == null) {
      if (mounted) showAppSnack(context, 'Please add at least one photo or video');
      return;
    }



    if (mounted) setState(() => _isSubmitting = true);

    SimplePostModel? post;

    try {

      final authService = ref.read(authServiceProvider);

      final currentUser = await authService.getCurrentUser();



      if (currentUser == null) {

        if (mounted) {

          showAppSnack(context, 'Error: User not authenticated', isError: true);

        }

        return;

      }



      final api = ref.read(apiServiceProvider);

      final storageSvc = ref.read(storageServiceProvider);

      // Upload video if selected
      String? uploadedVideoUrl;
      if (_video != null) {
        try {
          uploadedVideoUrl = await storageSvc.uploadPostVideo(_video!, currentUser.uid);
        } catch (e) {
          debugPrint('Error uploading video: $e');
        }
      }

      // Upload images

      final urls = List<String>.from(_existingImageUrls);

      for (final img in _images) {

        try {

          final url = await storageSvc.uploadPostImage(img, currentUser.uid);

          urls.add(url);

        } catch (e) {

          debugPrint('Error uploading image: $e');

          urls.add(img.path);

        }

      }



      // Determine GPS coordinates based on building name

      double lat = 0;

      double lng = 0;

      final buildingName = _buildingCtrl.text.toLowerCase();

      

      for (final b in CampusMapService.buildings) {

        if (buildingName.contains(b.name.toLowerCase())) {

          lat = b.lat;

          lng = b.lng;

          break;

        }

      }



      post = SimplePostModel(

        id: widget.postToEdit != null ? widget.postToEdit!.id : const Uuid().v4(),

        userId: currentUser.uid,

        type: _type,

        title: sanitizeInput(_titleCtrl.text),

        description: sanitizeInput(_descCtrl.text),

        imageUrls: urls,

        location: SimplePostLocation(

          name: sanitizeInput(_buildingCtrl.text),

          building: sanitizeInput(_buildingCtrl.text),

          floor: _floor,

          room: _roomCtrl.text.isEmpty ? null : sanitizeInput(_roomCtrl.text),

          latitude: lat,

          longitude: lng,

          indoorX: _indoorX,

          indoorY: _indoorY,

        ),

        timestamp: _lostDateTime ?? DateTime.now(),

        aiTags: _aiTags,

        posterName: currentUser.name,

        posterAvatarUrl: currentUser.photoURL ?? '',

        isCMSVerified: currentUser.isCMSVerified,

        secretDetailQuestion: _secretQuestionCtrl.text.isEmpty ? null : _secretQuestionCtrl.text.trim(),
        videoUrl: uploadedVideoUrl ?? () {
          final text = '${_titleCtrl.text} ${_descCtrl.text}'.toLowerCase();
          if (text.contains('#video4')) {
            return 'https://assets.mixkit.co/videos/preview/mixkit-holding-and-using-a-sleek-smart-phone-41484-large.mp4';
          } else if (text.contains('#video3')) {
            return 'https://assets.mixkit.co/videos/preview/mixkit-group-of-college-students-discussing-work-in-library-43393-large.mp4';
          } else if (text.contains('#video2')) {
            return 'https://assets.mixkit.co/videos/preview/mixkit-interior-of-a-modern-library-with-bookshelves-44813-large.mp4';
          } else if (text.contains('#video') || text.contains('#reel')) {
            return 'https://assets.mixkit.co/videos/preview/mixkit-university-campus-with-students-walking-43406-large.mp4';
          }
          return null;
        }(),
      );



      const storage = FlutterSecureStorage();

      await storage.delete(key: 'create_post_draft');



      if (widget.postToEdit != null) {

        await api.updatePost(widget.postToEdit!.id, post.toMap());

        ref.invalidate(postsProvider);

        AppHaptics.success();

        if (mounted) {

          showAppSnack(context, '✅ Post updated successfully!');

          context.go('/home');

        }

        return;

      }



      await api.createPost(post.toMap());

      await api.updateUserStats(

        currentUser.uid,

        {

          'itemsLost': _type == 'lost' ? 1 : 0,

          'itemsFound': _type == 'found' ? 1 : 0,

        },

      );



      // Trigger real-time refresh

      ref.invalidate(postsProvider);

      AppHaptics.success();



      if (!mounted) return;

      showAppSnack(context, '✅ Post created successfully!');

      context.go('/home');

    } catch (e) {

      debugPrint('Error submitting post: $e');

      

      // Check if it's a network-related failure to trigger offline queueing

      final errStr = e.toString().toLowerCase();

      final isOffline = errStr.contains('socketexception') || 

                        errStr.contains('connectiontimeout') || 

                        errStr.contains('network is unreachable') || 

                        errStr.contains('failed host lookup') ||

                        errStr.contains('dioexception');

                        

      if (isOffline) {

        try {

          final authService = ref.read(authServiceProvider);

          final currentUser = await authService.getCurrentUser();

          final String userId = currentUser?.uid ?? '';

          final String posterName = currentUser?.name ?? '';

          final String posterAvatar = currentUser?.photoURL ?? '';

          final bool verified = currentUser?.isCMSVerified ?? false;



          final SimplePostModel offlinePost = post ?? SimplePostModel(

            id: widget.postToEdit != null ? widget.postToEdit!.id : const Uuid().v4(),

            userId: userId,

            type: _type,

            title: sanitizeInput(_titleCtrl.text),

            description: sanitizeInput(_descCtrl.text),

            imageUrls: _images.map((img) => img.path).toList(),

            location: SimplePostLocation(

              name: sanitizeInput(_buildingCtrl.text),

              building: sanitizeInput(_buildingCtrl.text),

              floor: _floor,

              room: _roomCtrl.text.isEmpty ? null : sanitizeInput(_roomCtrl.text),

              latitude: 0,

              longitude: 0,

              indoorX: _indoorX,

              indoorY: _indoorY,

            ),

            timestamp: _lostDateTime ?? DateTime.now(),

            aiTags: _aiTags,

            posterName: posterName,

            posterAvatarUrl: posterAvatar,

            isCMSVerified: verified,

            secretDetailQuestion: _secretQuestionCtrl.text.isEmpty ? null : _secretQuestionCtrl.text.trim(),

          );



          await SyncManager.instance.addPostToQueue(offlinePost.toMap());

          AppHaptics.success();

          if (mounted) {

            showAppSnack(context, '📡 Saved offline! We will auto-sync once connected.');

            context.go('/home');

          }

          return;

        } catch (innerEx) {

          debugPrint('Offline queueing error: $innerEx');

        }

      }



      if (mounted) {

        showAppSnack(context, 'Failed to submit post: $e', isError: true);

      }

    } finally {

      if (mounted) setState(() => _isSubmitting = false);

    }

  }



  Future<void> _initAndListen() async {

    try {

      final status = await Permission.microphone.request();

      if (status != PermissionStatus.granted) {

        showAppSnack(context, '🎙️ Microphone permission denied. Please allow mic access in your device Settings!', isError: true);

        return;

      }



      final DateTime initTime = DateTime.now();



      bool available = await _speech.initialize(

        onStatus: (status) {

          debugPrint('🎙️ Speech Status: $status');

          if (status == 'notListening' || status == 'done') {

            final elapsed = DateTime.now().difference(initTime);

            // Only stop if we have actually been listening/active for at least 2 seconds.

            // This avoids instant cancellation due to initial boot/state status events.

            if (_isListening && elapsed.inMilliseconds > 2000) {

              _stopListeningAndParse();

            }

          }

        },

        onError: (val) {

          debugPrint('🎙️ Speech Error: $val');

          if (_isListening) {

            _stopListeningAndParse();

          }

        },

      );



      if (available) {

        setState(() {

          _isListening = true;

          _speechText = '';

        });

        

        _speech.listen(

          onResult: (val) {

            setState(() {

              _speechText = val.recognizedWords;

            });

          },

          listenFor: const Duration(seconds: 30),

          pauseFor: const Duration(seconds: 6),

        );

      } else {

        showAppSnack(context, 'Speech recognition not available on this device.', isError: true);

      }

    } catch (e) {

      showAppSnack(context, 'Microphone permission or engine not ready: $e', isError: true);

    }

  }



  Future<void> _stopListeningAndParse() async {

    setState(() {

      _isListening = false;

    });

    _speech.stop();



    if (_speechText.trim().isEmpty) {

      showAppSnack(context, 'No voice recorded. Please try again!');

      return;

    }



    setState(() {

      _speechParsing = true;

    });



    try {

      final ai = ref.read(aiServiceProvider);

      final result = await ai.parseVoiceTranscript(_speechText);

      

      if (result != null && mounted) {

        setState(() {

          if (result['title'] != null && result['title'].toString().isNotEmpty) {

            _titleCtrl.text = result['title'];

          }

          if (result['type'] != null && (result['type'] == 'lost' || result['type'] == 'found')) {

            _type = result['type'];

          }

          if (result['buildingName'] != null && result['buildingName'].toString().isNotEmpty) {

            _buildingCtrl.text = result['buildingName'];

          }

          if (result['floor'] != null) {

            _floor = result['floor'];

          }

          if (result['location_room'] != null && result['location_room'].toString().isNotEmpty) {

            _roomCtrl.text = result['location_room'];

          }

          if (result['description'] != null && result['description'].toString().isNotEmpty) {

            _descCtrl.text = result['description'];

          }

        });

        showAppSnack(context, '✨ Voice report successfully pre-filled with AI!');

      } else {

        if (mounted) showAppSnack(context, 'AI could not understand details. Try speaking more clearly!', isError: true);

      }

    } catch (e) {

      debugPrint('Voice parsing error: $e');

    } finally {

      if (mounted) {

        setState(() {

          _speechParsing = false;

        });

      }

    }

  }



  void _nextStep() {
    if (_currentStep == 0) {
      if (_images.isEmpty && _existingImageUrls.isEmpty && _video == null) {
        showAppSnack(context, 'Please add at least one photo or video first.', isError: true);
        return;
      }
    } else if (_currentStep == 1) {
      if (_titleCtrl.text.trim().isEmpty) {
        showAppSnack(context, 'Title is required', isError: true);
        return;
      }
      if (_buildingCtrl.text.trim().isEmpty) {
        showAppSnack(context, 'Building location is required', isError: true);
        return;
      }
    }
    
    if (_currentStep < 2) {
      _pageCtrl.nextPage(duration: 400.ms, curve: Curves.easeOutQuart);
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _prevStep() async {
    if (_currentStep > 0) {
      _pageCtrl.previousPage(duration: 400.ms, curve: Curves.easeOutQuart);
      setState(() => _currentStep--);
    } else {
      if (_hasStartedTyping()) {
        final proceed = await _showDiscardConfirm();
        if (proceed == true && mounted) context.go('/home');
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _prevStep,
                        icon: Icon(
                          _currentStep == 0 ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary(context),
                          size: _currentStep == 0 ? 28 : 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentStep == 0 ? 'Media (1/3)' : _currentStep == 1 ? 'Details (2/3)' : 'Security (3/3)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(child: Container(height: 4, decoration: BoxDecoration(color: _currentStep >= 0 ? AppColors.jadePrimary : AppColors.surface(context), borderRadius: BorderRadius.circular(2)))),
                                const SizedBox(width: 4),
                                Expanded(child: Container(height: 4, decoration: BoxDecoration(color: _currentStep >= 1 ? AppColors.jadePrimary : AppColors.surface(context), borderRadius: BorderRadius.circular(2)))),
                                const SizedBox(width: 4),
                                Expanded(child: Container(height: 4, decoration: BoxDecoration(color: _currentStep >= 2 ? AppColors.jadePrimary : AppColors.surface(context), borderRadius: BorderRadius.circular(2)))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: _isSubmitting ? null : _nextStep,
                        child: _isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(
                                _currentStep == 2 ? (widget.postToEdit != null ? 'Save' : 'Post') : 'Next',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMediaStep(),
                        _buildDetailsStep(),
                        _buildSecurityStep(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_isListening) _buildListeningOverlay(),
            if (_speechParsing) _buildParsingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        Text(
          'Show us what you found or lost.',
          style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Text(
          'Clear photos help the AI match items instantly.',
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary(context)),
        ),
        const SizedBox(height: 32),
        _ImagePicker(
          images: _images,
          existingUrls: _existingImageUrls,
          onPickGallery: () => _pickImages(ImageSource.gallery),
          onPickCamera: () => _pickImages(ImageSource.camera),
          onRemove: _removeImage,
          onRemoveExisting: (i) {
            if (mounted) setState(() => _existingImageUrls.removeAt(i));
          },
          video: _video,
          onPickVideo: () => _pickVideo(ImageSource.gallery),
          onRemoveVideo: () {
            if (mounted) setState(() => _video = null);
          },
        ),
        if (_analyzingImages || _aiTags.isNotEmpty) ...[
          const SizedBox(height: 32),
          _AiTagsSection(
            tags: _aiTags,
            isLoading: _analyzingImages,
            onRemove: _removeTag,
          ),
        ],
      ],
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }

  Widget _buildDetailsStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      children: [
        GestureDetector(
          onTap: () {
            if (_isListening) {
              _stopListeningAndParse();
            } else {
              _initAndListen();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isListening 
                  ? [Colors.redAccent, Colors.red.shade900] 
                  : [AppColors.jadePrimary, Colors.teal.shade700],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (_isListening ? Colors.redAccent : AppColors.jadePrimary).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: _speechParsing
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _speechParsing ? 'AI is parsing your voice...' : _isListening ? 'Tap to Stop Recording' : 'Quick Voice Report',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _speechParsing ? 'Reading your campus speech details...' : _isListening ? 'Speaking... Tap when done' : 'Speak naturally to auto-fill this form!',
                        style: GoogleFonts.inter(color: Colors.white.withOpacity(0.85), fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate(onPlay: (controller) => _isListening ? controller.repeat(reverse: true) : null).scaleXY(begin: 1.0, end: _isListening ? 1.03 : 1.0, duration: 800.ms),
        const SizedBox(height: 24),
        
        _PremiumSectionLabel(label: 'Report Type'),
        const SizedBox(height: 8),
        _TypeToggle(selected: _type, onChanged: (t) { if (mounted) setState(() => _type = t); }),
        const SizedBox(height: 24),

        _PremiumSectionLabel(label: 'Item Title'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleCtrl,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 50,
          style: GoogleFonts.plusJakartaSans(fontSize: 15),
          decoration: InputDecoration(
            hintText: _type == 'lost' ? 'e.g. Black leather wallet' : 'e.g. Found blue water bottle',
            filled: true,
            fillColor: AppColors.surface(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),

        _PremiumSectionLabel(label: 'Description'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descCtrl,
          maxLines: 3,
          maxLength: 500,
          style: GoogleFonts.plusJakartaSans(fontSize: 15),
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Provide details such as color, brand, distinct marks...',
            filled: true,
            fillColor: AppColors.surface(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),

        _PremiumSectionLabel(label: 'Date & Location'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDateTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _lostDateTime == null ? 'Select date and time' : '${AppDateUtils.friendlyDate(_lostDateTime!)} at ${_lostTime?.format(context) ?? ''}',
                    style: GoogleFonts.inter(fontSize: 14, color: _lostDateTime == null ? AppColors.textHint(context) : AppColors.textPrimary(context)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _buildingCtrl,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.plusJakartaSans(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Building (e.g. Main Library)',
            filled: true,
            fillColor: AppColors.surface(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(12)),
                child: DropdownButton<int>(
                  value: _floor,
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary(context), fontSize: 14),
                  items: List.generate(10, (i) => DropdownMenuItem(value: i, child: Text('Floor $i'))),
                  onChanged: (v) { if (v != null && mounted) setState(() => _floor = v); },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                menuMaxHeight: 180,
                isExpanded: true,
                value: MapEngineService.instance.isInitialized && MapEngineService.instance.getRoomsOnFloor(1).any((r) => r.roomNumber == _roomCtrl.text) ? _roomCtrl.text : null,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                hint: Text('Select Room', style: GoogleFonts.inter(color: AppColors.textHint(context), fontSize: 13)),
                items: MapEngineService.instance.isInitialized ? MapEngineService.instance.getRoomsOnFloor(1).where((r) => r.type != RoomType.hallway).map((r) => DropdownMenuItem(value: r.roomNumber, child: Text(r.roomNumber, style: GoogleFonts.plusJakartaSans(fontSize: 13)))).toList() : [],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _roomCtrl.text = val;
                      _buildingCtrl.text = "Liaquat Block";
                      _floor = 1;
                      final matched = MapEngineService.instance.getRoomsOnFloor(1).firstWhere((r) => r.roomNumber == val);
                      final center = MapEngineService.instance.getRoomCenter(matched);
                      _indoorX = center.dx;
                      _indoorY = center.dy;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }

  Widget _buildSecurityStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 120),
      children: [
        Icon(Icons.security_rounded, size: 64, color: AppColors.jadePrimary),
        const SizedBox(height: 24),
        Text(
          'Secure this claim.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2, letterSpacing: -0.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Set a distinct security question only the real owner would know. This automatically filters out scammers.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary(context)),
        ),
        const SizedBox(height: 40),
        _PremiumSectionLabel(label: 'Security Question (Optional)'),
        const SizedBox(height: 12),
        TextFormField(
          controller: _secretQuestionCtrl,
          style: GoogleFonts.plusJakartaSans(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'e.g. What color is the keychain?',
            filled: true,
            fillColor: AppColors.surface(context),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
        const SizedBox(height: 60),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.jadePrimary,
              elevation: 4,
              shadowColor: AppColors.jadePrimary.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: _isSubmitting
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : Text(
                    widget.postToEdit != null ? 'Save Changes' : 'Publish Report',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
                  ),
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }
  Widget _buildListeningOverlay() {

    return Positioned.fill(

      child: Container(

        color: Colors.black.withOpacity(0.85),

        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Container(

              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(

                color: Colors.redAccent.withOpacity(0.15),

                shape: BoxShape.circle,

              ),

              child: const Icon(Icons.mic_rounded, color: Colors.redAccent, size: 48),

            ).animate(onPlay: (controller) => controller.repeat(reverse: true))

             .scaleXY(begin: 1.0, end: 1.15, duration: 800.ms, curve: Curves.easeInOut),

            const SizedBox(height: 24),

            Text(

              'Listening...',

              style: GoogleFonts.plusJakartaSans(

                fontSize: 22,

                fontWeight: FontWeight.w800,

                color: Colors.white,

              ),

            ),

            const SizedBox(height: 12),

            Text(

              'Describe your lost or found item naturally, including building, floor, room, or any physical details.',

              textAlign: TextAlign.center,

              style: GoogleFonts.inter(

                fontSize: 13,

                color: Colors.white70,

                height: 1.4,

              ),

            ),

            const SizedBox(height: 40),

            Container(

              padding: const EdgeInsets.all(20),

              width: double.infinity,

              decoration: BoxDecoration(

                color: Colors.white.withOpacity(0.1),

                borderRadius: BorderRadius.circular(16),

                border: Border.all(color: Colors.white.withOpacity(0.15)),

              ),

              child: Text(

                _speechText.isEmpty ? 'Say something...' : '"$_speechText"',

                textAlign: TextAlign.center,

                style: GoogleFonts.plusJakartaSans(

                  fontSize: 15,

                  fontWeight: FontWeight.w600,

                  color: _speechText.isEmpty ? Colors.white.withOpacity(0.55) : Colors.white,

                  fontStyle: _speechText.isEmpty ? FontStyle.italic : FontStyle.normal,

                ),

              ),

            ),

            const SizedBox(height: 40),

            ElevatedButton(

              onPressed: _stopListeningAndParse,

              style: ElevatedButton.styleFrom(

                backgroundColor: Colors.redAccent,

                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),

                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

              ),

              child: Text(

                'Done speaking',

                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),

              ),

            ),

            const SizedBox(height: 24),

            Text(

              '— OR DEMO WITH SIMULATOR —',

              style: GoogleFonts.plusJakartaSans(

                color: Colors.white38,

                fontSize: 10,

                fontWeight: FontWeight.w800,

                letterSpacing: 1.5,

              ),

            ),

            const SizedBox(height: 12),

            SingleChildScrollView(

              scrollDirection: Axis.horizontal,

              child: Row(

                children: [

                  _PresetChip(

                    label: 'Preset 1: Lost MacBook',

                    onPressed: () {

                      setState(() {

                        _speechText = 'I lost my silver Apple MacBook Pro in the Software Engineering Lab inside the Engineering Block.';

                      });

                      _stopListeningAndParse();

                    },

                  ),

                  const SizedBox(width: 8),

                  _PresetChip(

                    label: 'Preset 2: Found Wallet',

                    onPressed: () {

                      setState(() {

                        _speechText = 'I found a black leather wallet containing a student ID card on the 1st floor of Liaquat Block near Room 102.';

                      });

                      _stopListeningAndParse();

                    },

                  ),

                  const SizedBox(width: 8),

                  _PresetChip(

                    label: 'Preset 3: Found Keys',

                    onPressed: () {

                      setState(() {

                        _speechText = 'Found a bunch of keys with a red keychain in the cafeteria of the Quaid Block.';

                      });

                      _stopListeningAndParse();

                    },

                  ),

                ],

              ),

            ),

          ],

        ),

      ).animate().fadeIn(duration: 200.ms),

    );

  }



  Widget _buildParsingOverlay() {

    return Positioned.fill(

      child: Container(

        color: Colors.black.withOpacity(0.6),

        child: Center(

          child: Container(

            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),

            decoration: BoxDecoration(

              color: AppColors.card(context),

              borderRadius: BorderRadius.circular(20),

              boxShadow: [

                BoxShadow(

                  color: Colors.black26,

                  blurRadius: 20,

                  offset: const Offset(0, 10),

                ),

              ],

            ),

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                const CircularProgressIndicator(),

                const SizedBox(height: 20),

                Text(

                  'Gemini AI parsing your voice...',

                  style: GoogleFonts.plusJakartaSans(

                    fontSize: 14,

                    fontWeight: FontWeight.bold,

                    color: AppColors.textPrimary(context),

                  ),

                ),

              ],

            ),

          ),

        ),

      ).animate().fadeIn(duration: 200.ms),

    );

  }

}



class _PremiumSectionCard extends StatelessWidget {

  const _PremiumSectionCard({

    required this.stepNumber,

    required this.title,

    required this.child,

  });



  final int stepNumber;

  final String title;

  final Widget child;



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: AppColors.cardBg(context),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: AppColors.border(context), width: 1.2),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Container(

                width: 24,

                height: 24,

                decoration: BoxDecoration(

                  color: AppColors.jadePrimary.withOpacity(0.12),

                  shape: BoxShape.circle,

                ),

                alignment: Alignment.center,

                child: Text(

                  stepNumber.toString(),

                  style: GoogleFonts.plusJakartaSans(

                    fontWeight: FontWeight.bold,

                    color: AppColors.jadePrimary,

                    fontSize: 12,

                  ),

                ),

              ),

              const SizedBox(width: 8),

              Text(

                title,

                style: GoogleFonts.plusJakartaSans(

                  fontWeight: FontWeight.bold,

                  fontSize: 16,

                  color: AppColors.textPrimary(context),

                ),

              ),

            ],

          ),

          const SizedBox(height: 16),

          child,

        ],

      ),

    );

  }

}



class _TypeToggle extends StatelessWidget {

  const _TypeToggle({required this.selected, required this.onChanged});



  final String selected;

  final ValueChanged<String> onChanged;



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(

        color: AppColors.surface(context),

        borderRadius: BorderRadius.circular(16),

      ),

      child: Row(

        children: [

          _ToggleOption(

            label: 'Lost Item',

            icon: Icons.search_rounded,

            isSelected: selected == 'lost',

            selectedColor: AppColors.lostAlert,

            onTap: () => onChanged('lost'),

          ),

          _ToggleOption(

            label: 'Found Item',

            icon: Icons.check_circle_outline,

            isSelected: selected == 'found',

            selectedColor: AppColors.foundSuccess,

            onTap: () => onChanged('found'),

          ),

        ],

      ),

    );

  }

}



class _ToggleOption extends StatelessWidget {

  const _ToggleOption({

    required this.label,

    required this.icon,

    required this.isSelected,

    required this.selectedColor,

    required this.onTap,

  });



  final String label;

  final IconData icon;

  final bool isSelected;

  final Color selectedColor;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    return Expanded(

      child: GestureDetector(

        onTap: onTap,

        child: AnimatedContainer(

          duration: const Duration(milliseconds: 250),

          curve: Curves.easeOutCubic,

          padding: const EdgeInsets.symmetric(vertical: 12),

          decoration: BoxDecoration(

            color: isSelected ? selectedColor : Colors.transparent,

            borderRadius: BorderRadius.circular(12),

            boxShadow: isSelected

                ? [

                    BoxShadow(

                      color: selectedColor.withOpacity(0.35),

                      blurRadius: 10,

                      offset: const Offset(0, 3),

                    ),

                  ]

                : [],

          ),

          child: Row(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              Icon(

                icon,

                color: isSelected ? Colors.white : AppColors.textSecondary(context),

                size: 18,

              ),

              const SizedBox(width: 8),

              Text(

                label,

                textAlign: TextAlign.center,

                style: GoogleFonts.plusJakartaSans(

                  fontSize: 14,

                  fontWeight: FontWeight.bold,

                  color: isSelected ? Colors.white : AppColors.textSecondary(context),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}



class _ImagePicker extends StatelessWidget {

  const _ImagePicker({

    required this.images,

    required this.existingUrls,

    required this.onPickGallery,

    required this.onPickCamera,

    required this.onRemove,

    required this.onRemoveExisting,

    this.video,

    this.onPickVideo,

    this.onRemoveVideo,

  });



  final List<File> images;

  final List<String> existingUrls;

  final VoidCallback onPickGallery;

  final VoidCallback onPickCamera;

  final ValueChanged<int> onRemove;

  final ValueChanged<int> onRemoveExisting;

  final File? video;

  final VoidCallback? onPickVideo;

  final VoidCallback? onRemoveVideo;



  @override

  Widget build(BuildContext context) {

    return SizedBox(

      height: 100,

      child: ListView(

        scrollDirection: Axis.horizontal,

        children: [

          if (video == null && images.length + existingUrls.length < 4) ...[

            _AddButton(

              icon: Icons.photo_library_outlined,

              label: 'Gallery',

              onTap: onPickGallery,

            ),

            const SizedBox(width: 10),

            _AddButton(

              icon: Icons.camera_alt_outlined,

              label: 'Camera',

              onTap: onPickCamera,

            ),

            const SizedBox(width: 10),

            if (onPickVideo != null) ...[

              _AddButton(

                icon: Icons.video_call_outlined,

                label: 'Video',

                onTap: onPickVideo!,

              ),

              const SizedBox(width: 10),

            ],

          ],

          if (video != null) ...[

            Padding(

              padding: const EdgeInsets.only(right: 10),

              child: Stack(

                children: [

                  ClipRRect(

                    borderRadius: BorderRadius.circular(14),

                    child: Container(

                      width: 100,

                      height: 100,

                      color: Colors.black87,

                      alignment: Alignment.center,

                      child: Column(

                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [

                          const Icon(Icons.play_circle_fill_rounded, color: Colors.tealAccent, size: 36),

                          const SizedBox(height: 4),

                          Text(

                            'Video Selected',

                            style: GoogleFonts.plusJakartaSans(

                              color: Colors.white,

                              fontSize: 10,

                              fontWeight: FontWeight.bold,

                            ),

                          ),

                        ],

                      ),

                    ),

                  ),

                  Positioned(

                    top: 4,

                    right: 4,

                    child: GestureDetector(

                      onTap: onRemoveVideo,

                      child: Container(

                        padding: const EdgeInsets.all(4),

                        decoration: const BoxDecoration(

                          color: Colors.black54,

                          shape: BoxShape.circle,

                        ),

                        child: const Icon(

                          Icons.close_rounded,

                          color: Colors.white,

                          size: 14,

                        ),

                      ),

                    ),

                  ),

                ],

              ),

            ),

          ],

          ...existingUrls.asMap().entries.map(

            (e) => Padding(

              padding: const EdgeInsets.only(right: 10),

              child: Stack(

                children: [

                  ClipRRect(

                    borderRadius: BorderRadius.circular(14),

                    child: Image.network(

                      e.value,

                      width: 100,

                      height: 100,

                      fit: BoxFit.cover,

                    ),

                  ),

                  Positioned(

                    top: 4,

                    right: 4,

                    child: GestureDetector(

                      onTap: () => onRemoveExisting(e.key),

                      child: Container(

                        padding: const EdgeInsets.all(4),

                        decoration: const BoxDecoration(

                          color: Colors.black54,

                          shape: BoxShape.circle,

                        ),

                        child: const Icon(

                          Icons.close_rounded,

                          color: Colors.white,

                          size: 14,

                        ),

                      ),

                    ),

                  ),

                ],

              ),

            ),

          ),

          ...images.asMap().entries.map(

            (e) => Padding(

              padding: const EdgeInsets.only(right: 10),

              child: Stack(

                children: [

                  ClipRRect(

                    borderRadius: BorderRadius.circular(14),

                    child: Image.file(

                      e.value,

                      width: 100,

                      height: 100,

                      fit: BoxFit.cover,

                    ),

                  ),

                  Positioned(

                    top: 4,

                    right: 4,

                    child: GestureDetector(

                      onTap: () => onRemove(e.key),

                      child: Container(

                        padding: const EdgeInsets.all(4),

                        decoration: const BoxDecoration(

                          color: Colors.black54,

                          shape: BoxShape.circle,

                        ),

                        child: const Icon(

                          Icons.close_rounded,

                          color: Colors.white,

                          size: 14,

                        ),

                      ),

                    ),

                  ),

                ],

              ),

            ),

          ),

        ],

      ),

    );

  }

}



class _AddButton extends StatelessWidget {

  const _AddButton({

    required this.icon,

    required this.label,

    required this.onTap,

  });



  final IconData icon;

  final String label;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        width: 100,

        height: 100,

        decoration: BoxDecoration(

          color: AppColors.surface(context),

          borderRadius: BorderRadius.circular(14),

          border: Border.all(color: AppColors.border(context), width: 1.5),

        ),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 26),

            const SizedBox(height: 6),

            Text(

              label,

              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context)),

            ),

          ],

        ),

      ),

    );

  }

}



class _AiTagsSection extends StatelessWidget {

  const _AiTagsSection({

    required this.tags,

    required this.isLoading,

    required this.onRemove,

  });



  final List<String> tags;

  final bool isLoading;

  final ValueChanged<String> onRemove;



  @override

  Widget build(BuildContext context) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Row(

          children: [

            const Text('✨', style: TextStyle(fontSize: 14)),

            const SizedBox(width: 6),

            Text(

              isLoading ? 'AI is scanning your image...' : 'AI Generated Tags',

              style: GoogleFonts.plusJakartaSans(

                fontSize: 13,

                fontWeight: FontWeight.bold,

                color: AppColors.textPrimary(context),

              ),

            ),

            if (isLoading) ...[

              const SizedBox(width: 10),

              SizedBox(

                width: 14,

                height: 14,

                child: CircularProgressIndicator(

                  strokeWidth: 2,

                  color: Theme.of(context).colorScheme.primary,

                ),

              ),

            ],

          ],

        ),

        const SizedBox(height: 8),

        if (tags.isNotEmpty)

          Wrap(

            spacing: 8,

            runSpacing: 6,

            children: tags

                .map(

                  (tag) => Container(

                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

                    decoration: BoxDecoration(

                      color: AppColors.surface(context),

                      borderRadius: BorderRadius.circular(20),

                    ),

                    child: Row(

                      mainAxisSize: MainAxisSize.min,

                      children: [

                        Text(

                          tag,

                          style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textPrimary(context)),

                        ),

                        const SizedBox(width: 4),

                        GestureDetector(

                          onTap: () => onRemove(tag),

                          child: Icon(Icons.close_rounded, size: 14, color: AppColors.textSecondary(context)),

                        ),

                      ],

                    ),

                  ),

                )

                .toList(),

          ),

      ],

    );

  }

}



class _PremiumSectionLabel extends StatelessWidget {

  const _PremiumSectionLabel({required this.label});



  final String label;



  @override

  Widget build(BuildContext context) {

    return Text(

      label,

      style: GoogleFonts.plusJakartaSans(

        fontSize: 13.5,

        fontWeight: FontWeight.w600,

        color: AppColors.textPrimary(context),

      ),

    );

  }

}



class _PresetChip extends StatelessWidget {

  const _PresetChip({required this.label, required this.onPressed});

  final String label;

  final VoidCallback onPressed;



  @override

  Widget build(BuildContext context) {

    return ActionChip(

      onPressed: onPressed,

      backgroundColor: Colors.white.withOpacity(0.12),

      side: BorderSide(color: Colors.white.withOpacity(0.15)),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

      label: Text(

        label,

        style: GoogleFonts.plusJakartaSans(

          color: Colors.white,

          fontSize: 12,

          fontWeight: FontWeight.w600,

        ),

      ),

    );

  }

}

