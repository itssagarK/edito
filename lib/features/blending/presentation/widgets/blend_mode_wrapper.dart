import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../models/blend_mode_config.dart';
import '../../services/blend_mode_compiler_service.dart';

class BlendModeWrapper extends StatelessWidget {
  final BlendModeConfig config;
  final Widget child;

  const BlendModeWrapper({
    super.key,
    required this.config,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.isEnabled) return child;

    Widget content = child;

    // Apply master layer opacity if less than 1.0
    if (config.opacity < 0.999) {
      content = Opacity(
        opacity: config.opacity.clamp(0.0, 1.0),
        child: content,
      );
    }

    // Apply GPU layer blend mode if not normal
    if (config.mode != ProBlendMode.normal) {
      final flutterBlend = BlendModeCompilerService.toFlutterBlendMode(config.mode);
      content = _LayerBlendWidget(
        blendMode: flutterBlend,
        child: content,
      );
    }

    return content;
  }
}

class _LayerBlendWidget extends SingleChildRenderObjectWidget {
  final BlendMode blendMode;

  const _LayerBlendWidget({
    required this.blendMode,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderLayerBlend(blendMode: blendMode);
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderLayerBlend renderObject) {
    renderObject.blendMode = blendMode;
  }
}

class _RenderLayerBlend extends RenderProxyBox {
  BlendMode _blendMode;

  _RenderLayerBlend({required BlendMode blendMode}) : _blendMode = blendMode;

  BlendMode get blendMode => _blendMode;

  set blendMode(BlendMode value) {
    if (_blendMode != value) {
      _blendMode = value;
      markNeedsPaint();
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;

    final Paint paint = Paint()..blendMode = _blendMode;
    context.canvas.saveLayer(offset & size, paint);
    context.paintChild(child!, offset);
    context.canvas.restore();
  }
}
