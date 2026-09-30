import 'dart:math' as math;
import '../models/color_wheels_config.dart';

/// CapCut Pro Primary & Log Color Wheels Mathematical Compiler Service.
/// Implements exact equations ported from PrimaryWheel.zip and LogWheel.zip GLSL shaders.
class ColorWheelsCompilerService {
  /// Core Primary Wheel transfer equation ported from CapCut fshader.frag:
  /// processWheel(float srcColor, float lift, float gamma, float gain)
  static double processPrimaryWheel(double src, double lift, double gamma, double gain) {
    double liftX = lift / (lift - 0.5);
    double gainX = (gain.abs() < 1e-6) ? 1e6 : (1.0 / gain);

    if (lift >= 0.5) liftX = -1e6;
    if (liftX >= gainX) gainX = liftX + 1e-6;

    double res = (src - liftX) / (gainX - liftX);
    if (res > 0.0 && gamma > 0.0) {
      res = math.exp(gamma * math.log(res));
    }
    return res.clamp(0.0, 1.0);
  }

  /// Core Log Wheel transfer equation ported from CapCut LogWheel fshader.frag:
  /// LogFunc2(float curColor, float ShadowWeight, float MidtoneWeight, float HightlightWeight, float Offset)
  static double processLogWheel({
    required double src,
    required double shadowWeight,
    required double midtoneWeight,
    required double highlightWeight,
    required double offset,
    required double lowRange,
    required double highRange,
  }) {
    double cur = src + offset;
    double shadowsWidth = lowRange;
    double shadowsInc = 0.0;

    if (cur < shadowsWidth) {
      shadowsInc = shadowsWidth - cur;
      if (shadowWeight < 0.0) shadowsInc *= 2.0;
    }

    final double low2 = math.max(lowRange - (highRange - lowRange) * 0.1, 0.0);
    final double high2 = math.min(highRange + (highRange - lowRange) * 0.1, 1.0);
    double midtoneInc = 0.0;
    final double span = high2 - low2;

    if (span > 0.001 && cur > low2 && cur < high2) {
      if (midtoneWeight < 0.0) {
        midtoneInc = -3.0 * (cur - high2) * (cur - low2) * (cur - low2) / (span * span);
      } else {
        midtoneInc = 3.0 * (cur - high2) * (cur - high2) * (cur - low2) / (span * span);
      }
    }

    final double highsWidth = 1.0 - highRange;
    double highsInc = 0.0;
    if (cur > (1.0 - highsWidth)) {
      highsInc = cur - (1.0 - highsWidth);
      if (highlightWeight > 0.0) highsInc *= 2.0;
    }

    cur += shadowsInc * shadowWeight + midtoneInc * midtoneWeight + highsInc * highlightWeight;
    return cur.clamp(0.0, 1.0);
  }

