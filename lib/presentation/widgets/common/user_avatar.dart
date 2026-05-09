import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../profile/flutter_avatar.dart';

class UserAvatar extends StatelessWidget {
  final String? photoURL;
  final double radius;

  const UserAvatar({
    super.key,
    required this.photoURL,
    this.radius = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final double size = radius * 2;
    
    if (photoURL != null && photoURL!.startsWith('{')) {
      final config = AvatarConfig.fromJson(photoURL!);
      return SizedBox(
        width: size,
        height: size,
        child: FlutterAvatar(config: config, size: size),
      );
    }

    if (photoURL != null && photoURL!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: photoURL!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            width: size,
            height: size,
          ),
          errorWidget: (context, url, error) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              size: radius,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        size: radius,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
