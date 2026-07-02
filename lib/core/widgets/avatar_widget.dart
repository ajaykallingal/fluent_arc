import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double radius;

  const AvatarWidget({
    super.key,
    required this.displayName,
    this.photoUrl,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(photoUrl!),
        backgroundColor: theme.colorScheme.primaryContainer,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary,
      child: Text(
        initial,
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
