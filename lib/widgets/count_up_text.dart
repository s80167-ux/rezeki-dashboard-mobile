import 'package:flutter/material.dart';

class CountUpText extends StatefulWidget {
  final int end;
  final Duration duration;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;

  const CountUpText({
    super.key,
    required this.end,
    this.duration = const Duration(milliseconds: 800),
    this.style,
    this.prefix,
    this.suffix,
  });

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = IntTween(begin: 0, end: widget.end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.end != widget.end) {
      _animation = IntTween(
        begin: _animation.value,
        end: widget.end,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix ?? ""}${_animation.value}${widget.suffix ?? ""}',
          style: widget.style,
        );
      },
    );
  }
}
