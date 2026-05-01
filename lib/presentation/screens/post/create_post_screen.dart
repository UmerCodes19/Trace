import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  List<String> _aiTags = [];
  bool _analyzingImages = false;
  bool _isSubmitting = false;

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
        _images.isNotEmpty;
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
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _buildingCtrl.dispose();
    _roomCtrl.dispose();
    _secretQuestionCtrl.dispose();
    super.dispose();
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

    if (_images.isEmpty && _existingImageUrls.isEmpty) {
      if (mounted) showAppSnack(context, 'Please add at least one image');
      return;
    }

    if (mounted) setState(() => _isSubmitting = true);

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

      final post = SimplePostModel(
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
      if (mounted) {
        showAppSnack(context, 'Failed to submit post: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      if (_hasStartedTyping()) {
                        final proceed = await _showDiscardConfirm();
                        if (proceed == true && mounted) context.go('/home');
                      } else {
                        context.go('/home');
                      }
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.postToEdit != null ? 'Edit Report' : 'New Report',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.postToEdit != null ? 'Save' : 'Post',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                  children: [
                    _PremiumSectionCard(
                      stepNumber: 1,
                      title: 'Report Type',
                      child: _TypeToggle(
                        selected: _type,
                        onChanged: (t) {
                          if (mounted) setState(() => _type = t);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PremiumSectionCard(
                      stepNumber: 2,
                      title: 'Item Details',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PremiumSectionLabel(label: 'Item Title'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleCtrl,
                            textCapitalization: TextCapitalization.sentences,
                            maxLength: 50,
                            style: GoogleFonts.plusJakartaSans(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: _type == 'lost'
                                  ? 'e.g. Black leather wallet'
                                  : 'e.g. Found blue water bottle',
                              hintStyle: GoogleFonts.inter(color: AppColors.textHint(context)),
                              filled: true,
                              fillColor: AppColors.surface(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Title is required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _PremiumSectionLabel(label: 'Description'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descCtrl,
                            maxLines: 4,
                            maxLength: 500,
                            style: GoogleFonts.plusJakartaSans(fontSize: 15),
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Provide details such as color, brand, distinct marks...',
                              hintStyle: GoogleFonts.inter(color: AppColors.textHint(context)),
                              filled: true,
                              fillColor: AppColors.surface(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            validator: (v) => (v == null || v.trim().length < 10)
                                ? 'Please provide more detail (min 10 chars)'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PremiumSectionCard(
                      stepNumber: 3,
                      title: 'Date & Location',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PremiumSectionLabel(label: _type == 'lost' ? 'When was it lost?' : 'When was it found?'),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _selectDateTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _lostDateTime == null
                                          ? 'Select date and time'
                                          : '${AppDateUtils.friendlyDate(_lostDateTime!)} at ${_lostTime?.format(context) ?? ''}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: _lostDateTime == null
                                            ? AppColors.textHint(context)
                                            : AppColors.textPrimary(context),
                                      ),
                                    ),
                                  ),
                                  if (_lostDateTime != null)
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _lostDateTime = null;
                                          _lostTime = null;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _PremiumSectionLabel(label: 'Building / Area'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _buildingCtrl,
                            textCapitalization: TextCapitalization.words,
                            style: GoogleFonts.plusJakartaSans(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'e.g. Main Library, Department Block',
                              hintStyle: GoogleFonts.inter(color: AppColors.textHint(context)),
                              filled: true,
                              fillColor: AppColors.surface(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Building is required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Floor',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface(context),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: DropdownButton<int>(
                                        value: _floor,
                                        isExpanded: true,
                                        underline: const SizedBox(),
                                        style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary(context), fontSize: 14),
                                        items: List.generate(
                                          10,
                                          (i) => DropdownMenuItem(
                                            value: i,
                                            child: Text('Floor $i'),
                                          ),
                                        ),
                                        onChanged: (v) {
                                          if (v != null && mounted) {
                                            setState(() => _floor = v);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Room (Optional)',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _roomCtrl,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'e.g. Room #3',
                                        hintStyle: GoogleFonts.inter(color: AppColors.textHint(context)),
                                        filled: true,
                                        fillColor: AppColors.surface(context),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PremiumSectionCard(
                      stepNumber: 4,
                      title: 'Media & Uploads',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PremiumSectionLabel(label: 'Photos (up to 4)'),
                          const SizedBox(height: 10),
                          _ImagePicker(
                            images: _images,
                            existingUrls: _existingImageUrls,
                            onPickGallery: () => _pickImages(ImageSource.gallery),
                            onPickCamera: () => _pickImages(ImageSource.camera),
                            onRemove: _removeImage,
                            onRemoveExisting: (i) {
                              if (mounted) setState(() => _existingImageUrls.removeAt(i));
                            },
                          ),
                          if (_analyzingImages || _aiTags.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _AiTagsSection(
                              tags: _aiTags,
                              isLoading: _analyzingImages,
                              onRemove: _removeTag,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PremiumSectionCard(
                      stepNumber: 5,
                      title: '🔒 Security Gatekeeper',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set a distinct security question only the real owner would know. This prevents bad claims automatically.',
                            style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary(context), height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _secretQuestionCtrl,
                            style: GoogleFonts.plusJakartaSans(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'e.g. What color is the keychain?',
                              hintStyle: GoogleFonts.inter(color: AppColors.textHint(context)),
                              filled: true,
                              fillColor: AppColors.surface(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.jadePrimary,
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                widget.postToEdit != null ? 'Save Changes' : 'Post Report',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
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
      ),
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
  });

  final List<File> images;
  final List<String> existingUrls;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onRemoveExisting;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (images.length + existingUrls.length < 4) ...[
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
