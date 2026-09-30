import 'dart:math' as math;
import '../models/curve_point.dart';
import '../models/channel_curve.dart';
import '../models/curves_config.dart';

/// CapCut Pro RGB Curves & Luma Spline Color Grading Compiler Service.
class CurvesCompilerService {
  /// Evaluates the curve's output value [0.0, 1.0] for a given normalized input [x]
  /// using Monotonic Cubic Hermite Spline interpolation (Fritsch-Carlson method).
  static double evaluateCurve(
    ChannelCurve curve,
    double x, {
    double masterIntensity = 1.0,
  }) {
    final points = curve.points;
    if (points.isEmpty) return x;
    if (points.length == 1) return points.first.y;

    final clampedX = x.clamp(0.0, 1.0);

    // Boundary constraints
    if (clampedX <= points.first.x) {
      final y = points.first.y;
      return _applyIntensity(clampedX, y, curve.intensity * masterIntensity);
    }
    if (clampedX >= points.last.x) {
      final y = points.last.y;
      return _applyIntensity(clampedX, y, curve.intensity * masterIntensity);
    }

    // Locate segment [i, i+1]
    int i = 0;
    while (i < points.length - 1 && points[i + 1].x < clampedX) {
      i++;
    }

    final p0 = points[i];
    final p1 = points[i + 1];
    final dx = p1.x - p0.x;
    if (dx <= 1e-6) {
      return _applyIntensity(clampedX, p0.y, curve.intensity * masterIntensity);
    }

    // Tangents estimation for smooth cubic Hermite interpolation
    final m0 = _computeMonotonicTangent(points, i);
    final m1 = _computeMonotonicTangent(points, i + 1);

    final t = (clampedX - p0.x) / dx;
    final t2 = t * t;
    final t3 = t2 * t;

    // Hermite basis functions
    final h00 = 2 * t3 - 3 * t2 + 1;
    final h10 = t3 - 2 * t2 + t;
    final h01 = -2 * t3 + 3 * t2;
    final h11 = t3 - t2;

    final rawY = h00 * p0.y + h10 * dx * m0 + h01 * p1.y + h11 * dx * m1;
    final clampedY = rawY.clamp(0.0, 1.0);

    return _applyIntensity(clampedX, clampedY, curve.intensity * masterIntensity);
  }

  /// Blends curve output towards identity (x) according to combined intensity.
  static double _applyIntensity(double input, double output, double intensity) {
    final clampedIntensity = intensity.clamp(0.0, 1.0);
    return (input + (output - input) * clampedIntensity).clamp(0.0, 1.0);
  }

  /// Calculates monotonic tangent slope at point index [k] (Fritsch-Carlson).
  static double _computeMonotonicTangent(List<CurvePoint> points, int k) {
    final n = points.length;
    if (k == 0) {
      final dx = points[1].x - points[0].x;
      return dx > 1e-6 ? (points[1].y - points[0].y) / dx : 0.0;
    }
    if (k == n - 1) {
      final dx = points[n - 1].x - points[n - 2].x;
      return dx > 1e-6 ? (points[n - 1].y - points[n - 2].y) / dx : 0.0;
    }

    final dxLeft = points[k].x - points[k - 1].x;
    final dyLeft = points[k].y - points[k - 1].y;
    final dxRight = points[k + 1].x - points[k].x;
    final dyRight = points[k + 1].y - points[k].y;

    final sLeft = dxLeft > 1e-6 ? dyLeft / dxLeft : 0.0;
    final sRight = dxRight > 1e-6 ? dyRight / dxRight : 0.0;

    // Harmonic mean of slopes to enforce monotonicity
    if (sLeft * sRight <= 0.0) return 0.0;
    return (2.0 * sLeft * sRight) / (sLeft + sRight);
  }

  /// Generates a 256-entry lookup table (LUT) mapping byte values [0..255] -> [0..255].
  static List<int> generateLut(
    ChannelCurve curve, {
    double masterIntensity = 1.0,
  }) {
    final lut = List<int>.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      final normX = i / 255.0;
      final normY = evaluateCurve(curve, normX, masterIntensity: masterIntensity);
      lut[i] = (normY * 255.0).round().clamp(0, 255);
    }
    return lut;
  }

  /// Compiles a 20-element 4x5 Skia color matrix approximating the curves transfer
  /// for real-time 60 FPS preview viewport rendering.
  static List<double> compileSkiaMatrix(CurvesConfig config) {
    if (!config.isActive) {
      // 4x5 Identity Matrix
      return <double>[
        1.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ];
    }

    // Sample key luminance points across the 0..1 spectrum
    final yBlack = evaluateCurve(config.lumaCurve, 0.0, masterIntensity: config.masterIntensity);
    final yMid = evaluateCurve(config.lumaCurve, 0.5, masterIntensity: config.masterIntensity);
    final yWhite = evaluateCurve(config.lumaCurve, 1.0, masterIntensity: config.masterIntensity);

    // Luma scaling & baseline offset
    final lumaSlope = (yWhite - yBlack).clamp(0.1, 3.0);
    final lumaOffset = (yBlack * 255.0) + ((yMid - 0.5) * 60.0);

    // Per-channel sample deltas
    final rDelta = evaluateCurve(config.redCurve, 0.5, masterIntensity: config.masterIntensity) - 0.5;
    final gDelta = evaluateCurve(config.greenCurve, 0.5, masterIntensity: config.masterIntensity) - 0.5;
    final bDelta = evaluateCurve(config.blueCurve, 0.5, masterIntensity: config.masterIntensity) - 0.5;

    final rScale = (1.0 + rDelta * 1.6) * lumaSlope;
    final gScale = (1.0 + gDelta * 1.6) * lumaSlope;
    final bScale = (1.0 + bDelta * 1.6) * lumaSlope;

    final rOffset = lumaOffset + (rDelta * 128.0);
    final gOffset = lumaOffset + (gDelta * 128.0);
    final bOffset = lumaOffset + (bDelta * 128.0);

    return <double>[
      rScale.clamp(0.1, 4.0), 0.0, 0.0, 0.0, rOffset.clamp(-128.0, 128.0),
      0.0, gScale.clamp(0.1, 4.0), 0.0, 0.0, gOffset.clamp(-128.0, 128.0),
      0.0, 0.0, bScale.clamp(0.1, 4.0), 0.0, bOffset.clamp(-128.0, 128.0),
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
  }

  /// Formats curve control points into FFmpeg's native `curves` filter syntax.
  static String formatFFmpegCurve(ChannelCurve curve) {
    return curve.points
        .map((p) => '${p.x.toStringAsFixed(3)}/${p.y.toStringAsFixed(3)}')
        .join(' ');
  }

  /// Generates FFmpeg video filter commands for 4K video exports.
  static List<String> generateFFmpegFilters(CurvesConfig config) {
    if (!config.isActive) return const [];

    final parts = <String>[];

    if (!config.lumaCurve.isIdentity) {
      parts.add("m='${formatFFmpegCurve(config.lumaCurve)}'");
    }
    if (!config.redCurve.isIdentity) {
      parts.add("r='${formatFFmpegCurve(config.redCurve)}'");
    }
    if (!config.greenCurve.isIdentity) {
      parts.add("g='${formatFFmpegCurve(config.greenCurve)}'");
    }
    if (!config.blueCurve.isIdentity) {
      parts.add("b='${formatFFmpegCurve(config.blueCurve)}'");
    }

    if (parts.isEmpty) return const [];

    return ['curves=${parts.join(':')}'];
  }
}
