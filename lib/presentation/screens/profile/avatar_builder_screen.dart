import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/profile/flutter_avatar.dart';

class AvatarBuilderScreen extends ConsumerStatefulWidget {
  const AvatarBuilderScreen({super.key});

  @override
  ConsumerState<AvatarBuilderScreen> createState() => _AvatarBuilderScreenState();
}

class _AvatarBuilderScreenState extends ConsumerState<AvatarBuilderScreen> {
  int _hair = 1;
  int _eyes = 0;
  int _mouth = 0;
  int _acc = 0;
  int _facialHair = 0;
  int _details = 0;
  String _bgColor = '#FF6B6B';
  String _skinColor = '#FFDBB5';
  String _hairColor = '#2D3748';
  String _outfitColor = '#4A5568';
  bool _isSaving = false;

  bool _isPaintingMode = false;
  List<PaintStroke> _customStrokes = [];
  List<Offset> _currentStrokePoints = [];
  String _brushColor = '#E53E3E';
  double _brushWidth = 4.0;

  final List<String> _brushColors = ['#E53E3E', '#FF9500', '#FFCC00', '#4CD964', '#007AFF', '#5856D6', '#FFFFFF', '#000000'];

  final List<String> _bgColors = ['#FF6B6B', '#4ECDC4', '#FFE66D', '#1A535C', '#A18CD1', '#FAD0C4', '#4FACFE', '#00F2FE', '#FF758C', '#2E2E2E'];
  final List<String> _skinColors = ['#FFDBB5', '#E0A96D', '#8D5524', '#F9C9B1', '#C68642', '#3C2F2F', '#FFF0E0', '#5c3826'];
  final List<String> _hairColors = ['#2D3748', '#1A202C', '#D69E2E', '#E53E3E', '#3182CE', '#38A169', '#E2E8F0', '#9F7AEA', '#ED64A6'];
  final List<String> _outfitColors = ['#4A5568', '#E53E3E', '#3182CE', '#38A169', '#805AD5', '#D69E2E', '#F7FAFC', '#2B6CB0', '#C53030'];

  @override
  void initState() {
    super.initState();
    _loadExistingAvatar();
  }

  void _loadExistingAvatar() async {
    final user = await ref.read(authServiceProvider).getCurrentUser();
    if (user != null && user.photoURL != null && user.photoURL!.startsWith('{')) {
      final config = AvatarConfig.fromJson(user.photoURL!);
      setState(() {
        _hair = config.hair;
        _eyes = config.eyes;
        _mouth = config.mouth;
        _acc = config.acc;
        _facialHair = config.facialHair;
        _details = config.details;
        _bgColor = config.bgColor;
        _skinColor = config.skinColor;
        _hairColor = config.hairColor;
        _outfitColor = config.outfitColor;
        _customStrokes = config.customStrokes;
      });
    }
  }

