import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/editor_provider.dart';

class _SearchableTool {
  final EditorTool tool;
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final bool isAi;
  final List<String> keywords;

  const _SearchableTool({
    required this.tool,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    this.isAi = false,
    required this.keywords,
  });
}

/// Instant tool search and quick launcher palette.
/// Allows creators to find any of the 64 editing tools in milliseconds
/// without endless scrolling.
class ToolSearchModal extends StatefulWidget {
  final Function(EditorTool) onSelectTool;

  const ToolSearchModal({
    super.key,
    required this.onSelectTool,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(EditorTool) onSelectTool,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ToolSearchModal(onSelectTool: onSelectTool),
    );
  }

  @override
  State<ToolSearchModal> createState() => _ToolSearchModalState();
}

class _ToolSearchModalState extends State<ToolSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _query = '';

  static const List<_SearchableTool> _catalog = [
    // --- EDIT & CUT ---
    _SearchableTool(
      tool: EditorTool.split,
      title: 'Split',
      category: 'Edit',
      description: 'Cut clip at playhead into two parts',
      icon: Icons.content_cut,
      keywords: ['split', 'cut', 'slice', 'divide', 'separate', 'scissors'],
    ),
    _SearchableTool(
      tool: EditorTool.trim,
      title: 'Trim',
      category: 'Edit',
      description: 'Trim in and out duration points',
      icon: Icons.content_cut_outlined,
      keywords: ['trim', 'crop', 'duration', 'shorten', 'length'],
    ),
    _SearchableTool(
      tool: EditorTool.speed,
      title: 'Speed & Curve',
      category: 'Edit',
      description: 'Speed ramping, slo-mo, velocity curves',
      icon: Icons.speed,
      keywords: ['speed', 'fast', 'slow', 'motion', 'slo-mo', 'velocity', 'curve', 'ramp', 'fps'],
    ),
    _SearchableTool(
      tool: EditorTool.freezeFrame,
      title: 'Freeze Frame',
      category: 'Edit',
      description: 'Pause video frame for 3s pause shot',
      icon: Icons.ac_unit,
      keywords: ['freeze', 'frame', 'pause', 'still', 'photo', 'hold'],
    ),
    _SearchableTool(
      tool: EditorTool.reverseClip,
      title: 'Reverse Playback',
      category: 'Edit',
      description: 'Play video & audio backward in reverse',
      icon: Icons.replay,
      keywords: ['reverse', 'rewind', 'backward', 'flip', 'backwards'],
    ),
    _SearchableTool(
      tool: EditorTool.duplicateClip,
      title: 'Duplicate',
      category: 'Edit',
      description: 'Clone clip onto timeline',
      icon: Icons.control_point_duplicate,
      keywords: ['duplicate', 'copy', 'clone', 'repeat'],
    ),
    _SearchableTool(
      tool: EditorTool.deleteClip,
      title: 'Delete',
      category: 'Edit',
      description: 'Remove clip and ripple timeline',
      icon: Icons.delete_outline,
      keywords: ['delete', 'remove', 'trash', 'clear'],
    ),

    // --- AI STUDIO ---
    _SearchableTool(
      tool: EditorTool.chromaKey,
      title: 'Smart Cutout & Chroma',
      category: 'AI Studio',
      description: 'MediaPipe selfie segmentation & green screen',
      icon: Icons.blur_linear,
      isAi: true,
      keywords: ['cutout', 'chroma', 'green screen', 'segmentation', 'background removal', 'key', 'mask', 'transparent'],
    ),
    _SearchableTool(
      tool: EditorTool.captions,
      title: 'Auto Captions (Whisper)',
      category: 'AI Studio',
      description: 'On-device Speech-to-Text subtitle generation',
      icon: Icons.closed_caption,
      isAi: true,
      keywords: ['captions', 'subtitles', 'whisper', 'speech', 'text', 'transcribe', 'srt', 'audio to text'],
    ),
    _SearchableTool(
      tool: EditorTool.aiColorEnhance,
      title: 'AI Auto-Color & Tone Intelligence',
      category: 'Color',
      description: '1-tap dynamic range, Gray World balance & vibrance optimization',
      icon: Icons.auto_awesome,
      isAi: true,
      keywords: ['ai color', 'auto color', 'balance', 'tone', 'auto tone', 'white balance', 'color enhance', 'exposure', 'hdr', 'vibrant'],
    ),
    _SearchableTool(
      tool: EditorTool.aiSilenceRemover,
      title: 'AI Silence Remover & Auto Jump-Cut',
      category: 'Audio',
      description: 'On-device VAD voice detection & dead-air pause excision',
      icon: Icons.content_cut,
      isAi: true,
      keywords: ['silence', 'vad', 'jump cut', 'auto cut', 'dead air', 'silence remover', 'cut silence', 'voice detect', 'speech'],
    ),
    _SearchableTool(
      tool: EditorTool.aiSceneSplit,
      title: 'AI Scene Cut & Shot Boundary Detector',
      category: 'Edit',
      description: 'Differential frame luminance and color histogram transition splitting',
      icon: Icons.movie_filter,
      isAi: true,
      keywords: ['scene', 'cut', 'shot', 'detect scenes', 'scene split', 'boundary', 'histogram', 'auto split'],
    ),
    _SearchableTool(
      tool: EditorTool.clipWorkflow,
      title: 'AI Smart Split & Silence Cut',
      category: 'AI Studio',
      description: 'VAD voice detection, auto silence trimming',
      icon: Icons.movie_filter_outlined,
      isAi: true,
      keywords: ['silence', 'vad', 'jump cut', 'smart split', 'dead air', 'cut silence', 'voice detect'],
    ),
    _SearchableTool(
      tool: EditorTool.enhance,
      title: '8K AI Upscale & Detail',
      category: 'AI Studio',
      description: 'Neural super resolution & Lanczos enhancement',
      icon: Icons.auto_awesome_motion,
      isAi: true,
      keywords: ['enhance', 'upscale', '8k', '4k', 'super resolution', 'quality', 'sharp', 'detail', 'esrgan'],
    ),
    _SearchableTool(
      tool: EditorTool.tracking,
      title: 'Motion Tracking',
      category: 'AI Studio',
      description: 'Lucas-Kanade optical flow feature tracking',
      icon: Icons.my_location,
      isAi: true,
      keywords: ['track', 'tracking', 'motion', 'follow', 'pin', 'anchor', 'optical flow'],
    ),
    _SearchableTool(
      tool: EditorTool.characterZoom,
      title: 'Auto Character Zoom',
      category: 'AI Studio',
      description: 'Auto-centering subject zoom & Kalman smoothing',
      icon: Icons.zoom_in_map,
      isAi: true,
      keywords: ['zoom', 'character', 'subject', 'face follow', 'center', 'crop'],
    ),
    _SearchableTool(
      tool: EditorTool.highlight,
      title: 'Character Highlight',
      category: 'AI Studio',
      description: 'Neon aura outline and spotlight effects',
      icon: Icons.photo_filter_outlined,
      isAi: true,
      keywords: ['highlight', 'aura', 'neon', 'outline', 'glow', 'spotlight', 'character'],
    ),
    _SearchableTool(
      tool: EditorTool.retouch,
      title: 'Face Retouch',
      category: 'AI Studio',
      description: 'Skin smoothing and face beauty polish',
      icon: Icons.face_retouching_natural,
      isAi: true,
      keywords: ['face', 'retouch', 'skin', 'beauty', 'smooth', 'blemish'],
    ),
    _SearchableTool(
      tool: EditorTool.faceReshape,
      title: 'Face Reshape',
      category: 'AI Studio',
      description: 'Facial contour sculpting and eye tuning',
      icon: Icons.face,
      isAi: true,
      keywords: ['reshape', 'contour', 'jaw', 'eyes', 'chin', 'mesh'],
    ),
    _SearchableTool(
      tool: EditorTool.objectRemoval,
      title: 'Magic Eraser (Object Removal)',
      category: 'AI Studio',
      description: 'Brush and remove unwanted objects from frame',
      icon: Icons.auto_fix_high,
      isAi: true,
      keywords: ['eraser', 'remove', 'inpaint', 'object', 'clean', 'brush'],
    ),

    // --- AUDIO & VOICE ---
    _SearchableTool(
      tool: EditorTool.audio,
      title: 'Volume & Audio Mixer',
      category: 'Audio',
      description: 'Gain slider, true-peak limiter, and ducking',
      icon: Icons.volume_up_outlined,
      keywords: ['volume', 'audio', 'sound', 'gain', 'loudness', 'mixer', 'mute', 'limiter'],
    ),
    _SearchableTool(
      tool: EditorTool.extractAudio,
      title: 'Extract Audio',
      category: 'Audio',
      description: 'Separate audio into dedicated sound track',
      icon: Icons.music_note,
      keywords: ['extract', 'separate', 'detach', 'mp3', 'sound track', 'isolate audio'],
    ),
    _SearchableTool(
      tool: EditorTool.beats,
      title: 'Beat Sync & Onset Snap',
      category: 'Audio',
      description: 'BPM rhythm detection and magnetic beat snapping',
      icon: Icons.graphic_eq,
      isAi: true,
      keywords: ['beat', 'rhythm', 'bpm', 'tempo', 'music', 'sync', 'onset', 'drop'],
    ),
    _SearchableTool(
      tool: EditorTool.denoise,
      title: 'Neural De-Noise (RNNoise)',
      category: 'Audio',
      description: 'Background hiss and hum reduction',
      icon: Icons.noise_control_off,
      isAi: true,
      keywords: ['denoise', 'noise', 'hiss', 'hum', 'clean audio', 'rnnoise', 'background sound'],
    ),
    _SearchableTool(
      tool: EditorTool.vocalIsolation,
      title: 'Vocal Isolation (Stem Split)',
      category: 'Audio',
      description: 'Separate vocals and background music',
      icon: Icons.mic_none,
      isAi: true,
      keywords: ['vocal', 'isolate', 'voice', 'singing', 'stems', 'acapella', 'instrumental'],
    ),
    _SearchableTool(
      tool: EditorTool.tts,
      title: 'AI Voiceover (TTS)',
      category: 'Audio',
      description: 'Neural text-to-speech voice narration',
      icon: Icons.record_voice_over,
      isAi: true,
      keywords: ['tts', 'voiceover', 'speech', 'narration', 'read', 'speak', 'voice'],
    ),
    _SearchableTool(
      tool: EditorTool.audioRecord,
      title: 'Audio Recorder',
      category: 'Audio',
      description: 'Record live voiceover microphone directly',
      icon: Icons.mic,
      keywords: ['record', 'mic', 'microphone', 'live voice', 'audio in'],
    ),
    _SearchableTool(
      tool: EditorTool.soundEffects,
      title: 'Sound Effects (SFX)',
      category: 'Audio',
      description: 'Motion whoosh, tactile clicks, and silence spacers',
      icon: Icons.speaker,
      keywords: ['sfx', 'sound effect', 'whoosh', 'click', 'spacer', 'foley'],
    ),

    // --- VISUALS & COMPOSITING ---
    _SearchableTool(
      tool: EditorTool.transform,
      title: 'Transform & Crop',
      category: 'Visuals',
      description: 'Spatial scale, rotation, and positioning',
      icon: Icons.crop_rotate,
      keywords: ['transform', 'scale', 'rotate', 'position', 'size', 'move', 'crop'],
    ),
    _SearchableTool(
      tool: EditorTool.keyframes,
      title: 'Keyframe Animation',
      category: 'Visuals',
      description: 'Custom motion path and parameter keyframing',
      icon: Icons.animation,
      keywords: ['keyframes', 'animation', 'animate', 'motion', 'curve', 'path'],
    ),
    _SearchableTool(
      tool: EditorTool.mask,
      title: 'Shape Masking',
      category: 'Visuals',
      description: 'Linear, radial, rectangle, and heart masks',
      icon: Icons.masks,
      keywords: ['mask', 'shape', 'linear', 'radial', 'feather', 'invert'],
    ),
    _SearchableTool(
      tool: EditorTool.blend,
      title: 'Blend Modes',
      category: 'Visuals',
      description: 'Screen, Multiply, Overlay, Darken compositor',
      icon: Icons.layers,
      keywords: ['blend', 'mode', 'screen', 'multiply', 'overlay', 'compositing', 'opacity'],
    ),
    _SearchableTool(
      tool: EditorTool.imageOverlay,
      title: 'Picture-in-Picture (PiP)',
      category: 'Visuals',
      description: 'Overlay images, logos, and secondary video clips',
      icon: Icons.picture_in_picture_alt_outlined,
      keywords: ['pip', 'overlay', 'picture in picture', 'sticker', 'logo', 'watermark'],
    ),
    _SearchableTool(
      tool: EditorTool.text,
      title: 'Text & Titles',
      category: 'Visuals',
      description: 'Curved text, kinetic typography, fonts',
      icon: Icons.title,
      keywords: ['text', 'title', 'font', 'typography', 'kinetic', 'heading'],
    ),
    _SearchableTool(
      tool: EditorTool.vfx,
      title: 'Video Effects (VFX)',
      category: 'Visuals',
      description: 'Glitch, neon, blur, and cinematic shaders',
      icon: Icons.auto_awesome_motion,
      keywords: ['vfx', 'effects', 'glitch', 'shake', 'flash', 'shaders'],
    ),
    _SearchableTool(
      tool: EditorTool.effects,
      title: 'Transitions',
      category: 'Visuals',
      description: 'Wipe, zoom, slide, and fade video transitions',
      icon: Icons.transform,
      keywords: ['transition', 'wipe', 'zoom', 'fade', 'cut transition', 'crossfade'],
    ),
    _SearchableTool(
      tool: EditorTool.doodle,
      title: 'Doodle Brush',
      category: 'Visuals',
      description: 'Draw freehand paths and annotations on video',
      icon: Icons.draw,
      keywords: ['doodle', 'draw', 'brush', 'paint', 'pen', 'sketch'],
    ),
    _SearchableTool(
      tool: EditorTool.splitScreen,
      title: 'Split Screen Layout',
      category: 'Visuals',
      description: 'Multi-frame vertical & horizontal video grids',
      icon: Icons.grid_view_rounded,
      keywords: ['split screen', 'grid', 'multi video', 'side by side', 'compare'],
    ),

    // --- COLOR & STYLE ---
    _SearchableTool(
      tool: EditorTool.color,
      title: 'Color Filters & Looks',
      category: 'Color',
      description: 'Cinematic looks, 4x5 GPU matrices',
      icon: Icons.palette_outlined,
      keywords: ['color', 'filter', 'lut', 'preset', 'looks', 'cinematic', 'teal and orange'],
    ),
    _SearchableTool(
      tool: EditorTool.curves,
      title: 'RGB Curves & Adjust',
      category: 'Color',
      description: 'RGB tonal curves, brightness, contrast, tint',
      icon: Icons.show_chart,
      keywords: ['curves', 'rgb', 'adjust', 'contrast', 'exposure', 'brightness', 'saturation'],
    ),
    _SearchableTool(
      tool: EditorTool.colorWheels,
      title: '3-Way Color Wheels',
      category: 'Color',
      description: 'Lift, Gamma, Gain professional color grading',
      icon: Icons.donut_large,
      keywords: ['wheels', 'lift', 'gamma', 'gain', 'shadows', 'midtones', 'highlights'],
    ),
    _SearchableTool(
      tool: EditorTool.filmGrain,
      title: 'Film Grain',
      category: 'Color',
      description: 'Organic 16mm / 35mm analogue texture',
      icon: Icons.grain,
      keywords: ['grain', 'film', 'texture', 'analog', 'vintage', 'noise'],
    ),
    _SearchableTool(
      tool: EditorTool.vignette,
      title: 'Vignette',
      category: 'Color',
      description: 'Radial edge darkening & softness framing',
      icon: Icons.vignette,
      keywords: ['vignette', 'edge', 'darken', 'frame', 'radial'],
    ),
    _SearchableTool(
      tool: EditorTool.layout,
      title: 'Canvas Ratio (Auto-Reframe)',
      category: 'Visuals',
      description: '9:16 TikTok, 16:9 YouTube, 1:1 Square, 4:5',
      icon: Icons.aspect_ratio,
      keywords: ['ratio', 'canvas', 'aspect', 'reframe', 'tiktok', 'reels', 'shorts', 'youtube'],
    ),
    _SearchableTool(
      tool: EditorTool.progressBar,
      title: 'Retention Progress Bar',
      category: 'Visuals',
      description: 'Real-time social video progress bar with glow and gradient styles',
      icon: Icons.linear_scale,
      keywords: ['progress', 'retention', 'bar', 'indicator', 'time', 'glow', 'gradient', 'reels', 'tiktok', 'social'],
    ),
    _SearchableTool(
      tool: EditorTool.kenBurns,
      title: 'Ken Burns Motion & Pan/Zoom',
      category: 'Visuals',
      description: 'Cinematic 2D photo motion, pan, and dynamic zoom animations',
      icon: Icons.slow_motion_video,
      keywords: ['ken burns', 'pan', 'zoom', 'motion', 'photo', 'drift', 'animation', 'camera'],
    ),
    _SearchableTool(
      tool: EditorTool.gapCloser,
      title: 'Timeline Gap Closer',
      category: 'Edit',
      description: 'Detect & ripple-close accidental black gaps and blank flashes',
      icon: Icons.space_bar,
      keywords: ['gap', 'closer', 'black frame', 'flash', 'blank', 'ripple', 'compact', 'timeline'],
    ),
    _SearchableTool(
      tool: EditorTool.beatCut,
      title: 'Auto Beat Cut & Rhythm Snapper',
      category: 'AI Studio',
      isAi: true,
      description: 'Auto-split clips on musical beats or tempo grid intervals & snap edit cutpoints',
      icon: Icons.auto_awesome_motion,
      keywords: ['beat', 'music', 'rhythm', 'tempo', 'cut', 'snapper', 'bpm', 'split', 'sync'],
    ),
    _SearchableTool(
      tool: EditorTool.audioFade,
      title: 'Audio Fade & Anti-Pop Crossfade',
      category: 'Audio',
      description: 'Smooth logarithmic and S-curve audio fade-in & fade-out envelopes to remove clicks',
      icon: Icons.graphic_eq,
      keywords: ['fade', 'audio fade', 'crossfade', 'pop', 'envelope', 'smooth', 'volume ramp'],
    ),
    _SearchableTool(
      tool: EditorTool.impactFlash,
      title: 'Cinematic Impact Flash & Strobe',
      category: 'Visuals',
      description: 'High-energy white burst, black dip, warm glow, or RGB cyber strobe accents at cutpoints',
      icon: Icons.flash_on,
      keywords: ['flash', 'impact', 'strobe', 'white burst', 'glow', 'cut accent', 'transition'],
    ),
    _SearchableTool(
      tool: EditorTool.freezeClimax,
      title: 'Action Freeze Frame Climax',
      category: 'Visuals',
      description: 'Cinematic action freeze hold with camera punch zoom, monochrome accent, and impact flash',
      icon: Icons.ac_unit,
      keywords: ['freeze', 'climax', 'hold', 'action', 'punch', 'still', 'pause', 'dramatic'],
    ),
    _SearchableTool(
      tool: EditorTool.speedEase,
      title: 'Bezier Speed Ramping & Optical Ease',
      category: 'Edit',
      description: 'Sculpt continuous velocity curves with cubic bezier handles and optical speed easing',
      icon: Icons.tune,
      keywords: ['bezier', 'speed', 'ease', 'velocity', 'curve', 'hero', 'bullet time', 'ramp', 'smooth'],
    ),
    _SearchableTool(
      tool: EditorTool.spatialPan,
      title: '8D Spatial Audio & Stereo Matrix Pan',
      category: 'Audio',
      description: 'Equal-power stereo balance and viral 8D binaural rotating audio orbits for headphones',
      icon: Icons.headphones,
      keywords: ['spatial', 'pan', '8d', 'audio', 'binaural', 'orbit', 'stereo', 'headphone', 'surround'],
    ),
    _SearchableTool(
      tool: EditorTool.typewriterTitle,
      title: 'Kinetic Typewriter Studio',
      category: 'Visuals',
      description: 'Char-by-char or word-by-word kinetic text reveals with blinking terminal cursors and glitch resolves',
      icon: Icons.keyboard,
      keywords: ['typewriter', 'kinetic', 'title', 'text', 'cursor', 'terminal', 'matrix', 'subtitle', 'quote'],
    ),
    _SearchableTool(
      tool: EditorTool.crtScanline,
      title: 'Retro CRT Scanlines Studio',
      category: 'Visuals',
      description: 'Cathode-ray raster scanlines, rolling hum bar, phosphor glow tints, barrel curvature, and TV noise',
      icon: Icons.tv,
      keywords: ['crt', 'scanline', 'retro', 'vhs', 'phosphor', 'arcade', 'terminal', 'cyberpunk', 'tube', 'pvm'],
    ),
    _SearchableTool(
      tool: EditorTool.reverbChamber,
      title: 'Reverb Chamber Studio',
      category: 'Audio',
      description: 'Acoustic room simulation, concert halls, cathedral echoes, EMT plates, and stereo depth',
      icon: Icons.surround_sound,
      keywords: ['reverb', 'echo', 'chamber', 'hall', 'cathedral', 'acoustic', 'dsp', 'spatial', 'room', 'plate'],
    ),
    _SearchableTool(
      tool: EditorTool.anamorphicFlare,
      title: 'Anamorphic Streak Flare Studio',
      category: 'Visuals',
      description: 'Horizontal cinema lens streak bloom, luminance threshold extraction, specular starburst spikes, and optical tints',
      icon: Icons.lens_blur,
      keywords: ['flare', 'anamorphic', 'streak', 'bloom', 'starburst', 'cinema', 'lens', 'glow', 'spikes', 'light'],
    ),
    _SearchableTool(
      tool: EditorTool.filmHalation,
      title: '35mm Film Halation Studio',
      category: 'Visuals',
      description: 'Photochemical red layer backscatter halo, specular edge bleed, diffusion radius, and authentic film stock presets',
      icon: Icons.blur_on,
      keywords: ['halation', 'film', '35mm', 'emulsion', 'red bleed', 'bloom', 'glow', 'analog', 'cinestill', 'kodak'],
    ),
    _SearchableTool(
      tool: EditorTool.tapeCassette,
      title: 'Vintage Tape Cassette Studio',
      category: 'Audio',
      description: 'Analog magnetic tape wow pitch drift, flutter vibration, head warmth bump, and high-frequency tape roll-off',
      icon: Icons.album,
      keywords: ['tape', 'cassette', 'wow', 'flutter', 'warble', 'lofi', 'vintage', 'analog', 'walkman', 'vhs'],
    ),
    _SearchableTool(
      tool: EditorTool.cameraShake,
      title: 'Camera Shake & Tremor Studio',
      category: 'Visuals',
      description: 'Organic handheld camera drift, violent earthquake shockwaves, offroad vehicle vibration, and impact tremors',
      icon: Icons.vibration,
      keywords: ['shake', 'camera', 'handheld', 'tremor', 'earthquake', 'vibration', 'impact', 'drift', 'jitter', 'motion'],
    ),
    _SearchableTool(
      tool: EditorTool.lensDistortion,
      title: 'Lens Distortion & Fisheye Studio',
      category: 'Visuals',
      description: 'Curved panoramic barrel fisheye curvature, telephoto pincushion zoom, chromatic aberration RGB fringes, and corner vignette',
      icon: Icons.panorama_fish_eye,
      keywords: ['distortion', 'fisheye', 'lens', 'barrel', 'pincushion', 'gopro', 'action', 'chromatic', 'aberration', 'warp'],
    ),
    _SearchableTool(
      tool: EditorTool.vinylRecord,
      title: 'Vinyl Turntable Studio',
      category: 'Audio',
      description: 'Analog vinyl turntable surface crackle, dust pops, mechanical needle cue, 33/45/78 RPM speeds, and warm RIAA phono curve',
      icon: Icons.album,
      keywords: ['vinyl', 'record', 'turntable', 'crackle', 'dust', 'needle', 'lp', 'lofi', 'analog', 'vintage'],
    ),
    _SearchableTool(
      tool: EditorTool.lightLeak,
      title: 'Light Leak & Rainbow Prisms Studio',
      category: 'Visuals',
      description: 'Organic solar light leaks, chromatic rainbow prism flares, warm anamorphic exposure breathing, and Skia Canvas simulation',
      icon: Icons.wb_sunny_rounded,
      keywords: ['light', 'leak', 'rainbow', 'prism', 'solar', 'flare', 'sun', 'anamorphic', 'burn', 'film', 'exposure', 'glow', 'vfx'],
    ),
    _SearchableTool(
      tool: EditorTool.nightVision,
      title: 'Night Vision & Thermal Scope Studio',
      category: 'Visuals',
      description: 'Military Gen-3 phosphor green matrix, FLIR thermal false-color heatmap, CRT scanlines, and tactical rangefinder reticles',
      icon: Icons.visibility_rounded,
      keywords: ['night vision', 'nvg', 'thermal', 'flir', 'infrared', 'ironbow', 'reticle', 'crosshair', 'scope', 'military', 'heatmap', 'green', 'tactical'],
    ),
    _SearchableTool(
      tool: EditorTool.bitcrusher,
      title: '8-Bit Lo-Fi Chiptune Crusher',
      category: 'Audio',
      description: 'Sample rate downsampling, bit depth DAC quantization, arcade crunch saturation, and true-peak brickwall ceiling limiter',
      icon: Icons.videogame_asset_rounded,
      keywords: ['bitcrusher', '8-bit', 'chiptune', 'lofi', 'nes', 'gameboy', 'arcade', 'downsample', 'quantize', 'dac', 'sample rate', 'audio', 'sound'],
    ),
    _SearchableTool(
      tool: EditorTool.kaleidoscope,
      title: 'Kaleidoscope & Radial Mirror',
      category: 'Visuals',
      description: 'Multi-facet radial symmetry reflection (2 to 12 facets), continuous rotation drift, center pivot offset, and mandala geometry',
      icon: Icons.flare_rounded,
      keywords: ['kaleidoscope', 'mirror', 'radial', 'symmetry', 'mandala', 'reflection', 'crystal', 'prismatic', 'facets', 'psychedelic', 'rotate'],
    ),
    _SearchableTool(
      tool: EditorTool.datamoshGlitch,
      title: 'Datamosh & Compression Glitch',
      category: 'Visuals',
      description: 'I-frame dropout keyframe glitch, macroblock DCT compression, RGB spectral displacement chromatic tear, and VHS tracking noise',
      icon: Icons.broken_image_rounded,
      keywords: ['datamosh', 'glitch', 'compression', 'artifact', 'iframe', 'macroblock', 'vhs', 'rgb shift', 'tear', 'pixelate', 'decay', 'cyberpunk'],
    ),
    _SearchableTool(
      tool: EditorTool.tremoloWah,
      title: 'Stereo Tremolo & Auto-Wah',
      category: 'Audio',
      description: 'Periodic stereo LFO amplitude modulation, dynamic resonant auto-wah filter envelope, Leslie rotary speaker, and brickwall limiter',
      icon: Icons.waves_rounded,
      keywords: ['tremolo', 'wah', 'autowah', 'lfo', 'modulation', 'amplitude', 'filter', 'resonance', 'leslie', 'rotary', 'stutter', 'gate', 'stereo', 'pan', 'audio'],
    ),
    _SearchableTool(
      tool: EditorTool.tiltShift,
      title: 'Tilt-Shift Miniature Studio',
      category: 'Visuals',
      description: 'Progressive miniature depth-of-field blur falloff, linear and radial focus planes, and toy-model color saturation boost',
      icon: Icons.camera_enhance_rounded,
      keywords: ['tilt shift', 'miniature', 'diorama', 'blur', 'depth of field', 'dof', 'focus', 'macro', 'lens', 'radial', 'toy'],
    ),
    _SearchableTool(
      tool: EditorTool.neonGlow,
      title: 'Cyberpunk Neon & Hologram Wireframe',
      category: 'Visuals',
      description: 'Sobel edge detection, electrifying neon silhouette edge glow, bloom diffusion halo, and holographic scanline raster',
      icon: Icons.electric_bolt_rounded,
      keywords: ['neon', 'glow', 'cyberpunk', 'edge', 'sobel', 'contour', 'wireframe', 'hologram', 'scanline', 'silhouette', 'bloom'],
    ),
    _SearchableTool(
      tool: EditorTool.pitchHarmonizer,
      title: 'Vocal Pitch & Formant Harmonizer',
      category: 'Audio',
      description: 'Musical semitone transposition, dual-voice interval harmonies (3rds/5ths/octaves), robot ring mod, and brickwall ceiling limiter',
      icon: Icons.music_note_rounded,
      keywords: ['pitch', 'harmonizer', 'harmony', 'vocal', 'semitone', 'transposition', 'formant', 'octave', 'robot', 'ring mod', 'voice', 'audio'],
    ),
    _SearchableTool(
      tool: EditorTool.chromaticAberration,
      title: 'RGB Chromatic Aberration & Glitch',
      category: 'Visuals',
      description: 'Optical prism displacement, Red/Cyan 3D anaglyph separation, holographic jitter, and angle dispersion vectors',
      icon: Icons.grain_rounded,
      keywords: ['chromatic', 'aberration', 'rgb', 'split', 'glitch', 'prism', 'dispersion', 'anaglyph', '3d', 'hologram', 'jitter', 'color shift', 'vfx'],
    ),
    _SearchableTool(
      tool: EditorTool.solarizeInvert,
      title: 'Thermal Solarization & Color Invert',
      category: 'Visuals',
      description: 'Sabattier photographic tone inflection curves, negative film inversion, psychedelic hue cycling, and FLIR thermal heat map',
      icon: Icons.wb_sunny_outlined,
      keywords: ['solarize', 'solarization', 'sabattier', 'invert', 'negative', 'psychedelic', 'thermal', 'flir', 'heat', 'cross process', 'tone curve', 'contrast'],
    ),
    _SearchableTool(
      tool: EditorTool.audioStutter,
      title: 'Rhythmic Audio Stutter & Glitch Repeater',
      category: 'Audio',
      description: 'Musical micro-buffer beat repetition (1/4 to 1/32 notes), accelerating drill build-ups, tape stop pitch drops, and brickwall limiter',
      icon: Icons.graphic_eq_rounded,
      keywords: ['stutter', 'repeater', 'buffer', 'glitch', 'drill', 'beat', 'rhythm', 'tape stop', 'pitch drop', 'accelerando', 'gate', 'chop', 'audio', 'sound'],
    ),
    _SearchableTool(
      tool: EditorTool.pixelSort,
      title: 'Pixel Sort & Digital Streak Glitch',
      category: 'Visuals',
      description: 'Luminance threshold pixel sorting, directional digital data streaks, horizontal tearing, radiant bursts, and Skia Canvas monitor',
      icon: Icons.waterfall_chart_rounded,
      keywords: ['pixel sort', 'pixelsort', 'glitch', 'streak', 'data', 'tear', 'cyberpunk', 'displacement', 'luminance', 'threshold', 'vfx', 'digital'],
    ),
    _SearchableTool(
      tool: EditorTool.posterizePop,
      title: 'Posterize & Warhol Pop Art',
      category: 'Visuals',
      description: 'Discrete color quantization (2 to 16 levels), Andy Warhol silk-screen pop art, comic book inked shading, and duotone posterization',
      icon: Icons.palette,
      keywords: ['posterize', 'pop art', 'warhol', 'quantize', 'comic', 'ink', 'duotone', '8-bit', 'retro', 'noir', 'silk screen', 'tonal', 'color levels'],
    ),
    _SearchableTool(
      tool: EditorTool.jetFlanger,
      title: 'Jet Flanger & Barberpole Frequency Phaser',
      category: 'Audio',
      description: 'Resonant comb-filter sweeping simulating jet aircraft flybys, infinite barberpole phasing, metallic robotic ringing, and brickwall limiter',
      icon: Icons.air,
      keywords: ['flanger', 'phaser', 'jet', 'comb filter', 'barberpole', 'metallic', 'resonance', 'feedback', 'shepard', 'stereo', 'audio', 'sound', 'dsp'],
    ),
    _SearchableTool(
      tool: EditorTool.lumaKey,
      title: 'Luma Key & Silhouette Transparency',
      category: 'Visuals',
      description: 'Luminance threshold cutout, dark shadow silhouette keying, bright sky transparency, soft feathered edge falloff, and Skia alpha monitor',
      icon: Icons.content_cut_rounded,
      keywords: ['luma key', 'lumakey', 'silhouette', 'alpha', 'transparency', 'mask', 'cutout', 'chroma', 'backdrop', 'sky replacement', 'contrast', 'vfx'],
    ),
    _SearchableTool(
      tool: EditorTool.matrixRain,
      title: 'Matrix Digital Code Rain & Stream',
      category: 'Visuals',
      description: 'Cascading terminal cyber code streams, phosphor green trails, white leading glyph heads, density control, and animated Skia digital rain',
      icon: Icons.terminal_rounded,
      keywords: ['matrix', 'code rain', 'cyber', 'terminal', 'hacker', 'phosphor', 'green', 'binary', 'stream', 'ascii', 'glitch', 'vfx', 'digital'],
    ),
    _SearchableTool(
      tool: EditorTool.ringModulator,
      title: 'Metallic Ring Modulator & Vocoder',
      category: 'Audio',
      description: 'Carrier wave frequency multiplication, Dalek robotic sci-fi voice synthesis, alien inharmonic speech, chimes, and brickwall limiter',
      icon: Icons.notifications_active_rounded,
      keywords: ['ring mod', 'ringmod', 'ring modulator', 'vocoder', 'robot', 'dalek', 'carrier', 'oscillator', 'metallic', 'alien', 'tremolo', 'audio', 'sound', 'dsp'],
    ),
    _SearchableTool(
      tool: EditorTool.echoMotion,
      title: 'Motion Blur & Echo Decay Trails',
      category: 'Visuals',
      description: 'Temporal frame blending decay, long exposure ghost trails, discrete stepped phantom echoes, and light trail streak smearing',
      icon: Icons.blur_on_rounded,
      keywords: ['motion blur', 'echo', 'trails', 'ghost', 'long exposure', 'shutter speed', 'lag', 'smear', 'temporal', 'light trails', 'vfx', 'blur'],
    ),
    _SearchableTool(
      tool: EditorTool.asciiArt,
      title: 'ASCII Terminal & Matrix Texturizer',
      category: 'Visuals',
      description: 'Retro computing character matrix rasterization, monochrome green phosphor, amber CRT, full-color ANSI glyphs, and character density scaling',
      icon: Icons.terminal_rounded,
      keywords: ['ascii', 'terminal', 'retro', 'text', 'matrix', 'glyph', 'vt100', 'amber', 'phosphor', '8-bit', 'raster', 'ansi', 'vfx'],
    ),
    _SearchableTool(
      tool: EditorTool.subBassExciter,
      title: 'Sub-Bass 808 Saturator & Harmonic Exciter',
      category: 'Audio',
      description: 'Deep 30-80 Hz sub-oscillator boost, psychoacoustic 2nd/3rd harmonic overtone synthesis for phone speakers, tube saturation, and brickwall limiter',
      icon: Icons.speaker_group_rounded,
      keywords: ['sub bass', '808', 'bass', 'sub', 'low end', 'exciter', 'maxxbass', 'harmonics', 'saturation', 'punch', 'rumble', 'audio', 'sound', 'dsp'],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_SearchableTool> get _filteredTools {
    return _catalog.where((tool) {
      if (_selectedCategory != 'All' && tool.category != _selectedCategory) {
        return false;
      }
      if (_query.trim().isEmpty) {
        return true;
      }
      final q = _query.toLowerCase().trim();
      if (tool.title.toLowerCase().contains(q)) return true;
      if (tool.description.toLowerCase().contains(q)) return true;
      if (tool.category.toLowerCase().contains(q)) return true;
      return tool.keywords.any((k) => k.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredTools;
    final categories = ['All', 'Edit', 'AI Studio', 'Audio', 'Visuals', 'Color'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag Handle
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Search Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search tools (e.g. split, speed, cutout, lut, voice)...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          prefixIcon: const Icon(Icons.search, color: AppColors.accent, size: 18),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 16),
                                  style: IconButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(24, 24),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _query = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _query = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Category Filter Chips
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategory == cat;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent.withOpacity(0.2) : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : AppColors.border,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.accent : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Tools Results List
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 36, color: AppColors.textMuted),
                          const SizedBox(height: 8),
                          Text(
                            'No matching tools found for "$_query"',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try searching "split", "speed", "cutout", or "voice"',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: results.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            widget.onSelectTool(item.tool);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: item.isAi ? AppColors.accent.withOpacity(0.15) : AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: item.isAi ? AppColors.accent.withOpacity(0.4) : AppColors.border,
                                    ),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 20,
                                    color: item.isAi ? AppColors.accent : AppColors.primaryLight,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          if (item.isAi) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [AppColors.primary, AppColors.accent],
                                                ),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: const Text(
                                                'AI',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 7.5,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.description,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    item.category,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
