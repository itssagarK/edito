import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Sound Effect Model representing a cinematic SFX audio item
/// Supports both bundled audio assets and deterministic native FFmpeg procedural audio synthesis.
class SoundEffectItem extends Equatable {
  final String id;
  final String name;
  final String category;
  final int durationMs;
  final IconData icon;
  final Color color;
  final String? assetPath;
  final String ffmpegAudioGenerator;
  final List<double> pcmPeaks;

  const SoundEffectItem({
    required this.id,
    required this.name,
    required this.category,
    required this.durationMs,
    required this.icon,
    required this.color,
    this.assetPath,
    required this.ffmpegAudioGenerator,
    required this.pcmPeaks,
  });

  @override
  List<Object?> get props => [id, name, category, durationMs, assetPath, ffmpegAudioGenerator];

  /// Curated CapCut-Style Sound Effects Library including native assets
  static const List<SoundEffectItem> library = [
    // --- 1. TRANSITIONS & WHOOSHES ---
    SoundEffectItem(
      id: 'motion_whoosh',
      name: 'Motion Swell & Swoosh',
      category: 'Transitions',
      durationMs: 2200,
      icon: Icons.blur_linear,
      color: Color(0xFF8E44AD),
      assetPath: 'assets/audio/motion_whoosh.mp3',
      ffmpegAudioGenerator: 'afade=t=in:ss=0:d=0.4,afade=t=out:st=1.8:d=0.4',
      pcmPeaks: [0.05, 0.15, 0.35, 0.65, 0.95, 0.85, 0.5, 0.25, 0.1, 0.03],
    ),
    SoundEffectItem(
      id: 'whoosh_fast',
      name: 'Fast Air Whoosh',
      category: 'Transitions',
      durationMs: 800,
      icon: Icons.air,
      color: Color(0xFF00E5FF),
      assetPath: 'assets/audio/motion_whoosh.mp3',
      ffmpegAudioGenerator: 'anoisesrc=d=0.8:c=pink:r=48000:a=0.5,bandpass=f=1200:w=800,afade=t=in:ss=0:d=0.3,afade=t=out:st=0.4:d=0.4',
      pcmPeaks: [0.1, 0.2, 0.4, 0.85, 0.95, 0.7, 0.35, 0.15, 0.05],
    ),
    SoundEffectItem(
      id: 'whoosh_cinematic',
      name: 'Cinematic Swish',
      category: 'Transitions',
      durationMs: 1400,
      icon: Icons.waves,
      color: Color(0xFF6C5CE7),
      assetPath: 'assets/audio/motion_whoosh.mp3',
      ffmpegAudioGenerator: 'anoisesrc=d=1.4:c=brown:r=48000:a=0.6,lowpass=f=2000,afade=t=in:ss=0:d=0.6,afade=t=out:st=0.7:d=0.7',
      pcmPeaks: [0.08, 0.18, 0.35, 0.65, 0.92, 0.88, 0.55, 0.3, 0.12, 0.04],
    ),
    SoundEffectItem(
      id: 'whip_pan',
      name: 'Whip Pan Snap',
      category: 'Transitions',
      durationMs: 600,
      icon: Icons.swipe,
      color: Color(0xFFFF7675),
      assetPath: 'assets/audio/tactile_click.wav',
      ffmpegAudioGenerator: 'anoisesrc=d=0.6:c=white:r=48000:a=0.7,bandpass=f=2500:w=1200,afade=t=in:ss=0:d=0.15,afade=t=out:st=0.25:d=0.35',
      pcmPeaks: [0.15, 0.45, 0.98, 0.75, 0.35, 0.1],
    ),

    // --- 2. IMPACTS & BOOMS ---
    SoundEffectItem(
      id: 'cinematic_boom',
      name: 'Sub Bass Impact',
      category: 'Impacts',
      durationMs: 2200,
      icon: Icons.flash_on,
      color: Color(0xFFFF2D55),
      assetPath: 'assets/audio/ambient_tone.mp3',
      ffmpegAudioGenerator: 'sine=f=55:d=2.2,afade=t=out:st=0.2:d=2.0,volume=1.4,alimiter=limit=0.95:attack=5:release=50:asc=1',
      pcmPeaks: [0.98, 0.92, 0.84, 0.72, 0.58, 0.42, 0.3, 0.2, 0.12, 0.06],
    ),
    SoundEffectItem(
      id: 'heavy_thud',
      name: 'Heavy Metal Hit',
      category: 'Impacts',
      durationMs: 1200,
      icon: Icons.front_hand,
      color: Color(0xFFFFB300),
      assetPath: 'assets/audio/tactile_click.wav',
      ffmpegAudioGenerator: 'sine=f=110:d=1.2,afade=t=out:st=0.1:d=1.1,flanger=delay=5:depth=2',
      pcmPeaks: [0.95, 0.8, 0.55, 0.35, 0.22, 0.12, 0.05],
    ),

    // --- 3. RISERS & TENSION ---
    SoundEffectItem(
      id: 'white_noise_riser',
      name: 'White Noise Riser',
      category: 'Risers',
      durationMs: 3000,
      icon: Icons.trending_up,
      color: Color(0xFF00FF88),
      assetPath: 'assets/audio/ambient_tone.mp3',
      ffmpegAudioGenerator: 'anoisesrc=d=3.0:c=white:r=48000:a=0.6,bandpass=f=2000:w=1500,afade=t=in:ss=0:d=2.8,afade=t=out:st=2.8:d=0.2',
      pcmPeaks: [0.05, 0.1, 0.18, 0.28, 0.42, 0.58, 0.75, 0.88, 0.98],
    ),
    SoundEffectItem(
      id: 'tension_drone',
      name: 'Suspense Drone',
      category: 'Risers',
      durationMs: 3500,
      icon: Icons.graphic_eq,
      color: Color(0xFFBD00FF),
      assetPath: 'assets/audio/ambient_tone.mp3',
      ffmpegAudioGenerator: 'sine=f=80:d=3.5,chorus=0.7:0.9:55:0.4:0.25:2,afade=t=in:ss=0:d=1.0,afade=t=out:st=2.5:d=1.0',
      pcmPeaks: [0.3, 0.45, 0.6, 0.68, 0.72, 0.75, 0.72, 0.55, 0.35],
    ),

    // --- 4. TACTILE & UI ---
    SoundEffectItem(
      id: 'tactile_snap',
      name: 'Tactile Shutter & Snap',
      category: 'Tactile & UI',
      durationMs: 500,
      icon: Icons.camera_alt,
      color: Color(0xFF00CEC9),
      assetPath: 'assets/audio/tactile_click.wav',
      ffmpegAudioGenerator: 'afade=t=out:st=0.1:d=0.4',
      pcmPeaks: [0.85, 0.98, 0.6, 0.25, 0.08],
    ),
    SoundEffectItem(
      id: 'smooth_pop',
      name: 'Smooth Bubble Pop',
      category: 'Tactile & UI',
      durationMs: 400,
      icon: Icons.touch_app,
      color: Color(0xFF00CEC9),
      assetPath: 'assets/audio/tactile_click.wav',
      ffmpegAudioGenerator: 'sine=f=440:d=0.4,afade=t=out:st=0.05:d=0.35',
      pcmPeaks: [0.2, 0.95, 0.45, 0.15, 0.05],
    ),
    SoundEffectItem(
      id: 'camera_shutter',
      name: 'Photo Shutter Click',
      category: 'Tactile & UI',
      durationMs: 500,
      icon: Icons.camera_alt,
      color: Color(0xFFFDCB6E),
      assetPath: 'assets/audio/tactile_click.wav',
      ffmpegAudioGenerator: 'anoisesrc=d=0.5:c=white:r=48000:a=0.8,bandpass=f=3500:w=1000,afade=t=out:st=0.1:d=0.4',
      pcmPeaks: [0.85, 0.95, 0.6, 0.25, 0.08],
    ),
    SoundEffectItem(
      id: 'bell_chime',
      name: 'Ambient Bell Chime',
      category: 'Tactile & UI',
      durationMs: 1800,
      icon: Icons.notifications_active,
      color: Color(0xFFFFD700),
      assetPath: 'assets/audio/ambient_tone.mp3',
      ffmpegAudioGenerator: 'sine=f=880:d=1.8,afade=t=out:st=0.1:d=1.7',
      pcmPeaks: [0.9, 0.75, 0.55, 0.4, 0.28, 0.18, 0.1, 0.04],
    ),

    // --- 5. AMBIENCE & BACKGROUND ---
    SoundEffectItem(
      id: 'vinyl_crackle',
      name: 'Vintage Vinyl Crackle',
      category: 'Ambience',
      durationMs: 4000,
      icon: Icons.album,
      color: Color(0xFFE17055),
      assetPath: 'assets/audio/ambient_tone.mp3',
      ffmpegAudioGenerator: 'anoisesrc=d=4.0:c=pink:r=48000:a=0.3,highpass=f=1000,volume=0.4',
      pcmPeaks: [0.35, 0.4, 0.38, 0.42, 0.36, 0.41, 0.39, 0.37, 0.4],
    ),
    SoundEffectItem(
      id: 'lofi_room_bed',
      name: 'Lo-Fi Studio Hum',
      category: 'Ambience',
      durationMs: 4000,
      icon: Icons.nightlife,
      color: Color(0xFF6C5CE7),
      assetPath: 'assets/audio/ambient_tone.mp3',
      ffmpegAudioGenerator: 'sine=f=120:d=4.0,volume=0.35,chorus=0.5:0.7:45:0.3:0.2:2',
      pcmPeaks: [0.3, 0.32, 0.31, 0.33, 0.3, 0.32, 0.31, 0.33, 0.3],
    ),

    // --- 6. SILENCE SPACERS (SSML TIMELINE ALIGNMENT) ---
    SoundEffectItem(
      id: 'silence_100ms',
      name: '100ms Micro Gap',
      category: 'Silence Spacers',
      durationMs: 100,
      icon: Icons.pause_circle_outline,
      color: Color(0xFF747D8C),
      assetPath: 'assets/audio/silence_100ms.mp3',
      ffmpegAudioGenerator: 'anullsrc=d=0.1',
      pcmPeaks: [0.0, 0.0, 0.0],
    ),
    SoundEffectItem(
      id: 'silence_200ms',
      name: '200ms Breath Pause',
      category: 'Silence Spacers',
      durationMs: 200,
      icon: Icons.pause_circle_outline,
      color: Color(0xFF747D8C),
      assetPath: 'assets/audio/silence_200ms.mp3',
      ffmpegAudioGenerator: 'anullsrc=d=0.2',
      pcmPeaks: [0.0, 0.0, 0.0, 0.0],
    ),
    SoundEffectItem(
      id: 'silence_400ms',
      name: '400ms Sentence Gap',
      category: 'Silence Spacers',
      durationMs: 400,
      icon: Icons.pause_circle_filled,
      color: Color(0xFF747D8C),
      assetPath: 'assets/audio/silence_400ms.mp3',
      ffmpegAudioGenerator: 'anullsrc=d=0.4',
      pcmPeaks: [0.0, 0.0, 0.0, 0.0, 0.0],
    ),
    SoundEffectItem(
      id: 'silence_800ms',
      name: '800ms Paragraph Gap',
      category: 'Silence Spacers',
      durationMs: 800,
      icon: Icons.pause_circle_filled,
      color: Color(0xFF747D8C),
      assetPath: 'assets/audio/silence_800ms.mp3',
      ffmpegAudioGenerator: 'anullsrc=d=0.8',
      pcmPeaks: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    ),
  ];
}
