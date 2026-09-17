import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/caption_line.dart';

class KineticCaptionOverlay extends StatelessWidget {
  final CaptionLine caption;
  final int offsetMs; // current playhead - caption.startTimeMs

  const KineticCaptionOverlay({
    super.key,
    required this.caption,
    required this.offsetMs,
  });

  @override
  Widget build(BuildContext context) {
    final style = caption.style;
    final words = caption.effectiveWords;
    final activeIdx = caption.getActiveWordIndex(offsetMs);

    // Alignment mapping
    final alignX = (style.positionX - 0.5) * 2.0;
    final alignY = (style.positionY - 0.5) * 2.0;

    final baseTextColor = Color(style.textColor);
    final highlightColor = Color(caption.highlightColor);
    final hasHighlight = caption.isKinetic && caption.highlightStyle != KaraokeHighlightStyle.none;

    TextStyle baseTextStyle;
    try {
      baseTextStyle = GoogleFonts.getFont(
        style.fontFamily,
        fontSize: style.fontSize,
        fontWeight: style.isBold ? FontWeight.bold : FontWeight.normal,
        letterSpacing: style.letterSpacing,
      );
    } catch (_) {
      baseTextStyle = TextStyle(
        fontFamily: style.fontFamily,
        fontSize: style.fontSize,
        fontWeight: style.isBold ? FontWeight.bold : FontWeight.normal,
        letterSpacing: style.letterSpacing,
      );
    }

    return Align(
      alignment: Alignment(alignX, alignY),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: style.boxPadding > 0 ? style.boxPadding : 12.0,
          vertical: style.boxPadding > 0 ? style.boxPadding * 0.6 : 6.0,
        ),
        decoration: style.backgroundColor != null
            ? BoxDecoration(
                color: Color(style.backgroundColor!),
                borderRadius: BorderRadius.circular(style.boxCornerRadius),
              )
            : null,
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: style.fontSize * 0.28,
          runSpacing: 4.0,
          children: List.generate(words.length, (idx) {
            final w = words[idx];
            final wordText = style.isUppercase ? w.word.toUpperCase() : w.word;
            final isActive = hasHighlight && idx == activeIdx;

            return _buildWordWidget(
              word: wordText,
              isActive: isActive,
              style: style,
              baseStyle: baseTextStyle,
              baseTextColor: baseTextColor,
              highlightColor: highlightColor,
              highlightStyle: caption.highlightStyle,
              highlightScale: caption.highlightScale,
            );
          }),
        ),
      ),
    );
  }

  Widget _buildWordWidget({
    required String word,
    required bool isActive,
    required dynamic style,
    required TextStyle baseStyle,
    required Color baseTextColor,
    required Color highlightColor,
    required KaraokeHighlightStyle highlightStyle,
    required double highlightScale,
  }) {
    Color wordColor = isActive ? highlightColor : baseTextColor;
    List<Shadow>? wordShadows;
    Widget? backgroundPill;

    if (isActive) {
      switch (highlightStyle) {
        case KaraokeHighlightStyle.colorFill:
          wordColor = highlightColor;
          break;

        case KaraokeHighlightStyle.scalePunch:
          wordColor = highlightColor;
          break;

        case KaraokeHighlightStyle.pillBackground:
          wordColor = Colors.black;
          backgroundPill = Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: highlightColor,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: highlightColor.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          );
          break;

        case KaraokeHighlightStyle.glowWave:
          wordColor = highlightColor;
          wordShadows = [
            Shadow(color: highlightColor, blurRadius: 14),
            Shadow(color: highlightColor.withOpacity(0.8), blurRadius: 24),
            const Shadow(color: Colors.black, blurRadius: 4),
          ];
          break;

        case KaraokeHighlightStyle.none:
          break;
      }
    } else if (style.shadowColor != null && style.shadowBlur > 0) {
      wordShadows = [
        Shadow(
          color: Color(style.shadowColor!),
          blurRadius: style.shadowBlur,
          offset: const Offset(1, 2),
        ),
      ];
    }

    final renderedText = Text(
      word,
      textAlign: TextAlign.center,
      style: baseStyle.copyWith(
        color: wordColor,
        shadows: wordShadows,
      ),
    );

    Widget content = renderedText;
    if (backgroundPill != null) {
      content = Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: backgroundPill),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: renderedText,
          ),
        ],
      );
    }

    if (isActive && (highlightStyle == KaraokeHighlightStyle.scalePunch || highlightStyle == KaraokeHighlightStyle.colorFill)) {
      final scale = highlightStyle == KaraokeHighlightStyle.scalePunch ? highlightScale : 1.08;
      return Transform.scale(
        scale: scale,
        child: content,
      );
    }

    return content;
  }
}
