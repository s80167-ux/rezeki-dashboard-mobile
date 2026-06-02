import 'package:flutter/material.dart';
import '../theme/rezeki_theme.dart';

class RezekiSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;

  const RezekiSearchBar({super.key, required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(RezekiRadii.input),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: RezekiTheme.softShadow,
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Icon(Icons.search, color: AppColors.textTertiary, size: 20),
          ),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
