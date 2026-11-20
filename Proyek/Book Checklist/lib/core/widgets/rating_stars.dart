import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.onChanged,
    this.iconSize = 20,
    this.showValue = false,
  });

  final double? rating;
  final ValueChanged<double?>? onChanged;
  final double iconSize;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stars = List<Widget>.generate(5, (index) {
      final value = index + 1.0;
      final icon = rating == null || rating! < value - 0.5
          ? Icons.star_outline_rounded
          : rating! < value
          ? Icons.star_half_rounded
          : Icons.star_rounded;
      final color = icon == Icons.star_outline_rounded
          ? theme.colorScheme.onSurfaceVariant
          : ShelfColors.book;

      if (onChanged == null) {
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(icon, size: iconSize, color: color),
        );
      }

      return IconButton(
        tooltip: 'Rate ${index + 1} out of 5',
        onPressed: () => onChanged!(value),
        icon: Icon(icon, color: color),
        iconSize: iconSize,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: BoxConstraints.tightFor(
          width: iconSize + 10,
          height: iconSize + 10,
        ),
      );
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...stars,
        if (showValue && rating != null) ...[
          const SizedBox(width: 4),
          Text(
            '${rating!.toStringAsFixed(rating! % 1 == 0 ? 0 : 1)} / 5',
            style: theme.textTheme.labelLarge,
          ),
        ],
        if (onChanged != null && rating != null)
          IconButton(
            tooltip: 'Clear rating',
            onPressed: () => onChanged!(null),
            icon: const Icon(Icons.close_rounded),
            iconSize: 18,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 32, height: 40),
          ),
      ],
    );
  }
}