  /// Generates a Skia GPU 4x5 ColorFilter matrix for real-time viewport composition.
  static List<double> generate4x5ColorMatrix(ColorWheelsConfig config) {
    if (!config.isActive) {
      return const [
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
      ];
    }

    final double intensity = config.masterIntensity.clamp(0.0, 1.0);

    double rScale = 1.0;
    double gScale = 1.0;
    double bScale = 1.0;
    double rOffset = 0.0;
    double gOffset = 0.0;
    double bOffset = 0.0;

    if (config.mode == ColorWheelsMode.primary) {
      final p = config.primary;

      // Lift (Shadows) biases low-end offsets
      rOffset += (p.lift.red * 40.0 + p.lift.luminance * 25.0) * intensity;
      gOffset += (p.lift.green * 40.0 + p.lift.luminance * 25.0) * intensity;
      bOffset += (p.lift.blue * 40.0 + p.lift.luminance * 25.0) * intensity;

      // Gain (Highlights) biases high-end multiplier
      rScale += (p.gain.red * 0.35 + p.gain.luminance * 0.20) * intensity;
      gScale += (p.gain.green * 0.35 + p.gain.luminance * 0.20) * intensity;
      bScale += (p.gain.blue * 0.35 + p.gain.luminance * 0.20) * intensity;

      // Gamma (Midtones) shifts diagonal curve
      rScale += (p.gamma.red * 0.20) * intensity;
      gScale += (p.gamma.green * 0.20) * intensity;
      bScale += (p.gamma.blue * 0.20) * intensity;
      rOffset += (p.gamma.luminance * 15.0) * intensity;
      gOffset += (p.gamma.luminance * 15.0) * intensity;
      bOffset += (p.gamma.luminance * 15.0) * intensity;

      // Global Offset
      rOffset += (p.offset.red * 30.0 + p.offset.luminance * 20.0) * intensity;
      gOffset += (p.offset.green * 30.0 + p.offset.luminance * 20.0) * intensity;
      bOffset += (p.offset.blue * 30.0 + p.offset.luminance * 20.0) * intensity;
    } else {
      final l = config.log;

      // Shadow wheel
      rOffset += (l.shadow.red * 45.0 + l.shadow.luminance * 30.0) * intensity;
      gOffset += (l.shadow.green * 45.0 + l.shadow.luminance * 30.0) * intensity;
      bOffset += (l.shadow.blue * 45.0 + l.shadow.luminance * 30.0) * intensity;

      // Highlight wheel
      rScale += (l.highlight.red * 0.40 + l.highlight.luminance * 0.25) * intensity;
      gScale += (l.highlight.green * 0.40 + l.highlight.luminance * 0.25) * intensity;
      bScale += (l.highlight.blue * 0.40 + l.highlight.luminance * 0.25) * intensity;

      // Midtone wheel
      rScale += (l.midtone.red * 0.22) * intensity;
      gScale += (l.midtone.green * 0.22) * intensity;
      bScale += (l.midtone.blue * 0.22) * intensity;
      rOffset += (l.midtone.luminance * 18.0) * intensity;
      gOffset += (l.midtone.luminance * 18.0) * intensity;
      bOffset += (l.midtone.luminance * 18.0) * intensity;

      // Global Offset
      rOffset += (l.offset.red * 30.0 + l.offset.luminance * 20.0) * intensity;
      gOffset += (l.offset.green * 30.0 + l.offset.luminance * 20.0) * intensity;
      bOffset += (l.offset.blue * 30.0 + l.offset.luminance * 20.0) * intensity;
    }

    return [
      rScale.clamp(0.1, 3.0), 0, 0, 0, rOffset.clamp(-128.0, 128.0),
      0, gScale.clamp(0.1, 3.0), 0, 0, gOffset.clamp(-128.0, 128.0),
      0, 0, bScale.clamp(0.1, 3.0), 0, bOffset.clamp(-128.0, 128.0),
      0, 0, 0, 1, 0,
    ];
  }

