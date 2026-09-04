package com.edito.app

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
