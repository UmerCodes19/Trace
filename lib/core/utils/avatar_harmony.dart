// lib/core/utils/avatar_harmony.dart
// Trace Avatar Harmony & Constraint Engine
// Ensures every generated combination looks intentionally designed.

import 'dart:math';

/// Compatibility severity levels
enum HarmonyLevel {
  perfect,   // Looks great together
  mild,      // Works but not ideal — dim/warn
  blocked,   // Geometry collision / silhouette break — auto-prevent
}

class AvatarHarmony {
  AvatarHarmony._();

  // ─── Hair + Hat Compatibility ──────────────────────────────────────────────
  // Large-volume hairstyles that break under hats
  static const Set<int> _voluminousHair = {3, 5, 14, 15, 21, 22}; // Curly, Afro, Wolf, Box Braids, Space Buns, Locs
  static const Set<int> _tallHair = {2, 11, 19}; // Spiky, Topknot, Mohawk

  static HarmonyLevel hairHatCompatibility(int hair, int hatOverride) {
    if (hatOverride == 0) return HarmonyLevel.perfect; // No hat — always fine
    if (_voluminousHair.contains(hair)) return HarmonyLevel.blocked; // Hard block
    if (_tallHair.contains(hair)) return HarmonyLevel.mild; // Warning
    return HarmonyLevel.perfect;
  }

  // ─── Accessory Collision Map ───────────────────────────────────────────────
  static HarmonyLevel accessoryCompatibility(int acc, int hair, int facialHair) {
    // Face mask (6) + facial hair = hidden beard, mild
    if (acc == 6 && facialHair > 0) return HarmonyLevel.mild;
    // Headphones (4) + headband hair (10) = geometry collision
    if (acc == 4 && hair == 10) return HarmonyLevel.blocked;
    // AirPods (9) + headphones (4) can't coexist — but they're same slot
    // Nose ring (10) + face mask (6) = hidden ring
    if (acc == 10 && acc == 6) return HarmonyLevel.mild; // same slot, N/A
    return HarmonyLevel.perfect;
  }

  // ─── Should suppress mouth rendering (e.g. face mask covers it) ────────────
  static bool shouldHideMouth(int acc) => acc == 6;

  // ─── Should suppress left eye (eyepatch) ───────────────────────────────────
  static bool shouldHideLeftEye(int acc) => acc == 3;

  // ─── Outfit + Hair silhouette balance ──────────────────────────────────────
  static HarmonyLevel outfitHairBalance(int outfit, int hair) {
    // Hoodie (1) + huge hair (afro, locs, space buns) = top-heavy
    if (outfit == 1 && _voluminousHair.contains(hair)) return HarmonyLevel.mild;
    // Turtleneck (3) + full beard (2) = neck collision
    return HarmonyLevel.perfect;
  }

  // ─── Facial hair + outfit collar ───────────────────────────────────────────
  static HarmonyLevel facialHairOutfitCompat(int facialHair, int outfit) {
    // Full beard (2) + turtleneck (3) = geometry overlap
    if (facialHair == 2 && outfit == 3) return HarmonyLevel.mild;
    return HarmonyLevel.perfect;
  }

  // ─── Master compatibility check ────────────────────────────────────────────
  /// Returns the worst harmony level for a full config
  static HarmonyLevel checkOverall({
    required int hair, required int acc, required int outfit,
    required int facialHair, int hatOverride = 0,
  }) {
    final checks = [
      hairHatCompatibility(hair, hatOverride),
      accessoryCompatibility(acc, hair, facialHair),
      outfitHairBalance(outfit, hair),
      facialHairOutfitCompat(facialHair, outfit),
    ];
    if (checks.contains(HarmonyLevel.blocked)) return HarmonyLevel.blocked;
    if (checks.contains(HarmonyLevel.mild)) return HarmonyLevel.mild;
    return HarmonyLevel.perfect;
  }

  // ─── Check if a specific trait change would cause issues ───────────────────
  /// Used by the studio to dim/block specific option chips
  static HarmonyLevel checkTraitChange({
    required String traitName,
    required int traitValue,
    required int hair, required int acc, required int outfit,
    required int facialHair, int hatOverride = 0,
  }) {
    switch (traitName) {
      case 'hair':
        return _worstOf([
          hairHatCompatibility(traitValue, hatOverride),
          outfitHairBalance(outfit, traitValue),
          accessoryCompatibility(acc, traitValue, facialHair),
        ]);
      case 'acc':
        return accessoryCompatibility(traitValue, hair, facialHair);
      case 'outfit':
        return _worstOf([
          outfitHairBalance(traitValue, hair),
          facialHairOutfitCompat(facialHair, traitValue),
        ]);
      case 'facialHair':
        return _worstOf([
          facialHairOutfitCompat(traitValue, outfit),
          accessoryCompatibility(acc, hair, traitValue),
        ]);
      case 'hatOverride':
        return hairHatCompatibility(hair, traitValue);
      default:
        return HarmonyLevel.perfect;
    }
  }

