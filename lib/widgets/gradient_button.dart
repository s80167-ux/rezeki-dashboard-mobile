import 'package:flutter/material.dart';
import '../theme/rezeki_theme.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double height;
  final Gradient? gradient;
  final BorderRadius? borderRadius;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height = 52,
    this.gradient,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(RezekiRadii.button);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient ?? RezekiTheme.primaryGradient,
        borderRadius: br,
        boxShadow: onPressed != null ? RezekiTheme.glowShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: br,
        child: InkWell(
          borderRadius: br,
          onTap: onPressed,
          child: Center(child: child),
        ),
      ),
    );
  }
}
