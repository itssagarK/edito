import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/mask_config.dart';

class MaskCompilerService {
  /// Builds a 2D vector [Path] for real-time Flutter canvas clipping and ShaderMask preview.
  static Path buildMaskPath(MaskConfig config, Size size) {
    if (!config.isActive) {
      return Path()..addRect(Offset.zero & size);
    }

    final double w = size.width;
    final double h = size.height;
    final double cx = w * config.centerX;
    final double cy = h * config.centerY;
    final double rx = math.max(4.0, (w * config.width * 0.5));
    final double ry = math.max(4.0, (h * config.height * 0.5));
    final double rad = config.rotation * math.pi / 180.0;

    Path shapePath = Path();

    switch (config.type) {
      case MaskType.none:
        return Path()..addRect(Offset.zero & size);

      case MaskType.linear:
        // Linear split dividing plane: create polygon on one side of dividing line
        final double diag = math.sqrt(w * w + h * h) * 2.0;
        final Matrix4 rotMatrix = Matrix4.identity()
          ..translate(cx, cy)
          ..rotateZ(rad);

        final Path rect = Path()
          ..moveTo(0, -diag)
          ..lineTo(diag, -diag)
          ..lineTo(diag, diag)
          ..lineTo(0, diag)
          ..close();

        shapePath = rect.transform(rotMatrix.storage);
        break;

      case MaskType.radial:
        final Path oval = Path()
          ..addOval(Rect.fromCenter(
            center: Offset.zero,
            width: rx * 2.0,
            height: ry * 2.0,
          ));
        final Matrix4 rotMatrix = Matrix4.identity()
          ..translate(cx, cy)
          ..rotateZ(rad);
        shapePath = oval.transform(rotMatrix.storage);
        break;

      case MaskType.rectangle:
        final double cornerRadius = math.min(rx, ry) * config.roundness;
        final Path rrect = Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: rx * 2.0,
              height: ry * 2.0,
            ),
            Radius.circular(cornerRadius),
          ));
        final Matrix4 rotMatrix = Matrix4.identity()
          ..translate(cx, cy)
          ..rotateZ(rad);
        shapePath = rrect.transform(rotMatrix.storage);
        break;

      case MaskType.filmStrip:
        // Classic 2.39:1 / anamorphic letterbox cutout
        final double barH = ry;
        final Path strip = Path()
          ..addRect(Rect.fromCenter(
            center: Offset.zero,
            width: w * 2.0,
            height: barH * 2.0,
          ));
        final Matrix4 rotMatrix = Matrix4.identity()
          ..translate(cx, cy)
          ..rotateZ(rad);
        shapePath = strip.transform(rotMatrix.storage);
        break;

      case MaskType.heart:
        final Path heart = Path();
        final double s = math.min(rx, ry);
        heart.moveTo(0, s * 0.3);
        heart.cubicTo(-s * 0.8, -s * 0.5, -s * 1.1, s * 0.2, 0, s * 1.1);
        heart.cubicTo(s * 1.1, s * 0.2, s * 0.8, -s * 0.5, 0, s * 0.3);
        heart.close();
        final Matrix4 rotMatrix = Matrix4.identity()
          ..translate(cx, cy)
          ..rotateZ(rad);
        shapePath = heart.transform(rotMatrix.storage);
        break;

      case MaskType.star:
        final Path star = Path();
        final double rOuter = math.min(rx, ry);
        final double rInner = rOuter * 0.45;
        const int points = 5;
        for (int i = 0; i < points * 2; i++) {
          final double currR = (i % 2 == 0) ? rOuter : rInner;
          final double angle = (i * math.pi / points) - (math.pi / 2.0);
          final double x = currR * math.cos(angle);
          final double y = currR * math.sin(angle);
          if (i == 0) {
            star.moveTo(x, y);
          } else {
            star.lineTo(x, y);
          }
        }
        star.close();
        final Matrix4 rotMatrix = Matrix4.identity()
          ..translate(cx, cy)
          ..rotateZ(rad);
        shapePath = star.transform(rotMatrix.storage);
        break;
    }

    if (config.inverted) {
      final Path fullRect = Path()..addRect(Offset.zero & size);
      return Path.combine(PathOperation.difference, fullRect, shapePath);
    }

    return shapePath;
  }

  /// Compiles parameterized FFmpeg filters to apply the alpha mask during video export.
  static List<String> generateFFmpegFilters(
    MaskConfig config, {
    required int outputWidth,
    required int outputHeight,
  }) {
    if (!config.isActive) return [];

    final double w = outputWidth.toDouble();
    final double h = outputHeight.toDouble();
    final double cx = (w * config.centerX).clamp(0.0, w);
    final double cy = (h * config.centerY).clamp(0.0, h);
    final double rx = math.max(4.0, (w * config.width * 0.5));
    final double ry = math.max(4.0, (h * config.height * 0.5));
    final double rad = config.rotation * math.pi / 180.0;
    final double cosTheta = math.cos(rad);
    final double sinTheta = math.sin(rad);

    final bool inv = config.inverted;
    final double masterAlpha = config.opacity.clamp(0.0, 1.0);

    // Coordinate rotation around center (cx, cy)
    // dx = (X - cx)*cos + (Y - cy)*sin
    // dy = -(X - cx)*sin + (Y - cy)*cos
    final String dx = "((X-${cx.toStringAsFixed(1)})*(${cosTheta.toStringAsFixed(4)})+(Y-${cy.toStringAsFixed(1)})*(${sinTheta.toStringAsFixed(4)}))";
    final String dy = "(-(X-${cx.toStringAsFixed(1)})*(${sinTheta.toStringAsFixed(4)})+(Y-${cy.toStringAsFixed(1)})*(${cosTheta.toStringAsFixed(4)}))";

    String alphaExpr;

    switch (config.type) {
      case MaskType.none:
        return [];

      case MaskType.linear:
        // Linear split along dx
        final double featherPx = math.max(1.0, config.feather * math.min(w, h) * 0.25);
        if (config.feather <= 0.001) {
          alphaExpr = "if(gt($dx,0),${inv ? 0 : 255},${inv ? 255 : 0})";
        } else {
          final String fStr = featherPx.toStringAsFixed(1);
          final String scaleStr = (2.0 * featherPx).toStringAsFixed(1);
          if (!inv) {
            alphaExpr = "if(lt($dx,-$fStr),0,if(gt($dx,$fStr),255,255*(($dx+$fStr)/$scaleStr)))";
          } else {
            alphaExpr = "if(lt($dx,-$fStr),255,if(gt($dx,$fStr),0,255*(1.0-(($dx+$fStr)/$scaleStr))))";
          }
        }
        break;

      case MaskType.radial:
        // Elliptical normalized distance squared: Q = (dx/rx)^2 + (dy/ry)^2
        final String qExpr = "(pow(($dx)/${rx.toStringAsFixed(1)},2)+pow(($dy)/${ry.toStringAsFixed(1)},2))";
        final double featherDelta = math.max(0.01, config.feather * 0.5);
        final double qOuter = (1.0 + featherDelta) * (1.0 + featherDelta);
        final String qOuterStr = qOuter.toStringAsFixed(3);
        final String denom = (qOuter - 1.0).toStringAsFixed(3);

        if (config.feather <= 0.001) {
          alphaExpr = "if(lte($qExpr,1.0),${inv ? 0 : 255},${inv ? 255 : 0})";
        } else {
          if (!inv) {
            alphaExpr = "if(lte($qExpr,1.0),255,if(gte($qExpr,$qOuterStr),0,255*(1.0-($qExpr-1.0)/$denom)))";
          } else {
            alphaExpr = "if(lte($qExpr,1.0),0,if(gte($qExpr,$qOuterStr),255,255*(($qExpr-1.0)/$denom)))";
          }
        }
        break;

      case MaskType.rectangle:
        // Box distance m = max(|dx|/rx, |dy|/ry)
        final String mExpr = "max(abs($dx)/${rx.toStringAsFixed(1)},abs($dy)/${ry.toStringAsFixed(1)})";
        final double featherDelta = math.max(0.01, config.feather * 0.35);
        final double mOuter = 1.0 + featherDelta;
        final String mOuterStr = mOuter.toStringAsFixed(3);
        final String denom = featherDelta.toStringAsFixed(3);

        if (config.feather <= 0.001) {
          alphaExpr = "if(lte($mExpr,1.0),${inv ? 0 : 255},${inv ? 255 : 0})";
        } else {
          if (!inv) {
            alphaExpr = "if(lte($mExpr,1.0),255,if(gte($mExpr,$mOuterStr),0,255*(1.0-($mExpr-1.0)/$denom)))";
          } else {
            alphaExpr = "if(lte($mExpr,1.0),0,if(gte($mExpr,$mOuterStr),255,255*(($mExpr-1.0)/$denom)))";
          }
        }
        break;

      case MaskType.filmStrip:
        // Letterbox bars along dy
        final String mExpr = "abs($dy)/${ry.toStringAsFixed(1)}";
        if (!inv) {
          alphaExpr = "if(lte($mExpr,1.0),255,0)";
        } else {
          alphaExpr = "if(lte($mExpr,1.0),0,255)";
        }
        break;

      case MaskType.heart:
      case MaskType.star:
        // Radial envelope boundary with soft decay
        final double s = math.min(rx, ry);
        final String qExpr = "(pow(($dx)/${s.toStringAsFixed(1)},2)+pow(($dy)/${s.toStringAsFixed(1)},2))";
        final double featherDelta = math.max(0.05, config.feather * 0.4);
        final double qOuter = (1.0 + featherDelta) * (1.0 + featherDelta);
        if (!inv) {
          alphaExpr = "if(lte($qExpr,1.0),255,if(gte($qExpr,${qOuter.toStringAsFixed(3)}),0,255*(1.0-($qExpr-1.0)/${(qOuter - 1.0).toStringAsFixed(3)})))";
        } else {
          alphaExpr = "if(lte($qExpr,1.0),0,if(gte($qExpr,${qOuter.toStringAsFixed(3)}),255,255*(($qExpr-1.0)/${(qOuter - 1.0).toStringAsFixed(3)})))";
        }
        break;
    }

    if (masterAlpha < 0.999) {
      alphaExpr = "($alphaExpr)*${masterAlpha.toStringAsFixed(2)}";
    }

    return [
      'format=yuva420p',
      "geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='$alphaExpr'",
    ];
  }
}
