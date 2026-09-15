import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/audio_effects_config.dart';

class ParametricEQCurveWidget extends StatefulWidget {
  final AudioEffectsConfig config;
  final ValueChanged<AudioEffectsConfig> onChanged;
  final double height;

  const ParametricEQCurveWidget({
    super.key,
    required this.config,
    required this.onChanged,
    this.height = 180,
  });

  @override
  State<ParametricEQCurveWidget> createState() => _ParametricEQCurveWidgetState();
}

class _ParametricEQCurveWidgetState extends State<ParametricEQCurveWidget> {
  int? _activeNodeIndex; // 0 = Low, 1 = Mid, 2 = High

  // Frequency range: 20 Hz to 20,000 Hz (logarithmic)
  static const double _minFreq = 20.0;
  static const double _maxFreq = 20000.0;
  // Gain range: -15 dB to +15 dB
  static const double _minGain = -15.0;
  static const double _maxGain = 15.0;

  static double freqToNormX(double freq) {
    final logMin = log(_minFreq);
    final logMax = log(_maxFreq);
    final logF = log(freq.clamp(_minFreq, _maxFreq));
    return (logF - logMin) / (logMax - logMin);
  }

  static double normXToFreq(double normX) {
    final logMin = log(_minFreq);
    final logMax = log(_maxFreq);
    final logF = logMin + normX.clamp(0.0, 1.0) * (logMax - logMin);
    return exp(logF);
  }

  static double gainToNormY(double gain) {
    return (1.0 - (gain - _minGain) / (_maxGain - _minGain)).clamp(0.0, 1.0);
  }

  static double normYToGain(double normY) {
    return _maxGain - normY.clamp(0.0, 1.0) * (_maxGain - _minGain);
  }