  void _saveAvatar() async {
    setState(() => _isSaving = true);
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      final config = AvatarConfig(
        hair: _hair,
        eyes: _eyes,
        mouth: _mouth,
        acc: _acc,
        facialHair: _facialHair,
        details: _details,
        bgColor: _bgColor,
        skinColor: _skinColor,
        hairColor: _hairColor,
        outfitColor: _outfitColor,
        customStrokes: _customStrokes,
      );

      final jsonStr = config.toJson();
      final updatedUser = user.copyWith(photoURL: jsonStr);
      await ref.read(authServiceProvider).updateUserProfile(user.uid, updatedUser.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar Saved Successfully! ✨')),
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

    final config = AvatarConfig(
      hair: _hair,
      eyes: _eyes,
      mouth: _mouth,
      acc: _acc,
      facialHair: _facialHair,
      details: _details,
      bgColor: _bgColor,
      skinColor: _skinColor,
      hairColor: _hairColor,
      outfitColor: _outfitColor,
      customStrokes: _customStrokes,
    );

    return Scaffold(
      backgroundColor: AppColors.pageBg(context),
      appBar: AppBar(
        title: Text('Campus Identity Lab', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Interactive Preview
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Hero(
                      tag: 'avatar_creator_canvas',
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                              blurRadius: 36,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            FlutterAvatar(config: config, size: 190),
                            if (_isPaintingMode)
                              Positioned.fill(
                                child: ClipOval(
                                  child: GestureDetector(
                                    onPanStart: (details) {
                                      final localPos = details.localPosition;
                                      setState(() {
                                        _currentStrokePoints = [Offset(localPos.dx / 190.0, localPos.dy / 190.0)];
                                        _customStrokes = List.from(_customStrokes)
                                          ..add(PaintStroke(
                                            points: _currentStrokePoints,
                                            color: _brushColor,
                                            width: _brushWidth,
                                          ));
                                      });
                                    },
                                    onPanUpdate: (details) {
                                      final localPos = details.localPosition;
                                      if (localPos.dx >= 0 && localPos.dx <= 190 && localPos.dy >= 0 && localPos.dy <= 190) {
                                        setState(() {
                                          _currentStrokePoints.add(Offset(localPos.dx / 190.0, localPos.dy / 190.0));
                                          _customStrokes[_customStrokes.length - 1] = PaintStroke(
                                            points: List.from(_currentStrokePoints),
                                            color: _brushColor,
                                            width: _brushWidth,
                                          );
                                        });
                                      }
                                    },
                                    onPanEnd: (details) {
                                      _currentStrokePoints = [];
                                    },
                                    child: Container(
                                      color: Colors.transparent,
                                      width: 190,
                                      height: 190,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Painting Mode Toolbar
                  if (!_isPaintingMode) ...[
                    GestureDetector(
                      onTap: () => setState(() => _isPaintingMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accent.withOpacity(0.2), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.brush_rounded, color: accent, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Enter Paint Studio',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg(context),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border(context).withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Brush colors selection
                          Expanded(
                            child: SizedBox(
                              height: 28,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _brushColors.length,
                                itemBuilder: (context, idx) {
                                  final hex = _brushColors[idx];
                                  final color = Color(int.parse('FF' + hex.replaceFirst('#', ''), radix: 16));
                                  final isSelected = hex == _brushColor;
                                  return GestureDetector(
                                    onTap: () => setState(() => _brushColor = hex),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? AppColors.textPrimary(context) : Colors.white24,
                                          width: isSelected ? 2.5 : 1.0,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Undo last stroke
                          IconButton(
                            icon: Icon(Icons.undo_rounded, color: AppColors.textPrimary(context), size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              if (_customStrokes.isNotEmpty) {
                                setState(() => _customStrokes.removeLast());
                                HapticFeedback.lightImpact();
                              }
                            },
                          ),
                          const SizedBox(width: 10),
                          // Clear all strokes
                          IconButton(
                            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 19),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              if (_customStrokes.isNotEmpty) {
                                setState(() => _customStrokes.clear());
                                HapticFeedback.mediumImpact();
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          // Exit paint mode
                          GestureDetector(
                            onTap: () => setState(() => _isPaintingMode = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.green.withOpacity(0.2)),
                              ),
                              child: Text(
                                'Exit',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Deep Control Panel
            Expanded(
              flex: 6,
              child: GlassCard(
                borderRadius: 32,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Hair Styles
                    _buildSectionTitle('Hairstyles'),
                    const SizedBox(height: 10),
                    _buildSelectionRow(
                      count: 12,
                      labels: ['Bald', 'Classic', 'Spiky', 'Curly', 'Cap', 'Afro', 'Bun', 'Long', 'Undercut', 'Braids', 'Band', 'Topknot'],
                      selected: _hair,
                      onSelected: (i) => setState(() => _hair = i),
                    ),
                    const SizedBox(height: 20),

                    // Expressions (Eyes)
                    _buildSectionTitle('Eyes & Looks'),
                    const SizedBox(height: 10),
                    _buildSelectionRow(
                      count: 6,
                      labels: ['Normal', 'Wink', 'Happy', 'Star', 'Anime', 'Squint'],
                      selected: _eyes,
                      onSelected: (i) => setState(() => _eyes = i),
                    ),
                    const SizedBox(height: 20),

                    // Expressions (Mouth)
                    _buildSectionTitle('Mouth & Vibe'),
                    const SizedBox(height: 10),
                    _buildSelectionRow(
                      count: 6,
                      labels: ['Smile', 'Surprised', 'Serious', 'Smirk', 'Laughing', 'Frown'],
                      selected: _mouth,
                      onSelected: (i) => setState(() => _mouth = i),
                    ),
                    const SizedBox(height: 20),

                    // Facial Hair (Beard)
                    _buildSectionTitle('Facial Hair'),
                    const SizedBox(height: 10),
                    _buildSelectionRow(
                      count: 5,
                      labels: ['Clean', 'Goatee', 'Full Beard', 'Stubble', 'Moustache'],
                      selected: _facialHair,
                      onSelected: (i) => setState(() => _facialHair = i),
                    ),
                    const SizedBox(height: 20),

                    // Accessories
                    _buildSectionTitle('Accessories'),
                    const SizedBox(height: 10),
                    _buildSelectionRow(
                      count: 6,
                      labels: ['None', 'Glasses', 'Shades', 'Eyepatch', 'Headset', 'Scar'],
                      selected: _acc,
                      onSelected: (i) => setState(() => _acc = i),
                    ),
                    const SizedBox(height: 20),

                    // Cheek details (Blush/freckles)
                    _buildSectionTitle('Special Details'),
                    const SizedBox(height: 10),
                    _buildSelectionRow(
                      count: 3,
                      labels: ['None', 'Rosy Cheeks', 'Freckles'],
                      selected: _details,
                      onSelected: (i) => setState(() => _details = i),
                    ),
                    const SizedBox(height: 24),

                    // Color Trays
                    _buildSectionTitle('Skin Complexion'),
                    const SizedBox(height: 10),
                    _buildColorRow(_skinColors, _skinColor, (c) => setState(() => _skinColor = c)),
                    const SizedBox(height: 20),

                    _buildSectionTitle('Hair Dye Color'),
                    const SizedBox(height: 10),
                    _buildColorRow(_hairColors, _hairColor, (c) => setState(() => _hairColor = c)),
                    const SizedBox(height: 20),

                    _buildSectionTitle('Outfit Fashion Color'),
                    const SizedBox(height: 10),
                    _buildColorRow(_outfitColors, _outfitColor, (c) => setState(() => _outfitColor = c)),
                    const SizedBox(height: 20),

                    _buildSectionTitle('ID Card Background'),
                    const SizedBox(height: 10),
                    _buildColorRow(_bgColors, _bgColor, (c) => setState(() => _bgColor = c)),
                    const SizedBox(height: 32),

                    // Save Button
                    GestureDetector(
                      onTap: _isSaving ? null : _saveAvatar,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [accent, accent.withOpacity(0.85)]),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.3),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Lock Digital Identity',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: AppColors.textPrimary(context),
      ),
    );
  }

  Widget _buildSelectionRow({
    required int count,
    required List<String> labels,
    required int selected,
    required ValueChanged<int> onSelected,
  }) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = selected == i;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : AppColors.surface(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.border(context).withOpacity(0.5),
                ),
              ),
              child: Text(
                labels[i],
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                  color: isSelected ? Colors.white : AppColors.textPrimary(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorRow(List<String> colors, String selectedColor, ValueChanged<String> onSelected) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final hex = colors[i];
          final isSelected = hex.toLowerCase() == selectedColor.toLowerCase();
          final Color color = Color(int.parse('FF' + hex.replaceFirst('#', ''), radix: 16));

          return GestureDetector(
            onTap: () => onSelected(hex),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.textPrimary(context) : Colors.white24,
                  width: isSelected ? 3 : 1.5,
                ),
                boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)] : [],
              ),
            ),
          );
        },
      ),
    );
  }
}
