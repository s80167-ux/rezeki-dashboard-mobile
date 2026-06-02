import 'package:flutter/material.dart';
import '../theme/rezeki_theme.dart';

class RezekiStatusChip extends StatelessWidget {
  final String label;
  final ({Color bg, Color fg}) colors;

  const RezekiStatusChip({super.key, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(RezekiRadii.badge),
        border: Border.all(color: colors.fg.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colors.fg,
        ),
      ),
    );
  }
}

class RezekiTagChip extends StatelessWidget {
  final String label;

  const RezekiTagChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(RezekiRadii.badge),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
