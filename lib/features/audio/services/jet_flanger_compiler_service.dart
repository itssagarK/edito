import '../models/jet_flanger_config.dart';

/// Compiles jet flanger, barberpole phaser, and metallic comb-filter modulation
/// into deterministic, studio-grade FFmpeg audio filter chains.
class JetFlangerCompilerService {
  /// Compiles the complete FFmpeg audio filter string for flanger/comb modulation.
  /// Strictly includes true-peak brickwall ceiling limiter per AGENTS.md Rule 4.
  static String compileFilter(JetFlangerConfig config) {
    if (!config.isActive) return '';

    final filters = <String>[];
    final speed = config.sweepSpeedHz.clamp(0.05, 5.0).toStringAsFixed(2);
    final depth = config.depthMs.clamp(1.0, 15.0).toStringAsFixed(1);
    final regen = (config.feedback * 100).round().clamp(-95, 95);
    final phasePct = (config.stereoPhaseDeg / 1.8).round().clamp(0, 100); // 0°..180° -> 0%..100%

    switch (config.mode) {
      case JetFlangerMode.jetEngineFlyby:
        // Deep comb delay + high regenerative resonance sweeps
        filters.add('flanger=delay=1.5:depth=$depth:regen=$regen:width=90:speed=$speed:shape=sinusoidal:phase=$phasePct');
        break;

      case JetFlangerMode.barberpolePhaser:
        // High-order infinite phasing simulation with sinusoidal multi-stage aphaser
        final decay = (config.feedback.abs() * 0.75).clamp(0.2, 0.85).toStringAsFixed(2);
        filters.add('aphaser=in_gain=0.6:out_gain=0.8:delay=$depth:decay=$decay:speed=$speed:type=sinusoidal');
        break;

      case JetFlangerMode.metallicResonator:
        // Tight ultra-short delay with ringing positive feedback
        filters.add('flanger=delay=0.4:depth=$depth:regen=$regen:width=95:speed=$speed:shape=triangular:phase=25');
        break;

      case JetFlangerMode.stereoSpreadFlanger:
        // Wide 180° phase flanger + extrastereo widening
        filters.add('flanger=delay=2.0:depth=$depth:regen=$regen:width=85:speed=$speed:shape=sinusoidal:phase=$phasePct');
        filters.add('extrastereo=m=1.45');
        break;

      case JetFlangerMode.deepSpaceComb:
        // Slow ambient comb sweeps
        filters.add('flanger=delay=4.0:depth=$depth:regen=$regen:width=80:speed=$speed:shape=sinusoidal:phase=$phasePct');
        filters.add('extrastereo=m=1.25');
        break;
    }

    // Mix control attenuation if wet/dry balance is below 1.0
    if (config.mix < 0.99) {
      final vol = (0.6 + config.mix * 0.4).toStringAsFixed(2);
      filters.add('volume=$vol');
    }

    // AGENTS.md Rule 4: Mandatory true-peak brickwall ceiling limiter
    filters.add('alimiter=limit=0.95:attack=5:release=50:asc=1');

    return filters.join(',');
  }

  /// Returns user-facing HUD status badge text for the editor viewport.
  static String getJetFlangerBadge(JetFlangerConfig config) {
    if (!config.isActive) return '';
    return '✈️ JET FLANGER: ${config.mode.displayName.toUpperCase()} (${config.sweepSpeedHz.toStringAsFixed(2)}Hz / ${(config.feedback * 100).round()}% REGEN)';
  }
}
