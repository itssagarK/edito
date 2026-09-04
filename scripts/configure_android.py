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
        c = c.replace("versionCode = flutter.versionCode", "versionCode = 14")
        c = c.replace("versionName = flutter.versionName", 'versionName = "1.0.13"')
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
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.edito.app/gallery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
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
                else -> result.notImplemented()
            }
        }
    }

    private fun saveVideo(sourceFile: File, title: String, album: String): Map<String, Any> {
        val sanitized = title.replace(Regex("[^a-zA-Z0-9_-]"), "_")
        val fileName = "${sanitized}_${System.currentTimeMillis()}.mp4"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Video.Media.TITLE, title)
                put(MediaStore.Video.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
                put(MediaStore.Video.Media.RELATIVE_PATH, "${Environment.DIRECTORY_MOVIES}/$album")
                put(MediaStore.Video.Media.IS_PENDING, 1)
            }

            val collection = MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val uri = contentResolver.insert(collection, values)
                ?: throw IllegalStateException("Unable to insert into MediaStore")

            contentResolver.openOutputStream(uri)?.use { outStream ->
                FileInputStream(sourceFile).use { inStream ->
                    inStream.copyTo(outStream)
                }
            } ?: throw IllegalStateException("Unable to open MediaStore output stream")

            values.clear()
            values.put(MediaStore.Video.Media.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)

            val realPath = "/storage/emulated/0/${Environment.DIRECTORY_MOVIES}/$album/$fileName"
            MediaScannerConnection.scanFile(context, arrayOf(realPath, uri.toString()), arrayOf("video/mp4"), null)

            return mapOf(
                "success" to true,
                "uri" to uri.toString(),
                "path" to realPath,
                "fileName" to fileName
            )
        } else {
            val moviesDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES), album)
            if (!moviesDir.exists()) moviesDir.mkdirs()
            val targetFile = File(moviesDir, fileName)

            FileInputStream(sourceFile).use { inStream ->
                FileOutputStream(targetFile).use { outStream ->
                    inStream.copyTo(outStream)
                }
            }

            MediaScannerConnection.scanFile(context, arrayOf(targetFile.absolutePath), arrayOf("video/mp4"), null)

            return mapOf(
                "success" to true,
                "uri" to Uri.fromFile(targetFile).toString(),
                "path" to targetFile.absolutePath,
                "fileName" to fileName
            )
        }
    }

    private fun saveImage(sourceFile: File, title: String, album: String): Map<String, Any> {
        val sanitized = title.replace(Regex("[^a-zA-Z0-9_-]"), "_")
        val fileName = "${sanitized}_${System.currentTimeMillis()}.png"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.TITLE, title)
                put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/$album")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }

            val collection = MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val uri = contentResolver.insert(collection, values)
                ?: throw IllegalStateException("Unable to insert image into MediaStore")

            contentResolver.openOutputStream(uri)?.use { outStream ->
                FileInputStream(sourceFile).use { inStream ->
                    inStream.copyTo(outStream)
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
                "fileName" to fileName
            )
        } else {
            val picturesDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), album)
            if (!picturesDir.exists()) picturesDir.mkdirs()
            val targetFile = File(picturesDir, fileName)

            FileInputStream(sourceFile).use { inStream ->
                FileOutputStream(targetFile).use { outStream ->
                    inStream.copyTo(outStream)
                }
            }

            MediaScannerConnection.scanFile(context, arrayOf(targetFile.absolutePath), arrayOf("image/png"), null)

            return mapOf(
                "success" to true,
                "uri" to Uri.fromFile(targetFile).toString(),
                "path" to targetFile.absolutePath,
                "fileName" to fileName
            )
        }
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
