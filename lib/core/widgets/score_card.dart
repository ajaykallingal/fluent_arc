import 'package:flutter/material.dart';

class ScoreCard extends StatelessWidget {
  final String title;
  final double score; // Out of 100
  final String description;
  final Color? customColor;

  const ScoreCard({
    super.key,
    required this.title,
    required this.score,
    required this.description,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor =
        customColor ??
        (score >= 80
            ? theme.colorScheme.tertiary
            : score >= 50
            ? theme.colorScheme.secondary
            : theme.colorScheme.error);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Semantics(
                  // Screen reader announcement: "<score> out of 100,
                  // <description>". The description string is already
                  // passed in by the caller (e.g. "Good attempt. Focus
                  // on the highlighted words.") which contains the
                  // textual band descriptor required for accessibility.
                  label: '${score.toInt()} out of 100. $description',
                  child: Text(
                    '${score.toInt()}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
