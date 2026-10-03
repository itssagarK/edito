import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/services/ai_configuration_service.dart';

class CutoutResult {
  final bool isSuccess;
  final String? outputPath;
  final String? errorMessage;

  const CutoutResult({
    required this.isSuccess,
    this.outputPath,
    this.errorMessage,
  });
}

class AiBackgroundRemovalService {
  /// Removes background from an image file using Remove.bg or RMBG Cloud API
  static Future<CutoutResult> removeBackground(String imagePath) async {
    final inputFile = File(imagePath);
    if (!inputFile.existsSync()) {
      return const CutoutResult(
        isSuccess: false,
        errorMessage: 'Source image does not exist on disk.',
      );
    }

    final settings = await AiConfigurationService.getSettings();
    if (settings.removeBgApiKey.trim().isEmpty) {
      return const CutoutResult(
        isSuccess: false,
        errorMessage: 'Remove.bg API Key not configured. Please enter your API key in AI Settings.',
      );
    }

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final cutoutDir = Directory(p.join(docDir.path, 'cutouts'));
      if (!await cutoutDir.exists()) {
        await cutoutDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFile = File(p.join(cutoutDir.path, 'cutout_$timestamp.png'));

      final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
      final request = await client.postUrl(Uri.parse('https://api.remove.bg/v1.0/removebg'));

      final boundary = '----RemoveBgBoundary$timestamp';
      request.headers.set('X-Api-Key', settings.removeBgApiKey.trim());
      request.headers.set('Content-Type', 'multipart/form-data; boundary=$boundary');

      final bodyBytes = <int>[];

      // Form field: size = auto
      bodyBytes.addAll(utf8.encode('--$boundary\r\n'));
      bodyBytes.addAll(utf8.encode('Content-Disposition: form-data; name="size"\r\n\r\n'));
      bodyBytes.addAll(utf8.encode('auto\r\n'));

      // Form file: image_file
      final filename = p.basename(imagePath);
      bodyBytes.addAll(utf8.encode('--$boundary\r\n'));
      bodyBytes.addAll(utf8.encode('Content-Disposition: form-data; name="image_file"; filename="$filename"\r\n'));
      bodyBytes.addAll(utf8.encode('Content-Type: application/octet-stream\r\n\r\n'));
      bodyBytes.addAll(await inputFile.readAsBytes());
      bodyBytes.addAll(utf8.encode('\r\n'));

      // End boundary
      bodyBytes.addAll(utf8.encode('--$boundary--\r\n'));

      request.contentLength = bodyBytes.length;
      request.add(bodyBytes);

      final response = await request.close();

      if (response.statusCode == 200) {
        final outStream = outputFile.openWrite();
        await response.pipe(outStream);
        await outStream.close();

        return CutoutResult(
          isSuccess: true,
          outputPath: outputFile.absolutePath,
        );
      } else {
        final errText = await utf8.decodeStream(response);
        return CutoutResult(
          isSuccess: false,
          errorMessage: 'Remove.bg API Error (${response.statusCode}): $errText',
        );
      }
    } catch (e) {
      debugPrint('Background removal API error: $e');
      return CutoutResult(
        isSuccess: false,
        errorMessage: 'Background removal failed: $e',
      );
    }
  }
}
