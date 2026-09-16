import '../models/vfx_config.dart';

class VfxCompilerService {
  /// Compiles deterministic FFmpeg video filters for cinematic VFX & motion effects
  static List<String> generateFFmpegFilters(VfxConfig config) {
    if (!config.isActive) return [];

    final filters = <String>[];

    switch (config.type) {
      case VfxType.filmGrain:
        // Authentic 35mm analog film grain using temporal uniform noise
        final noiseLevel = (config.intensity * 40).clamp(5, 50).toInt();
        filters.add('noise=alls=$noiseLevel:allf=t+u');
        break;

      case VfxType.rgbGlitch:
        // Chromatic aberration / RGB channel split displacement
        final shift = (config.rgbOffset * config.intensity).round().clamp(2, 30);
        filters.add('rgbashift=rh=$shift:bh=-$shift');
        break;

      case VfxType.lensBlur:
        // Optical Gaussian lens defocus blur
        final sigma = (config.blurRadius * config.intensity).clamp(0.5, 25.0).toStringAsFixed(1);
        filters.add('gblur=sigma=$sigma:steps=2');
        break;

      case VfxType.vhsVintage:
        // 80s analog camcorder CRT scanlines, desaturated tape warmth, and noise
        final noiseLevel = (config.intensity * 22).clamp(5, 30).toInt();
        filters.add("curves=all='0/0 0.5/0.46 1/0.95':r='0/0 1/0.92':b='0/0.06 1/0.88'");
        filters.add('noise=alls=$noiseLevel:allf=t');
        filters.add('vignette=PI/4');
        break;

      case VfxType.vignette:
        // Darkened optical perimeter falloff
        final angle = (0.25 + (1.0 - config.vignetteRadius) * 0.75 * config.intensity).clamp(0.2, 1.2).toStringAsFixed(2);
        filters.add('vignette=angle=$angle');
        break;

      case VfxType.lightLeak:
        // Warm anamorphic golden hour sun flare pulses
        filters.add('colorchannelmixer=rr=1.14:rg=0.08:rb=0:gr=0:gg=1.04:gb=0:br=0:bg=0:bb=0.90');
        filters.add("curves=r='0/0.06 1/1'");
        break;

      case VfxType.cameraShake:
        // Organic handheld camera tremor
        final amp = (config.shakeAmplitude * config.intensity).clamp(4.0, 30.0).toInt();
        final halfAmp = (amp / 2).toInt();
        filters.add("crop=w=iw-$amp:h=ih-$amp:x='(iw-ow)/2+sin(n*1.8)*$halfAmp':y='(ih-oh)/2+cos(n*1.4)*$halfAmp',scale=iw+$amp:ih+$amp");
        break;

      case VfxType.radialZoom:
        // High-velocity action zoom blur
        final blur = (config.blurRadius * config.intensity * 0.4).clamp(0.5, 12.0).toStringAsFixed(1);
        filters.add('scale=iw*1.05:ih*1.05,crop=iw/1.05:ih/1.05');
        filters.add('gblur=sigma=$blur:steps=1');
        break;

      case VfxType.none:
        break;
    }

    return filters;
  }

  /// Returns a concise HUD badge descriptor for real-time viewport display
  static String getVfxBadge(VfxConfig config) {
    if (!config.isActive) return '';

    switch (config.type) {
      case VfxType.filmGrain:
        return '🎞️ FILM GRAIN (${(config.intensity * 100).toInt()}%)';
      case VfxType.rgbGlitch:
        return '⚡ RGB GLITCH (${(config.rgbOffset * config.intensity).toInt()}px)';
      case VfxType.lensBlur:
        return '🌫️ LENS BLUR (${(config.blurRadius * config.intensity).toInt()}px)';
      case VfxType.vhsVintage:
        return '📼 RETRO VHS';
      case VfxType.vignette:
        return '🎬 VIGNETTE (${(config.intensity * 100).toInt()}%)';
      case VfxType.lightLeak:
        return '☀️ LIGHT LEAK';
      case VfxType.cameraShake:
        return '📳 CAMERA SHAKE';
      case VfxType.radialZoom:
        return '🚀 RADIAL ZOOM';
      case VfxType.none:
        return '';
    }
  }
}
