import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'theme_extensions.dart';

/// Configures a new wave.
class Wave {
  /// The amount of pixels the wave extends and contracts up and down.
  final double intensity;

  /// The amount bumps the wave has.
  final double frequency;

  /// The amount of pixels the wave should be pushed in towards the center
  /// of the screen.
  final double gravity;

  /// The color that washes the wave perpendicularly from the peaks.
  final Color startColor;

  /// The color that washes the wave perpendicularly from the troughs.
  final Color endColor;

  /// The height of the square that makes up the entire area below the wave.
  /// This is used to control the strength of the gradients.
  final double depth;

  /// The rotation of the wave in radians.
  final double rotation;

  /// Whether the wave should glide in the opposite direction.
  final bool reverseDirection;

  /// Creates a new wave.
  const Wave({
    required this.intensity,
    required this.frequency,
    required this.gravity,
    required this.startColor,
    required this.endColor,
    this.rotation = 0,
    this.depth = 300,
    this.reverseDirection = false,
  });
}

class WaveBackground extends ImplicitlyAnimatedWidget {
  final List<Wave> waves;
  final double waveMotion;

  const WaveBackground({
    super.key,
    required super.duration,
    required this.waves,
    super.curve = Curves.linear,
    this.waveMotion = 0,
  });

  @override
  ImplicitlyAnimatedWidgetState<WaveBackground> createState() =>
      _FancyBackgroundState();
}

class _FancyBackgroundState
    extends ImplicitlyAnimatedWidgetState<WaveBackground> {
  Tween<double>? _waveMotion;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _waveMotion = visitor(
      _waveMotion,
      widget.waveMotion,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>;
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = this.animation;
    return CustomPaint(
      painter: FancyBackgroundPainter(
        primaryColor: context.colorScheme.primary,
        secondaryColor: context.colorScheme.primaryContainer,
        overlay: context.colorScheme.background,
        waveMotion: _waveMotion?.evaluate(animation) ?? 0,
        waves: widget.waves,
      ),
    );
  }
}

class FancyBackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color overlay;
  final double waveMotion;
  final List<Wave> waves;
  final Map<Wave, Paint> wavePaint;

  FancyBackgroundPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.overlay,
    required this.waves,
    required this.waveMotion,
  }) : wavePaint = {
          for (final Wave wave in waves)
            wave: Paint()
              ..style = PaintingStyle.fill
              ..shader = ui.Gradient.linear(
                const Offset(0, 0),
                Offset(0, wave.depth),
                [
                  wave.startColor,
                  wave.endColor,
                ],
              ),
        };

  @override
  void paint(Canvas canvas, Size size) {
    final double waveExtent = max(4000, size.longestSide * 2);

    canvas.translate(size.width / 2, size.height / 2);

    for (final Wave wave in waves) {
      final Path path = genCurvePath(
        depth: 300,
        frequency: wave.frequency,
        intensity: wave.intensity,
        waveExtent: waveExtent,
      );

      // Need to translate it towards the screen's edge, with respect to rotation
      final double edgeX = cos(wave.rotation) * size.width / 2;
      final double edgeY = sin(wave.rotation) * size.height / 2;

      canvas.translate(edgeX, edgeY);

      // Apply the gravity towards the center.
      final double gravX = cos(wave.rotation) * -wave.gravity;
      final double gravY = sin(wave.rotation) * -wave.gravity;
      canvas.translate(gravX, gravY);

      canvas.rotate(wave.rotation);
      canvas.rotate(-pi / 2);

      drawCurvedPath(
        path: path,
        canvas: canvas,
        size: size,
        paint: wavePaint[wave]!,
        waveExtent: waveExtent,
        reverse: wave.reverseDirection,
      );

      canvas.rotate(pi / 2);
      canvas.rotate(-wave.rotation);
      canvas.translate(-gravX, -gravY);
      canvas.translate(-edgeX, -edgeY);
    }

    canvas.translate(-size.width / 2, -size.height / 2);
  }

  void drawCurvedPath({
    required Path path,
    required double waveExtent,
    required Canvas canvas,
    required Size size,
    required Paint paint,
    bool reverse = false,
  }) {
    final double motion = waveMotion * (reverse ? -1 : 1);
    canvas.translate(-waveExtent / 2, 0);
    canvas.translate(motion * (waveExtent / 4), 0);

    canvas.drawPath(path, paint);

    canvas.translate(-motion * (waveExtent / 4), 0);
    canvas.translate(waveExtent / 2, 0);
  }

  Path genCurvePath({
    required double depth,
    required double frequency,
    required double waveExtent,
    required double intensity,
  }) {
    final path = Path()..moveTo(0, depth);
    for (int i = 0; i < frequency; i++) {
      final bool isEven = i % 2 == 0;
      final double x = waveExtent * (i / frequency);
      if (i == 0) {
        path.moveTo(x, 0);
        continue;
      }
      final double prevX = waveExtent * ((i - 1) / frequency);
      final double halfX = (x + prevX) / 2.0;
      path.quadraticBezierTo(
        halfX,
        intensity * (isEven ? 1 : -1),
        x,
        0,
      );
    }
    path.lineTo(waveExtent, depth);
    path.lineTo(0, depth);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant FancyBackgroundPainter oldDelegate) =>
      oldDelegate.waveMotion != waveMotion ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.secondaryColor != secondaryColor ||
      oldDelegate.overlay != overlay ||
      oldDelegate.waves != waves;
}