  static HarmonyLevel _worstOf(List<HarmonyLevel> levels) {
    if (levels.contains(HarmonyLevel.blocked)) return HarmonyLevel.blocked;
    if (levels.contains(HarmonyLevel.mild)) return HarmonyLevel.mild;
    return HarmonyLevel.perfect;
  }

  // ─── Weighted Harmonious Randomizer ────────────────────────────────────────
  /// Generates a designer-quality avatar config using weighted harmony rules
  static Map<String, dynamic> generateHarmonious(Random rng) {
    // 1. Pick a color family first — this anchors the whole identity
    final skinPalette = _kSkinTones[rng.nextInt(_kSkinTones.length)];
    final colorFamily = _kColorFamilies[rng.nextInt(_kColorFamilies.length)];

    // 2. Pick hair from weighted pools (common 65%, distinctive 35%)
    final int hair;
    if (rng.nextDouble() < 0.65) {
      hair = _kCommonHair[rng.nextInt(_kCommonHair.length)];
    } else {
      hair = _kDistinctiveHair[rng.nextInt(_kDistinctiveHair.length)];
    }

    // 3. Pick complementary outfit
    final outfit = rng.nextInt(7);

    // 4. Pick accessory (60% none, 40% something)
    final acc = rng.nextDouble() < 0.6 ? 0 : (rng.nextInt(10) + 1);

    // 5. Pick facial features
    final eyes = rng.nextInt(11);
    final mouth = rng.nextInt(10);
    final eyebrows = rng.nextInt(7);
    final facialHair = rng.nextDouble() < 0.65 ? 0 : rng.nextInt(5);
    final details = rng.nextDouble() < 0.7 ? 0 : (rng.nextInt(2) + 1);

    // 6. Validate — reroll conflicts
    int finalAcc = acc;
    if (accessoryCompatibility(finalAcc, hair, facialHair) == HarmonyLevel.blocked) {
      finalAcc = 0;
    }

    // 7. Background style (80% solid, 20% fancy)
    final bgStyle = rng.nextDouble() < 0.8 ? 0 : (rng.nextInt(3) + 1);

    return {
      'hair': hair, 'eyes': eyes, 'mouth': mouth, 'acc': finalAcc,
      'facialHair': facialHair, 'details': details, 'eyebrows': eyebrows,
      'noseStyle': 0, 'outfit': outfit, 'earring': 0, 'hatOverride': 0,
      'bgStyle': bgStyle,
      'bgColor': colorFamily['bg']!, 'skinColor': skinPalette,
      'hairColor': colorFamily['hair']!, 'outfitColor': colorFamily['outfit']!,
    };
  }

  // ─── Color Data ────────────────────────────────────────────────────────────
  static const List<String> _kSkinTones = [
    '#FFDBB5', '#F9C9B1', '#E0A96D', '#C68642', '#8D5524', '#5C3826', '#3C2F2F', '#FFF0E0',
  ];

  static const List<int> _kCommonHair = [0, 1, 3, 6, 7, 8, 12, 13, 17, 18];
  static const List<int> _kDistinctiveHair = [2, 4, 5, 9, 10, 11, 14, 15, 16, 19, 20, 21, 22, 23];

  static const List<Map<String, String>> _kColorFamilies = [
    {'bg': '#1A535C', 'hair': '#E2E8F0', 'outfit': '#FFE66D'},    // Deep Forest Contrast
    {'bg': '#FF6B6B', 'hair': '#1A202C', 'outfit': '#FFFFFF'},    // Warm Ember Highlight
    {'bg': '#4ECDC4', 'hair': '#2C3E50', 'outfit': '#F7FFF7'},    // Jade Refresh
    {'bg': '#9F7AEA', 'hair': '#2D3748', 'outfit': '#E9D8FD'},    // Purple Contrast
    {'bg': '#FFE66D', 'hair': '#2D3748', 'outfit': '#FF6B6B'},    // Golden Sun
    {'bg': '#0D1615', 'hair': '#E2E8F0', 'outfit': '#00BFA5'},    // Cyber Pop
    {'bg': '#5D4037', 'hair': '#F3E5AB', 'outfit': '#FFAB91'},    // Toasted Brown
    {'bg': '#FF71CE', 'hair': '#1A202C', 'outfit': '#05FFA1'},    // Neon Shock
    {'bg': '#2E2E2E', 'hair': '#FFFFFF', 'outfit': '#90CDF4'},    // Monotech
    {'bg': '#588157', 'hair': '#DAD7CD', 'outfit': '#344E41'},    // High Forest
    {'bg': '#B967FF', 'hair': '#01CDFE', 'outfit': '#FFF176'},    // Hyperwave
    {'bg': '#1B1B2F', 'hair': '#E2E8F0', 'outfit': '#FF758C'},    // Nightfall Red
  ];
}
