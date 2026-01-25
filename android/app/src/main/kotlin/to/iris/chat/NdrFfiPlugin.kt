package to.iris.chat

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong

// UniFFI Import - Uncomment after running build-android.sh:
// import uniffi.ndr_ffi.*

/**
 * Flutter plugin for ndr-ffi bindings.
 *
 * This plugin bridges Flutter's platform channels to the UniFFI-generated
 * Kotlin bindings for the Rust ndr-ffi library.
 *
 * Integration steps:
 * 1. Build ndr-ffi: cd /path/to/nostr-double-ratchet && ./scripts/mobile/build-android.sh --release
 * 2. Copy jniLibs to android/app/src/main/jniLibs/
 * 3. Copy ndr_ffi.kt to android/app/src/main/kotlin/to/iris/chat/
 * 4. Uncomment the UniFFI import above and the implementations below
 */
class NdrFfiPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel

    // Handle storage with type-erased containers
    // These will hold InviteHandle and SessionHandle instances once UniFFI is integrated
    private val inviteHandles = ConcurrentHashMap<String, Any>()
    private val sessionHandles = ConcurrentHashMap<String, Any>()
    private val nextHandleId = AtomicLong(1)

    private fun generateHandleId(): String = nextHandleId.getAndIncrement().toString()

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
        } catch (e: IllegalArgumentException) {
            result.error("InvalidArguments", e.message, null)
        } catch (e: Exception) {
            result.error("NdrError", e.message, e.stackTraceToString())
        }
    }

    // MARK: - Version

    private fun handleVersion(result: Result) {
        // Uncomment when UniFFI bindings are integrated:
        // result.success(version())
        result.success("0.0.39")
    }

    // MARK: - Keypair

    private fun handleGenerateKeypair(result: Result) {
        // Uncomment when UniFFI bindings are integrated:
        // val keypair = generateKeypair()
        // result.success(mapOf(
        //     "publicKeyHex" to keypair.publicKeyHex,
        //     "privateKeyHex" to keypair.privateKeyHex
        // ))
        result.error("NotImplemented", "Build ndr-ffi and integrate UniFFI bindings", null)
    }

    // MARK: - Invite Creation

    private fun handleCreateInvite(call: MethodCall, result: Result) {
        val inviterPubkeyHex = call.argument<String>("inviterPubkeyHex")
            ?: throw IllegalArgumentException("Missing inviterPubkeyHex")
        val deviceId = call.argument<String>("deviceId")
        val maxUses = call.argument<Int>("maxUses")?.toUInt()

        // Uncomment when UniFFI bindings are integrated:
        // try {
        //     val invite = InviteHandle.createNew(inviterPubkeyHex, deviceId, maxUses)
        //     val id = generateHandleId()
        //     inviteHandles[id] = invite
        //     result.success(mapOf("id" to id))
        // } catch (e: NdrError) {
        //     result.error("NdrError", e.message, null)
        // }
        result.error("NotImplemented", "Build ndr-ffi and integrate UniFFI bindings", null)
    }

    private fun handleInviteFromUrl(call: MethodCall, result: Result) {
        val url = call.argument<String>("url")
            ?: throw IllegalArgumentException("Missing url")

        // Uncomment when UniFFI bindings are integrated:
        // try {
        //     val invite = InviteHandle.fromUrl(url)
        //     val id = generateHandleId()
        //     inviteHandles[id] = invite
        //     result.success(mapOf("id" to id))
        // } catch (e: NdrError) {
        //     result.error("NdrError", e.message, null)
        // }
        result.error("NotImplemented", "Build ndr-ffi and integrate UniFFI bindings", null)
    }

    private fun handleInviteFromEventJson(call: MethodCall, result: Result) {
        val eventJson = call.argument<String>("eventJson")
            ?: throw IllegalArgumentException("Missing eventJson")

        // Uncomment when UniFFI bindings are integrated:
        // try {
        //     val invite = InviteHandle.fromEventJson(eventJson)
        //     val id = generateHandleId()
        //     inviteHandles[id] = invite
        //     result.success(mapOf("id" to id))
        // } catch (e: NdrError) {
        //     result.error("NdrError", e.message, null)
        // }
        result.error("NotImplemented", "Build ndr-ffi and integrate UniFFI bindings", null)
    }

    private fun handleInviteDeserialize(call: MethodCall, result: Result) {
        val json = call.argument<String>("json")
            ?: throw IllegalArgumentException("Missing json")

        // Uncomment when UniFFI bindings are integrated:
        // try {
        //     val invite = InviteHandle.deserialize(json)
        //     val id = generateHandleId()
        //     inviteHandles[id] = invite
        //     result.success(mapOf("id" to id))
        // } catch (e: NdrError) {
        //     result.error("NdrError", e.message, null)
        // }
        result.error("NotImplemented", "Build ndr-ffi and integrate UniFFI bindings", null)
    }

    // MARK: - Invite Methods

    private fun handleInviteToUrl(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("Missing id")
        val root = call.argument<String>("root")
            ?: throw IllegalArgumentException("Missing root")

        // Uncomment when UniFFI bindings are integrated:
        // val invite = inviteHandles[id] as? InviteHandle
        //     ?: throw IllegalArgumentException("Invite handle not found: $id")
        // try {
        //     val url = invite.toUrl(root)
        //     result.success(url)
        // } catch (e: NdrError) {
        //     result.error("NdrError", e.message, null)
        // }
        result.error("NotImplemented", "Build ndr-ffi and integrate UniFFI bindings", null)
    }

    private fun handleInviteToEventJson(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("Missing id")

        // Uncomment when UniFFI bindings are integrated:
        // val invite = inviteHandles[id] as? InviteHandle
        //     ?: throw IllegalArgumentException("Invite handle not found: $id")
        // try {
        //     val eventJson = invite.toEventJson()
        //     result.success(eventJson)
        // } catch (e: NdrError) {
        //     result.error("NdrError", e.message, null)
        // }
        result.error("NotImplemented", "Build ndr-ffi and integrate UniFFI bindings", null)
    }

    private fun handleInviteSerialize(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("Missing id")

        // Uncomment when UniFFI bindings are integrated:
        // val invite = inviteHandles[id] as? InviteHandle
        //     ?: throw IllegalArgumentException("Invite handle not found: $id")
        // try {
        //     val json = invite.serialize()
        //     result.success(json)
        // } catch (e: NdrError) {
        //     result.error("NdrError", e.message, null)
        // }
        result.error("NotImplemented", "Build ndr-ffi and integrate UniFFI bindings", null)
    }

    private fun handleInviteAccept(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("Missing id")
        val inviteePubkeyHex = call.argument<String>("inviteePubkeyHex")
            ?: throw IllegalArgumentException("Missing inviteePubkeyHex")
        val inviteePrivkeyHex = call.argument<String>("inviteePrivkeyHex")
            ?: throw IllegalArgumentException("Missing inviteePrivkeyHex")
        val deviceId = call.argument<String>("deviceId")

        // Uncomment when UniFFI bindings are integrated:
        // val invite = inviteHandles[id] as? InviteHandle
        //     ?: throw IllegalArgumentException("Invite handle not found: $id")
        // try {
        //     val acceptResult = invite.accept(inviteePubkeyHex, inviteePrivkeyHex, deviceId)
        //     val sessionId = generateHandleId()
        //     sessionHandles[sessionId] = acceptResult.session
        //     result.success(mapOf(
        //         "session" to mapOf("id" to sessionId),
        //         "responseEventJson" to acceptResult.responseEventJson
        //     ))
        // } catch (e: NdrError) {
        //     result.error("NdrError", e.message, null)
        // }
        result.error("NotImplemented", "Build ndr-ffi and integrate UniFFI bindings", null)
    }

    private fun handleInviteGetInviterPubkeyHex(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("Missing id")

        // Uncomment when UniFFI bindings are integrated:
        // val invite = inviteHandles[id] as? InviteHandle
        //     ?: throw IllegalArgumentException("Invite handle not found: $id")
        // result.success(invite.getInviterPubkeyHex())
        result.error("NotImplemented", "Build ndr-ffi and integrate UniFFI bindings", null)
    }

    private fun handleInviteGetSharedSecretHex(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("Missing id")

        // Uncomment when UniFFI bindings are integrated:
        // val invite = inviteHandles[id] as? InviteHandle
        //     ?: throw IllegalArgumentException("Invite handle not found: $id")
        // result.success(invite.getSharedSecretHex())
        result.error("NotImplemented", "Build ndr-ffi and integrate UniFFI bindings", null)
    }

    private fun handleInviteDispose(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("Missing id")
        inviteHandles.remove(id)
        result.success(null)
    }

    // MARK: - Session Creation

    private fun handleSessionFromStateJson(call: MethodCall, result: Result) {
        val stateJson = call.argument<String>("stateJson")
            ?: throw IllegalArgumentException("Missing stateJson")

        // Uncomment when UniFFI bindings are integrated:
        // try {
        //     val session = SessionHandle.fromStateJson(stateJson)
        //     val id = generateHandleId()
        //     sessionHandles[id] = session
        //     result.success(mapOf("id" to id))
        // } catch (e: NdrError) {
        //     result.error("NdrError", e.message, null)
        // }
        result.error("NotImplemented", "Build ndr-ffi and integrate UniFFI bindings", null)
    }

    private fun handleSessionInit(call: MethodCall, result: Result) {
        val theirEphemeralPubkeyHex = call.argument<String>("theirEphemeralPubkeyHex")
            ?: throw IllegalArgumentException("Missing theirEphemeralPubkeyHex")
        val ourEphemeralPrivkeyHex = call.argument<String>("ourEphemeralPrivkeyHex")
            ?: throw IllegalArgumentException("Missing ourEphemeralPrivkeyHex")
        val isInitiator = call.argument<Boolean>("isInitiator")
            ?: throw IllegalArgumentException("Missing isInitiator")
        val sharedSecretHex = call.argument<String>("sharedSecretHex")
            ?: throw IllegalArgumentException("Missing sharedSecretHex")
        val name = call.argument<String>("name")

        // Uncomment when UniFFI bindings are integrated:
        // try {
        //     val session = SessionHandle.init(
        //         theirEphemeralPubkeyHex,
        //         ourEphemeralPrivkeyHex,
        //         isInitiator,
        //         sharedSecretHex,
        //         name
        //     )
        //     val id = generateHandleId()
        //     sessionHandles[id] = session
        //     result.success(mapOf("id" to id))
        // } catch (e: NdrError) {
        //     result.error("NdrError", e.message, null)
        // }
        result.error("NotImplemented", "Build ndr-ffi and integrate UniFFI bindings", null)
    }

    // MARK: - Session Methods

    private fun handleSessionCanSend(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("Missing id")

        // Uncomment when UniFFI bindings are integrated:
        // val session = sessionHandles[id] as? SessionHandle
        //     ?: throw IllegalArgumentException("Session handle not found: $id")
        // result.success(session.canSend())
        result.error("NotImplemented", "Build ndr-ffi and integrate UniFFI bindings", null)
    }

    private fun handleSessionSendText(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("Missing id")
        val text = call.argument<String>("text")
            ?: throw IllegalArgumentException("Missing text")

        // Uncomment when UniFFI bindings are integrated:
        // val session = sessionHandles[id] as? SessionHandle
        //     ?: throw IllegalArgumentException("Session handle not found: $id")
        // try {
        //     val sendResult = session.sendText(text)
        //     result.success(mapOf(
        //         "outerEventJson" to sendResult.outerEventJson,
        //         "innerEventJson" to sendResult.innerEventJson
        //     ))
        // } catch (e: NdrError) {
        //     result.error("NdrError", e.message, null)
        // }
        result.error("NotImplemented", "Build ndr-ffi and integrate UniFFI bindings", null)
    }

    private fun handleSessionDecryptEvent(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("Missing id")
        val outerEventJson = call.argument<String>("outerEventJson")
            ?: throw IllegalArgumentException("Missing outerEventJson")

        // Uncomment when UniFFI bindings are integrated:
        // val session = sessionHandles[id] as? SessionHandle
        //     ?: throw IllegalArgumentException("Session handle not found: $id")
        // try {
        //     val decryptResult = session.decryptEvent(outerEventJson)
        //     result.success(mapOf(
        //         "plaintext" to decryptResult.plaintext,
        //         "innerEventJson" to decryptResult.innerEventJson
        //     ))
        // } catch (e: NdrError) {
        //     result.error("NdrError", e.message, null)
        // }
        result.error("NotImplemented", "Build ndr-ffi and integrate UniFFI bindings", null)
    }

    private fun handleSessionStateJson(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("Missing id")

        // Uncomment when UniFFI bindings are integrated:
        // val session = sessionHandles[id] as? SessionHandle
        //     ?: throw IllegalArgumentException("Session handle not found: $id")
        // try {
        //     val stateJson = session.stateJson()
        //     result.success(stateJson)
        // } catch (e: NdrError) {
        //     result.error("NdrError", e.message, null)
        // }
        result.error("NotImplemented", "Build ndr-ffi and integrate UniFFI bindings", null)
    }

    private fun handleSessionIsDrMessage(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("Missing id")
        val eventJson = call.argument<String>("eventJson")
            ?: throw IllegalArgumentException("Missing eventJson")

        // Uncomment when UniFFI bindings are integrated:
        // val session = sessionHandles[id] as? SessionHandle
        //     ?: throw IllegalArgumentException("Session handle not found: $id")
        // result.success(session.isDrMessage(eventJson))
        result.error("NotImplemented", "Build ndr-ffi and integrate UniFFI bindings", null)
    }

    private fun handleSessionDispose(call: MethodCall, result: Result) {
        val id = call.argument<String>("id")
            ?: throw IllegalArgumentException("Missing id")
        sessionHandles.remove(id)
        result.success(null)
    }
}
