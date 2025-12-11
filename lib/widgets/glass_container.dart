import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.black.withAlpha((255 * 0.15).round()), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withAlpha((255 * 0.3).round()),
        ),
      ),
      child: child,
    );
  }
}