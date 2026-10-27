package com.minddrop.app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.TimeZone

/**
 * Hosts the Flutter UI and exposes a small platform bridge on [CHANNEL]:
 *
 * - launch actions (share-to-app text, launcher shortcuts)
 * - saving / opening backup files through the Storage Access Framework
 * - sharing a backup file through the system share sheet
 * - device time zone and app version
 */
class MainActivity : FlutterActivity() {

    private var channel: MethodChannel? = null
    private var pendingAction: Map<String, Any?>? = null

    // Only one file picker can be open at a time.
    private var pendingFileResult: MethodChannel.Result? = null
    private var pendingFileContent: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        val launchedFromHistory =
            (intent?.flags ?: 0) and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0
        if (savedInstanceState == null && !launchedFromHistory) {
            pendingAction = parseAction(intent)
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        ch.setMethodCallHandler { call, result -> handleCall(call, result) }
        channel = ch
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val action = parseAction(intent) ?: return
        val ch = channel
        if (ch != null) {
            ch.invokeMethod("onAction", action)
        } else {
            pendingAction = action
        }
    }

    private fun handleCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "takeLaunchAction" -> {
                result.success(pendingAction)
                pendingAction = null
            }
            "getTimeZone" -> result.success(TimeZone.getDefault().id)
            "getAppVersion" -> result.success(appVersion())
            "saveFile" -> saveFile(
                call.argument<String>("name") ?: "minddrop-backup.json",
                call.argument<String>("content") ?: "",
                result,
            )
            "openFile" -> openFile(result)
            "shareFile" -> shareFile(
                call.argument<String>("name") ?: "minddrop-backup.json",
                call.argument<String>("content") ?: "",
                call.argument<String>("subject"),
                result,
            )
            else -> result.notImplemented()
        }
    }

    private fun parseAction(intent: Intent?): Map<String, Any?>? {
        if (intent == null) return null
        return when (intent.action) {
            Intent.ACTION_SEND -> {
                val text = intent.getStringExtra(Intent.EXTRA_TEXT)
                val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
                if (text.isNullOrBlank() && subject.isNullOrBlank()) {
                    null
                } else {
                    mapOf("type" to "share", "text" to (text ?: ""), "subject" to subject)
                }
            }
            ACTION_NEW_TASK -> mapOf("type" to "new_task")
            ACTION_SEARCH -> mapOf("type" to "search")
            else -> null
        }
    }

    private fun appVersion(): String {
        return try {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, 0).versionName ?: ""
        } catch (e: Exception) {
            ""
        }
    }

    private fun beginFileOperation(result: MethodChannel.Result): Boolean {
        if (pendingFileResult != null) {
            result.error("busy", "Another file operation is already in progress", null)
            return false
        }
        pendingFileResult = result
        return true
    }

    private fun saveFile(name: String, content: String, result: MethodChannel.Result) {
        if (!beginFileOperation(result)) return
        pendingFileContent = content
        val picker = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/json"
            putExtra(Intent.EXTRA_TITLE, name)
        }
        launchPicker(picker, REQUEST_SAVE)
    }

    private fun openFile(result: MethodChannel.Result) {
        if (!beginFileOperation(result)) return
        // Files received through messengers often lose their JSON mime type,
        // so accept anything and let the Dart side validate the content.
        val picker = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
        }
        launchPicker(picker, REQUEST_OPEN)
    }

    @Suppress("DEPRECATION")
    private fun launchPicker(picker: Intent, requestCode: Int) {
        try {
            startActivityForResult(picker, requestCode)
        } catch (e: Exception) {
            val result = pendingFileResult
            pendingFileResult = null
            pendingFileContent = null
            result?.error("no_picker", e.message, null)
        }
    }

    @Deprecated("Deprecated in Android SDK, still the simplest option for FlutterActivity")
    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_SAVE && requestCode != REQUEST_OPEN) return
        val result = pendingFileResult ?: return
        val content = pendingFileContent
        pendingFileResult = null
        pendingFileContent = null

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null) // cancelled by the user
            return
        }

        Thread {
            try {
                if (requestCode == REQUEST_SAVE) {
                    val out = contentResolver.openOutputStream(uri, "w")
                        ?: throw IOException("Cannot write to the selected location")
                    out.use { it.write((content ?: "").toByteArray(Charsets.UTF_8)) }
                    runOnUiThread { result.success(true) }
                } else {
                    val input = contentResolver.openInputStream(uri)
                        ?: throw IOException("Cannot read the selected file")
                    val text = input.use { it.readBytes().toString(Charsets.UTF_8) }
                    runOnUiThread { result.success(text) }
                }
            } catch (e: Exception) {
                runOnUiThread { result.error("io", e.message, null) }
            }
        }.start()
    }

    private fun shareFile(
        name: String,
        content: String,
        subject: String?,
        result: MethodChannel.Result,
    ) {
        try {
            val dir = File(cacheDir, "shared").apply { mkdirs() }
            val file = File(dir, name)
            file.writeText(content, Charsets.UTF_8)
            val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            val send = Intent(Intent.ACTION_SEND).apply {
                type = "application/json"
                putExtra(Intent.EXTRA_STREAM, uri)
                if (subject != null) putExtra(Intent.EXTRA_SUBJECT, subject)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(send, subject))
            result.success(true)
        } catch (e: Exception) {
            result.error("share", e.message, null)
        }
    }

    companion object {
        private const val CHANNEL = "minddrop/platform"
        private const val ACTION_NEW_TASK = "com.minddrop.app.action.NEW_TASK"
        private const val ACTION_SEARCH = "com.minddrop.app.action.SEARCH"
        private const val REQUEST_SAVE = 4101
        private const val REQUEST_OPEN = 4102
    }
}
