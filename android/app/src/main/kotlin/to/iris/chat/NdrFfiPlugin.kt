package to.iris.chat

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

// Import UniFFI-generated bindings (will be generated from ndr-ffi)
// import uniffi.ndr_ffi.*

/**
 * Flutter plugin for ndr-ffi bindings.
 *
 * This plugin bridges Flutter's platform channels to the UniFFI-generated
 * Kotlin bindings for the Rust ndr-ffi library.
 */
class NdrFfiPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel

    // Store native handles with generated IDs
    private val inviteHandles = ConcurrentHashMap<String, Any>() // InviteHandle
    private val sessionHandles = ConcurrentHashMap<String, Any>() // SessionHandle

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "to.iris.chat/ndr_ffi")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        // Clean up all handles
        inviteHandles.clear()
        sessionHandles.clear()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "version" -> handleVersion(result)
                "generateKeypair" -> handleGenerateKeypair(result)
                "createInvite" -> handleCreateInvite(call, result)
                "inviteFromUrl" -> handleInviteFromUrl(call, result)
                "inviteFromEventJson" -> handleInviteFromEventJson(call, result)
                "inviteDeserialize" -> handleInviteDeserialize(call, result)
                "inviteToUrl" -> handleInviteToUrl(call, result)
                "inviteToEventJson" -> handleInviteToEventJson(call, result)
                "inviteSerialize" -> handleInviteSerialize(call, result)
                "inviteAccept" -> handleInviteAccept(call, result)
                "inviteGetInviterPubkeyHex" -> handleInviteGetInviterPubkeyHex(call, result)
                "inviteGetSharedSecretHex" -> handleInviteGetSharedSecretHex(call, result)
                "inviteDispose" -> handleInviteDispose(call, result)
                "sessionFromStateJson" -> handleSessionFromStateJson(call, result)
                "sessionInit" -> handleSessionInit(call, result)
                "sessionCanSend" -> handleSessionCanSend(call, result)
                "sessionSendText" -> handleSessionSendText(call, result)
                "sessionDecryptEvent" -> handleSessionDecryptEvent(call, result)
                "sessionStateJson" -> handleSessionStateJson(call, result)
                "sessionIsDrMessage" -> handleSessionIsDrMessage(call, result)
                "sessionDispose" -> handleSessionDispose(call, result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("NdrError", e.message, e.stackTraceToString())
        }
    }

    private fun handleVersion(result: Result) {
        // TODO: Replace with actual call when UniFFI bindings available
        // result.success(version())
        result.success("0.0.39")
    }

    private fun handleGenerateKeypair(result: Result) {
        // TODO: Replace with actual call when UniFFI bindings available
        // val keypair = generateKeypair()
        // result.success(mapOf(
        //     "publicKeyHex" to keypair.publicKeyHex,
        //     "privateKeyHex" to keypair.privateKeyHex
        // ))
        result.error("NotImplemented", "UniFFI bindings not yet integrated", null)
    }

    private fun handleCreateInvite(call: MethodCall, result: Result) {
        val inviterPubkeyHex = call.argument<String>("inviterPubkeyHex")!!
        val deviceId = call.argument<String>("deviceId")
        val maxUses = call.argument<Int>("maxUses")?.toUInt()

        // TODO: Replace with actual call when UniFFI bindings available
        // val invite = InviteHandle.createNew(inviterPubkeyHex, deviceId, maxUses)
        // val id = UUID.randomUUID().toString()
        // inviteHandles[id] = invite
        // result.success(mapOf("id" to id))
        result.error("NotImplemented", "UniFFI bindings not yet integrated", null)
    }

    private fun handleInviteFromUrl(call: MethodCall, result: Result) {
        val url = call.argument<String>("url")!!
        // TODO: Implement
        result.error("NotImplemented", "UniFFI bindings not yet integrated", null)
    }

    private fun handleInviteFromEventJson(call: MethodCall, result: Result) {
        val eventJson = call.argument<String>("eventJson")!!
        // TODO: Implement
        result.error("NotImplemented", "UniFFI bindings not yet integrated", null)
    }

    private fun handleInviteDeserialize(call: MethodCall, result: Result) {
        val json = call.argument<String>("json")!!
        // TODO: Implement
        result.error("NotImplemented", "UniFFI bindings not yet integrated", null)
    }

    private fun handleInviteToUrl(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")!!
        val root = call.argument<String>("root")!!
        // TODO: Implement
        result.error("NotImplemented", "UniFFI bindings not yet integrated", null)
    }

    private fun handleInviteToEventJson(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")!!
        // TODO: Implement
        result.error("NotImplemented", "UniFFI bindings not yet integrated", null)
    }

    private fun handleInviteSerialize(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")!!
        // TODO: Implement
        result.error("NotImplemented", "UniFFI bindings not yet integrated", null)
    }

    private fun handleInviteAccept(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")!!
        val inviteePubkeyHex = call.argument<String>("inviteePubkeyHex")!!
        val inviteePrivkeyHex = call.argument<String>("inviteePrivkeyHex")!!
        val deviceId = call.argument<String>("deviceId")
        // TODO: Implement
        result.error("NotImplemented", "UniFFI bindings not yet integrated", null)
    }

    private fun handleInviteGetInviterPubkeyHex(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")!!
        // TODO: Implement
        result.error("NotImplemented", "UniFFI bindings not yet integrated", null)
    }

    private fun handleInviteGetSharedSecretHex(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")!!
        // TODO: Implement
        result.error("NotImplemented", "UniFFI bindings not yet integrated", null)
    }

    private fun handleInviteDispose(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")!!
        inviteHandles.remove(id)
        result.success(null)
    }

    private fun handleSessionFromStateJson(call: MethodCall, result: Result) {
        val stateJson = call.argument<String>("stateJson")!!
        // TODO: Implement
        result.error("NotImplemented", "UniFFI bindings not yet integrated", null)
    }

    private fun handleSessionInit(call: MethodCall, result: Result) {
        val theirEphemeralPubkeyHex = call.argument<String>("theirEphemeralPubkeyHex")!!
        val ourEphemeralPrivkeyHex = call.argument<String>("ourEphemeralPrivkeyHex")!!
        val isInitiator = call.argument<Boolean>("isInitiator")!!
        val sharedSecretHex = call.argument<String>("sharedSecretHex")!!
        val name = call.argument<String>("name")
        // TODO: Implement
        result.error("NotImplemented", "UniFFI bindings not yet integrated", null)
    }

    private fun handleSessionCanSend(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")!!
        // TODO: Implement
        result.error("NotImplemented", "UniFFI bindings not yet integrated", null)
    }

    private fun handleSessionSendText(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")!!
        val text = call.argument<String>("text")!!
        // TODO: Implement
        result.error("NotImplemented", "UniFFI bindings not yet integrated", null)
    }

    private fun handleSessionDecryptEvent(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")!!
        val outerEventJson = call.argument<String>("outerEventJson")!!
        // TODO: Implement
        result.error("NotImplemented", "UniFFI bindings not yet integrated", null)
    }

    private fun handleSessionStateJson(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")!!
        // TODO: Implement
        result.error("NotImplemented", "UniFFI bindings not yet integrated", null)
    }

    private fun handleSessionIsDrMessage(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")!!
        val eventJson = call.argument<String>("eventJson")!!
        // TODO: Implement
        result.error("NotImplemented", "UniFFI bindings not yet integrated", null)
    }

    private fun handleSessionDispose(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")!!
        sessionHandles.remove(id)
        result.success(null)
    }
}
