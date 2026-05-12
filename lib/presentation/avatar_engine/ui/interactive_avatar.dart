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

        // Advanced Spatial-Hit Mapping
        if (normY < 0.3) {
          engine.triggerReaction(AvatarEmotion.curious, duration: const Duration(milliseconds: 1800));
        } else if (normX < 0.3 || normX > 0.7) {
          engine.triggerReaction(AvatarEmotion.alert, duration: const Duration(milliseconds: 1500));
        } else {
          engine.triggerReaction(AvatarEmotion.happy, duration: const Duration(milliseconds: 1500));
        }
      },
      behavior: HitTestBehavior.opaque,
      child: avatar,
    );
  }
}
