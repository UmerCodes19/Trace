import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/avatar_config.dart';
import '../models/engine_state.dart';
import '../core/avatar_engine.dart';
import '../rendering/avatar_painter.dart';
import '../emotions/emotion_preset.dart';

/// High-performance visual proxy binding procedural animation state to optimized raster outputs.
class InteractiveAvatarView extends ConsumerWidget {
  final AvatarConfig config;
  final double size;
  final bool interactive;

  const InteractiveAvatarView({
    super.key,
    required this.config,
    this.size = 120.0,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Deep link to simulation thread delivering display-sync snapshots
    final AvatarRenderSnapshot snapshot = ref.watch(avatarEngineProvider);

    final Widget avatar = RepaintBoundary(
      child: CustomPaint(
        size: Size(size, size),
        painter: AvatarPainter(
          config: config,
          snapshot: snapshot,
          renderSize: size,
          accentColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );

    if (!interactive) return avatar;

    return GestureDetector(
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final Offset local = box.globalToLocal(details.globalPosition);
        final double normX = local.dx / size;
        final double normY = local.dy / size;

        final engine = ref.read(avatarEngineProvider.notifier);

        // 🚀 DIVERSIFIED PERSONALITY INJECTION
        // Derive unique reaction archetypes based on CURRENT MOUTH TYPE!
        AvatarEmotion reaction = AvatarEmotion.happy;
        int durationMs = 1500;

        if (config.mouth == 1) { // Surprised
          reaction = AvatarEmotion.alert; durationMs = 1800;
        } else if (config.mouth == 2) { // Serious
          reaction = AvatarEmotion.focused; durationMs = 2000;
        } else if (config.mouth == 5) { // Frown
          reaction = AvatarEmotion.confused; durationMs = 2200;
        } else if (config.mouth == 7 || config.mouth == 8) { // Grin / Tongue
          reaction = AvatarEmotion.excited; durationMs = 1200;
        } else if (config.mouth == 9) { // Whisper
          reaction = AvatarEmotion.sleepy; durationMs = 2500;
        } else {
          // Spatial Default for standard mouths
          if (normY < 0.3) {
            reaction = AvatarEmotion.curious;
            durationMs = 1800;
          } else if (normX < 0.3 || normX > 0.7) {
            reaction = AvatarEmotion.alert;
          }
        }

        engine.triggerReaction(reaction, duration: Duration(milliseconds: durationMs));
      },
      behavior: HitTestBehavior.opaque,
      child: avatar,
    );
  }
}
