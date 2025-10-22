// lib/shared/widgets/responsive_center.dart
import 'package:flutter/material.dart';

/// Un widget que centra a su hijo y le impone un ancho máximo.
/// En pantallas más estrechas que el ancho máximo, el hijo ocupa todo el ancho.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 800,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}