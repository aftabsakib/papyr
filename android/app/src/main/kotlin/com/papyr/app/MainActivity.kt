package com.papyr.app

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Handles "Open with Papyr" / share-sheet intents natively: copies the incoming
 * PDF/EPUB (which may be a content:// URI) into the app cache and hands its path
 * to Flutter over a MethodChannel.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "papyr/intent"
    private var channel: MethodChannel? = null
    private var pendingPath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel!!.setMethodCallHandler { call, result ->
            if (call.method == "getInitialFile") {
                result.success(pendingPath)
                pendingPath = null
            } else {
                result.notImplemented()
            }
        }
        // The intent that launched the app (null path for a normal launch).
        pendingPath = extractPath(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val path = extractPath(intent) ?: return
        val ch = channel
        if (ch != null) {
            ch.invokeMethod("onFile", path)
        } else {
            pendingPath = path
        }
    }

    private fun extractPath(intent: Intent?): String? {
        if (intent == null) return null
        val uri: Uri? = when (intent.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> @Suppress("DEPRECATION")
            (intent.getParcelableExtra(Intent.EXTRA_STREAM) as? Uri)
            else -> null
        }
        return uri?.let { copyToCache(it, intent.type) }
    }

    private fun copyToCache(uri: Uri, mime: String?): String? {
        return try {
            val display = queryName(uri)
            val name = ensureExtension(
                display ?: "shared_${System.currentTimeMillis()}",
                mime,
            )
            val outFile = File(cacheDir, name)
            contentResolver.openInputStream(uri)?.use { input ->
                outFile.outputStream().use { output -> input.copyTo(output) }
            }
            outFile.absolutePath
        } catch (e: Exception) {
            null
        }
    }

    private fun ensureExtension(name: String, mime: String?): String {
        if (name.contains('.')) return name
        val ext = when (mime) {
            "application/epub+zip" -> ".epub"
            else -> ".pdf"
        }
        return name + ext
    }

    private fun queryName(uri: Uri): String? {
        if (uri.scheme == "file") return uri.path?.let { File(it).name }
        var name: String? = null
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (idx >= 0 && cursor.moveToFirst()) {
                name = cursor.getString(idx)
            }
        }
        return name
    }
}
