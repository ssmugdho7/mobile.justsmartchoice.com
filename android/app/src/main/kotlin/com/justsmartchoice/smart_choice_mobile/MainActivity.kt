package com.justsmartchoice.smart_choice_mobile

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.provider.MediaStore
import android.os.Handler
import android.os.Looper
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.justsmartchoice.mobile/documents").setMethodCallHandler { call, result ->
            when (call.method) {
                "saveDownload" -> {
                    val path = call.argument<String>("path")
                    val name = call.argument<String>("name")
                    val mime = call.argument<String>("mime")
                    if (path == null || name == null || mime == null) {
                        result.error("invalid", "Missing document information", null)
                        return@setMethodCallHandler
                    }
                    Thread {
                        var outputUri: Uri? = null
                        try {
                            val input = File(path).canonicalFile
                            require(input.path.startsWith(cacheDir.canonicalPath + File.separator))
                            require(input.isFile && input.length() in 1..104857600)
                            require(name.matches(Regex("[a-zA-Z0-9._ -]{1,120}")) && name != "." && name != "..")
                            require(mime.matches(Regex("[a-zA-Z0-9.+-]+/[a-zA-Z0-9.+-]+")))
                            val values = ContentValues().apply {
                                put(MediaStore.Downloads.DISPLAY_NAME, name)
                                put(MediaStore.Downloads.MIME_TYPE, mime)
                                put(MediaStore.Downloads.RELATIVE_PATH, "Download/SmartChoice")
                                put(MediaStore.Downloads.IS_PENDING, 1)
                            }
                            outputUri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                                ?: error("Unable to create download")
                            contentResolver.openOutputStream(outputUri)?.use { output ->
                                input.inputStream().use { it.copyTo(output) }
                            } ?: error("Unable to write download")
                            values.clear()
                            values.put(MediaStore.Downloads.IS_PENDING, 0)
                            contentResolver.update(outputUri, values, null, null)
                            val saved = outputUri.toString()
                            Handler(Looper.getMainLooper()).post { result.success(saved) }
                        } catch (_: Exception) {
                            outputUri?.let { runCatching { contentResolver.delete(it, null, null) } }
                            Handler(Looper.getMainLooper()).post { result.error("save_failed", "Unable to save document", null) }
                        }
                    }.start()
                }
                "openDownload" -> {
                    try {
                        val uri = Uri.parse(call.argument<String>("uri"))
                        require(uri.scheme == "content" && uri.authority == "media" && uri.path?.contains("/downloads/") == true)
                        startActivity(Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, call.argument<String>("mime"))
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        })
                        result.success(null)
                    } catch (_: Exception) { result.error("open_failed", "No document viewer available", null) }
                }
                else -> result.notImplemented()
            }
        }
    }
}
