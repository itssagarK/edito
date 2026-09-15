import 'package:flutter/material.dart';
import '../../models/chroma_key_config.dart';
import '../../services/chroma_key_compiler_service.dart';

class ChromaKeyPreviewWrapper extends StatelessWidget {
  final ChromaKeyConfig config;
  final Widget child;

  const ChromaKeyPreviewWrapper({
    super.key,
    required this.config,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.isEnabled) return child;

    // Apply Skia 4x5 Color Matrix for real-time color spill suppression
    final matrix = ChromaKeyCompilerService.generateSpillMatrix(config);

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(matrix),
      child: child,
    );
  }
}
