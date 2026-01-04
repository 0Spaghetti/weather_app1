import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final bool isGlassEnabled;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.isGlassEnabled = true,
  });

  // دالة بناء الواجهة، مسؤولة عن عرض حاوية زجاجية قابلة لإعادة الاستخدام
  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: child,
    );

    if (isGlassEnabled) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: content,
        ),
      );
    } else {
      return content;
    }
  }
}
