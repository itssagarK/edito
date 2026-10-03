import 'package:flutter/material.dart';
import '../../../../core/services/ai_configuration_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class AiSettingsSheet extends StatefulWidget {
  const AiSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AiSettingsSheet(),
    );
  }

  @override
  State<AiSettingsSheet> createState() => _AiSettingsSheetState();
}

class _AiSettingsSheetState extends State<AiSettingsSheet> {
  late TextEditingController _openAiController;
  late TextEditingController _groqController;
  late TextEditingController _elevenLabsController;
  late TextEditingController _removeBgController;

  AiSettings _settings = const AiSettings();
  bool _isLoading = true;
  String? _testMessage;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _openAiController = TextEditingController();
    _groqController = TextEditingController();
    _elevenLabsController = TextEditingController();
    _removeBgController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await AiConfigurationService.getSettings();
    if (mounted) {
      setState(() {
        _settings = s;
        _openAiController.text = s.openAiApiKey;
        _groqController.text = s.groqApiKey;
        _elevenLabsController.text = s.elevenLabsApiKey;
        _removeBgController.text = s.removeBgApiKey;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _openAiController.dispose();
    _groqController.dispose();
    _elevenLabsController.dispose();
    _removeBgController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final updated = _settings.copyWith(
      openAiApiKey: _openAiController.text.trim(),
      groqApiKey: _groqController.text.trim(),
      elevenLabsApiKey: _elevenLabsController.text.trim(),
      removeBgApiKey: _removeBgController.text.trim(),
    );

    await AiConfigurationService.saveSettings(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ AI Settings and API Keys saved successfully!'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _testKey(String type) async {
    setState(() {
      _isTesting = true;
      _testMessage = null;
    });

    bool success = false;
    String name = '';

    if (type == 'openai') {
      name = 'OpenAI';
      success = await AiConfigurationService.testOpenAiKey(_openAiController.text.trim());
    } else if (type == 'groq') {
      name = 'Groq';
      success = await AiConfigurationService.testGroqKey(_groqController.text.trim());
    } else if (type == 'elevenlabs') {
      name = 'ElevenLabs';
      success = await AiConfigurationService.testElevenLabsKey(_elevenLabsController.text.trim());
    }

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testMessage = success
            ? '✓ $name connection successful!'
            : '✕ $name connection failed. Check your API key.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 300,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.accent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'AI Cloud Setup & Keys',
                      style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(28, 28)),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 16),

          if (_testMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _testMessage!.startsWith('✓')
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _testMessage!.startsWith('✓') ? AppColors.primary : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _testMessage!.startsWith('✓') ? Icons.check_circle : Icons.error_outline,
                    color: _testMessage!.startsWith('✓') ? AppColors.primaryLight : Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _testMessage!,
                      style: AppTypography.labelMedium.copyWith(
                        color: _testMessage!.startsWith('✓') ? Colors.white : Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                Text(
                  'Configure real Cloud AI providers for speech-to-text auto-captions, high-quality voice synthesis, and background cutouts.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),

                // 1. OpenAI (Whisper & TTS)
                _buildApiKeySection(
                  title: 'OpenAI API Key (Whisper & TTS)',
                  subtitle: 'Powers Whisper auto-captions and realistic neural voiceovers.',
                  controller: _openAiController,
                  hint: 'sk-proj-...',
                  onTest: () => _testKey('openai'),
                  docUrl: 'https://platform.openai.com/api-keys',
                ),

                const SizedBox(height: 18),

                // 2. Groq (Fast Whisper)
                _buildApiKeySection(
                  title: 'Groq API Key (Ultra-Fast Whisper)',
                  subtitle: 'Blazing-fast Whisper-large-v3 transcription (Free tier available).',
                  controller: _groqController,
                  hint: 'gsk_...',
                  onTest: () => _testKey('groq'),
                  docUrl: 'https://console.groq.com/keys',
                ),

                const SizedBox(height: 18),

                // 3. ElevenLabs
                _buildApiKeySection(
                  title: 'ElevenLabs API Key (Emotional AI Voice)',
                  subtitle: 'Studio-grade voice cloning and cinematic narration.',
                  controller: _elevenLabsController,
                  hint: 'xi-...',
                  onTest: () => _testKey('elevenlabs'),
                  docUrl: 'https://elevenlabs.io',
                ),

                const SizedBox(height: 18),

                // 4. Remove.bg (Optional Cutout)
                _buildApiKeySection(
                  title: 'Remove.bg API Key (AI Cutout)',
                  subtitle: 'Removes image & sticker backgrounds with 1 tap.',
                  controller: _removeBgController,
                  hint: 'api_key_...',
                  docUrl: 'https://www.remove.bg/api',
                ),

                const SizedBox(height: 20),

                // Provider Selectors
                Text('ACTIVE PROVIDER PREFERENCES', style: AppTypography.labelSmall.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Auto-Captions (STT)', style: AppTypography.labelMedium.copyWith(color: Colors.white)),
                          DropdownButton<SttProvider>(
                            value: _settings.sttProvider,
                            dropdownColor: AppColors.surfaceElevated,
                            underline: const SizedBox(),
                            items: SttProvider.values.map((p) {
                              return DropdownMenuItem(
                                value: p,
                                child: Text(p.name == 'groqWhisper' ? 'Groq Whisper (Fast)' : 'OpenAI Whisper', style: const TextStyle(fontSize: 13, color: Colors.white)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _settings = _settings.copyWith(sttProvider: val));
                            },
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.border, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('AI Voiceover (TTS)', style: AppTypography.labelMedium.copyWith(color: Colors.white)),
                          DropdownButton<TtsProvider>(
                            value: _settings.ttsProvider,
                            dropdownColor: AppColors.surfaceElevated,
                            underline: const SizedBox(),
                            items: TtsProvider.values.map((p) {
                              return DropdownMenuItem(
                                value: p,
                                child: Text(p.name == 'elevenLabs' ? 'ElevenLabs' : p.name == 'openAi' ? 'OpenAI TTS' : 'On-Device', style: const TextStyle(fontSize: 13, color: Colors.white)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _settings = _settings.copyWith(ttsProvider: val));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),

          // Bottom Save Action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveSettings,
                icon: const Icon(Icons.check, size: 20),
                label: const Text('Save AI Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeySection({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String hint,
    VoidCallback? onTest,
    required String docUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              if (onTest != null)
                TextButton(
                  onPressed: _isTesting ? null : onTest,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 28),
                    foregroundColor: AppColors.accent,
                  ),
                  child: const Text('Test', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }
}
