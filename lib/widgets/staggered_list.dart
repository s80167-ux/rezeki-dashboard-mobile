import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final double interval;
  final EdgeInsetsGeometry? padding;

  const StaggeredList({
    super.key,
    required this.children,
    this.interval = 0.06,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: children.asMap().entries.map((entry) {
        final delay = (entry.key * interval * 1000).toInt();
        return entry.value
            .animate()
            .fadeIn(delay: delay.ms, duration: 400.ms)
            .slideY(
              begin: 0.15,
              end: 0,
              delay: delay.ms,
              duration: 400.ms,
              curve: Curves.easeOutCubic,
            );
      }).toList(),
    );
  }
}
