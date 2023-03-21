import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'theme_extensions.dart';

/// A wave representing multiple properties such as intensity, frequency,
/// and colors.
///
/// [Wave] is used to define on-screen wave patterns and characteristics.
class Wave {
  /// The vertical oscillation in pixels.
  final double intensity;

  /// The number of wave peaks.
  final double frequency;

  /// The horizontal offset in pixels towards the center of the screen.
  final double gravity;

  /// The color at the peak of the wave.
  final Color startColor;

  /// The color at the trough of the wave.
  final Color endColor;

  /// The height of the wave's bounding box to control gradient strength.
  final double depth;

  /// The wave's rotation angle in radians.
  final double rotation;

  /// Whether the wave should move in the opposite direction.
  final bool reverseDirection;

  /// Creates a new [Wave] with the given properties.
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

/// A widget that animates a set of [Wave] instances to create a wavy
/// background.
class WaveBackground extends ImplicitlyAnimatedWidget {
  /// The list of [Wave] instances to render.
  final List<Wave> waves;

  /// The horizontal motion of the wave.
  final double waveMotion;

  /// Creates a [WaveBackground] instance with the provided list of waves and
  /// animation settings.
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

/// Manages the state of the [WaveBackground] widget.
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

/// A custom painter that renders a set of [Wave] instances onto the canvas.
class FancyBackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color overlay;
  final double waveMotion;
  final List<Wave> waves;
  final Map<Wave, Paint> wavePaint;

  /// Initializes properties for the [FancyBackgroundPainter].
  ///
  /// Takes in the primary and secondary colors, overlay color,
  /// horizontal wave motion, and list of waves to render.
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

    // Render each wave and apply transformations
    for (final Wave wave in waves) {
      final Path path = genCurvePath(
        depth: 300,
        frequency: wave.frequency,
        intensity: wave.intensity,
        waveExtent: waveExtent,
      );

      // Save canvas state
      canvas.save();

      // Apply wave transformations
      canvas.translate(cos(wave.rotation) * size.width / 2,
          sin(wave.rotation) * size.height / 2);
      canvas.translate(cos(wave.rotation) * -wave.gravity,
          sin(wave.rotation) * -wave.gravity);
      canvas.rotate(wave.rotation);
      canvas.rotate(-pi / 2);

      // Draw wave
      drawCurvedPath(
        path: path,
        canvas: canvas,
        size: size,
        paint: wavePaint[wave]!,
        waveExtent: waveExtent,
        reverse: wave.reverseDirection,
      );

      // Restore canvas state
      canvas.restore();
    }
  }

  /// Draws a curved path with a waving motion effect on [canvas].
  ///
  /// [path] The Path to draw.
  /// [waveExtent] The extent of the wave motion effect.
  /// [canvas] The Canvas on which to draw the curved path.
  /// [size] The size of the canvas.
  /// [paint] The Paint object to use for drawing.
  /// [reverse] Whether to reverse the direction of the wave motion effect. Defaults to false.
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

  /// [depth] The height of the generated wave.
  /// [frequency] The number of complete waves in the path.
  /// [waveExtent] The width of the wave.
  /// [intensity] Multiplication factor to control wave intensity.
  /// [returns] A [Path] object containing the generated wave.
  Path genCurvePath({
    required double depth,
    required double frequency,
    required double waveExtent,
    required double intensity,
  }) {
    // Initialize path object and set initial position.
    final path = Path()..moveTo(0, depth);

    // Loop through each wave segment in the path.
    for (int i = 0; i < frequency; i++) {
      // Determine if the current wave segment is even or odd.
      final bool isEven = i % 2 == 0;
      final double x = waveExtent * (i / frequency);

      // Move the path to the initial position if it's the first wave segment.
      if (i == 0) {
        path.moveTo(x, 0);
        continue;
      }

      // Calculate the previous and half-point positions of the path.
      final double prevX = waveExtent * ((i - 1) / frequency);
      final double halfX = (x + prevX) / 2.0;

      // Add a quadratic bezier curve segment to the path.
      path.quadraticBezierTo(
        halfX,
        intensity * (isEven ? 1 : -1),
        x,
        0,
      );
    }

    // Complete the path by returning to the initial depth and closing the path.
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
