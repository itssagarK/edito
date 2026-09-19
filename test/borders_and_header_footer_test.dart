import 'package:flutter_test/flutter_test.dart';
import 'package:edito/models/clip.dart';
import 'package:edito/features/borders/models/video_border_config.dart';
import 'package:edito/features/borders/services/video_border_compiler_service.dart';
import 'package:edito/features/header_footer/models/header_footer_config.dart';
import 'package:edito/features/header_footer/services/header_footer_compiler_service.dart';

void main() {
  group('VideoBorderConfig & Service Tests', () {
    test('Default VideoBorderConfig has expected disabled defaults', () {
      const config = VideoBorderConfig();
      expect(config.isEnabled, false);
      expect(config.style, VideoBorderStyle.solid);
      expect(config.borderWidth, 8.0);
      expect(config.borderRadius, 0.0);
      expect(config.primaryColor, 0xFFFFFFFF);
      expect(config.opacity, 1.0);
    });

    test('BorderPreset correctly instantiates presets', () {
      final neon = BorderPreset.cyberpunkNeon.createConfig();
      expect(neon.isEnabled, true);
      expect(neon.style, VideoBorderStyle.neonGlow);
      expect(neon.primaryColor, 0xFF00E5FF);
      expect(neon.glowIntensity, greaterThan(0.5));

      final letterbox = BorderPreset.roundedCard.createConfig();
      expect(letterbox.isEnabled, true);
      expect(letterbox.style, VideoBorderStyle.roundedCard);

      final film = BorderPreset.filmStrip35mm.createConfig();
      expect(film.isEnabled, true);
      expect(film.style, VideoBorderStyle.filmStrip);
    });

    test('VideoBorderConfig JSON serialization roundtrip preserves all values', () {
      final config = BorderPreset.goldLuxury.createConfig();
      final json = config.toJson();
      final revived = VideoBorderConfig.fromJson(json);

      expect(revived.isEnabled, config.isEnabled);
      expect(revived.style, config.style);
      expect(revived.borderWidth, config.borderWidth);
      expect(revived.primaryColor, config.primaryColor);
      expect(revived.secondaryColor, config.secondaryColor);
      expect(revived.glowIntensity, config.glowIntensity);
      expect(revived.borderRadius, config.borderRadius);
      expect(revived, equals(config));
    });

    test('VideoBorderCompilerService generates drawbox filters when enabled', () {
      final config = BorderPreset.cleanWhite.createConfig();
      final filter = VideoBorderCompilerService.generateFFmpegFilter(
        config,
        targetWidth: 1920,
        targetHeight: 1080,
      );

      expect(filter, isNotEmpty);
      expect(filter, contains('drawbox=x=0:y=0:w=1920'));
      expect(filter, contains('drawbox=x=0:y=1080-'));

      // Disabled config returns empty filter
      const disabledConfig = VideoBorderConfig(isEnabled: false);
      final emptyFilter = VideoBorderCompilerService.generateFFmpegFilter(
        disabledConfig,
        targetWidth: 1920,
        targetHeight: 1080,
      );
      expect(emptyFilter, isEmpty);
    });

    test('VideoBorderCompilerService generates HUD badges', () {
      const disabled = VideoBorderConfig(isEnabled: false);
      expect(VideoBorderCompilerService.getBorderBadge(disabled), isEmpty);

      final neon = BorderPreset.cyberpunkNeon.createConfig();
      final badge = VideoBorderCompilerService.getBorderBadge(neon);
      expect(badge, contains('NEON'));
      expect(badge, contains('PX'));
    });
  });

  group('HeaderFooterConfig & Service Tests', () {
    test('Default HeaderFooterConfig has active overlay false', () {
      const config = HeaderFooterConfig();
      expect(config.isHeaderEnabled, false);
      expect(config.isFooterEnabled, false);
      expect(config.hasActiveOverlay, false);
    });

    test('HeaderFooterPreset correctly creates presets', () {
      final viral = HeaderFooterPreset.socialReelsViral.createConfig();
      expect(viral.isHeaderEnabled, true);
      expect(viral.isFooterEnabled, true);
      expect(viral.hasActiveOverlay, true);
      expect(viral.headerText, isNotEmpty);
      expect(viral.footerText, isNotEmpty);
      expect(viral.headerEmoji, '🔥');

      final news = HeaderFooterPreset.breakingNews.createConfig();
      expect(news.isHeaderEnabled, true);
      expect(news.headerText, contains('BREAKING NEWS'));
      expect(news.headerEmoji, '🔴');
    });

    test('HeaderFooterConfig JSON serialization roundtrip preserves all values', () {
      final config = HeaderFooterPreset.podcastStudio.createConfig();
      final json = config.toJson();
      final revived = HeaderFooterConfig.fromJson(json);

      expect(revived.isHeaderEnabled, config.isHeaderEnabled);
      expect(revived.isFooterEnabled, config.isFooterEnabled);
      expect(revived.headerText, config.headerText);
      expect(revived.footerText, config.footerText);
      expect(revived.headerFont, config.headerFont);
      expect(revived.footerFont, config.footerFont);
      expect(revived.headerStyle, config.headerStyle);
      expect(revived.headerAnimation, config.headerAnimation);
      expect(revived, equals(config));
    });

    test('HeaderFooterCompilerService generates drawbox and drawtext filters', () {
      final config = HeaderFooterPreset.breakingNews.createConfig();
      final filter = HeaderFooterCompilerService.generateFFmpegFilter(
        config,
        clipDurationMs: 5000,
        targetWidth: 1920,
        targetHeight: 1080,
      );

      expect(filter, isNotEmpty);
      expect(filter, contains('drawbox=x=0:y=0:w=1920'));
      expect(filter, contains('drawtext=text='));
      expect(filter, contains('BREAKING NEWS'));
      expect(filter, contains('DEVELOPING NEWS'));

      // Disabled config returns empty filter
      const disabled = HeaderFooterConfig();
      expect(HeaderFooterCompilerService.generateFFmpegFilter(
        disabled,
        clipDurationMs: 5000,
        targetWidth: 1920,
        targetHeight: 1080,
      ), isEmpty);
    });

    test('HeaderFooterCompilerService generates HUD badges', () {
      const disabled = HeaderFooterConfig();
      expect(HeaderFooterCompilerService.getHeaderFooterBadge(disabled), isEmpty);

      final viral = HeaderFooterPreset.socialReelsViral.createConfig();
      final badge = HeaderFooterCompilerService.getHeaderFooterBadge(viral);
      expect(badge, '📌 HEADER & FOOTER ACTIVE');

      final headerOnly = viral.copyWith(isFooterEnabled: false);
      expect(HeaderFooterCompilerService.getHeaderFooterBadge(headerOnly), '📌 TOP HEADER ACTIVE');
    });
  });

  group('Clip Integration Tests', () {
    test('Clip model has safe defaults for border and headerFooter', () {
      const clip = Clip(
        id: 'clip-1',
        assetId: 'asset-1',
        trackId: 'track-1',
        startTimeMs: 0,
        durationMs: 5000,
        sourceInMs: 0,
        sourceOutMs: 5000,
      );

      expect(clip.border.isEnabled, false);
      expect(clip.headerFooter.hasActiveOverlay, false);
    });

    test('Clip model supports copyWith and serialization with border and headerFooter', () {
      const clip = Clip(
        id: 'clip-2',
        assetId: 'asset-2',
        trackId: 'track-1',
        startTimeMs: 1000,
        durationMs: 4000,
        sourceInMs: 0,
        sourceOutMs: 4000,
      );

      final border = BorderPreset.cyberpunkNeon.createConfig();
      final headerFooter = HeaderFooterPreset.socialReelsViral.createConfig();

      final updatedClip = clip.copyWith(
        border: border,
        headerFooter: headerFooter,
      );

      expect(updatedClip.border.isEnabled, true);
      expect(updatedClip.headerFooter.hasActiveOverlay, true);

      final json = updatedClip.toJson();
      final revivedClip = Clip.fromJson(json);

      expect(revivedClip.border.isEnabled, true);
      expect(revivedClip.border.style, VideoBorderStyle.neonGlow);
      expect(revivedClip.headerFooter.isHeaderEnabled, true);
      expect(revivedClip.headerFooter.headerText, contains('VIDEO EDITING'));
      expect(revivedClip, equals(updatedClip));
    });
  });
}
