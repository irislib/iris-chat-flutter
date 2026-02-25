package to.iris.chat

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import uniffi.hashtree_ffi.*

/**
 * Flutter plugin for hashtree attachment bindings.
 *
 * Uses a dedicated method channel so attachment APIs stay separate from ndr-ffi APIs.
 */
class HashtreePlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "to.iris.chat/hashtree")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "nhashFromFile" -> handleNhashFromFile(call, result)
                "uploadFile" -> handleUploadFile(call, result)
                "downloadBytes" -> handleDownloadBytes(call, result)
                "downloadToFile" -> handleDownloadToFile(call, result)
                else -> result.notImplemented()
            }
        } catch (e: IllegalArgumentException) {
            result.error("InvalidArguments", e.message, null)
        } catch (e: HashtreeException) {
            result.error("HashtreeError", e.message, null)
        } catch (e: Exception) {
            result.error("HashtreeError", e.message, e.stackTraceToString())
        }
    }

    private fun handleNhashFromFile(call: MethodCall, result: Result) {
        val filePath = call.argument<String>("filePath")
            ?: throw IllegalArgumentException("Missing filePath")

        result.success(hashtreeNhashFromFile(filePath))
    }

    private fun handleUploadFile(call: MethodCall, result: Result) {
        val privkeyHex = call.argument<String>("privkeyHex")
            ?: throw IllegalArgumentException("Missing privkeyHex")
        val filePath = call.argument<String>("filePath")
            ?: throw IllegalArgumentException("Missing filePath")
        val readServers = call.argument<List<String>>("readServers") ?: emptyList()
        val writeServers = call.argument<List<String>>("writeServers") ?: emptyList()

        result.success(
            hashtreeUploadFile(
                privkeyHex = privkeyHex,
                filePath = filePath,
                readServers = readServers,
                writeServers = writeServers,
            ),
        )
    }

    private fun handleDownloadBytes(call: MethodCall, result: Result) {
        val nhash = call.argument<String>("nhash")
            ?: throw IllegalArgumentException("Missing nhash")
        val readServers = call.argument<List<String>>("readServers") ?: emptyList()

        result.success(hashtreeDownloadBytes(nhash, readServers))
    }

    private fun handleDownloadToFile(call: MethodCall, result: Result) {
        val nhash = call.argument<String>("nhash")
            ?: throw IllegalArgumentException("Missing nhash")
        val outputPath = call.argument<String>("outputPath")
            ?: throw IllegalArgumentException("Missing outputPath")
        val readServers = call.argument<List<String>>("readServers") ?: emptyList()

        hashtreeDownloadToFile(nhash, outputPath, readServers)
        result.success(null)
    }
}