  void _handlePanStart(DragStartDetails details, Size size) {
    final pos = details.localPosition;
    final lowX = freqToNormX(widget.config.eqLowFreq) * size.width;
    final lowY = gainToNormY(widget.config.eqLowGain) * size.height;

    final midX = freqToNormX(widget.config.eqMidFreq) * size.width;
    final midY = gainToNormY(widget.config.eqMidGain) * size.height;

    final highX = freqToNormX(widget.config.eqHighFreq) * size.width;
    final highY = gainToNormY(widget.config.eqHighGain) * size.height;

    final touchRadius = 36.0;
    double dist(double x1, double y1, double x2, double y2) =>
        sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));

    final dLow = dist(pos.dx, pos.dy, lowX, lowY);
    final dMid = dist(pos.dx, pos.dy, midX, midY);
    final dHigh = dist(pos.dx, pos.dy, highX, highY);

    if (dMid <= touchRadius && dMid <= dLow && dMid <= dHigh) {
      setState(() => _activeNodeIndex = 1);
    } else if (dLow <= touchRadius && dLow <= dHigh) {
      setState(() => _activeNodeIndex = 0);
    } else if (dHigh <= touchRadius) {
      setState(() => _activeNodeIndex = 2);
    } else {
      // Find whichever is horizontally closest
      final closestDist = [dLow, dMid, dHigh]..sort();
      if (closestDist.first < touchRadius * 1.5) {
        if (closestDist.first == dMid) {
          setState(() => _activeNodeIndex = 1);
        } else if (closestDist.first == dLow) {
          setState(() => _activeNodeIndex = 0);
        } else {
          setState(() => _activeNodeIndex = 2);
        }
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    if (_activeNodeIndex == null) return;

    final normX = (details.localPosition.dx / size.width).clamp(0.0, 1.0);
    final normY = (details.localPosition.dy / size.height).clamp(0.0, 1.0);
    final newFreq = normXToFreq(normX);
    final newGain = double.parse(normYToGain(normY).toStringAsFixed(1));

    AudioEffectsConfig updated = widget.config;
    switch (_activeNodeIndex!) {
      case 0: // Low band: 30 to 400 Hz
        updated = widget.config.copyWith(
          isEqualizerEnabled: true,
          equalizerPreset: EqualizerPreset.custom,
          eqLowFreq: newFreq.clamp(30.0, 400.0),
          eqLowGain: newGain.clamp(_minGain, _maxGain),
        );
        break;
      case 1: // Mid band: 400 to 5000 Hz
        updated = widget.config.copyWith(
          isEqualizerEnabled: true,
          equalizerPreset: EqualizerPreset.custom,
          eqMidFreq: newFreq.clamp(400.0, 5000.0),
          eqMidGain: newGain.clamp(_minGain, _maxGain),
        );
        break;
      case 2: // High band: 5000 to 18000 Hz
        updated = widget.config.copyWith(
          isEqualizerEnabled: true,
          equalizerPreset: EqualizerPreset.custom,
          eqHighFreq: newFreq.clamp(5000.0, 18000.0),
          eqHighGain: newGain.clamp(_minGain, _maxGain),
        );
        break;
    }

    widget.onChanged(updated);
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() => _activeNodeIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = widget.height;
        final size = Size(width, height);

        return GestureDetector(
          onPanStart: (d) => _handlePanStart(d, size),
          onPanUpdate: (d) => _handlePanUpdate(d, size),
          onPanEnd: _handlePanEnd,
          onPanCancel: () => setState(() => _activeNodeIndex = null),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  CustomPaint(
                    size: size,
                    painter: _EQCurvePainter(
                      config: widget.config,
                      activeNodeIndex: _activeNodeIndex,
                    ),
                  ),
                  // Active Floating Bubble
                  if (_activeNodeIndex != null) _buildActiveTooltip(size),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveTooltip(Size size) {
    double freq = 0;
    double gain = 0;
    String label = '';
    Color color = AppColors.accent;

    if (_activeNodeIndex == 0) {
      freq = widget.config.eqLowFreq;
      gain = widget.config.eqLowGain;
      label = 'LOW SHELF';
      color = const Color(0xFF00E5FF);
    } else if (_activeNodeIndex == 1) {
      freq = widget.config.eqMidFreq;
      gain = widget.config.eqMidGain;
      label = 'MID BELL';
      color = const Color(0xFFFF9100);
    } else {
      freq = widget.config.eqHighFreq;
      gain = widget.config.eqHighGain;
      label = 'HIGH SHELF';
      color = const Color(0xFFD500F9);
    }

    final nx = freqToNormX(freq) * size.width;
    final ny = gainToNormY(gain) * size.height;

    final freqStr = freq >= 1000 ? '${(freq / 1000).toStringAsFixed(1)} kHz' : '${freq.toInt()} Hz';
    final gainStr = gain > 0 ? '+${gain.toStringAsFixed(1)} dB' : '${gain.toStringAsFixed(1)} dB';

    return Positioned(
      left: (nx - 55).clamp(8.0, size.width - 118.0),
      top: (ny - 42).clamp(6.0, size.height - 40.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              '$freqStr  $gainStr',
              style: AppTypography.timecode.copyWith(fontSize: 10, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _EQCurvePainter extends CustomPainter {
  final AudioEffectsConfig config;
  final int? activeNodeIndex;

  _EQCurvePainter({
    required this.config,
    required this.activeNodeIndex,
  });

  // Logarithmic evaluation of combined EQ curve in dB
  double _evaluateEQ(double f) {
    double totalDb = 0.0;

    // High-pass filter roll-off (12dB/octave below cutoff)
    if (config.highPassCutoff > 20.0 && f < config.highPassCutoff) {
      final octavesBelow = log(config.highPassCutoff / f) / ln2;
      totalDb -= octavesBelow * 12.0;
    }

    // Low-pass filter roll-off (12dB/octave above cutoff)
    if (config.lowPassCutoff < 20000.0 && f > config.lowPassCutoff) {
      final octavesAbove = log(f / config.lowPassCutoff) / ln2;
      totalDb -= octavesAbove * 12.0;
    }

    // Low shelf filter
    if (config.eqLowGain.abs() > 0.05) {
      final ratio = f / config.eqLowFreq;
      final shelf = 1.0 / (1.0 + pow(ratio, 2));
      totalDb += config.eqLowGain * shelf;
    }

    // Mid peaking / bell filter
    if (config.eqMidGain.abs() > 0.05) {
      final logF = log(f);
      final logCenter = log(config.eqMidFreq);
      final octDiff = (logF - logCenter) / ln2;
      final bw = 1.0 / config.eqMidQ;
      final bell = exp(-pow(octDiff / (bw * 0.8), 2));
      totalDb += config.eqMidGain * bell;
    }

    // High shelf filter
    if (config.eqHighGain.abs() > 0.05) {
      final ratio = f / config.eqHighFreq;
      final shelf = pow(ratio, 2) / (1.0 + pow(ratio, 2));
      totalDb += config.eqHighGain * shelf;
    }

    return totalDb.clamp(-18.0, 18.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1.0;

    final zeroLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.20)
      ..strokeWidth = 1.2;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 1. Draw dB Horizontal Grid Lines & Labels
    final gains = [-12.0, -6.0, 0.0, 6.0, 12.0];
    for (final g in gains) {
      final y = _ParametricEQCurveWidgetState.gainToNormY(g) * size.height;
      if (g == 0.0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), zeroLinePaint);
      } else {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }

      textPainter.text = TextSpan(
        text: '${g > 0 ? "+" : ""}${g.toInt()}dB',
        style: TextStyle(
          fontSize: 8,
          color: g == 0.0 ? Colors.white70 : Colors.white30,
          fontFamily: 'monospace',
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(4, y - 5));
    }

    // 2. Draw Frequency Vertical Grid Lines & Labels
    final freqs = [100.0, 1000.0, 10000.0];
    for (final f in freqs) {
      final x = _ParametricEQCurveWidgetState.freqToNormX(f) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);

      final label = f >= 1000 ? '${(f / 1000).toInt()}k' : '${f.toInt()}';
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 8,
          color: Colors.white30,
          fontFamily: 'monospace',
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2), size.height - 12));
    }

    // 3. Draw EQ Response Curve & Gradient Fill
    final curvePath = Path();
    final fillPath = Path();
    const steps = 120;

    final zeroY = _ParametricEQCurveWidgetState.gainToNormY(0.0) * size.height;
    fillPath.moveTo(0, zeroY);

    for (int i = 0; i <= steps; i++) {
      final normX = i / steps;
      final f = _ParametricEQCurveWidgetState.normXToFreq(normX);
      final gainDb = _evaluateEQ(f);
      final x = normX * size.width;
      final y = _ParametricEQCurveWidgetState.gainToNormY(gainDb) * size.height;

      if (i == 0) {
        curvePath.moveTo(x, y);
      } else {
        curvePath.lineTo(x, y);
      }
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(size.width, zeroY);
    fillPath.close();

    // Fill under curve
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.accent.withOpacity(0.25),
        AppColors.accent.withOpacity(0.03),
      ],
    );
    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Glowing Curve Stroke
    final glowPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(curvePath, glowPaint);

    final curveStrokePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(curvePath, curveStrokePaint);

    // 4. Draw Interactive Node Handles (Low, Mid, High)
    _drawNode(
      canvas: canvas,
      size: size,
      nodeIndex: 0,
      freq: config.eqLowFreq,
      gain: config.eqLowGain,
      color: const Color(0xFF00E5FF),
      label: 'L',
    );

    _drawNode(
      canvas: canvas,
      size: size,
      nodeIndex: 1,
      freq: config.eqMidFreq,
      gain: config.eqMidGain,
      color: const Color(0xFFFF9100),
      label: 'M',
    );

    _drawNode(
      canvas: canvas,
      size: size,
      nodeIndex: 2,
      freq: config.eqHighFreq,
      gain: config.eqHighGain,
      color: const Color(0xFFD500F9),
      label: 'H',
    );
  }

  void _drawNode({
    required Canvas canvas,
    required Size size,
    required int nodeIndex,
    required double freq,
    required double gain,
    required Color color,
    required String label,
  }) {
    final x = _ParametricEQCurveWidgetState.freqToNormX(freq) * size.width;
    final y = _ParametricEQCurveWidgetState.gainToNormY(gain) * size.height;
    final isSelected = activeNodeIndex == nodeIndex;

    // Outer glow
    canvas.drawCircle(
      Offset(x, y),
      isSelected ? 14.0 : 10.0,
      Paint()..color = color.withOpacity(isSelected ? 0.45 : 0.20),
    );

    // Node body
    canvas.drawCircle(
      Offset(x, y),
      isSelected ? 8.0 : 6.5,
      Paint()..color = color,
    );

    // Inner center
    canvas.drawCircle(
      Offset(x, y),
      isSelected ? 4.0 : 3.0,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _EQCurvePainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.activeNodeIndex != activeNodeIndex;
  }
}
