import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/avatar_presets.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/utils/avatar_harmony.dart';
import '../../widgets/common/glass_card.dart';
import '../../avatar_engine/models/avatar_config.dart';
import '../../avatar_engine/ui/interactive_avatar.dart';
import '../../avatar_engine/audio/music_sync_engine.dart';
import '../../avatar_engine/audio/music_state.dart';

class AvatarBuilderScreen extends ConsumerStatefulWidget {
  const AvatarBuilderScreen({super.key});
  @override
  ConsumerState<AvatarBuilderScreen> createState() => _AvatarBuilderScreenState();
}

class _AvatarBuilderScreenState extends ConsumerState<AvatarBuilderScreen> with TickerProviderStateMixin {
  // Core identity traits
  int _hair = 1, _eyes = 0, _mouth = 0, _acc = 0, _facialHair = 0, _details = 0;
  int _eyebrows = 0, _noseStyle = 0, _outfit = 0, _earring = 0, _bgStyle = 0;
  int _vibe = 0; // New Vibe tracking for Phase 3
  String _bgColor = '#FF6B6B', _skinColor = '#FFDBB5', _hairColor = '#2D3748', _outfitColor = '#4A5568';
  bool _isSaving = false;

  // Cinematic effects
  late AnimationController _pedestalController;
  int _revealToken = 0; // Triggers pop/morph on identity reveal

  // Paint studio
  bool _isPaintingMode = false;
  List<PaintStroke> _customStrokes = [];
  List<Offset> _currentStrokePoints = [];
  String _brushColor = '#E53E3E';
  double _brushWidth = 4.0;
  final List<String> _brushColors = ['#E53E3E', '#FF9500', '#FFCC00', '#4CD964', '#007AFF', '#5856D6', '#FFFFFF', '#000000'];

  // Tab controller
  late TabController _tabController;
  int _activeTab = 0;

  // Palette index
  int _paletteIndex = 0;
  
