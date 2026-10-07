import '../models/cyber_hud_config.dart';

/// Compiles sci-fi tactical HUD hologram overlays and cyber reticles
/// into deterministic FFmpeg video filter chains.
class CyberHudCompilerService {
  const CyberHudCompilerService();

  /// Compiles the complete FFmpeg video filter string for cyber HUD overlay.
  static String compileFilter(
    CyberHudConfig config, {
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) {
    if (!config.isActive) return '';

    final filters = <String>[];
    final op = config.opacity.clamp(0.1, 1.0);
    final colorHex = _getColorHex(config.color);

    // 1. Tactical grid raster
    final gridAlpha = (op * 0.35).toStringAsFixed(2);
    filters.add('drawgrid=w=iw/12:h=ih/8:c=$colorHex@$gridAlpha:t=1');

    // 2. Scanline rasterization if enabled
    if (config.scanlines) {
      final scanAlpha = (op * 0.22).toStringAsFixed(2);
      filters.add('drawgrid=w=iw:h=4:t=1:c=$colorHex@$scanAlpha');
    }

    // 3. Four corner tactical L-brackets
    final bracketAlpha = op.toStringAsFixed(2);
    // Top-Left corner bracket
    filters.add('drawbox=x=32:y=32:w=48:h=3:c=$colorHex@$bracketAlpha:t=fill');
    filters.add('drawbox=x=32:y=32:w=3:h=48:c=$colorHex@$bracketAlpha:t=fill');
    // Top-Right corner bracket
    filters.add('drawbox=x=iw-80:y=32:w=48:h=3:c=$colorHex@$bracketAlpha:t=fill');
    filters.add('drawbox=x=iw-35:y=32:w=3:h=48:c=$colorHex@$bracketAlpha:t=fill');
    // Bottom-Left corner bracket
    filters.add('drawbox=x=32:y=ih-35:w=48:h=3:c=$colorHex@$bracketAlpha:t=fill');
    filters.add('drawbox=x=32:y=ih-80:w=3:h=48:c=$colorHex@$bracketAlpha:t=fill');
    // Bottom-Right corner bracket
    filters.add('drawbox=x=iw-80:y=ih-35:w=48:h=3:c=$colorHex@$bracketAlpha:t=fill');
    filters.add('drawbox=x=iw-35:y=ih-80:w=3:h=48:c=$colorHex@$bracketAlpha:t=fill');

    // 4. Center reticle crosshair ticks based on mode
    switch (config.mode) {
      case CyberHudMode.tacticalTargeting:
      case CyberHudMode.flightAvionics:
        filters.add('drawbox=x=iw/2-24:y=ih/2-1:w=48:h=2:c=$colorHex@$bracketAlpha:t=fill');
        filters.add('drawbox=x=iw/2-1:y=ih/2-24:w=2:h=48:c=$colorHex@$bracketAlpha:t=fill');
        break;
      case CyberHudMode.radarSonarScan:
      case CyberHudMode.cyberpunkCombat:
      case CyberHudMode.sciFiTelemetry:
        filters.add('drawbox=x=iw/2-16:y=ih/2-1:w=32:h=2:c=$colorHex@$bracketAlpha:t=fill');
        filters.add('drawbox=x=iw/2-1:y=ih/2-16:w=2:h=32:c=$colorHex@$bracketAlpha:t=fill');
        break;
    }

    // 5. Holographic bloom enhancement
    filters.add('unsharp=5:5:1.2:3:3:0.6');

    return filters.join(',');
  }

  static String _getColorHex(CyberHudColor color) {
    switch (color) {
      case CyberHudColor.cyanQuantum:
        return '0x00F0FF';
      case CyberHudColor.neonGreen:
        return '0x00FF66';
      case CyberHudColor.amberWarning:
        return '0xFFFFB800';
      case CyberHudColor.crimsonCombat:
        return '0xFFFF1744';
      case CyberHudColor.violetSyndicate:
        return '0xD500F9';
    }
  }

  /// Returns user-facing HUD status badge text for the editor viewport.
  static String getCyberHudBadge(CyberHudConfig config) {
    if (!config.isActive) return '';
    return '🛡️ CYBER HUD: ${config.mode.label.toUpperCase()} (${config.color.label.toUpperCase()})';
  }
}
