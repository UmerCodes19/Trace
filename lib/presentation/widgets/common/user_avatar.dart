import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../profile/flutter_avatar.dart';
import '../profile/animated_flutter_avatar.dart';

class UserAvatar extends StatefulWidget {
  final String? photoURL;
  final double radius;
  final bool animated;

  const UserAvatar({
    super.key,
    required this.photoURL,
    this.radius = 20.0,
    this.animated = false,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _auraController;

  @override
  void initState() {
    super.initState();
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    if (widget.animated) {
      _auraController.repeat();
    }
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated && !oldWidget.animated) {
      _auraController.repeat();
    } else if (!widget.animated && oldWidget.animated) {
      _auraController.stop();
    }
  }

  @override
  void dispose() {
    _auraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.radius * 2;
    
    Widget avatarWidget;
    
    if (widget.photoURL != null && widget.photoURL!.startsWith('{')) {
      final config = AvatarConfig.fromJson(widget.photoURL!);
      avatarWidget = SizedBox(
        width: size, height: size,
        child: widget.animated 
            ? AnimatedFlutterAvatar(config: config, size: size)
            : FlutterAvatar(config: config, size: size),
      );
    } else if (widget.photoURL != null && widget.photoURL!.isNotEmpty) {
      avatarWidget = ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: CachedNetworkImage(
          imageUrl: widget.photoURL!, width: size, height: size, fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.grey[200], width: size, height: size),
          errorWidget: (context, url, error) => _buildPlaceholder(size),
        ),
      );
    } else {
      avatarWidget = _buildPlaceholder(size);
    }

    // Social Presence Stack
    final content = Stack(
      alignment: Alignment.center,
      children: [
        if (widget.animated)
          AnimatedBuilder(
            animation: _auraController,
            builder: (context, child) {
              final scale = 1.0 + (_auraController.value * 0.15);
              final opacity = (1.0 - _auraController.value) * 0.3;
              return Container(
                width: size, height: size,
                transform: Matrix4.identity()..scale(scale),
                transformAlignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(opacity),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),
        avatarWidget,
      ],
    );

    // Elegant Pop-In Mount Animation
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, val, child) {
        return Transform.scale(scale: val, child: child);
      },
      child: content,
    );
  }

  Widget _buildPlaceholder(double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded, size: widget.radius,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