  // Music Deck Local State
  bool _isMusicExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // 6 Tabs now (Presets, Vibes, Gen, Skin, Paint...)
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() => _activeTab = _tabController.index);
    });
    
    _pedestalController = AnimationController(
      vsync: this, duration: const Duration(seconds: 6),
    )..repeat();

    _loadExistingAvatar();
  }

  @override
  void dispose() {
    try {
      ref.read(musicSyncProvider.notifier).stop();
    } catch (_) { /* Safe release if disposed earlier */ }
    
    _tabController.dispose();
    _pedestalController.dispose();
    super.dispose();
  }

  void _loadExistingAvatar() async {
    final user = await ref.read(authServiceProvider).getCurrentUser();
    if (user != null && user.photoURL != null && user.photoURL!.startsWith('{')) {
      final c = AvatarConfig.fromJson(user.photoURL!);
      setState(() {
        _hair = c.hair; _eyes = c.eyes; _mouth = c.mouth; _acc = c.acc;
        _facialHair = c.facialHair; _details = c.details; _eyebrows = c.eyebrows;
        _noseStyle = c.noseStyle; _outfit = c.outfit; _earring = c.earring;
        _bgStyle = c.bgStyle; _bgColor = c.bgColor; _skinColor = c.skinColor;
        _hairColor = c.hairColor; _outfitColor = c.outfitColor;
        _customStrokes = c.customStrokes;
        _vibe = c.vibe;
      });
    }
  }

  AvatarConfig get _currentConfig => AvatarConfig(
    hair: _hair, eyes: _eyes, mouth: _mouth, acc: _acc,
    facialHair: _facialHair, details: _details, eyebrows: _eyebrows,
    noseStyle: _noseStyle, outfit: _outfit, earring: _earring,
    bgStyle: _bgStyle, bgColor: _bgColor, skinColor: _skinColor,
    hairColor: _hairColor, outfitColor: _outfitColor, customStrokes: _customStrokes,
    vibe: _vibe,
  );

  void _applyPreset(StarterIdentity preset) {
    HapticFeedback.mediumImpact();
    final c = preset.config;
    setState(() {
      _hair = c['hair'] ?? _hair; _eyes = c['eyes'] ?? _eyes;
      _mouth = c['mouth'] ?? _mouth; _acc = c['acc'] ?? _acc;
      _facialHair = c['facialHair'] ?? _facialHair; _details = c['details'] ?? _details;
      _eyebrows = c['eyebrows'] ?? _eyebrows; _noseStyle = c['noseStyle'] ?? _noseStyle;
      _outfit = c['outfit'] ?? _outfit; _bgStyle = c['bgStyle'] ?? _bgStyle;
      _bgColor = c['bgColor'] ?? _bgColor; _skinColor = c['skinColor'] ?? _skinColor;
      _hairColor = c['hairColor'] ?? _hairColor; _outfitColor = c['outfitColor'] ?? _outfitColor;
      _vibe = c['vibe'] ?? _vibe;
      _revealToken++; // trigger cinematic transition
    });
  }

  void _randomize() {
    HapticFeedback.lightImpact();
    final newConfig = AvatarHarmony.generateHarmonious(Random());
    setState(() {
      _hair = newConfig['hair']; _eyes = newConfig['eyes'];
      _mouth = newConfig['mouth']; _acc = newConfig['acc'];
      _facialHair = newConfig['facialHair']; _details = newConfig['details'];
      _eyebrows = newConfig['eyebrows']; _noseStyle = newConfig['noseStyle'];
      _outfit = newConfig['outfit']; _bgStyle = newConfig['bgStyle'];
      _bgColor = newConfig['bgColor']; _skinColor = newConfig['skinColor'];
      _hairColor = newConfig['hairColor']; _outfitColor = newConfig['outfitColor'];
      _revealToken++; // Enable satisfying elastic bounce on randomize
    });
  }

  void _saveAvatar() async {
    setState(() => _isSaving = true);
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      final jsonStr = _currentConfig.toJson();
      final updatedUser = user.copyWith(photoURL: jsonStr);
      await ref.read(authServiceProvider).updateUserProfile(user.uid, updatedUser.toMap());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identity locked! ✨')),
        );
        context.pop();
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      appBar: AppBar(
        title: Text('Identity Lab', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent, elevation: 0,
        foregroundColor: AppColors.textPrimary(context),
        actions: [
          IconButton(
            icon: Icon(Icons.casino_rounded, color: accent, size: 22),
            tooltip: 'Randomize',
            onPressed: _randomize,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
        child: Column(
          children: [
            // Live Avatar Preview
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Hero(
                  tag: 'avatar_creator_canvas',
                  child: SizedBox(
                    height: 200, width: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cinematic Pedestal
                        // Pedestal removed by user request
                        // Identity Morph Reveal Switcher
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, anim) => ScaleTransition(
                            scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: Container(
                            key: ValueKey('reveal_$_revealToken'),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), blurRadius: 28, offset: const Offset(0, 8)),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                InteractiveAvatarView(config: _currentConfig, size: 160),
                                if (_isPaintingMode)
                                  Positioned.fill(
                                    child: ClipOval(
                                      child: GestureDetector(
                                        onPanStart: (d) {
                                          final p = d.localPosition;
                                          setState(() {
                                            _currentStrokePoints = [Offset(p.dx / 160, p.dy / 160)];
                                            _customStrokes = List.from(_customStrokes)
                                              ..add(PaintStroke(points: _currentStrokePoints, color: _brushColor, width: _brushWidth));
                                          });
                                        },
                                        onPanUpdate: (d) {
                                          final p = d.localPosition;
                                          if (p.dx >= 0 && p.dx <= 160 && p.dy >= 0 && p.dy <= 160) {
                                            setState(() {
                                              _currentStrokePoints.add(Offset(p.dx / 160, p.dy / 160));
                                              _customStrokes[_customStrokes.length - 1] = PaintStroke(
                                                points: List.from(_currentStrokePoints), color: _brushColor, width: _brushWidth,
                                              );
                                            });
                                          }
                                        },
                                        onPanEnd: (_) => _currentStrokePoints = [],
                                        child: Container(color: Colors.transparent, width: 160, height: 160),
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
                ),
              ),
            ),

            // Avatar Actions Row (Paint Studio + Music Sync)
            if (!_isPaintingMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isPaintingMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accent.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.brush_rounded, color: accent, size: 14),
                            const SizedBox(width: 5),
                            Text('Paint Studio', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11.5, color: accent)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // --- DYNAMIC MUSIC SYNC INJECTION WITH TOGGLE ---
                    Consumer(
                      builder: (context, ref, _) {
                        final music = ref.watch(musicSyncProvider);
                        final isMusicPlaying = music.isPlaying;
                        final isMusicActive = music.fileName != null;
                        final notifier = ref.read(musicSyncProvider.notifier);

                        return GestureDetector(
                          onTap: () async {
                            if (isMusicActive) {
                              notifier.stop();
                              return;
                            }
                            try {
                              final res = await FilePicker.pickFiles(type: FileType.audio);
                              if (res != null && res.files.single.path != null) {
                                notifier.playFile(res.files.single.path!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🎵 Vibe Sync Activated!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                                    backgroundColor: Colors.deepPurpleAccent,
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (_) {}
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isMusicActive 
                                  ? [Colors.redAccent, Colors.orangeAccent]
                                  : [Colors.deepPurpleAccent, Colors.purple.shade400]
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: (isMusicActive ? Colors.redAccent : Colors.purple).withValues(alpha: 0.3), 
                                  blurRadius: 8, 
                                  offset: const Offset(0, 3)
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isMusicActive ? Icons.stop_circle_rounded : Icons.music_note_rounded, 
                                  color: Colors.white, size: 14
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isMusicActive ? 'Stop Vibe' : 'Drop a Beat', 
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.white)
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    ),
                  ],
                ),
              )
            else
              _buildPaintToolbar(),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary(context),
                labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 10.5),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 10.5),
                indicator: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(12)),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                splashBorderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Vibes', height: 32),
                  Tab(text: 'Presets', height: 32),
                  Tab(text: 'Face', height: 32),
                  Tab(text: 'Hair', height: 32),
                  Tab(text: 'Outfit', height: 32),
                  Tab(text: 'Colors', height: 32),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVibeTab(),
                  _buildPresetsTab(),
                  _buildFaceTab(),
                  _buildIdentityTab(), // rename logic: identity usually meant hair
                  _buildStyleTab(),
                  _buildColorsTab(),
                ],
              ),
            ),

            // Save Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: GestureDetector(
                onTap: _isSaving ? null : _saveAvatar,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [accent, accent.withOpacity(0.85)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: accent.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  alignment: Alignment.center,
                  child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Lock Identity', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
      _buildMusicStatsDeck(),
    ],
  ),
);
}

  // ─── Tab Builders ───────────────────────────────────────────────────────────

  Widget _buildVibeTab() {
    final vibeNames = ['Balanced', 'Calm', 'Chaotic', 'Dreamcore', 'Night Owl', 'Techwear'];
    final vibeDescs = [
      'Neutral cadence & smooth idle motion.',
      'Slower pacing, deep gentle breathing loop.',
      'Higher intensity with alert fast blinking.',
      'Slow vertical physics & soft easing cycles.',
      'Smooth idle cadence with double-blink spikes.',
      'Robotic linear physics & exact timing loops.'
    ];

    return _tabContent([
      _section('Select Psychological Vibe', _chipRow('vibe', 6, vibeNames, _vibe, (i) {
        setState(() {
          _vibe = i;
          // Removed _revealToken++ to ensure animation continuity while tuning
        });
      })),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context).withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  vibeDescs[_vibe],
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textSecondary(context), fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildIdentityTab() {
    return _tabContent([
      _section('Hairstyle', _chipRow('hair', 24, [
        'Bald','Classic','Spiky','Curly','Cap','Afro','Bun','Long','Undercut','Braids','Band','Topknot',
        'Curtain','Buzz','Wolf','Box Braids','Shag','Pixie','Bob','Mohawk','Cornrows','Space Buns','Locs','Side Shave',
      ], _hair, (i) => setState(() => _hair = i))),
      _section('Facial Hair', _chipRow('facialHair', 5, ['Clean','Goatee','Full Beard','Stubble','Moustache'], _facialHair, (i) => setState(() => _facialHair = i))),
      _section('Eyebrows', _chipRow('eyebrows', 7, ['Default','Arched','Straight','Thick','Thin','Angry','Worried'], _eyebrows, (i) => setState(() => _eyebrows = i))),
    ]);
  }

  Widget _buildFaceTab() {
    return _tabContent([
      _section('Eyes', _chipRow('eyes', 11, ['Normal','Wink','Happy','Star','Anime','Squint','Sleepy','Fox','Doe','Hetero','Crescent'], _eyes, (i) => setState(() => _eyes = i))),
      _section('Mouth', _chipRow('mouth', 10, ['Smile','Surprised','Serious','Smirk','Laughing','Frown','Cat','Grin','Tongue','Whisper'], _mouth, (i) => setState(() => _mouth = i))),
      _section('Details', _chipRow('details', 3, ['None','Rosy Cheeks','Freckles'], _details, (i) => setState(() => _details = i))),
    ]);
  }

  Widget _buildStyleTab() {
    return _tabContent([
      _section('Outfit', _chipRow('outfit', 7, ['Tee','Hoodie','Jacket','Turtleneck','Tank','Shirt','Sweater'], _outfit, (i) => setState(() => _outfit = i))),
      _section('Accessories', _chipRow('acc', 11, ['None','Glasses','Shades','Eyepatch','Headset','Scar','Mask','Bandaid','Chain','AirPods','Nose Ring'], _acc, (i) => setState(() => _acc = i))),
      _section('Earrings', _chipRow('earring', 4, ['None','Stud','Hoop','Drop'], _earring, (i) => setState(() => _earring = i))),
      _section('Background', _chipRow('bgStyle', 4, ['Solid','Radial','Split','Glow'], _bgStyle, (i) => setState(() => _bgStyle = i))),
    ]);
  }

  Widget _buildColorsTab() {
    final palette = kCuratedPalettes[_paletteIndex];
    return _tabContent([
      // Palette selector
      _section('Color Palette', SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: kCuratedPalettes.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final p = kCuratedPalettes[i];
            final sel = i == _paletteIndex;
            return GestureDetector(
              onTap: () => setState(() => _paletteIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? Theme.of(context).colorScheme.primary : AppColors.surface(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: sel ? Colors.transparent : AppColors.border(context).withOpacity(0.4)),
                ),
                child: Text(p.name, style: GoogleFonts.plusJakartaSans(
                  fontWeight: sel ? FontWeight.bold : FontWeight.w600, fontSize: 12,
                  color: sel ? Colors.white : AppColors.textPrimary(context),
                )),
              ),
            );
          },
        ),
      )),
      _section('Skin', _colorRow(palette.skin, _skinColor, (c) => setState(() => _skinColor = c))),
      _section('Hair Color', _colorRow(palette.hair, _hairColor, (c) => setState(() => _hairColor = c))),
      _section('Outfit Color', _colorRow(palette.outfit, _outfitColor, (c) => setState(() => _outfitColor = c))),
      _section('Background', _colorRow(palette.bg, _bgColor, (c) => setState(() => _bgColor = c))),
    ]);
  }

  Widget _buildPresetsTab() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85,
      ),
      itemCount: kStarterIdentities.length,
      itemBuilder: (context, i) {
        final preset = kStarterIdentities[i];
        final previewConfig = AvatarConfig(
          hair: preset.config['hair'] ?? 1, eyes: preset.config['eyes'] ?? 0,
          mouth: preset.config['mouth'] ?? 0, acc: preset.config['acc'] ?? 0,
          facialHair: preset.config['facialHair'] ?? 0, details: preset.config['details'] ?? 0,
          eyebrows: preset.config['eyebrows'] ?? 0, noseStyle: preset.config['noseStyle'] ?? 0,
          outfit: preset.config['outfit'] ?? 0, bgColor: preset.config['bgColor'] ?? '#FF6B6B',
          skinColor: preset.config['skinColor'] ?? '#FFDBB5', hairColor: preset.config['hairColor'] ?? '#2D3748',
          outfitColor: preset.config['outfitColor'] ?? '#4A5568', bgStyle: preset.config['bgStyle'] ?? 0,
        );
        return GestureDetector(
          onTap: () => _applyPreset(preset),
          child: GlassCard(
            borderRadius: 20, elevation: 2,
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InteractiveAvatarView(config: previewConfig, size: 72, interactive: false),
                const SizedBox(height: 10),
                Text(preset.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Text(preset.name, style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.textPrimary(context),
                ), textAlign: TextAlign.center),
                const SizedBox(height: 2),
                Text(preset.tagline, style: GoogleFonts.inter(
                  fontSize: 9.5, color: AppColors.textSecondary(context), fontWeight: FontWeight.w500,
                ), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Shared Widgets ─────────────────────────────────────────────────────────

  Widget _tabContent(List<Widget> children) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      physics: const BouncingScrollPhysics(),
      children: children,
    );
  }

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary(context))),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _chipRow(String traitName, int count, List<String> labels, int selected, ValueChanged<int> onSelected) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final sel = selected == i;
          
          final harmony = AvatarHarmony.checkTraitChange(
            traitName: traitName, traitValue: i,
            hair: traitName == 'hair' ? i : _hair,
            acc: traitName == 'acc' ? i : _acc,
            outfit: traitName == 'outfit' ? i : _outfit,
            facialHair: traitName == 'facialHair' ? i : _facialHair,
          );
          
          final bool isBlocked = harmony == HarmonyLevel.blocked;
          final bool isWarned = harmony == HarmonyLevel.mild;

          return GestureDetector(
            onTap: isBlocked ? () { HapticFeedback.heavyImpact(); } : () { HapticFeedback.selectionClick(); onSelected(i); },
            child: Opacity(
              opacity: isBlocked ? 0.3 : (isWarned && !sel ? 0.6 : 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? Theme.of(context).colorScheme.primary : AppColors.surface(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isWarned && !sel ? Colors.orange.withOpacity(0.5) : (sel ? Colors.transparent : AppColors.border(context).withOpacity(0.4)),
                  ),
                ),
                child: Text(
                  labels[i],
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: sel ? FontWeight.bold : FontWeight.w600, fontSize: 12,
                    color: sel ? Colors.white : (isWarned && !sel ? Colors.orange : AppColors.textPrimary(context)),
                    decoration: isBlocked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _colorRow(List<String> colors, String selectedColor, ValueChanged<String> onSelected) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final hex = colors[i];
          final sel = hex.toLowerCase() == selectedColor.toLowerCase();
          final color = Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onSelected(hex); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: color, shape: BoxShape.circle,
                border: Border.all(color: sel ? AppColors.textPrimary(context) : Colors.white24, width: sel ? 3 : 1.5),
                boxShadow: sel ? [BoxShadow(color: color.withOpacity(0.45), blurRadius: 10)] : [],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaintToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border(context).withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 26,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _brushColors.length,
                  itemBuilder: (context, idx) {
                    final hex = _brushColors[idx];
                    final color = Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
                    final sel = hex == _brushColor;
                    return GestureDetector(
                      onTap: () => setState(() => _brushColor = hex),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle,
                          border: Border.all(color: sel ? AppColors.textPrimary(context) : Colors.white24, width: sel ? 2.5 : 1),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(icon: Icon(Icons.undo_rounded, size: 16, color: AppColors.textPrimary(context)), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () {
              if (_customStrokes.isNotEmpty) { setState(() => _customStrokes.removeLast()); HapticFeedback.lightImpact(); }
            }),
            const SizedBox(width: 6),
            IconButton(icon: const Icon(Icons.delete_sweep_rounded, size: 17, color: Colors.redAccent), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () {
              if (_customStrokes.isNotEmpty) { setState(() => _customStrokes.clear()); HapticFeedback.mediumImpact(); }
            }),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _isPaintingMode = false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.2))),
                child: Text('Done', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildMusicStatsDeck() {
    return Consumer(
      builder: (context, ref, _) {
        final music = ref.watch(musicSyncProvider);
        final notifier = ref.read(musicSyncProvider.notifier);
        if (music.fileName == null) return const SizedBox.shrink();

        final accent = Theme.of(context).colorScheme.primary;
        final double posMs = music.position.inMilliseconds.toDouble();
        final double durMs = music.duration.inMilliseconds.toDouble().clamp(1.0, double.infinity);
        final double progress = (posMs / durMs).clamp(0.0, 1.0);

        String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2,'0')}';

        return Positioned(
          bottom: 90, left: 16, right: 16,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context).withOpacity(0.75),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: accent.withOpacity(0.25), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header: Title + Expansion Toggle
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => notifier.pauseResume(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                              child: Icon(music.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 18, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(music.fileName!, 
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.textPrimary(context)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                                // 🚀 PERFORMANCE ISOLATED SPECTRUM: ONLY THIS TINY BUILDER REDRAWS, SAVING MASSIVE LAG!
                                const SizedBox(height: 4),
                                ValueListenableBuilder<double>(
                                  valueListenable: notifier.liveEnergyNotifier,
                                  builder: (context, energy, _) {
                                    return Container(
                                      height: 3,
                                      width: 100,
                                      alignment: Alignment.centerLeft,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 40),
                                        height: 3, 
                                        width: 100 * energy,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [accent, Colors.pinkAccent]),
                                          borderRadius: BorderRadius.circular(1.5),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(_isMusicExpanded ? Icons.expand_less_rounded : Icons.tune_rounded, size: 20, color: AppColors.textSecondary(context)),
                            onPressed: () => setState(() => _isMusicExpanded = !_isMusicExpanded),
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20, color: Colors.redAccent),
                            onPressed: () {
                              notifier.stop();
                              setState(() => _isMusicExpanded = false);
                            },
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                          )
                        ],
                      ),

                      // ELEGANTLY COLLAPSIBLE DETAILS
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 300),
                        crossFadeState: _isMusicExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        firstChild: const SizedBox.shrink(),
                        secondChild: Column(
                          children: [
                            const SizedBox(height: 16),
                            // Expanded Progress Scrubber
                            Row(
                              children: [
                                Text(_fmt(music.position), style: GoogleFonts.robotoMono(fontSize: 10, color: AppColors.textSecondary(context))),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                      activeTrackColor: accent, inactiveTrackColor: accent.withOpacity(0.15), thumbColor: accent,
                                    ),
                                    child: Slider(
                                      value: progress,
                                      onChanged: (v) => notifier.seek(Duration(milliseconds: (v * durMs).toInt())),
                                    ),
                                  ),
                                ),
                                Text(_fmt(music.duration), style: GoogleFonts.robotoMono(fontSize: 10, color: AppColors.textSecondary(context))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Sensitivity Slider (The detailed Tweak!)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('BOB INTENSITY', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.textPrimary(context))),
                                      Text('${(music.sensitivity * 100).toInt()}%', style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.orangeAccent)),
                                    ],
                                  ),
                                  SliderTheme(
                                    data: SliderThemeData(
                                      trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                      activeTrackColor: Colors.orangeAccent, inactiveTrackColor: Colors.orangeAccent.withOpacity(0.15), thumbColor: Colors.orangeAccent,
                                    ),
                                    child: Slider(
                                      value: music.sensitivity,
                                      min: 0.5, max: 2.5,
                                      onChanged: (v) => notifier.setSensitivity(v),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}

class PedestalPainter extends CustomPainter {
  final double rotation;
  final Color baseColor;
  PedestalPainter(this.rotation, this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..isAntiAlias = true;
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Inner glowing disc shadow
    final shadowRect = Rect.fromCenter(center: Offset(cx, cy + 4), width: size.width * 0.9, height: size.height * 0.4);
    paint.shader = RadialGradient(
      colors: [baseColor.withOpacity(0.4), baseColor.withOpacity(0.0)],
      stops: const [0.0, 1.0],
    ).createShader(shadowRect);
    canvas.drawOval(shadowRect, paint);

    // Main glowing edge rim ring
    paint.shader = null;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.5;
    final rimRect = Rect.fromCenter(center: Offset(cx, cy), width: size.width * 0.85, height: size.height * 0.35);
    
    final SweepGradient rimGrad = SweepGradient(
      colors: [Colors.white.withOpacity(0.0), baseColor.withOpacity(0.7), Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.0)],
      stops: const [0.0, 0.4, 0.6, 1.0],
      transform: GradientRotation(rotation * 2 * pi),
    );
    paint.shader = rimGrad.createShader(rimRect);
    canvas.drawOval(rimRect, paint);
  }

  @override
  bool shouldRepaint(covariant PedestalPainter oldDelegate) => oldDelegate.rotation != rotation || oldDelegate.baseColor != baseColor;
}
