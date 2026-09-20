import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/caption_line.dart';
import '../../services/word_level_aligner_service.dart';

/// CapCut Pro Real-Time Skia GPU Kinetic Karaoke Viewport Compositor
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

    // Alignment mapping (-1.0 to 1.0)
    final alignX = (style.positionX - 0.5) * 2.0;
    final alignY = (style.positionY - 0.5) * 2.0;

    final baseTextColor = Color(style.textColor);
    final highlightColor = Color(caption.highlightColor);
    final inactiveTextColor = Color(caption.inactiveColor);
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

    return RepaintBoundary(
      child: Align(
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

              // Typewriter reveal: future words remain invisible
              if (hasHighlight &&
                  caption.highlightStyle == KaraokeHighlightStyle.typewriterReveal &&
                  activeIdx != -1 &&
                  idx > activeIdx) {
                return const SizedBox.shrink();
              }

              return _buildWordWidget(
                word: wordText,
                wordTimestamp: w,
                isActive: isActive,
                style: style,
                baseStyle: baseTextStyle,
                baseTextColor: baseTextColor,
                inactiveColor: inactiveTextColor,
                highlightColor: highlightColor,
                highlightStyle: caption.highlightStyle,
                highlightScale: caption.highlightScale,
                inactiveOpacity: caption.inactiveOpacity,
                glowRadius: caption.glowRadius,
                hasHighlight: hasHighlight,
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildWordWidget({
    required String word,
    required WordTimestamp wordTimestamp,
    required bool isActive,
    required dynamic style,
    required TextStyle baseStyle,
    required Color baseTextColor,
    required Color inactiveColor,
    required Color highlightColor,
    required KaraokeHighlightStyle highlightStyle,
    required double highlightScale,
    required double inactiveOpacity,
    required double glowRadius,
    required bool hasHighlight,
  }) {
    Color wordColor;
    List<Shadow>? wordShadows;
    Widget? backgroundPill;
    Widget? underlineBar;
    double scale = 1.0;
    double verticalBounce = 0.0;

    if (isActive) {
      wordColor = highlightColor;

      switch (highlightStyle) {
        case KaraokeHighlightStyle.colorFill:
          scale = 1.08;
          break;

        case KaraokeHighlightStyle.scalePunch:
          scale = WordLevelAlignerService.calculateSpringScale(
            offsetMs: offsetMs,
            word: wordTimestamp,
            targetScale: highlightScale,
          );
          break;

        case KaraokeHighlightStyle.pillBackground:
          wordColor = Colors.black;
          scale = 1.05;
          backgroundPill = Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: highlightColor,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: highlightColor.withOpacity(0.55),
                  blurRadius: glowRadius,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          );
          break;

        case KaraokeHighlightStyle.glowWave:
          wordShadows = [
            Shadow(color: highlightColor, blurRadius: glowRadius),
            Shadow(color: highlightColor.withOpacity(0.8), blurRadius: glowRadius * 1.8),
            const Shadow(color: Colors.black, blurRadius: 4),
          ];
          scale = 1.10;
          break;

        case KaraokeHighlightStyle.neonUnderline:
          scale = 1.08;
          underlineBar = Positioned(
            bottom: 0,
            left: 2,
            right: 2,
            child: Container(
              height: 3.5,
              decoration: BoxDecoration(
                color: highlightColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: highlightColor.withOpacity(0.8),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          );
          break;

        case KaraokeHighlightStyle.bouncePop:
          scale = WordLevelAlignerService.calculateSpringScale(
            offsetMs: offsetMs,
            word: wordTimestamp,
            targetScale: highlightScale,
          );
          verticalBounce = WordLevelAlignerService.calculateVerticalBounce(
            offsetMs: offsetMs,
            word: wordTimestamp,
          );
          break;

        case KaraokeHighlightStyle.typewriterReveal:
          scale = 1.0;
          break;

        case KaraokeHighlightStyle.none:
          wordColor = baseTextColor;
          break;
      }
    } else {
      // Inactive word dimming
      if (hasHighlight) {
        wordColor = inactiveColor.withOpacity(inactiveOpacity.clamp(0.1, 1.0));
      } else {
        wordColor = baseTextColor;
      }

      if (style.shadowColor != null && style.shadowBlur > 0) {
        wordShadows = [
          Shadow(
            color: Color(style.shadowColor!),
            blurRadius: style.shadowBlur,
            offset: const Offset(1, 2),
          ),
        ];
      }
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
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: backgroundPill),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            child: renderedText,
          ),
        ],
      );
    } else if (underlineBar != null) {
      content = Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 5.0),
            child: renderedText,
          ),
          underlineBar,
        ],
      );
    }

    if (verticalBounce != 0.0) {
      content = Transform.translate(
        offset: Offset(0, verticalBounce),
        child: content,
      );
    }

    if (scale != 1.0) {
      content = Transform.scale(
        scale: scale,
        child: content,
      );
    }

    return content;
  }
}
