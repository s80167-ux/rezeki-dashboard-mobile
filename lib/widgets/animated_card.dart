import 'package:flutter/material.dart';
import '../theme/rezeki_theme.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final List<BoxShadow>? shadows;
  final Color? backgroundColor;
  final Gradient? gradient;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius,
    this.shadows,
    this.backgroundColor,
    this.gradient,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? RezekiRadii.card;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        margin: widget.margin,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? AppColors.surface,
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5),
          ),
          boxShadow: _pressed
              ? RezekiTheme.softShadow
              : (widget.shadows ?? RezekiTheme.elevatedShadow),
        ),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