  /// Compiles FFmpeg video filter commands for 4K video exports.
  static List<String> generateFFmpegFilters(ColorWheelsConfig config) {
    if (!config.isActive) return const [];

    final filters = <String>[];
    final double intensity = config.masterIntensity.clamp(0.0, 1.0);

    if (config.mode == ColorWheelsMode.primary) {
      final p = config.primary;

      // FFmpeg colorbalance filter:
      // rs/gs/bs: shadows (-1.0 to 1.0)
      // rm/gm/bm: midtones (-1.0 to 1.0)
      // rh/gh/bh: highlights (-1.0 to 1.0)
      final rs = (p.lift.red * intensity).clamp(-1.0, 1.0);
      final gs = (p.lift.green * intensity).clamp(-1.0, 1.0);
      final bs = (p.lift.blue * intensity).clamp(-1.0, 1.0);

      final rm = (p.gamma.red * intensity).clamp(-1.0, 1.0);
      final gm = (p.gamma.green * intensity).clamp(-1.0, 1.0);
      final bm = (p.gamma.blue * intensity).clamp(-1.0, 1.0);

      final rh = (p.gain.red * intensity).clamp(-1.0, 1.0);
      final gh = (p.gain.green * intensity).clamp(-1.0, 1.0);
      final bh = (p.gain.blue * intensity).clamp(-1.0, 1.0);

      if (rs.abs() > 0.005 ||
          gs.abs() > 0.005 ||
          bs.abs() > 0.005 ||
          rm.abs() > 0.005 ||
          gm.abs() > 0.005 ||
          bm.abs() > 0.005 ||
          rh.abs() > 0.005 ||
          gh.abs() > 0.005 ||
          bh.abs() > 0.005) {
        filters.add(
          'colorbalance=rs=${rs.toStringAsFixed(3)}:gs=${gs.toStringAsFixed(3)}:bs=${bs.toStringAsFixed(3)}:'
          'rm=${rm.toStringAsFixed(3)}:gm=${gm.toStringAsFixed(3)}:bm=${bm.toStringAsFixed(3)}:'
          'rh=${rh.toStringAsFixed(3)}:gh=${gh.toStringAsFixed(3)}:bh=${bh.toStringAsFixed(3)}',
        );
      }

      // Brightness / Contrast adjustment from luminance shifts
      final brightnessShift = (p.offset.luminance * 0.15 + p.lift.luminance * 0.10 + p.gamma.luminance * 0.10) * intensity;
      final contrastShift = 1.0 + (p.gain.luminance * 0.30 - p.lift.luminance * 0.15) * intensity;

      if (brightnessShift.abs() > 0.005 || (contrastShift - 1.0).abs() > 0.005) {
        filters.add(
          'eq=brightness=${brightnessShift.clamp(-0.5, 0.5).toStringAsFixed(3)}:'
          'contrast=${contrastShift.clamp(0.5, 2.0).toStringAsFixed(3)}',
        );
      }
    } else {
      final l = config.log;

      final rs = (l.shadow.red * intensity).clamp(-1.0, 1.0);
      final gs = (l.shadow.green * intensity).clamp(-1.0, 1.0);
      final bs = (l.shadow.blue * intensity).clamp(-1.0, 1.0);

      final rm = (l.midtone.red * intensity).clamp(-1.0, 1.0);
      final gm = (l.midtone.green * intensity).clamp(-1.0, 1.0);
      final bm = (l.midtone.blue * intensity).clamp(-1.0, 1.0);

      final rh = (l.highlight.red * intensity).clamp(-1.0, 1.0);
      final gh = (l.highlight.green * intensity).clamp(-1.0, 1.0);
      final bh = (l.highlight.blue * intensity).clamp(-1.0, 1.0);

      if (rs.abs() > 0.005 ||
          gs.abs() > 0.005 ||
          bs.abs() > 0.005 ||
          rm.abs() > 0.005 ||
          gm.abs() > 0.005 ||
          bm.abs() > 0.005 ||
          rh.abs() > 0.005 ||
          gh.abs() > 0.005 ||
          bh.abs() > 0.005) {
        filters.add(
          'colorbalance=rs=${rs.toStringAsFixed(3)}:gs=${gs.toStringAsFixed(3)}:bs=${bs.toStringAsFixed(3)}:'
          'rm=${rm.toStringAsFixed(3)}:gm=${gm.toStringAsFixed(3)}:bm=${bm.toStringAsFixed(3)}:'
          'rh=${rh.toStringAsFixed(3)}:gh=${gh.toStringAsFixed(3)}:bh=${bh.toStringAsFixed(3)}',
        );
      }

      final brightnessShift = (l.offset.luminance * 0.15 + l.shadow.luminance * 0.12) * intensity;
      final contrastShift = 1.0 + (l.highlight.luminance * 0.25 - l.shadow.luminance * 0.15) * intensity;

      if (brightnessShift.abs() > 0.005 || (contrastShift - 1.0).abs() > 0.005) {
        filters.add(
          'eq=brightness=${brightnessShift.clamp(-0.5, 0.5).toStringAsFixed(3)}:'
          'contrast=${contrastShift.clamp(0.5, 2.0).toStringAsFixed(3)}',
        );
      }
    }

    return filters;
  }
}
