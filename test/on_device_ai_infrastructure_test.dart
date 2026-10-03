import 'package:flutter_test/flutter_test.dart';
import 'package:edito/core/ai/models/ai_model_descriptor.dart';
import 'package:edito/core/ai/device_tier_service.dart';
import 'package:edito/core/ai/on_device_inference_runner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('On-Device AI Model Catalog & Strict Licenses', () {
    test('all catalog models have permissive open-source licenses (MIT, Apache-2.0, BSD)', () {
      final allowedLicenses = {'MIT', 'Apache-2.0', 'BSD-3-Clause'};

      for (final model in AiModelCatalog.allModels) {
        expect(
          allowedLicenses.contains(model.license),
          isTrue,
          reason: 'Model "${model.name}" has unapproved license: ${model.license}',
        );
        expect(model.id.isNotEmpty, isTrue);
        expect(model.name.isNotEmpty, isTrue);
        expect(model.sizeBytes, greaterThan(0));
        expect(model.expectedSha256.length, equals(64),
            reason: 'SHA-256 for ${model.name} must be 64 characters');
      }
    });

    test('catalog model lookup by ID returns correct model', () {
      final whisper = AiModelCatalog.findById('whisper-tiny-en');
      expect(whisper, isNotNull);
      expect(whisper!.category, equals(AiModelCategory.speechToText));
      expect(whisper.license, equals('MIT'));

      final seg = AiModelCatalog.findById('selfie-segmenter');
      expect(seg, isNotNull);
      expect(seg!.category, equals(AiModelCategory.subjectSegmentation));
      expect(seg.license, equals('Apache-2.0'));
      expect(seg.isBundled, isTrue);

      final nonExistent = AiModelCatalog.findById('unknown-model');
      expect(nonExistent, isNull);
    });

    test('model sizes are human-readable and formatted correctly', () {
      final seg = AiModelCatalog.selfieSegmentation;
      expect(seg.formattedSize, contains('KB'));

      final whisper = AiModelCatalog.whisperTinyEn;
      expect(whisper.formattedSize, contains('MB'));
      expect(whisper.sizeInMb, greaterThan(30.0));
    });
  });

  group('DeviceTierService & Inference Profiles', () {
    test('hardware tier accurately computes recommended parameters', () {
      // Low Tier device
      const lowDev = DeviceHardwareInfo(
        totalRamMb: 3000,
        availableRamMb: 1200,
        cpuCores: 4,
        androidApiLevel: 28,
        modelName: 'Budget Phone',
        tier: DeviceTier.low,
      );
      expect(lowDev.previewFrameSkip, equals(5));
      expect(lowDev.maxInferenceResolution, equals(256));
      expect(lowDev.inferenceThreads, equals(2));
      expect(lowDev.enableHardwareDelegate, isFalse); // API 28 < 29
      expect(lowDev.recommendedWhisperModel, equals(AiModelCatalog.whisperTinyEn));

      // Medium Tier device
      const medDev = DeviceHardwareInfo(
        totalRamMb: 6000,
        availableRamMb: 3200,
        cpuCores: 8,
        androidApiLevel: 33,
        modelName: 'Mid-range Phone',
        tier: DeviceTier.medium,
      );
      expect(medDev.previewFrameSkip, equals(3));
      expect(medDev.maxInferenceResolution, equals(384));
      expect(medDev.inferenceThreads, equals(4));
      expect(medDev.enableHardwareDelegate, isTrue);

      // High Tier device
      const highDev = DeviceHardwareInfo(
        totalRamMb: 12000,
        availableRamMb: 8000,
        cpuCores: 8,
        androidApiLevel: 34,
        modelName: 'Flagship Phone',
        tier: DeviceTier.high,
      );
      expect(highDev.previewFrameSkip, equals(2));
      expect(highDev.maxInferenceResolution, equals(512));
      expect(highDev.enableHardwareDelegate, isTrue);
    });
  });

  group('OnDeviceInferenceRunner Concurrency & Cancellation', () {
    test('cooperative CancellationToken triggers early abort', () {
      final token = CancellationToken();
      expect(token.isCancelled, isFalse);

      bool listenerFired = false;
      token.addListener(() {
        listenerFired = true;
      });

      token.cancel();
      expect(token.isCancelled, isTrue);
      expect(listenerFired, isTrue);

      expect(() => token.throwIfCancelled(), throwsA(isA<AiCancelledException>()));
    });

    test('runHeavyInference executes sequentially without race conditions', () async {
      final executionOrder = <int>[];

      final future1 = OnDeviceInferenceRunner.runHeavyInference<int>(
        taskName: 'Task 1',
        action: (token) async {
          await Future.delayed(const Duration(milliseconds: 30));
          executionOrder.add(1);
          return 1;
        },
      );

      final future2 = OnDeviceInferenceRunner.runHeavyInference<int>(
        taskName: 'Task 2',
        action: (token) async {
          await Future.delayed(const Duration(milliseconds: 10));
          executionOrder.add(2);
          return 2;
        },
      );

      final results = await Future.wait([future1, future2]);
      expect(results, equals([1, 2]));
      // Even though task 2 had shorter delay, task 1 had the lock first
      expect(executionOrder, equals([1, 2]));
    });

    test('idle memory eviction registers and cleans up smoothly', () async {
      bool cleaned = false;
      cleaner() async {
        cleaned = true;
      }

      OnDeviceInferenceRunner.registerIdleCleaner(cleaner);
      await OnDeviceInferenceRunner.releaseMemoryNow();
      expect(cleaned, isTrue);

      OnDeviceInferenceRunner.unregisterIdleCleaner(cleaner);
    });
  });
}
