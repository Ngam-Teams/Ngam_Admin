import 'dart:ui';
import 'package:flutter/material.dart';

/// Web & Mobile compatible glassmorphism drop-in replacement for
/// `package:liquid_glass_widgets` (matching Ngam Business & Ngam Teams).
enum GlassQuality {
  standard,
  high,
  low,
}

class LiquidRoundedSuperellipse {
  final double borderRadius;
  const LiquidRoundedSuperellipse({this.borderRadius = 24.0});
}

class LiquidGlassSettings {
  final double thickness;
  final double blur;
  final double refractiveIndex;
  final Color glassColor;
  final double lightAngle;
  final double lightIntensity;
  final double specularIntensity;
  final double ambientStrength;
  final double saturation;
  final double chromaticAberration;
  final double refraction;

  const LiquidGlassSettings({
    this.thickness = 0.1,
    this.blur = 12.0,
    this.refractiveIndex = 1.0,
    this.glassColor = Colors.transparent,
    this.lightAngle = 45.0,
    this.lightIntensity = 0.15,
    this.specularIntensity = 0.0,
    this.ambientStrength = 1.0,
    this.saturation = 1.0,
    this.chromaticAberration = 0.0,
    this.refraction = 0.0,
  });
}

class LiquidGlassWidgets {
  static Future<void> initialize() async {}
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final bool useOwnLayer;
  final GlassQuality quality;
  final LiquidRoundedSuperellipse? shape;
  final LiquidGlassSettings? settings;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  const GlassContainer({
    super.key,
    required this.child,
    this.useOwnLayer = true,
    this.quality = GlassQuality.standard,
    this.shape,
    this.settings,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final radius = shape?.borderRadius ?? 24.0;
    final blurSigma = (settings?.blur ?? 12.0).clamp(4.0, 24.0);
    final tint = color ?? settings?.glassColor ?? Colors.transparent;

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            color: tint == Colors.transparent ? null : tint,
            child: child,
          ),
        ),
      ),
    );
  }
}
