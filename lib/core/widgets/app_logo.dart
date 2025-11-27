import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final bool showSubtitle;
  final double imageHeight;

  const AppLogo({
    super.key,
    this.showSubtitle = false,
    this.imageHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Twoje logo z assets
        Image.asset(
          'assets/images/logoSTP.png',
          height: imageHeight,
        ),
        const SizedBox(height: 12),
        Text(
          'SwipeToPlay',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          Text(
            'Your personal game diary',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }
}
