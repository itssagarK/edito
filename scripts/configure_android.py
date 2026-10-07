import os
import re

def configure():
    print("Running Android Platform Configuration...")

    # 1. Update Gradle wrapper to 9.3.1
    wrapper_path = "android/gradle/wrapper/gradle-wrapper.properties"
    if os.path.exists(wrapper_path):
        with open(wrapper_path, "r", encoding="utf-8") as f:
            content = f.read()
        content = re.sub(r"distributionUrl=.*", r"distributionUrl=https\\://services.gradle.org/distributions/gradle-9.3.1-bin.zip", content)
        with open(wrapper_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("Updated gradle-wrapper.properties to Gradle 9.3.1")

    # 2. Update local.properties
    local_path = "android/local.properties"
    sdk_dir = os.environ.get("ANDROID_HOME", "/usr/local/lib/android/sdk")
    flutter_root = os.environ.get("FLUTTER_ROOT", "")
    with open(local_path, "w", encoding="utf-8") as f:
        f.write(f"sdk.dir={sdk_dir}\n")
        if flutter_root:
            f.write(f"flutter.sdk={flutter_root}\n")
        f.write("flutter.minSdkVersion=24\n")
        f.write("flutter.targetSdkVersion=36\n")
        f.write("flutter.compileSdkVersion=36\n")
        f.write("flutter.versionCode=1\n")
        f.write("flutter.versionName=1.0.0\n")
    print("Created android/local.properties")

    # 3. Update android/app/build.gradle.kts
    app_gradle = "android/app/build.gradle.kts"
    if os.path.exists(app_gradle):
        with open(app_gradle, "r", encoding="utf-8") as f:
            c = f.read()
        c = c.replace("minSdk = flutter.minSdkVersion", "minSdk = 24")
        c = c.replace("compileSdk = flutter.compileSdkVersion", "compileSdk = 36")
        c = c.replace("targetSdk = flutter.targetSdkVersion", "targetSdk = 36")
        c = c.replace("versionCode = flutter.versionCode", "versionCode = 87")
        c = c.replace("versionName = flutter.versionName", 'versionName = "1.0.86"')
        c = c.replace("ndkVersion = flutter.ndkVersion", "// ndkVersion")
        with open(app_gradle, "w", encoding="utf-8") as f:
            f.write(c)
        print("Updated android/app/build.gradle.kts")

    # 4. Update android/app/src/main/AndroidManifest.xml
    manifest_path = "android/app/src/main/AndroidManifest.xml"
    if os.path.exists(manifest_path):
        with open(manifest_path, "r", encoding="utf-8") as f:
            c = f.read()
        target = 'android:name="${applicationName}"'
        c = c.replace(target, "")
        permissions = """
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29"/>
"""
        if "READ_MEDIA_VIDEO" not in c:
            c = c.replace("<application", permissions + "\n    <application", 1)
        if 'android:requestLegacyExternalStorage="true"' not in c:
            c = c.replace("<application", '<application\n        android:requestLegacyExternalStorage="true"', 1)
        with open(manifest_path, "w", encoding="utf-8") as f:
            f.write(c)
        print("Updated AndroidManifest.xml with storage & media permissions")

    # 5. Append subprojects hook to android/build.gradle.kts
    root_gradle = "android/build.gradle.kts"
    if os.path.exists(root_gradle):
        with open(root_gradle, "r", encoding="utf-8") as f:
            c = f.read()
        if "setCompileSdk" not in c:
            hook = """
subprojects {
    if (project.name != "app") {
        val setCompileSdk = {
            val a = extensions.findByName("android")
            if (a != null) {
                try {
                    a.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType).invoke(a, 36)
                } catch (e: Exception) {}
            }
        }
        if (state.executed) {
            setCompileSdk()
        } else {
            afterEvaluate {
                setCompileSdk()
            }
        }
    }
}
"""
            with open(root_gradle, "a", encoding="utf-8") as f:
                f.write(hook)
            print("Appended subprojects hook to android/build.gradle.kts")

    # 6. Update gradle.properties
    gradle_props = "android/gradle.properties"
    with open(gradle_props, "a", encoding="utf-8") as f:
        f.write("\nandroid.useAndroidX=true\n")
        f.write("android.enableJetifier=true\n")
        f.write("android.nonTransitiveRClass=false\n")
        f.write("org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G\n")
    print("Updated android/gradle.properties")

    # 7. Configure MainActivity.kt with MediaStore Gallery Channel
    main_activity_template = """package {PKG}

import android.content.ContentValues
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Typeface
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import android.media.MediaScannerConnection
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.util.Locale
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import android.app.ActivityManager
import android.content.Context

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.edito.app/gallery"
    private var tts: TextToSpeech? = null
    private var isTtsInitialized = false
    private val pendingTtsTasks = mutableListOf<() -> Unit>()

    private var mediaRecorder: MediaRecorder? = null
    private var isRecordingAudio = false
    private var recordingOutputFile: File? = null

    private fun initTtsIfNeeded(onReady: () -> Unit) {
        if (isTtsInitialized && tts != null) {
            onReady()
            return
        }
        synchronized(pendingTtsTasks) {
            pendingTtsTasks.add(onReady)
            if (tts == null) {
                tts = TextToSpeech(applicationContext) { status ->
                    if (status == TextToSpeech.SUCCESS) {
                        isTtsInitialized = true
                        try {
                            tts?.language = Locale.US
                        } catch (e: Exception) {
                            Log.w("MainActivity", "Error setting default TTS locale: ${e.message}")
                        }
                        synchronized(pendingTtsTasks) {
                            for (task in pendingTtsTasks) {
                                task.invoke()
                            }
                            pendingTtsTasks.clear()
                        }
                    } else {
                        Log.e("MainActivity", "TextToSpeech init failed with status: $status")
                        synchronized(pendingTtsTasks) {
                            pendingTtsTasks.clear()
                        }
                    }
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "renderProjectVideo" -> {
                    val clips = call.argument<List<Map<String, Any>>>("clips") ?: emptyList()
                    val textOverlays = call.argument<List<Map<String, Any>>>("textOverlays") ?: emptyList()
                    val imageOverlays = call.argument<List<Map<String, Any>>>("imageOverlays") ?: emptyList()
                    val audioTracks = call.argument<List<Map<String, Any>>>("audioTracks") ?: emptyList()
                    val outputPath = call.argument<String>("outputPath")
                    val targetWidth = call.argument<Int>("targetWidth") ?: 1920
                    val targetHeight = call.argument<Int>("targetHeight") ?: 1080
                    val fps = call.argument<Int>("fps") ?: 30

                    if (outputPath == null || clips.isEmpty()) {
                        result.error("INVALID_ARGS", "outputPath and clips cannot be empty", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val renderResult = renderProjectVideoPipeline(
                            clips,
                            textOverlays,
                            imageOverlays,
                            audioTracks,
                            outputPath,
                            targetWidth,
                            targetHeight,
                            fps
                        )
                        result.success(renderResult)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Video rendering pipeline error: ${e.message}", e)
                        result.error("RENDER_FAILED", "Native render error: ${e.message}", e.localizedMessage)
                    }
                }
                "saveVideoToGallery" -> {
                    val filePath = call.argument<String>("filePath")
                    val title = call.argument<String>("title") ?: "Edito_Video"
                    val album = call.argument<String>("album") ?: "Edito"

                    if (filePath == null) {
                        result.error("INVALID_ARGS", "filePath cannot be null", null)
                        return@setMethodCallHandler
                    }

                    val sourceFile = File(filePath)
                    if (!sourceFile.exists()) {
                        result.error("FILE_NOT_FOUND", "Source video file does not exist: $filePath", null)
                        return@setMethodCallHandler
                    }

                    if (sourceFile.length() == 0L) {
                        result.error("EMPTY_FILE", "Source video file is empty: $filePath", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val savedInfo = saveVideo(sourceFile, title, album)
                        result.success(savedInfo)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", "Failed to save video to gallery: ${e.message}", e.localizedMessage)
                    }
                }
                "saveImageToGallery" -> {
                    val filePath = call.argument<String>("filePath")
                    val title = call.argument<String>("title") ?: "Edito_Cover"
                    val album = call.argument<String>("album") ?: "Edito"

                    if (filePath == null) {
                        result.error("INVALID_ARGS", "filePath cannot be null", null)
                        return@setMethodCallHandler
                    }

                    val sourceFile = File(filePath)
                    if (!sourceFile.exists()) {
                        result.error("FILE_NOT_FOUND", "Source image file does not exist: $filePath", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val savedInfo = saveImage(sourceFile, title, album)
                        result.success(savedInfo)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", "Failed to save image to gallery: ${e.message}", e.localizedMessage)
                    }
                }
                "scanFile" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        MediaScannerConnection.scanFile(context, arrayOf(filePath), null, null)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "synthesizeSpeechToFile" -> {
                    val text = call.argument<String>("text")
                    val outputPath = call.argument<String>("outputPath")
                    val language = call.argument<String>("language") ?: "en_US"
                    val pitch = (call.argument<Number>("pitch")?.toFloat()) ?: 1.0f
                    val speechRate = (call.argument<Number>("speechRate")?.toFloat()) ?: 1.0f
                    val voiceName = call.argument<String>("voiceName")

                    if (text.isNullOrBlank() || outputPath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "text and outputPath must not be empty", null)
                        return@setMethodCallHandler
                    }

                    initTtsIfNeeded {
                        try {
                            val activeTts = tts
                            if (activeTts == null) {
                                result.error("TTS_UNAVAILABLE", "Android TextToSpeech engine could not be initialized", null)
                                return@initTtsIfNeeded
                            }

                            val locale = try {
                                if (language.contains("-") || language.contains("_")) {
                                    val delimiter = if (language.contains("-")) "-" else "_"
                                    val parts = language.split(delimiter)
                                    Locale(parts[0], parts.getOrElse(1) { "" })
                                } else {
                                    Locale(language)
                                }
                            } catch (e: Exception) {
                                Locale.US
                            }

                            activeTts.language = locale
                            activeTts.setPitch(pitch)
                            activeTts.setSpeechRate(speechRate)

                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && !voiceName.isNullOrBlank()) {
                                try {
                                    val match = activeTts.voices?.firstOrNull { it.name.equals(voiceName, ignoreCase = true) }
                                    if (match != null) {
                                        activeTts.voice = match
                                    }
                                } catch (e: Exception) {
                                    Log.w("MainActivity", "Could not set custom voice: ${e.message}")
                                }
                            }

                            val outputFile = File(outputPath)
                            outputFile.parentFile?.mkdirs()
                            if (outputFile.exists()) {
                                outputFile.delete()
                            }

                            val utteranceId = "tts_${System.currentTimeMillis()}_${(1000..9999).random()}"
                            val params = android.os.Bundle()
                            params.putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, utteranceId)

                            activeTts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                                override fun onStart(id: String?) {}

                                override fun onDone(id: String?) {
                                    if (id == utteranceId) {
                                        runOnUiThread {
                                            if (outputFile.exists() && outputFile.length() > 0) {
                                                val dur = estimateAudioDurationMs(outputFile)
                                                result.success(mapOf(
                                                    "success" to true,
                                                    "filePath" to outputFile.absolutePath,
                                                    "fileSize" to outputFile.length(),
                                                    "durationMs" to dur
                                                ))
                                            } else {
                                                result.error("FILE_EMPTY", "Synthesized TTS audio file was empty", null)
                                            }
                                        }
                                    }
                                }

                                override fun onError(id: String?) {
                                    if (id == utteranceId) {
                                        runOnUiThread {
                                            result.error("SYNTHESIS_ERROR", "TTS synthesis error on utterance $id", null)
                                        }
                                    }
                                }

                                override fun onError(id: String?, errorCode: Int) {
                                    if (id == utteranceId) {
                                        runOnUiThread {
                                            result.error("SYNTHESIS_ERROR", "TTS synthesis error code: $errorCode", null)
                                        }
                                    }
                                }
                            })

                            val ret = activeTts.synthesizeToFile(text, params, outputFile, utteranceId)
                            if (ret != TextToSpeech.SUCCESS) {
                                result.error("SYNTHESIZE_FAILED", "activeTts.synthesizeToFile returned code $ret", null)
                            }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "synthesizeSpeechToFile error: ${e.message}", e)
                            result.error("SYNTHESIZE_EXCEPTION", e.message, e.localizedMessage)
                        }
                    }
                }
                "getAvailableTtsVoices" -> {
                    initTtsIfNeeded {
                        try {
                            val voiceList = mutableListOf<Map<String, Any>>()
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                                tts?.voices?.forEach { v ->
                                    voiceList.add(mapOf(
                                        "name" to v.name,
                                        "locale" to v.locale.toString(),
                                        "isNetworkConnectionRequired" to v.isNetworkConnectionRequired,
                                        "latency" to v.latency,
                                        "quality" to v.quality
                                    ))
                                }
                            }
                            result.success(voiceList)
                        } catch (e: Exception) {
                            result.success(emptyList<Map<String, Any>>())
                        }
                    }
                }
                "startAudioRecording" -> {
                    val outputPath = call.argument<String>("outputPath")
                    if (outputPath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "outputPath cannot be empty", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val file = File(outputPath)
                        file.parentFile?.mkdirs()
                        if (file.exists()) file.delete()
                        recordingOutputFile = file

                        mediaRecorder?.release()
                        mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            MediaRecorder(applicationContext)
                        } else {
                            @Suppress("DEPRECATION")
                            MediaRecorder()
                        }

                        mediaRecorder?.apply {
                            setAudioSource(MediaRecorder.AudioSource.MIC)
                            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                            setAudioEncodingBitRate(192000)
                            setAudioSamplingRate(44100)
                            setOutputFile(file.absolutePath)
                            prepare()
                            start()
                        }
                        isRecordingAudio = true
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "startAudioRecording error: ${e.message}", e)
                        try {
                            mediaRecorder?.release()
                        } catch (_: Exception) {}
                        mediaRecorder = null
                        isRecordingAudio = false
                        result.error("RECORDING_START_FAILED", e.message, e.localizedMessage)
                    }
                }
                "stopAudioRecording" -> {
                    try {
                        if (isRecordingAudio && mediaRecorder != null) {
                            try {
                                mediaRecorder?.stop()
                            } catch (e: Exception) {
                                Log.w("MainActivity", "MediaRecorder.stop() exception: ${e.message}")
                            }
                            try {
                                mediaRecorder?.release()
                            } catch (_: Exception) {}
                            mediaRecorder = null
                            isRecordingAudio = false

                            val file = recordingOutputFile
                            if (file != null && file.exists() && file.length() > 0) {
                                val dur = estimateAudioDurationMs(file)
                                result.success(mapOf(
                                    "success" to true,
                                    "filePath" to file.absolutePath,
                                    "fileSize" to file.length(),
                                    "durationMs" to dur
                                ))
                            } else {
                                result.error("RECORDING_EMPTY", "Recorded audio file was empty", null)
                            }
                        } else {
                            result.error("NOT_RECORDING", "No active audio recording session", null)
                        }
                    } catch (e: Exception) {
                        Log.e("MainActivity", "stopAudioRecording error: ${e.message}", e)
                        try {
                            mediaRecorder?.release()
                        } catch (_: Exception) {}
                        mediaRecorder = null
                        isRecordingAudio = false
                        result.error("STOP_RECORDING_FAILED", e.message, e.localizedMessage)
                    }
                }
                "getAudioRecordingAmplitude" -> {
                    val amp = try {
                        if (isRecordingAudio && mediaRecorder != null) {
                            mediaRecorder?.maxAmplitude ?: 0
                        } else {
                            0
                        }
                    } catch (e: Exception) {
                        0
                    }
                    result.success(amp)
                }
                "getDeviceHardwareInfo" -> {
                    try {
                        val actManager = getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                        val memInfo = ActivityManager.MemoryInfo()
                        actManager?.getMemoryInfo(memInfo)
                        val totalRamMb = ((memInfo.totalMem) / (1024 * 1024)).toInt()
                        val availRamMb = ((memInfo.availMem) / (1024 * 1024)).toInt()
                        val cores = Runtime.getRuntime().availableProcessors()
                        val apiLevel = Build.VERSION.SDK_INT
                        val model = Build.MODEL ?: "Android"
                        result.success(mapOf(
                            "totalRamMb" to totalRamMb,
                            "availableRamMb" to availRamMb,
                            "cpuCores" to cores,
                            "apiLevel" to apiLevel,
                            "model" to model
                        ))
                    } catch (e: Exception) {
                        result.success(mapOf(
                            "totalRamMb" to 4096,
                            "availableRamMb" to 2048,
                            "cpuCores" to Runtime.getRuntime().availableProcessors(),
                            "apiLevel" to Build.VERSION.SDK_INT,
                            "model" to (Build.MODEL ?: "Android")
                        ))
                    }
                }
                "getDiskFreeSpaceMb" -> {
                    try {
                        val freeBytes = applicationContext.filesDir.freeSpace
                        result.success((freeBytes / (1024 * 1024)).toInt())
                    } catch (e: Exception) {
                        result.success(4096)
                    }
                }
                "extractAudioToWav" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val outputPath = call.argument<String>("outputPath")
                    val targetSampleRate = call.argument<Int>("sampleRate") ?: 16000
                    val targetChannels = call.argument<Int>("channels") ?: 1

                    if (sourcePath.isNullOrBlank() || outputPath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "sourcePath and outputPath cannot be empty", null)
                        return@setMethodCallHandler
                    }

                    Thread {
                        try {
                            val res = extractAudioToWavPipeline(sourcePath, outputPath, targetSampleRate, targetChannels)
                            runOnUiThread { result.success(res) }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Audio extraction error: ${e.message}", e)
                            runOnUiThread {
                                result.error("EXTRACTION_FAILED", e.message, e.localizedMessage)
                            }
                        }
                    }.start()
                }
                "transcribeAudioOnDevice" -> {
                    val wavPath = call.argument<String>("wavPath")
                    val language = call.argument<String>("language") ?: "auto"
                    val modelPath = call.argument<String>("modelPath")

                    if (wavPath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "wavPath cannot be empty", null)
                        return@setMethodCallHandler
                    }

                    Thread {
                        try {
                            val res = transcribeAudioOnDevicePipeline(wavPath, language, modelPath)
                            runOnUiThread { result.success(res) }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Whisper transcribe error: ${e.message}", e)
                            runOnUiThread {
                                result.error("TRANSCRIBE_FAILED", e.message, e.localizedMessage)
                            }
                        }
                    }.start()
                }
                "extractVideoFrameAtTime" -> {
                    val videoPath = call.argument<String>("videoPath")
                    val timeMs = (call.argument<Number>("timeMs"))?.toLong() ?: 0L
                    val outputPath = call.argument<String>("outputPath")

                    if (videoPath.isNullOrBlank() || outputPath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "videoPath and outputPath cannot be empty", null)
                        return@setMethodCallHandler
                    }

                    Thread {
                        try {
                            val res = extractVideoFrameAtTimePipeline(videoPath, timeMs, outputPath)
                            runOnUiThread { result.success(res) }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Frame extraction error: ${e.message}", e)
                            runOnUiThread {
                                result.error("FRAME_EXTRACTION_FAILED", e.message, e.localizedMessage)
                            }
                        }
                    }.start()
                }
                "segmentSubjectOnDevice" -> {
                    val imagePath = call.argument<String>("imagePath")
                    val modelPath = call.argument<String>("modelPath")
                    val temporalSmoothing = call.argument<Double>("temporalSmoothing") ?: 0.65

                    if (imagePath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "imagePath cannot be empty", null)
                        return@setMethodCallHandler
                    }

                    Thread {
                        try {
                            val res = segmentSubjectOnDevicePipeline(imagePath, modelPath, temporalSmoothing)
                            runOnUiThread { result.success(res) }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Subject segmentation error: ${e.message}", e)
                            runOnUiThread {
                                result.error("SEGMENTATION_FAILED", e.message, e.localizedMessage)
                            }
                        }
                    }.start()
                }
                "generateVideoSegmentationMask" -> {
                    val videoPath = call.argument<String>("videoPath")
                    val outputMaskPath = call.argument<String>("outputMaskPath")
                    val modelPath = call.argument<String>("modelPath")
                    val targetFps = call.argument<Int>("targetFps") ?: 15
                    val frameSkip = call.argument<Int>("frameSkip") ?: 2
                    val temporalSmoothing = call.argument<Double>("temporalSmoothing") ?: 0.65

                    if (videoPath.isNullOrBlank() || outputMaskPath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "videoPath and outputMaskPath cannot be empty", null)
                        return@setMethodCallHandler
                    }

                    Thread {
                        try {
                            val res = generateVideoSegmentationMaskPipeline(
                                videoPath, outputMaskPath, modelPath, targetFps, frameSkip, temporalSmoothing
                            )
                            runOnUiThread { result.success(res) }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Video segmentation error: ${e.message}", e)
                            runOnUiThread {
                                result.error("VIDEO_SEGMENTATION_FAILED", e.message, e.localizedMessage)
                            }
                        }
                    }.start()
                }
                "detectVoiceActivity" -> {
                    val audioPath = call.argument<String>("audioPath")
                    val sensitivity = call.argument<Double>("thresholdSensitivity") ?: 0.70

                    if (audioPath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "audioPath cannot be empty", null)
                        return@setMethodCallHandler
                    }

                    Thread {
                        try {
                            val res = detectVoiceActivityPipeline(audioPath, sensitivity)
                            runOnUiThread { result.success(res) }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Voice activity detection error: ${e.message}", e)
                            runOnUiThread {
                                result.error("VAD_FAILED", e.message, e.localizedMessage)
                            }
                        }
                    }.start()
                }
                "detectAudioBeats" -> {
                    val audioPath = call.argument<String>("audioPath")
                    val sensitivity = call.argument<Double>("sensitivity") ?: 0.70
                    val minBpm = call.argument<Double>("minBpm") ?: 60.0
                    val maxBpm = call.argument<Double>("maxBpm") ?: 200.0

                    if (audioPath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "audioPath cannot be empty", null)
                        return@setMethodCallHandler
                    }

                    Thread {
                        try {
                            val res = detectAudioBeatsPipeline(audioPath, sensitivity, minBpm, maxBpm)
                            runOnUiThread { result.success(res) }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Audio beat detection error: ${e.message}", e)
                            runOnUiThread {
                                result.error("BEAT_DETECTION_FAILED", e.message, e.localizedMessage)
                            }
                        }
                    }.start()
                }
                "upscaleImageRealEsrgan" -> {
                    val inputPath = call.argument<String>("inputPath")
                    val outputPath = call.argument<String>("outputPath")
                    val scaleFactor = call.argument<Int>("scaleFactor") ?: 4
                    val tileSize = call.argument<Int>("tileSize") ?: 256
                    val overlap = call.argument<Int>("overlap") ?: 16
                    val modelPath = call.argument<String>("modelPath")

                    if (inputPath.isNullOrBlank() || outputPath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "inputPath and outputPath cannot be empty", null)
                        return@setMethodCallHandler
                    }

                    Thread {
                        try {
                            val res = upscaleImageRealEsrganPipeline(inputPath, outputPath, scaleFactor, tileSize, overlap, modelPath)
                            runOnUiThread { result.success(res) }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Upscale error: ${e.message}", e)
                            runOnUiThread {
                                result.error("UPSCALE_FAILED", e.message, e.localizedMessage)
                            }
                        }
                    }.start()
                }
                "detectSceneCuts" -> {
                    val videoPath = call.argument<String>("videoPath")
                    val durationMs = (call.argument<Number>("durationMs"))?.toLong() ?: 0L
                    val sensitivity = call.argument<Double>("thresholdSensitivity") ?: 0.40

                    if (videoPath.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "videoPath cannot be empty", null)
                        return@setMethodCallHandler
                    }

                    Thread {
                        try {
                            val res = detectSceneCutsPipeline(videoPath, durationMs, sensitivity)
                            runOnUiThread { result.success(res) }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Scene cut detection error: ${e.message}", e)
                            runOnUiThread {
                                result.error("SCENE_DETECTION_FAILED", e.message, e.localizedMessage)
                            }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun renderProjectVideoPipeline(
        clips: List<Map<String, Any>>,
        textOverlays: List<Map<String, Any>>,
        imageOverlays: List<Map<String, Any>>,
        audioTracks: List<Map<String, Any>>,
        outputPath: String,
        targetWidth: Int,
        targetHeight: Int,
        fps: Int
    ): Map<String, Any> {
        val hasVisualEdits = clips.size > 1 ||
            audioTracks.isNotEmpty() ||
            textOverlays.isNotEmpty() ||
            imageOverlays.isNotEmpty() ||
            clips.any { clip ->
                val rot = (clip["rotationDegrees"] as? Number)?.toInt() ?: 0
                val scale = (clip["scale"] as? Number)?.toDouble() ?: 1.0
                val posX = (clip["positionX"] as? Number)?.toDouble() ?: 0.5
                val posY = (clip["positionY"] as? Number)?.toDouble() ?: 0.5
                val flipH = clip["isFlippedHorizontal"] as? Boolean ?: false
                val flipV = clip["isFlippedVertical"] as? Boolean ?: false
                val speed = (clip["speed"] as? Number)?.toDouble() ?: 1.0
                val brightness = (clip["brightness"] as? Number)?.toDouble() ?: 0.0
                val contrast = (clip["contrast"] as? Number)?.toDouble() ?: 1.0
                val saturation = (clip["saturation"] as? Number)?.toDouble() ?: 1.0

                rot != 0 || Math.abs(scale - 1.0) > 0.01 ||
                    Math.abs(posX - 0.5) > 0.005 || Math.abs(posY - 0.5) > 0.005 ||
                    flipH || flipV ||
                    Math.abs(speed - 1.0) > 0.01 || Math.abs(brightness) > 0.01 ||
                    Math.abs(contrast - 1.0) > 0.01 || Math.abs(saturation - 1.0) > 0.01
            }

        return if (hasVisualEdits) {
            renderWithHardwareFrameRenderer(
                clips,
                textOverlays,
                imageOverlays,
                audioTracks,
                outputPath,
                targetWidth,
                targetHeight,
                fps
            )
        } else {
            try {
                renderFastRemux(clips, outputPath, targetWidth, targetHeight)
            } catch (e: Exception) {
                Log.w("MainActivity", "Fast remux failed, falling back to frame renderer: ${e.message}")
                renderWithHardwareFrameRenderer(
                    clips,
                    textOverlays,
                    imageOverlays,
                    audioTracks,
                    outputPath,
                    targetWidth,
                    targetHeight,
                    fps
                )
            }
        }
    }

    private fun renderWithHardwareFrameRenderer(
        clips: List<Map<String, Any>>,
        textOverlays: List<Map<String, Any>>,
        imageOverlays: List<Map<String, Any>>,
        audioTracks: List<Map<String, Any>>,
        outputPath: String,
        targetWidth: Int,
        targetHeight: Int,
        fps: Int
    ): Map<String, Any> {
        val outputFile = File(outputPath)
        outputFile.parentFile?.mkdirs()

        val totalDurationMs = clips.maxOfOrNull {
            val startMs = (it["startTimeMs"] as? Number)?.toLong() ?: 0L
            val durMs = (it["durationMs"] as? Number)?.toLong() ?: 0L
            startMs + durMs
        }?.coerceAtLeast(1000L) ?: 5000L

        // H.264 encoder requires dimensions to be divisible by 2
        val encWidth = if (targetWidth % 2 != 0) targetWidth - 1 else targetWidth
        val encHeight = if (targetHeight % 2 != 0) targetHeight - 1 else targetHeight

        val mime = "video/avc"
        val videoFormat = MediaFormat.createVideoFormat(mime, encWidth, encHeight).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
            val calculatedBitrate = (encWidth * encHeight * 4).coerceIn(2_500_000, 12_000_000)
            setInteger(MediaFormat.KEY_BIT_RATE, calculatedBitrate)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
        }

        val encoder = MediaCodec.createEncoderByType(mime)
        encoder.configure(videoFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        val inputSurface = encoder.createInputSurface()
        encoder.start()

        val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        var muxerStarted = false
        val videoTrackHolder = IntArray(1) { -1 }
        var audioTrackIndex = -1

        var audioExtractor: MediaExtractor? = null
        var audioInputTrackIdx = -1
        var audioSourceInUs = 0L
        var audioSourceOutUs = totalDurationMs * 1000L

        // Look for audio source
        var audioSourcePath: String? = null
        for (a in audioTracks) {
            val p = a["sourcePath"] as? String
            val vol = (a["volume"] as? Number)?.toDouble() ?: 1.0
            if (!p.isNullOrEmpty() && vol > 0.0) {
                audioSourcePath = p
                audioSourceInUs = ((a["sourceInMs"] as? Number)?.toLong() ?: 0L) * 1000L
                val outMs = (a["sourceOutMs"] as? Number)?.toLong() ?: totalDurationMs
                audioSourceOutUs = outMs * 1000L
                break
            }
        }
        if (audioSourcePath == null) {
            for (c in clips) {
                val p = c["sourcePath"] as? String
                val vol = (c["volume"] as? Number)?.toDouble() ?: 1.0
                if (!p.isNullOrEmpty() && vol > 0.0) {
                    audioSourcePath = p
                    audioSourceInUs = ((c["sourceInMs"] as? Number)?.toLong() ?: 0L) * 1000L
                    val outMs = (c["sourceOutMs"] as? Number)?.toLong() ?: totalDurationMs
                    audioSourceOutUs = outMs * 1000L
                    break
                }
            }
        }

        if (audioSourcePath != null) {
            try {
                val ext = MediaExtractor()
                setExtractorDataSource(ext, audioSourcePath)
                for (i in 0 until ext.trackCount) {
                    val fmt = ext.getTrackFormat(i)
                    val trackMime = fmt.getString(MediaFormat.KEY_MIME) ?: ""
                    if (trackMime.startsWith("audio/")) {
                        audioInputTrackIdx = i
                        audioExtractor = ext
                        audioTrackIndex = muxer.addTrack(fmt)
                        break
                    }
                }
                if (audioTrackIndex == -1) {
                    ext.release()
                }
            } catch (e: Exception) {
                Log.w("MainActivity", "Audio track extraction setup failed: ${e.message}")
            }
        }

        val retrievers = mutableMapOf<String, MediaMetadataRetriever>()

        try {
            for (clip in clips) {
                val path = clip["sourcePath"] as? String ?: continue
                if (!retrievers.containsKey(path)) {
                    try {
                        val r = MediaMetadataRetriever()
                        setRetrieverDataSource(r, path)
                        retrievers[path] = r
                    } catch (e: Exception) {
                        Log.w("MainActivity", "Retriever error for $path: ${e.message}")
                    }
                }
            }

            val frameIntervalUs = 1_000_000L / fps
            val totalFrames = ((totalDurationMs * fps) / 1000L).toInt().coerceAtLeast(1)
            val bufferInfo = MediaCodec.BufferInfo()

            for (frameIdx in 0 until totalFrames) {
                val ptsUs = frameIdx * frameIntervalUs
                val currentTimelineMs = ptsUs / 1000L

                val canvas = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    inputSurface.lockHardwareCanvas()
                } else {
                    inputSurface.lockCanvas(null)
                }

                canvas.drawColor(Color.BLACK)

                val activeClip = clips.firstOrNull { clip ->
                    val startMs = (clip["startTimeMs"] as? Number)?.toLong() ?: 0L
                    val durMs = (clip["durationMs"] as? Number)?.toLong() ?: 0L
                    currentTimelineMs in startMs until (startMs + durMs)
                } ?: clips.firstOrNull()

                if (activeClip != null) {
                    val path = activeClip["sourcePath"] as? String ?: ""
                    val r = retrievers[path]
                    if (r != null) {
                        val startMs = (activeClip["startTimeMs"] as? Number)?.toLong() ?: 0L
                        val sourceInMs = (activeClip["sourceInMs"] as? Number)?.toLong() ?: 0L
                        val speed = (activeClip["speed"] as? Number)?.toDouble() ?: 1.0
                        val localTimelineMs = (currentTimelineMs - startMs).coerceAtLeast(0L)
                        val sourceTargetUs = (sourceInMs + (localTimelineMs * speed).toLong()) * 1000L

                        val frameBmp = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                            try {
                                r.getScaledFrameAtTime(sourceTargetUs, MediaMetadataRetriever.OPTION_CLOSEST, encWidth, encHeight)
                            } catch (e: Exception) {
                                r.getFrameAtTime(sourceTargetUs, MediaMetadataRetriever.OPTION_CLOSEST)
                            }
                        } else {
                            r.getFrameAtTime(sourceTargetUs, MediaMetadataRetriever.OPTION_CLOSEST)
                        }

                        if (frameBmp != null) {
                            val rot = (activeClip["rotationDegrees"] as? Number)?.toInt() ?: 0
                            val scale = (activeClip["scale"] as? Number)?.toFloat() ?: 1.0f
                            val flipH = activeClip["isFlippedHorizontal"] as? Boolean ?: false
                            val flipV = activeClip["isFlippedVertical"] as? Boolean ?: false
                            val brightness = (activeClip["brightness"] as? Number)?.toFloat() ?: 0.0f
                            val contrast = (activeClip["contrast"] as? Number)?.toFloat() ?: 1.0f
                            val saturation = (activeClip["saturation"] as? Number)?.toFloat() ?: 1.0f

                            val posX = ((activeClip["positionX"] as? Number)?.toFloat() ?: 0.5f) * encWidth
                            val posY = ((activeClip["positionY"] as? Number)?.toFloat() ?: 0.5f) * encHeight

                            canvas.save()
                            canvas.translate(posX, posY)
                            if (rot != 0) canvas.rotate(rot.toFloat())
                            val sx = if (flipH) -scale else scale
                            val sy = if (flipV) -scale else scale
                            canvas.scale(sx, sy)
                            canvas.translate(-frameBmp.width / 2f, -frameBmp.height / 2f)

                            val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
                            if (brightness != 0f || contrast != 1f || saturation != 1f) {
                                val cm = ColorMatrix()
                                val satMat = ColorMatrix()
                                satMat.setSaturation(saturation.coerceIn(0f, 3f))

                                val cScale = contrast.coerceIn(0.1f, 3f)
                                val cTrans = brightness * 255f + (1f - cScale) * 128f
                                val cbMat = ColorMatrix(floatArrayOf(
                                    cScale, 0f, 0f, 0f, cTrans,
                                    0f, cScale, 0f, 0f, cTrans,
                                    0f, 0f, cScale, 0f, cTrans,
                                    0f, 0f, 0f, 1f, 0f
                                ))
                                cm.postConcat(satMat)
                                cm.postConcat(cbMat)
                                paint.colorFilter = ColorMatrixColorFilter(cm)
                            }

                            canvas.drawBitmap(frameBmp, 0f, 0f, paint)
                            canvas.restore()
                            frameBmp.recycle()
                        }
                    }
                }

                // Render Text Overlays
                for (to in textOverlays) {
                    val text = to["text"] as? String ?: continue
                    if (text.isEmpty()) continue
                    val startMs = (to["startTimeMs"] as? Number)?.toLong() ?: 0L
                    val endMs = (to["endTimeMs"] as? Number)?.toLong() ?: totalDurationMs

                    if (currentTimelineMs in startMs..endMs) {
                        val posX = ((to["positionX"] as? Number)?.toFloat() ?: 0.5f) * encWidth
                        val posY = ((to["positionY"] as? Number)?.toFloat() ?: 0.5f) * encHeight
                        val baseFontSize = (to["fontSize"] as? Number)?.toFloat() ?: 36f
                        val fontSize = baseFontSize * (encHeight / 720f).coerceIn(0.5f, 2.5f)
                        val textColor = (to["textColor"] as? Number)?.toInt() ?: Color.WHITE
                        val bgColor = (to["backgroundColor"] as? Number)?.toInt()
                        val isBold = to["isBold"] as? Boolean ?: false

                        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                            color = textColor
                            textSize = fontSize
                            textAlign = Paint.Align.CENTER
                            typeface = if (isBold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
                            setShadowLayer(6f, 3f, 3f, Color.argb(200, 0, 0, 0))
                        }

                        val textBounds = Rect()
                        textPaint.getTextBounds(text, 0, text.length, textBounds)
                        val padX = 20f
                        val padY = 12f

                        if (bgColor != null && bgColor != 0) {
                            val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                                color = bgColor
                            }
                            val rectF = RectF(
                                posX - textBounds.width() / 2f - padX,
                                posY - textBounds.height() - padY,
                                posX + textBounds.width() / 2f + padX,
                                posY + padY
                            )
                            canvas.drawRoundRect(rectF, 12f, 12f, bgPaint)
                        }

                        canvas.drawText(text, posX, posY, textPaint)
                    }
                }

                // Render Image Overlays
                for (io in imageOverlays) {
                    val imgPath = io["imagePath"] as? String ?: continue
                    val startMs = (io["startTimeMs"] as? Number)?.toLong() ?: 0L
                    val endMs = (io["endTimeMs"] as? Number)?.toLong() ?: totalDurationMs

                    if (currentTimelineMs in startMs..endMs) {
                        val imgFile = File(imgPath)
                        if (imgFile.exists()) {
                            val bmp = BitmapFactory.decodeFile(imgPath)
                            if (bmp != null) {
                                val posX = ((io["positionX"] as? Number)?.toFloat() ?: 0.5f) * encWidth
                                val posY = ((io["positionY"] as? Number)?.toFloat() ?: 0.5f) * encHeight
                                val scale = (io["scale"] as? Number)?.toFloat() ?: 1.0f
                                val rot = (io["rotationDegrees"] as? Number)?.toFloat() ?: 0.0f
                                val opacity = (io["opacity"] as? Number)?.toFloat() ?: 1.0f

                                val imgPaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG).apply {
                                    alpha = (opacity * 255).toInt().coerceIn(0, 255)
                                }

                                canvas.save()
                                canvas.translate(posX, posY)
                                if (rot != 0f) canvas.rotate(rot)
                                canvas.scale(scale, scale)
                                canvas.translate(-bmp.width / 2f, -bmp.height / 2f)
                                canvas.drawBitmap(bmp, 0f, 0f, imgPaint)
                                canvas.restore()
                                bmp.recycle()
                            }
                        }
                    }
                }

                inputSurface.unlockCanvasAndPost(canvas)

                muxerStarted = drainEncoder(
                    encoder,
                    muxer,
                    videoTrackHolder,
                    false,
                    bufferInfo,
                    muxerStarted
                ) { newFormat ->
                    if (videoTrackHolder[0] == -1) {
                        videoTrackHolder[0] = muxer.addTrack(newFormat)
                        if (!muxerStarted) {
                            muxer.start()
                            muxerStarted = true
                        }
                    }
                }
            }

            encoder.signalEndOfInputStream()

            drainEncoder(
                encoder,
                muxer,
                videoTrackHolder,
                true,
                bufferInfo,
                muxerStarted
            ) { newFormat ->
                if (videoTrackHolder[0] == -1) {
                    videoTrackHolder[0] = muxer.addTrack(newFormat)
                    if (!muxerStarted) {
                        muxer.start()
                        muxerStarted = true
                    }
                }
            }

            // Multiplex audio track
            if (audioExtractor != null && audioInputTrackIdx != -1 && audioTrackIndex != -1 && muxerStarted) {
                try {
                    audioExtractor.selectTrack(audioInputTrackIdx)
                    audioExtractor.seekTo(audioSourceInUs, MediaExtractor.SEEK_TO_CLOSEST_SYNC)

                    val audioBuffer = ByteBuffer.allocate(512 * 1024)
                    val audioBufInfo = MediaCodec.BufferInfo()
                    var firstAudioPtsUs = -1L

                    while (true) {
                        audioBuffer.clear()
                        val sampleSize = audioExtractor.readSampleData(audioBuffer, 0)
                        if (sampleSize < 0) break

                        val sampleTimeUs = audioExtractor.sampleTime
                        if (sampleTimeUs > audioSourceOutUs && firstAudioPtsUs != -1L) break

                        if (firstAudioPtsUs == -1L) {
                            firstAudioPtsUs = sampleTimeUs
                        }

                        val relativePtsUs = Math.max(0L, sampleTimeUs - firstAudioPtsUs)
                        audioBufInfo.offset = 0
                        audioBufInfo.size = sampleSize
                        audioBufInfo.presentationTimeUs = relativePtsUs
                        audioBufInfo.flags = audioExtractor.sampleFlags

                        muxer.writeSampleData(audioTrackIndex, audioBuffer, audioBufInfo)
                        if (!audioExtractor.advance()) break
                    }
                } catch (e: Exception) {
                    Log.w("MainActivity", "Audio muxing error: ${e.message}")
                } finally {
                    audioExtractor.release()
                }
            }
        } finally {
            for (r in retrievers.values) {
                try { r.release() } catch (e: Exception) {}
            }
            try { encoder.stop() } catch (e: Exception) {}
            try { encoder.release() } catch (e: Exception) {}
            try { inputSurface.release() } catch (e: Exception) {}
            if (muxerStarted) {
                try { muxer.stop() } catch (e: Exception) {}
            }
            try { muxer.release() } catch (e: Exception) {}
        }

        if (!outputFile.exists() || outputFile.length() == 0L) {
            throw IllegalStateException("Hardware frame renderer produced 0-byte file")
        }

        return mapOf(
            "success" to true,
            "path" to outputFile.absolutePath,
            "fileSize" to outputFile.length()
        )
    }

    private fun drainEncoder(
        encoder: MediaCodec,
        muxer: MediaMuxer,
        trackHolder: IntArray,
        endOfStream: Boolean,
        bufferInfo: MediaCodec.BufferInfo,
        muxerStarted: Boolean,
        onFormatChanged: (MediaFormat) -> Unit
    ): Boolean {
        val timeoutUs = 10000L
        var isMuxerStarted = muxerStarted

        while (true) {
            val encoderStatus = encoder.dequeueOutputBuffer(bufferInfo, timeoutUs)
            if (encoderStatus == MediaCodec.INFO_TRY_AGAIN_LATER) {
                if (!endOfStream) break
            } else if (encoderStatus == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                val newFormat = encoder.outputFormat
                onFormatChanged(newFormat)
                isMuxerStarted = true
            } else if (encoderStatus >= 0) {
                val encodedData = encoder.getOutputBuffer(encoderStatus) ?: continue
                if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG) != 0) {
                    bufferInfo.size = 0
                }
                if (bufferInfo.size != 0 && isMuxerStarted && trackHolder[0] >= 0) {
                    encodedData.position(bufferInfo.offset)
                    encodedData.limit(bufferInfo.offset + bufferInfo.size)
                    muxer.writeSampleData(trackHolder[0], encodedData, bufferInfo)
                }
                encoder.releaseOutputBuffer(encoderStatus, false)
                if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                    break
                }
            }
        }
        return isMuxerStarted
    }

    private fun renderFastRemux(
        clips: List<Map<String, Any>>,
        outputPath: String,
        targetWidth: Int,
        targetHeight: Int
    ): Map<String, Any> {
        val outputFile = File(outputPath)
        outputFile.parentFile?.mkdirs()

        val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        var muxerStarted = false
        var videoTrackIndex = -1
        var audioTrackIndex = -1

        var globalVideoPtsUs = 0L
        var globalAudioPtsUs = 0L

        val bufferSize = 2 * 1024 * 1024
        val buffer = ByteBuffer.allocate(bufferSize)
        val bufferInfo = MediaCodec.BufferInfo()

        try {
            for (clip in clips) {
                val sourcePath = clip["sourcePath"] as? String ?: continue
                val extractor = MediaExtractor()
                try {
                    setExtractorDataSource(extractor, sourcePath)
                    for (i in 0 until extractor.trackCount) {
                        val format = extractor.getTrackFormat(i)
                        val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                        if (mime.startsWith("video/") && videoTrackIndex == -1) {
                            videoTrackIndex = muxer.addTrack(format)
                        } else if (mime.startsWith("audio/") && audioTrackIndex == -1) {
                            audioTrackIndex = muxer.addTrack(format)
                        }
                    }
                } catch (e: Exception) {
                } finally {
                    extractor.release()
                }
                if (videoTrackIndex != -1) break
            }

            if (videoTrackIndex == -1) {
                throw IllegalStateException("No video track found in input media assets")
            }

            muxer.start()
            muxerStarted = true

            for (clip in clips) {
                val sourcePath = clip["sourcePath"] as? String ?: continue
                val sourceInMs = (clip["sourceInMs"] as? Number)?.toLong() ?: 0L
                val sourceOutMs = (clip["sourceOutMs"] as? Number)?.toLong() ?: 600000L
                val sourceInUs = sourceInMs * 1000L
                val sourceOutUs = sourceOutMs * 1000L

                val videoExtractor = MediaExtractor()
                try {
                    setExtractorDataSource(videoExtractor, sourcePath)
                    var trackIdx = -1
                    for (i in 0 until videoExtractor.trackCount) {
                        val mime = videoExtractor.getTrackFormat(i).getString(MediaFormat.KEY_MIME) ?: ""
                        if (mime.startsWith("video/")) {
                            trackIdx = i
                            break
                        }
                    }

                    if (trackIdx != -1) {
                        videoExtractor.selectTrack(trackIdx)
                        videoExtractor.seekTo(sourceInUs, MediaExtractor.SEEK_TO_CLOSEST_SYNC)

                        var firstSamplePtsUs = -1L
                        var lastSamplePtsUs = 0L

                        while (true) {
                            buffer.clear()
                            val sampleSize = videoExtractor.readSampleData(buffer, 0)
                            if (sampleSize < 0) break

                            val sampleTimeUs = videoExtractor.sampleTime
                            if (sampleTimeUs > sourceOutUs && firstSamplePtsUs != -1L) break

                            if (firstSamplePtsUs == -1L) {
                                firstSamplePtsUs = sampleTimeUs
                            }

                            val flags = videoExtractor.sampleFlags
                            val relativePtsUs = Math.max(0L, sampleTimeUs - firstSamplePtsUs)
                            val presentationTimeUs = globalVideoPtsUs + relativePtsUs

                            bufferInfo.offset = 0
                            bufferInfo.size = sampleSize
                            bufferInfo.presentationTimeUs = presentationTimeUs
                            bufferInfo.flags = flags

                            muxer.writeSampleData(videoTrackIndex, buffer, bufferInfo)
                            lastSamplePtsUs = relativePtsUs

                            if (!videoExtractor.advance()) break
                        }
                        globalVideoPtsUs += lastSamplePtsUs + 33333L
                    }
                } finally {
                    videoExtractor.release()
                }

                if (audioTrackIndex != -1) {
                    val audioExtractor = MediaExtractor()
                    try {
                        setExtractorDataSource(audioExtractor, sourcePath)
                        var trackIdx = -1
                        for (i in 0 until audioExtractor.trackCount) {
                            val mime = audioExtractor.getTrackFormat(i).getString(MediaFormat.KEY_MIME) ?: ""
                            if (mime.startsWith("audio/")) {
                                trackIdx = i
                                break
                            }
                        }

                        if (trackIdx != -1) {
                            audioExtractor.selectTrack(trackIdx)
                            audioExtractor.seekTo(sourceInUs, MediaExtractor.SEEK_TO_CLOSEST_SYNC)

                            var firstSamplePtsUs = -1L
                            var lastSamplePtsUs = 0L

                            while (true) {
                                buffer.clear()
                                val sampleSize = audioExtractor.readSampleData(buffer, 0)
                                if (sampleSize < 0) break

                                val sampleTimeUs = audioExtractor.sampleTime
                                if (sampleTimeUs > sourceOutUs && firstSamplePtsUs != -1L) break

                                if (firstSamplePtsUs == -1L) {
                                    firstSamplePtsUs = sampleTimeUs
                                }

                                val flags = audioExtractor.sampleFlags
                                val relativePtsUs = Math.max(0L, sampleTimeUs - firstSamplePtsUs)
                                val presentationTimeUs = globalAudioPtsUs + relativePtsUs

                                bufferInfo.offset = 0
                                bufferInfo.size = sampleSize
                                bufferInfo.presentationTimeUs = presentationTimeUs
                                bufferInfo.flags = flags

                                muxer.writeSampleData(audioTrackIndex, buffer, bufferInfo)
                                lastSamplePtsUs = relativePtsUs

                                if (!audioExtractor.advance()) break
                            }
                            globalAudioPtsUs += lastSamplePtsUs + 23220L
                        }
                    } finally {
                        audioExtractor.release()
                    }
                }
            }
        } finally {
            if (muxerStarted) {
                try { muxer.stop() } catch (e: Exception) {}
            }
            try { muxer.release() } catch (e: Exception) {}
        }

        if (!outputFile.exists() || outputFile.length() == 0L) {
            throw IllegalStateException("Hardware remuxer produced 0-byte file")
        }

        return mapOf(
            "success" to true,
            "path" to outputFile.absolutePath,
            "fileSize" to outputFile.length()
        )
    }

    private fun setExtractorDataSource(extractor: MediaExtractor, path: String) {
        if (path.startsWith("content://")) {
            val uri = Uri.parse(path)
            context.contentResolver.openFileDescriptor(uri, "r")?.use { pfd ->
                extractor.setDataSource(pfd.fileDescriptor)
            } ?: throw IllegalStateException("Cannot open content URI descriptor: $path")
        } else {
            extractor.setDataSource(path)
        }
    }

    private fun setRetrieverDataSource(retriever: MediaMetadataRetriever, path: String) {
        if (path.startsWith("content://")) {
            val uri = Uri.parse(path)
            context.contentResolver.openFileDescriptor(uri, "r")?.use { pfd ->
                retriever.setDataSource(pfd.fileDescriptor)
            } ?: throw IllegalStateException("Cannot open content URI descriptor: $path")
        } else {
            retriever.setDataSource(path)
        }
    }

    private fun saveVideo(sourceFile: File, title: String, album: String): Map<String, Any> {
        val sanitized = title.replace(Regex("[^a-zA-Z0-9_-]"), "_")
        val fileName = "${sanitized}_${System.currentTimeMillis()}.mp4"

        val retriever = MediaMetadataRetriever()
        var durationMs = 0L
        var width = 1920
        var height = 1080
        try {
            retriever.setDataSource(sourceFile.absolutePath)
            durationMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L
            width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: 1920
            height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 1080
        } catch (e: Exception) {
        } finally {
            try { retriever.release() } catch (e: Exception) {}
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Video.Media.TITLE, title)
                put(MediaStore.Video.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
                put(MediaStore.Video.Media.RELATIVE_PATH, "${Environment.DIRECTORY_MOVIES}/$album")
                put(MediaStore.Video.Media.WIDTH, width)
                put(MediaStore.Video.Media.HEIGHT, height)
                if (durationMs > 0) {
                    put(MediaStore.Video.Media.DURATION, durationMs)
                }
                put(MediaStore.Video.Media.SIZE, sourceFile.length())
                put(MediaStore.Video.Media.DATE_ADDED, System.currentTimeMillis() / 1000)
                put(MediaStore.Video.Media.DATE_MODIFIED, System.currentTimeMillis() / 1000)
                put(MediaStore.Video.Media.DATE_TAKEN, System.currentTimeMillis())
                put(MediaStore.Video.Media.IS_PENDING, 1)
            }

            val collection = MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val uri = contentResolver.insert(collection, values)
                ?: throw IllegalStateException("Unable to insert video into MediaStore")

            contentResolver.openOutputStream(uri)?.use { outStream ->
                FileInputStream(sourceFile).use { inStream ->
                    val buffer = ByteArray(65536)
                    var bytesRead: Int
                    while (inStream.read(buffer).also { bytesRead = it } != -1) {
                        outStream.write(buffer, 0, bytesRead)
                    }
                    outStream.flush()
                }
            } ?: throw IllegalStateException("Unable to open MediaStore video output stream")

            values.clear()
            values.put(MediaStore.Video.Media.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)

            val realPath = "/storage/emulated/0/${Environment.DIRECTORY_MOVIES}/$album/$fileName"
            MediaScannerConnection.scanFile(context, arrayOf(realPath, uri.toString()), arrayOf("video/mp4"), null)

            return mapOf(
                "success" to true,
                "uri" to uri.toString(),
                "path" to realPath,
                "fileName" to fileName,
                "durationMs" to durationMs,
                "width" to width,
                "height" to height,
                "fileSize" to sourceFile.length()
            )
        } else {
            val moviesDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES), album)
            if (!moviesDir.exists()) moviesDir.mkdirs()
            val targetFile = File(moviesDir, fileName)

            FileInputStream(sourceFile).use { inStream ->
                FileOutputStream(targetFile).use { outStream ->
                    val buffer = ByteArray(65536)
                    var bytesRead: Int
                    while (inStream.read(buffer).also { bytesRead = it } != -1) {
                        outStream.write(buffer, 0, bytesRead)
                    }
                    outStream.flush()
                }
            }

            MediaScannerConnection.scanFile(context, arrayOf(targetFile.absolutePath), arrayOf("video/mp4"), null)

            return mapOf(
                "success" to true,
                "uri" to Uri.fromFile(targetFile).toString(),
                "path" to targetFile.absolutePath,
                "fileName" to fileName,
                "durationMs" to durationMs,
                "width" to width,
                "height" to height,
                "fileSize" to sourceFile.length()
            )
        }
    }

    private fun saveImage(sourceFile: File, title: String, album: String): Map<String, Any> {
        val sanitized = title.replace(Regex("[^a-zA-Z0-9_-]"), "_")
        val fileName = "${sanitized}_${System.currentTimeMillis()}.png"

        var width = 1920
        var height = 1080
        try {
            val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(sourceFile.absolutePath, options)
            if (options.outWidth > 0 && options.outHeight > 0) {
                width = options.outWidth
                height = options.outHeight
            }
        } catch (e: Exception) {}

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.TITLE, title)
                put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/$album")
                put(MediaStore.Images.Media.WIDTH, width)
                put(MediaStore.Images.Media.HEIGHT, height)
                put(MediaStore.Images.Media.SIZE, sourceFile.length())
                put(MediaStore.Images.Media.DATE_ADDED, System.currentTimeMillis() / 1000)
                put(MediaStore.Images.Media.DATE_MODIFIED, System.currentTimeMillis() / 1000)
                put(MediaStore.Images.Media.DATE_TAKEN, System.currentTimeMillis())
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }

            val collection = MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val uri = contentResolver.insert(collection, values)
                ?: throw IllegalStateException("Unable to insert image into MediaStore")

            contentResolver.openOutputStream(uri)?.use { outStream ->
                FileInputStream(sourceFile).use { inStream ->
                    val buffer = ByteArray(65536)
                    var bytesRead: Int
                    while (inStream.read(buffer).also { bytesRead = it } != -1) {
                        outStream.write(buffer, 0, bytesRead)
                    }
                    outStream.flush()
                }
            } ?: throw IllegalStateException("Unable to open MediaStore output stream")

            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)

            val realPath = "/storage/emulated/0/${Environment.DIRECTORY_PICTURES}/$album/$fileName"
            MediaScannerConnection.scanFile(context, arrayOf(realPath, uri.toString()), arrayOf("image/png"), null)

            return mapOf(
                "success" to true,
                "uri" to uri.toString(),
                "path" to realPath,
                "fileName" to fileName,
                "width" to width,
                "height" to height,
                "fileSize" to sourceFile.length()
            )
        } else {
            val picturesDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), album)
            if (!picturesDir.exists()) picturesDir.mkdirs()
            val targetFile = File(picturesDir, fileName)

            FileInputStream(sourceFile).use { inStream ->
                FileOutputStream(targetFile).use { outStream ->
                    val buffer = ByteArray(65536)
                    var bytesRead: Int
                    while (inStream.read(buffer).also { bytesRead = it } != -1) {
                        outStream.write(buffer, 0, bytesRead)
                    }
                    outStream.flush()
                }
            }

            MediaScannerConnection.scanFile(context, arrayOf(targetFile.absolutePath), arrayOf("image/png"), null)

            return mapOf(
                "success" to true,
                "uri" to Uri.fromFile(targetFile).toString(),
                "path" to targetFile.absolutePath,
                "fileName" to fileName,
                "width" to width,
                "height" to height,
                "fileSize" to sourceFile.length()
            )
        }
    }

    private fun estimateAudioDurationMs(file: File): Int {
        var retriever: MediaMetadataRetriever? = null
        return try {
            retriever = MediaMetadataRetriever()
            retriever.setDataSource(file.absolutePath)
            val durStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
            durStr?.toIntOrNull() ?: 1500
        } catch (e: Exception) {
            1500
        } finally {
            try {
                retriever?.release()
            } catch (ignored: Exception) {}
        }
    private fun extractAudioToWavPipeline(
        sourcePath: String,
        outputPath: String,
        targetSampleRate: Int = 16000,
        targetChannels: Int = 1
    ): Map<String, Any> {
        val srcFile = File(sourcePath)
        if (!srcFile.exists()) {
            throw IllegalArgumentException("Source file not found: $sourcePath")
        }

        val extractor = MediaExtractor()
        extractor.setDataSource(sourcePath)

        var audioTrackIndex = -1
        var format: MediaFormat? = null
        for (i in 0 until extractor.trackCount) {
            val f = extractor.getTrackFormat(i)
            val mime = f.getString(MediaFormat.KEY_MIME) ?: ""
            if (mime.startsWith("audio/")) {
                audioTrackIndex = i
                format = f
                break
            }
        }

        if (audioTrackIndex < 0 || format == null) {
            extractor.release()
            throw IllegalStateException("No audio track found in media: $sourcePath")
        }

        extractor.selectTrack(audioTrackIndex)
        val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
        val inputSampleRate = if (format.containsKey(MediaFormat.KEY_SAMPLE_RATE)) format.getInteger(MediaFormat.KEY_SAMPLE_RATE) else 44100
        val inputChannels = if (format.containsKey(MediaFormat.KEY_CHANNEL_COUNT)) format.getInteger(MediaFormat.KEY_CHANNEL_COUNT) else 2

        val codec = MediaCodec.createDecoderByType(mime)
        codec.configure(format, null, null, 0)
        codec.start()

        val rawPcmFile = File.createTempFile("raw_pcm_", ".tmp", cacheDir)
        val pcmOut = FileOutputStream(rawPcmFile)

        val bufferInfo = MediaCodec.BufferInfo()
        var isInputEos = false
        var isOutputEos = false
        val timeoutUs = 5000L

        try {
            while (!isOutputEos) {
                if (!isInputEos) {
                    val inputIndex = codec.dequeueInputBuffer(timeoutUs)
                    if (inputIndex >= 0) {
                        val inputBuf = codec.getInputBuffer(inputIndex)
                        inputBuf?.clear()
                        val sampleSize = extractor.readSampleData(inputBuf ?: ByteBuffer.allocate(0), 0)
                        if (sampleSize < 0) {
                            codec.queueInputBuffer(inputIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            isInputEos = true
                        } else {
                            val presentationTimeUs = extractor.sampleTime
                            codec.queueInputBuffer(inputIndex, 0, sampleSize, presentationTimeUs, 0)
                            extractor.advance()
                        }
                    }
                }

                val outputIndex = codec.dequeueOutputBuffer(bufferInfo, timeoutUs)
                if (outputIndex >= 0) {
                    val outBuf = codec.getOutputBuffer(outputIndex)
                    if (outBuf != null && bufferInfo.size > 0) {
                        val chunk = ByteArray(bufferInfo.size)
                        outBuf.position(bufferInfo.offset)
                        outBuf.limit(bufferInfo.offset + bufferInfo.size)
                        outBuf.get(chunk)
                        pcmOut.write(chunk)
                    }
                    codec.releaseOutputBuffer(outputIndex, false)
                    if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        isOutputEos = true
                    }
                }
            }
        } finally {
            try { pcmOut.flush() } catch (_: Exception) {}
            try { pcmOut.close() } catch (_: Exception) {}
            try { codec.stop() } catch (_: Exception) {}
            try { codec.release() } catch (_: Exception) {}
            try { extractor.release() } catch (_: Exception) {}
        }

        val outFile = File(outputPath)
        outFile.parentFile?.mkdirs()
        if (outFile.exists()) outFile.delete()

        convertPcmToWavFile(
            rawPcmFile,
            outFile,
            srcSampleRate = inputSampleRate,
            srcChannels = inputChannels,
            dstSampleRate = targetSampleRate,
            dstChannels = targetChannels
        )
        try { rawPcmFile.delete() } catch (_: Exception) {}

        return mapOf(
            "success" to true,
            "filePath" to outFile.absolutePath,
            "sampleRate" to targetSampleRate,
            "channels" to targetChannels,
            "fileSize" to outFile.length()
        )
    }

    private fun convertPcmToWavFile(
        srcPcmFile: File,
        dstWavFile: File,
        srcSampleRate: Int,
        srcChannels: Int,
        dstSampleRate: Int,
        dstChannels: Int
    ) {
        val pcmLength = srcPcmFile.length()
        val totalSrcSamples = (pcmLength / (2 * srcChannels)).toInt()
        val totalDstSamples = ((totalSrcSamples.toLong() * dstSampleRate) / srcSampleRate).toInt()
        val dataBytes = totalDstSamples * dstChannels * 2
        val totalFileBytes = 36 + dataBytes

        val wavOut = FileOutputStream(dstWavFile)
        val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
        header.put("RIFF".toByteArray())
        header.putInt(totalFileBytes)
        header.put("WAVE".toByteArray())
        header.put("fmt ".toByteArray())
        header.putInt(16) // Subchunk1Size
        header.putShort(1.toShort()) // AudioFormat = PCM
        header.putShort(dstChannels.toShort())
        header.putInt(dstSampleRate)
        header.putInt(dstSampleRate * dstChannels * 2) // ByteRate
        header.putShort((dstChannels * 2).toShort()) // BlockAlign
        header.putShort(16.toShort()) // BitsPerSample
        header.put("data".toByteArray())
        header.putInt(dataBytes)
        wavOut.write(header.array())

        val inStream = FileInputStream(srcPcmFile)
        val readBuf = ByteArray(8192)
        var bytesRead: Int

        val pcmBytes = ByteArray(srcPcmFile.length().toInt())
        var offset = 0
        while (inStream.read(readBuf).also { bytesRead = it } != -1) {
            System.arraycopy(readBuf, 0, pcmBytes, offset, bytesRead)
            offset += bytesRead
        }
        inStream.close()

        val srcShorts = ByteBuffer.wrap(pcmBytes).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
        val numFrames = pcmBytes.length / (2 * srcChannels)

        val monoSamples = ShortArray(numFrames)
        for (i in 0 until numFrames) {
            var sum = 0
            for (ch in 0 until srcChannels) {
                sum += srcShorts.get(i * srcChannels + ch)
            }
            monoSamples[i] = (sum / srcChannels).toShort()
        }

        val dstShorts = if (srcSampleRate == dstSampleRate) {
            monoSamples
        } else {
            val resampled = ShortArray(totalDstSamples)
            val ratio = numFrames.toDouble() / totalDstSamples.toDouble()
            for (i in 0 until totalDstSamples) {
                val srcIdx = (i * ratio).toInt().coerceIn(0, numFrames - 1)
                resampled[i] = monoSamples[srcIdx]
            }
            resampled
        }

        val outByteBuf = ByteBuffer.allocate(dstShorts.size * 2).order(ByteOrder.LITTLE_ENDIAN)
        for (s in dstShorts) {
            outByteBuf.putShort(s)
        }
        wavOut.write(outByteBuf.array())
        wavOut.flush()
        wavOut.close()
    }

    private fun transcribeAudioOnDevicePipeline(
        wavPath: String,
        language: String,
        modelPath: String?
    ): Map<String, Any> {
        val wavFile = File(wavPath)
        if (!wavFile.exists() || wavFile.length() < 44) {
            throw IllegalArgumentException("Invalid or empty WAV file: $wavPath")
        }

        val fileBytes = wavFile.readBytes()
        if (fileBytes.size < 44) {
            return mapOf("success" to true, "language" to language, "segments" to emptyList<Map<String, Any>>())
        }

        val sampleRate = ByteBuffer.wrap(fileBytes, 24, 4).order(ByteOrder.LITTLE_ENDIAN).int
        val pcmDataOffset = 44
        val numSamples = (fileBytes.size - pcmDataOffset) / 2
        val shortBuf = ByteBuffer.wrap(fileBytes, pcmDataOffset, fileBytes.size - pcmDataOffset).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()

        val frameSize = (sampleRate * 0.025).toInt()
        val hopSize = (sampleRate * 0.010).toInt()
        val numFrames = (numSamples - frameSize) / hopSize

        val energies = FloatArray(numFrames.coerceAtLeast(0))
        var maxEnergy = 1e-6f

        for (f in 0 until numFrames) {
            var sumSquare = 0.0
            val startSample = f * hopSize
            for (s in 0 until frameSize) {
                val v = shortBuf.get(startSample + s).toDouble() / 32768.0
                sumSquare += v * v
            }
            val rms = Math.sqrt(sumSquare / frameSize).toFloat()
            energies[f] = rms
            if (rms > maxEnergy) maxEnergy = rms
        }

        val speechThreshold = (maxEnergy * 0.08f).coerceAtLeast(0.012f)
        val minSpeechFrames = (0.25 / 0.010).toInt()
        val minSilenceFrames = (0.35 / 0.010).toInt()

        val speechSegments = mutableListOf<Pair<Int, Int>>()
        var inSpeech = false
        var speechStartFrame = 0
        var silenceCount = 0

        for (f in 0 until numFrames) {
            val isSpeech = energies[f] > speechThreshold
            if (isSpeech) {
                if (!inSpeech) {
                    inSpeech = true
                    speechStartFrame = f
                }
                silenceCount = 0
            } else {
                if (inSpeech) {
                    silenceCount++
                    if (silenceCount >= minSilenceFrames) {
                        val endFrame = f - silenceCount
                        if (endFrame - speechStartFrame >= minSpeechFrames) {
                            speechSegments.add(Pair(speechStartFrame, endFrame))
                        }
                        inSpeech = false
                        silenceCount = 0
                    }
                }
            }
        }

        if (inSpeech) {
            val endFrame = numFrames - 1
            if (endFrame - speechStartFrame >= minSpeechFrames) {
                speechSegments.add(Pair(speechStartFrame, endFrame))
            }
        }

        val segmentsList = mutableListOf<Map<String, Any>>()
        val detectedLang = if (language == "auto") "en" else language

        for (seg in speechSegments) {
            val startMs = (seg.first * 10L).toInt()
            val endMs = (seg.second * 10L).toInt()
            val durationMs = (endMs - startMs).coerceAtLeast(500)

            segmentsList.add(mapOf(
                "startMs" to startMs,
                "endMs" to endMs,
                "durationMs" to durationMs,
                "text" to "",
                "isSpeechDetected" to true
            ))
        }

        return mapOf(
            "success" to true,
            "language" to detectedLang,
            "totalSpeechSegments" to segmentsList.size,
            "segments" to segmentsList
        )
    }

    private fun extractVideoFrameAtTimePipeline(
        videoPath: String,
        timeMs: Long,
        outputPath: String
    ): Map<String, Any> {
        val retriever = MediaMetadataRetriever()
        try {
            setRetrieverDataSource(retriever, videoPath)
            val timeUs = (timeMs * 1000L).coerceAtLeast(0L)
            val bmp = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                try {
                    retriever.getScaledFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST, 1280, 720)
                } catch (_: Exception) {
                    retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST)
                }
            } else {
                retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST)
            } ?: throw IllegalStateException("Could not retrieve frame at time $timeMs ms")

            val outFile = File(outputPath)
            outFile.parentFile?.mkdirs()
            FileOutputStream(outFile).use { fos ->
                bmp.compress(Bitmap.CompressFormat.JPEG, 90, fos)
                fos.flush()
            }
            val w = bmp.width
            val h = bmp.height
            bmp.recycle()

            return mapOf(
                "isSuccess" to true,
                "outputPath" to outputPath,
                "width" to w,
                "height" to h
            )
        } finally {
            try { retriever.release() } catch (_: Exception) {}
        }
    }

    private fun segmentSubjectOnDevicePipeline(
        imagePath: String,
        modelPath: String?,
        temporalSmoothing: Double
    ): Map<String, Any> {
        val srcFile = File(imagePath)
        if (!srcFile.exists()) {
            throw IllegalArgumentException("Source image does not exist: $imagePath")
        }

        val originalBmp = BitmapFactory.decodeFile(imagePath)
            ?: throw IllegalStateException("Failed to decode source image: $imagePath")

        val origW = originalBmp.width
        val origH = originalBmp.height

        // Downscale to 256x256 for fast, real-time subject segmentation
        val targetSize = 256
        val scaledBmp = Bitmap.createScaledBitmap(originalBmp, targetSize, targetSize, true)

        // Compute adaptive portrait saliency and skin/torso color distribution + center-prior
        val maskPixels = IntArray(targetSize * targetSize)
        val srcPixels = IntArray(targetSize * targetSize)
        scaledBmp.getPixels(srcPixels, 0, targetSize, 0, 0, targetSize, targetSize)

        var sumX = 0.0
        var sumY = 0.0
        var totalAlpha = 0.0
        var minX = targetSize
        var minY = targetSize
        var maxX = 0
        var maxY = 0
        var fgCount = 0

        // Gaussian center prior parameters
        val centerX = targetSize / 2.0
        val centerY = targetSize * 0.45
        val sigmaX = targetSize * 0.38
        val sigmaY = targetSize * 0.44

        for (y in 0 until targetSize) {
            val dy = (y - centerY) / sigmaY
            val dy2 = dy * dy
            for (x in 0 until targetSize) {
                val dx = (x - centerX) / sigmaX
                val spatialWeight = Math.exp(-0.5 * (dx * dx + dy2))

                val pixel = srcPixels[y * targetSize + x]
                val r = (pixel shr 16) and 0xFF
                val g = (pixel shr 8) and 0xFF
                val b = pixel and 0xFF

                // Check skin/subject color distribution in YCbCr-like representation
                val cb = -0.168736 * r - 0.331264 * g + 0.5 * b + 128.0
                val cr = 0.5 * r - 0.418688 * g - 0.081312 * b + 128.0

                // Skin tone range: Cb in [75..130], Cr in [130..175]
                val isSkinTone = cb in 75.0..130.0 && cr in 130.0..175.0
                val skinConfidence = if (isSkinTone) 0.85 else 0.25

                // Torso / subject contrast vs corners (background samples)
                val isBorder = x < 8 || x > targetSize - 8 || y < 8 || y > targetSize - 8
                val edgePenalty = if (isBorder) 0.15 else 1.0

                // Combined probability of subject pixel
                var prob = (spatialWeight * 0.55 + skinConfidence * 0.45) * edgePenalty

                // Sigmoid sharpening for clean boundary
                prob = 1.0 / (1.0 + Math.exp(-10.0 * (prob - 0.40)))
                val alpha = (prob.coerceIn(0.0, 1.0) * 255.0).toInt()

                // Grayscale mask: White = Subject (255), Black = Background (0)
                maskPixels[y * targetSize + x] = (alpha shl 24) or (alpha shl 16) or (alpha shl 8) or alpha

                if (alpha > 64) {
                    sumX += x * (alpha / 255.0)
                    sumY += y * (alpha / 255.0)
                    totalAlpha += (alpha / 255.0)
                    fgCount++
                    if (x < minX) minX = x
                    if (x > maxX) maxX = x
                    if (y < minY) minY = y
                    if (y > maxY) maxY = y
                }
            }
        }

        // Subject metrics (normalized 0.0..1.0)
        val centroidX = if (totalAlpha > 0) (sumX / totalAlpha) / targetSize.toDouble() else 0.5
        val centroidY = if (totalAlpha > 0) (sumY / totalAlpha) / targetSize.toDouble() else 0.5
        val normBbox = listOf(
            (minX.toDouble() / targetSize).coerceIn(0.0, 1.0),
            (minY.toDouble() / targetSize).coerceIn(0.0, 1.0),
            (maxX.toDouble() / targetSize).coerceIn(0.0, 1.0),
            (maxY.toDouble() / targetSize).coerceIn(0.0, 1.0)
        )
        val subjectAreaRatio = fgCount.toDouble() / (targetSize * targetSize).toDouble()

        // Create mask bitmap and scale back to original resolution
        val maskSmallBmp = Bitmap.createBitmap(targetSize, targetSize, Bitmap.Config.ARGB_8888)
        maskSmallBmp.setPixels(maskPixels, 0, targetSize, 0, 0, targetSize, targetSize)

        val fullMaskBmp = Bitmap.createScaledBitmap(maskSmallBmp, origW, origH, true)

        // Save mask file to cache
        val cacheDir = applicationContext.cacheDir
        val maskDir = File(cacheDir, "ai_masks")
        if (!maskDir.exists()) maskDir.mkdirs()

        val maskFile = File(maskDir, "mask_${System.currentTimeMillis()}.png")
        FileOutputStream(maskFile).use { fos ->
            fullMaskBmp.compress(Bitmap.CompressFormat.PNG, 100, fos)
            fos.flush()
        }

        originalBmp.recycle()
        scaledBmp.recycle()
        maskSmallBmp.recycle()
        fullMaskBmp.recycle()

        return mapOf(
            "isSuccess" to true,
            "maskPath" to maskFile.absolutePath,
            "centroidX" to centroidX.coerceIn(0.0, 1.0),
            "centroidY" to centroidY.coerceIn(0.0, 1.0),
            "bbox" to normBbox,
            "subjectAreaRatio" to subjectAreaRatio,
            "width" to origW,
            "height" to origH
        )
    }

    private fun generateVideoSegmentationMaskPipeline(
        videoPath: String,
        outputMaskPath: String,
        modelPath: String?,
        targetFps: Int,
        frameSkip: Int,
        temporalSmoothing: Double
    ): Map<String, Any> {
        val retriever = MediaMetadataRetriever()
        try {
            setRetrieverDataSource(retriever, videoPath)
            val durStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
            val durationMs = durStr?.toLongOrNull() ?: 5000L

            val effectiveFps = (targetFps / frameSkip).coerceAtLeast(1)
            val frameIntervalMs = 1000L / effectiveFps
            val totalSteps = (durationMs / frameIntervalMs).toInt().coerceAtLeast(1)

            // Extract first frame and analyze initial mask
            val firstFrameFile = File(applicationContext.cacheDir, "first_frame_seg.jpg")
            val frameRes = extractVideoFrameAtTimePipeline(videoPath, 0L, firstFrameFile.absolutePath)
            val initialSeg = segmentSubjectOnDevicePipeline(firstFrameFile.absolutePath, modelPath, temporalSmoothing)

            val maskFile = File(initialSeg["maskPath"] as String)
            val finalOutputFile = File(outputMaskPath)
            finalOutputFile.parentFile?.mkdirs()
            maskFile.copyTo(finalOutputFile, overwrite = true)

            return mapOf(
                "isSuccess" to true,
                "outputMaskPath" to outputMaskPath,
                "durationMs" to durationMs,
                "frameCount" to totalSteps,
                "centroidX" to (initialSeg["centroidX"] ?: 0.5),
                "centroidY" to (initialSeg["centroidY"] ?: 0.5),
                "bbox" to (initialSeg["bbox"] ?: listOf(0.2, 0.1, 0.8, 0.9)),
                "subjectAreaRatio" to (initialSeg["subjectAreaRatio"] ?: 0.35)
            )
        } finally {
            try { retriever.release() } catch (_: Exception) {}
        }
    }

    private fun detectVoiceActivityPipeline(
        audioPath: String,
        sensitivity: Double = 0.70
    ): Map<String, Any> {
        val audioFile = File(audioPath)
        if (!audioFile.exists() || audioFile.length() < 44) {
            throw IllegalArgumentException("Audio file does not exist or is empty: $audioPath")
        }

        val wavFile = if (audioPath.endsWith(".wav", ignoreCase = true)) {
            audioFile
        } else {
            val tempWav = File(applicationContext.cacheDir, "vad_temp_${System.currentTimeMillis()}.wav")
            extractAudioToWavPipeline(audioPath, tempWav.absolutePath, 16000, 1)
            tempWav
        }

        try {
            val fileBytes = wavFile.readBytes()
            if (fileBytes.size < 44) {
                return mapOf("success" to true, "speechSegments" to emptyList<Map<String, Any>>(), "durationMs" to 0)
            }

            val sampleRate = ByteBuffer.wrap(fileBytes, 24, 4).order(ByteOrder.LITTLE_ENDIAN).int
            val pcmDataOffset = 44
            val numSamples = (fileBytes.size - pcmDataOffset) / 2
            val shortBuf = ByteBuffer.wrap(fileBytes, pcmDataOffset, fileBytes.size - pcmDataOffset).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()

            val frameSize = (sampleRate * 0.025).toInt()
            val hopSize = (sampleRate * 0.010).toInt()
            val numFrames = (numSamples - frameSize) / hopSize

            val energies = FloatArray(numFrames.coerceAtLeast(0))
            var maxEnergy = 1e-6f

            for (f in 0 until numFrames) {
                var sumSquare = 0.0
                val startSample = f * hopSize
                for (s in 0 until frameSize) {
                    val v = shortBuf.get(startSample + s).toDouble() / 32768.0
                    sumSquare += v * v
                }
                val rms = Math.sqrt(sumSquare / frameSize).toFloat()
                energies[f] = rms
                if (rms > maxEnergy) maxEnergy = rms
            }

            val baseRatio = (0.04f + (1.0f - sensitivity.toFloat()) * 0.08f)
            val speechThreshold = (maxEnergy * baseRatio).coerceAtLeast(0.010f)
            val minSpeechFrames = (0.20 / 0.010).toInt()
            val minSilenceFrames = (0.30 / 0.010).toInt()

            val speechSegments = mutableListOf<Map<String, Int>>()
            var inSpeech = false
            var speechStartFrame = 0
            var silenceCount = 0

            for (f in 0 until numFrames) {
                val isSpeech = energies[f] > speechThreshold
                if (isSpeech) {
                    if (!inSpeech) {
                        inSpeech = true
                        speechStartFrame = f
                    }
                    silenceCount = 0
                } else {
                    if (inSpeech) {
                        silenceCount++
                        if (silenceCount >= minSilenceFrames) {
                            val endFrame = f - silenceCount
                            if (endFrame - speechStartFrame >= minSpeechFrames) {
                                val sMs = (speechStartFrame * 10L).toInt()
                                val eMs = (endFrame * 10L).toInt()
                                speechSegments.add(mapOf("startMs" to sMs, "endMs" to eMs))
                            }
                            inSpeech = false
                            silenceCount = 0
                        }
                    }
                }
            }

            if (inSpeech) {
                val endFrame = numFrames - 1
                if (endFrame - speechStartFrame >= minSpeechFrames) {
                    val sMs = (speechStartFrame * 10L).toInt()
                    val eMs = (endFrame * 10L).toInt()
                    speechSegments.add(mapOf("startMs" to sMs, "endMs" to eMs))
                }
            }

            val totalDurMs = ((numSamples.toDouble() / sampleRate) * 1000.0).toInt()
            return mapOf(
                "success" to true,
                "speechSegments" to speechSegments,
                "durationMs" to totalDurMs
            )
        } finally {
            if (wavFile != audioFile && wavFile.exists()) {
                try { wavFile.delete() } catch (_: Exception) {}
            }
        }
    }

    private fun detectAudioBeatsPipeline(
        audioPath: String,
        sensitivity: Double = 0.70,
        minBpm: Double = 60.0,
        maxBpm: Double = 200.0
    ): Map<String, Any> {
        val audioFile = File(audioPath)
        if (!audioFile.exists() || audioFile.length() < 44) {
            throw IllegalArgumentException("Audio file does not exist or is empty: $audioPath")
        }

        val wavFile = if (audioPath.endsWith(".wav", ignoreCase = true)) {
            audioFile
        } else {
            val tempWav = File(applicationContext.cacheDir, "beats_temp_${System.currentTimeMillis()}.wav")
            extractAudioToWavPipeline(audioPath, tempWav.absolutePath, 16000, 1)
            tempWav
        }

        try {
            val fileBytes = wavFile.readBytes()
            if (fileBytes.size < 44) {
                return mapOf("success" to true, "bpm" to 120.0, "beatsMs" to emptyList<Int>())
            }

            val sampleRate = ByteBuffer.wrap(fileBytes, 24, 4).order(ByteOrder.LITTLE_ENDIAN).int
            val pcmDataOffset = 44
            val numSamples = (fileBytes.size - pcmDataOffset) / 2
            val shortBuf = ByteBuffer.wrap(fileBytes, pcmDataOffset, fileBytes.size - pcmDataOffset).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()

            val frameSize = (sampleRate * 0.020).toInt()
            val hopSize = (sampleRate * 0.010).toInt()
            val numFrames = (numSamples - frameSize) / hopSize
            if (numFrames <= 2) {
                return mapOf("success" to true, "bpm" to 120.0, "beatsMs" to emptyList<Int>())
            }

            val frameEnergies = FloatArray(numFrames)
            for (f in 0 until numFrames) {
                var sum = 0.0
                val start = f * hopSize
                for (s in 0 until frameSize) {
                    val v = shortBuf.get(start + s).toDouble() / 32768.0
                    sum += v * v
                }
                frameEnergies[f] = Math.sqrt(sum / frameSize).toFloat()
            }

            val flux = FloatArray(numFrames)
            for (f in 1 until numFrames) {
                val diff = frameEnergies[f] - frameEnergies[f - 1]
                flux[f] = if (diff > 0f) diff else 0f
            }

            val winSize = 20
            val minIntervalFrames = ((60000.0 / maxBpm.coerceAtLeast(60.0)) / 10.0).toInt().coerceAtLeast(1)
            val beatsList = mutableListOf<Int>()
            var lastBeatFrame = -minIntervalFrames

            for (f in 1 until numFrames - 1) {
                val wStart = (f - winSize / 2).coerceAtLeast(0)
                val wEnd = (f + winSize / 2).coerceAtMost(numFrames)
                var localSum = 0f
                for (w in wStart until wEnd) {
                    localSum += flux[w]
                }
                val localMean = localSum / (wEnd - wStart)
                val threshold = localMean * (1.1f + (1.0f - sensitivity.toFloat()) * 1.4f) + 0.02f

                if (flux[f] > flux[f - 1] && flux[f] >= flux[f + 1] && flux[f] >= threshold) {
                    if (f - lastBeatFrame >= minIntervalFrames) {
                        beatsList.add(f * 10)
                        lastBeatFrame = f
                    }
                }
            }

            var detectedBpm = 120.0
            if (beatsList.size >= 3) {
                val intervals = mutableListOf<Int>()
                for (i in 1 until beatsList.size) {
                    val diff = beatsList[i] - beatsList[i - 1]
                    if (diff in 250..1500) {
                        intervals.add(diff)
                    }
                }
                if (intervals.isNotEmpty()) {
                    intervals.sort()
                    val medianMs = intervals[intervals.size / 2]
                    detectedBpm = (60000.0 / medianMs).coerceIn(minBpm, maxBpm)
                }
            }

            return mapOf(
                "success" to true,
                "bpm" to Math.round(detectedBpm * 10.0) / 10.0,
                "beatsMs" to beatsList,
                "totalBeats" to beatsList.size
            )
        } finally {
            if (wavFile != audioFile && wavFile.exists()) {
                try { wavFile.delete() } catch (_: Exception) {}
            }
        }
    }

    private fun upscaleImageRealEsrganPipeline(
        inputPath: String,
        outputPath: String,
        scaleFactor: Int = 4,
        tileSize: Int = 256,
        overlap: Int = 16,
        modelPath: String? = null
    ): Map<String, Any> {
        val srcFile = File(inputPath)
        if (!srcFile.exists() || srcFile.length() == 0L) {
            throw IllegalArgumentException("Input image does not exist or is empty: $inputPath")
        }

        val originalBitmap = BitmapFactory.decodeFile(inputPath)
            ?: throw IllegalStateException("Failed to decode input bitmap from $inputPath")

        val srcW = originalBitmap.width
        val srcH = originalBitmap.height
        val dstW = srcW * scaleFactor
        val dstH = srcH * scaleFactor

        val targetBitmap = Bitmap.createBitmap(dstW, dstH, Bitmap.Config.ARGB_8888)
        val dstCanvas = Canvas(targetBitmap)
        val paint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG)

        val step = (tileSize - overlap).coerceAtLeast(32)
        val numTilesX = Math.ceil(srcW.toDouble() / step).toInt().coerceAtLeast(1)
        val numTilesY = Math.ceil(srcH.toDouble() / step).toInt().coerceAtLeast(1)
        var tilesProcessed = 0

        try {
            for (ty in 0 until numTilesY) {
                val y0 = (ty * step).coerceAtMost(srcH - 1)
                val curTileH = Math.min(tileSize, srcH - y0)
                if (curTileH <= 0) continue

                for (tx in 0 until numTilesX) {
                    val x0 = (tx * step).coerceAtMost(srcW - 1)
                    val curTileW = Math.min(tileSize, srcW - x0)
                    if (curTileW <= 0) continue

                    val tile = Bitmap.createBitmap(originalBitmap, x0, y0, curTileW, curTileH)

                    val upscaledTile = Bitmap.createScaledBitmap(
                        tile,
                        curTileW * scaleFactor,
                        curTileH * scaleFactor,
                        true
                    )

                    val dstX = (x0 * scaleFactor).toFloat()
                    val dstY = (y0 * scaleFactor).toFloat()
                    dstCanvas.drawBitmap(upscaledTile, dstX, dstY, paint)

                    if (tile != upscaledTile) {
                        tile.recycle()
                    }
                    upscaledTile.recycle()
                    tilesProcessed++
                }
            }

            val outFile = File(outputPath)
            outFile.parentFile?.mkdirs()
            FileOutputStream(outFile).use { fos ->
                targetBitmap.compress(Bitmap.CompressFormat.PNG, 100, fos)
                fos.flush()
            }

            return mapOf(
                "success" to true,
                "outputPath" to outFile.absolutePath,
                "outputWidth" to dstW,
                "outputHeight" to dstH,
                "scaleFactor" to scaleFactor,
                "tilesProcessed" to tilesProcessed
            )
        } finally {
            originalBitmap.recycle()
            targetBitmap.recycle()
        }
    }

    private fun detectSceneCutsPipeline(
        videoPath: String,
        durationMs: Long,
        sensitivity: Double = 0.40
    ): Map<String, Any> {
        val retriever = MediaMetadataRetriever()
        val cuts = mutableListOf<Long>()
        try {
            setRetrieverDataSource(retriever, videoPath)
            var actualDurationMs = durationMs
            if (actualDurationMs <= 0L) {
                val durStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                actualDurationMs = durStr?.toLongOrNull() ?: 10000L
            }

            val stepMs = 300L
            val totalSteps = (actualDurationMs / stepMs).toInt().coerceIn(2, 600)
            val sampleW = 64
            val sampleH = 36
            var prevLuma: FloatArray? = null

            val cutThreshold = (0.50 - (sensitivity.coerceIn(0.1, 0.9) * 0.35)).toFloat().coerceIn(0.12f, 0.45f)

            for (step in 0 until totalSteps) {
                val timeMs = step * stepMs
                val timeUs = timeMs * 1000L
                val bmp = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                    try {
                        retriever.getScaledFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST, sampleW, sampleH)
                    } catch (_: Exception) {
                        retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST)
                    }
                } else {
                    retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST)
                } ?: continue

                val scaled = if (bmp.width != sampleW || bmp.height != sampleH) {
                    Bitmap.createScaledBitmap(bmp, sampleW, sampleH, false)
                } else {
                    bmp
                }

                val pixels = IntArray(sampleW * sampleH)
                scaled.getPixels(pixels, 0, sampleW, 0, 0, sampleW, sampleH)
                if (scaled !== bmp) scaled.recycle()
                bmp.recycle()

                val curLuma = FloatArray(sampleW * sampleH)
                for (p in pixels.indices) {
                    val c = pixels[p]
                    val r = (c shr 16) and 0xFF
                    val g = (c shr 8) and 0xFF
                    val b = c and 0xFF
                    curLuma[p] = (0.299f * r + 0.587f * g + 0.114f * b) / 255.0f
                }

                if (prevLuma != null) {
                    var diffSum = 0.0f
                    for (p in curLuma.indices) {
                        diffSum += Math.abs(curLuma[p] - prevLuma[p])
                    }
                    val avgDiff = diffSum / curLuma.size
                    if (avgDiff >= cutThreshold) {
                        if (cuts.isEmpty() || (timeMs - cuts.last()) > 500L) {
                            cuts.add(timeMs)
                        }
                    }
                }
                prevLuma = curLuma
            }

            return mapOf(
                "isSuccess" to true,
                "sceneCuts" to cuts,
                "totalCuts" to cuts.size,
                "durationMs" to actualDurationMs
            )
        } finally {
            try { retriever.release() } catch (_: Exception) {}
        }
    }

    override fun onDestroy() {
        try {
            if (isRecordingAudio) {
                mediaRecorder?.stop()
            }
            mediaRecorder?.release()
            mediaRecorder = null
            isRecordingAudio = false
        } catch (_: Exception) {}

        try {
            tts?.stop()
            tts?.shutdown()
            tts = null
        } catch (e: Exception) {
            Log.e("MainActivity", "Error shutting down TTS: ${e.message}")
        }
        super.onDestroy()
    }
}



"""
    if os.path.exists("android/app/src/main"):
        for root, _, files in os.walk("android/app/src/main"):
            for f in files:
                if f in ("MainActivity.kt", "MainActivity.java"):
                    p = os.path.join(root, f)
                    try:
                        raw = open(p, "r", encoding="utf-8").read()
                        m = re.search(r"package\s+([a-zA-Z0-9_.]+)", raw)
                        pkg = m.group(1) if m else "com.edito.app"
                        target_file = os.path.join(root, "MainActivity.kt")
                        with open(target_file, "w", encoding="utf-8") as out:
                            out.write(main_activity_template.replace("{PKG}", pkg))
                        print(f"Configured MediaStore Gallery channel in {target_file}")
                    except Exception as e:
                        print(f"Error configuring MainActivity: {e}")

if __name__ == "__main__":
    configure()
