import Flutter
import UIKit

// MARK: - UniFFI Import
// After running build-ios.sh, uncomment and import the generated bindings:
// import NdrFfi

/// Flutter plugin for ndr-ffi bindings.
///
/// This plugin bridges Flutter's platform channels to the UniFFI-generated
/// Swift bindings for the Rust ndr-ffi library.
///
/// Integration steps:
/// 1. Build ndr-ffi: cd /path/to/nostr-double-ratchet && ./scripts/mobile/build-ios.sh --release
/// 2. Add NdrFfi.xcframework to the Xcode project
/// 3. Add the generated Swift binding files (ndr_ffi.swift) to Runner
/// 4. Uncomment the UniFFI import above and the implementations below
public class NdrFfiPlugin: NSObject, FlutterPlugin {
    // Handle storage with type-erased containers
    // These will hold InviteHandle and SessionHandle instances once UniFFI is integrated
    private var inviteHandles: [String: Any] = [:]
    private var sessionHandles: [String: Any] = [:]
    private var nextHandleId: UInt64 = 1

    private func generateHandleId() -> String {
        let id = nextHandleId
        nextHandleId += 1
        return String(id)
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "to.iris.chat/ndr_ffi",
            binaryMessenger: registrar.messenger()
        )
        let instance = NdrFfiPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            switch call.method {
            case "version":
                handleVersion(result: result)
            case "generateKeypair":
                handleGenerateKeypair(result: result)
            case "createInvite":
                try handleCreateInvite(call: call, result: result)
            case "inviteFromUrl":
                try handleInviteFromUrl(call: call, result: result)
            case "inviteFromEventJson":
                try handleInviteFromEventJson(call: call, result: result)
            case "inviteDeserialize":
                try handleInviteDeserialize(call: call, result: result)
            case "inviteToUrl":
                try handleInviteToUrl(call: call, result: result)
            case "inviteToEventJson":
                try handleInviteToEventJson(call: call, result: result)
            case "inviteSerialize":
                try handleInviteSerialize(call: call, result: result)
            case "inviteAccept":
                try handleInviteAccept(call: call, result: result)
            case "inviteGetInviterPubkeyHex":
                try handleInviteGetInviterPubkeyHex(call: call, result: result)
            case "inviteGetSharedSecretHex":
                try handleInviteGetSharedSecretHex(call: call, result: result)
            case "inviteDispose":
                try handleInviteDispose(call: call, result: result)
            case "sessionFromStateJson":
                try handleSessionFromStateJson(call: call, result: result)
            case "sessionInit":
                try handleSessionInit(call: call, result: result)
            case "sessionCanSend":
                try handleSessionCanSend(call: call, result: result)
            case "sessionSendText":
                try handleSessionSendText(call: call, result: result)
            case "sessionDecryptEvent":
                try handleSessionDecryptEvent(call: call, result: result)
            case "sessionStateJson":
                try handleSessionStateJson(call: call, result: result)
            case "sessionIsDrMessage":
                try handleSessionIsDrMessage(call: call, result: result)
            case "sessionDispose":
                try handleSessionDispose(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        } catch let error as NdrPluginError {
            result(FlutterError(code: error.code, message: error.message, details: nil))
        } catch {
            result(FlutterError(code: "NdrError", message: error.localizedDescription, details: nil))
        }
    }

    // MARK: - Version

    private func handleVersion(result: FlutterResult) {
        // Uncomment when UniFFI bindings are integrated:
        // result(version())
        result("0.0.39")
    }

    // MARK: - Keypair

    private func handleGenerateKeypair(result: FlutterResult) {
        // Uncomment when UniFFI bindings are integrated:
        // let keypair = generateKeypair()
        // result([
        //     "publicKeyHex": keypair.publicKeyHex,
        //     "privateKeyHex": keypair.privateKeyHex
        // ])
        result(FlutterError(code: "NotImplemented", message: "Build ndr-ffi and integrate UniFFI bindings", details: nil))
    }

    // MARK: - Invite Creation

    private func handleCreateInvite(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let inviterPubkeyHex = args["inviterPubkeyHex"] as? String else {
            throw NdrPluginError.invalidArguments("Missing inviterPubkeyHex")
        }
        let deviceId = args["deviceId"] as? String
        let maxUses = args["maxUses"] as? UInt32

        // Uncomment when UniFFI bindings are integrated:
        // do {
        //     let invite = try InviteHandle.createNew(
        //         inviterPubkeyHex: inviterPubkeyHex,
        //         deviceId: deviceId,
        //         maxUses: maxUses
        //     )
        //     let id = generateHandleId()
        //     inviteHandles[id] = invite
        //     result(["id": id])
        // } catch {
        //     throw NdrPluginError.ndrError(error.localizedDescription)
        // }
        result(FlutterError(code: "NotImplemented", message: "Build ndr-ffi and integrate UniFFI bindings", details: nil))
    }

    private func handleInviteFromUrl(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let url = args["url"] as? String else {
            throw NdrPluginError.invalidArguments("Missing url")
        }

        // Uncomment when UniFFI bindings are integrated:
        // do {
        //     let invite = try InviteHandle.fromUrl(url: url)
        //     let id = generateHandleId()
        //     inviteHandles[id] = invite
        //     result(["id": id])
        // } catch {
        //     throw NdrPluginError.ndrError(error.localizedDescription)
        // }
        result(FlutterError(code: "NotImplemented", message: "Build ndr-ffi and integrate UniFFI bindings", details: nil))
    }

    private func handleInviteFromEventJson(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let eventJson = args["eventJson"] as? String else {
            throw NdrPluginError.invalidArguments("Missing eventJson")
        }

        // Uncomment when UniFFI bindings are integrated:
        // do {
        //     let invite = try InviteHandle.fromEventJson(eventJson: eventJson)
        //     let id = generateHandleId()
        //     inviteHandles[id] = invite
        //     result(["id": id])
        // } catch {
        //     throw NdrPluginError.ndrError(error.localizedDescription)
        // }
        result(FlutterError(code: "NotImplemented", message: "Build ndr-ffi and integrate UniFFI bindings", details: nil))
    }

    private func handleInviteDeserialize(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let json = args["json"] as? String else {
            throw NdrPluginError.invalidArguments("Missing json")
        }

        // Uncomment when UniFFI bindings are integrated:
        // do {
        //     let invite = try InviteHandle.deserialize(json: json)
        //     let id = generateHandleId()
        //     inviteHandles[id] = invite
        //     result(["id": id])
        // } catch {
        //     throw NdrPluginError.ndrError(error.localizedDescription)
        // }
        result(FlutterError(code: "NotImplemented", message: "Build ndr-ffi and integrate UniFFI bindings", details: nil))
    }

    // MARK: - Invite Methods

    private func handleInviteToUrl(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String,
              let root = args["root"] as? String else {
            throw NdrPluginError.invalidArguments("Missing id or root")
        }

        // Uncomment when UniFFI bindings are integrated:
        // guard let invite = inviteHandles[id] as? InviteHandle else {
        //     throw NdrPluginError.handleNotFound("Invite handle not found: \(id)")
        // }
        // do {
        //     let url = try invite.toUrl(root: root)
        //     result(url)
        // } catch {
        //     throw NdrPluginError.ndrError(error.localizedDescription)
        // }
        result(FlutterError(code: "NotImplemented", message: "Build ndr-ffi and integrate UniFFI bindings", details: nil))
    }

    private func handleInviteToEventJson(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
            throw NdrPluginError.invalidArguments("Missing id")
        }

        // Uncomment when UniFFI bindings are integrated:
        // guard let invite = inviteHandles[id] as? InviteHandle else {
        //     throw NdrPluginError.handleNotFound("Invite handle not found: \(id)")
        // }
        // do {
        //     let eventJson = try invite.toEventJson()
        //     result(eventJson)
        // } catch {
        //     throw NdrPluginError.ndrError(error.localizedDescription)
        // }
        result(FlutterError(code: "NotImplemented", message: "Build ndr-ffi and integrate UniFFI bindings", details: nil))
    }

    private func handleInviteSerialize(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
            throw NdrPluginError.invalidArguments("Missing id")
        }

        // Uncomment when UniFFI bindings are integrated:
        // guard let invite = inviteHandles[id] as? InviteHandle else {
        //     throw NdrPluginError.handleNotFound("Invite handle not found: \(id)")
        // }
        // do {
        //     let json = try invite.serialize()
        //     result(json)
        // } catch {
        //     throw NdrPluginError.ndrError(error.localizedDescription)
        // }
        result(FlutterError(code: "NotImplemented", message: "Build ndr-ffi and integrate UniFFI bindings", details: nil))
    }

    private func handleInviteAccept(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String,
              let inviteePubkeyHex = args["inviteePubkeyHex"] as? String,
              let inviteePrivkeyHex = args["inviteePrivkeyHex"] as? String else {
            throw NdrPluginError.invalidArguments("Missing required arguments")
        }
        let deviceId = args["deviceId"] as? String

        // Uncomment when UniFFI bindings are integrated:
        // guard let invite = inviteHandles[id] as? InviteHandle else {
        //     throw NdrPluginError.handleNotFound("Invite handle not found: \(id)")
        // }
        // do {
        //     let acceptResult = try invite.accept(
        //         inviteePubkeyHex: inviteePubkeyHex,
        //         inviteePrivkeyHex: inviteePrivkeyHex,
        //         deviceId: deviceId
        //     )
        //     let sessionId = generateHandleId()
        //     sessionHandles[sessionId] = acceptResult.session
        //     result([
        //         "session": ["id": sessionId],
        //         "responseEventJson": acceptResult.responseEventJson
        //     ])
        // } catch {
        //     throw NdrPluginError.ndrError(error.localizedDescription)
        // }
        result(FlutterError(code: "NotImplemented", message: "Build ndr-ffi and integrate UniFFI bindings", details: nil))
    }

    private func handleInviteGetInviterPubkeyHex(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
            throw NdrPluginError.invalidArguments("Missing id")
        }

        // Uncomment when UniFFI bindings are integrated:
        // guard let invite = inviteHandles[id] as? InviteHandle else {
        //     throw NdrPluginError.handleNotFound("Invite handle not found: \(id)")
        // }
        // result(invite.getInviterPubkeyHex())
        result(FlutterError(code: "NotImplemented", message: "Build ndr-ffi and integrate UniFFI bindings", details: nil))
    }

    private func handleInviteGetSharedSecretHex(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
            throw NdrPluginError.invalidArguments("Missing id")
        }

        // Uncomment when UniFFI bindings are integrated:
        // guard let invite = inviteHandles[id] as? InviteHandle else {
        //     throw NdrPluginError.handleNotFound("Invite handle not found: \(id)")
        // }
        // result(invite.getSharedSecretHex())
        result(FlutterError(code: "NotImplemented", message: "Build ndr-ffi and integrate UniFFI bindings", details: nil))
    }

    private func handleInviteDispose(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
            throw NdrPluginError.invalidArguments("Missing id")
        }
        inviteHandles.removeValue(forKey: id)
        result(nil)
    }

    // MARK: - Session Creation

    private func handleSessionFromStateJson(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let stateJson = args["stateJson"] as? String else {
            throw NdrPluginError.invalidArguments("Missing stateJson")
        }

        // Uncomment when UniFFI bindings are integrated:
        // do {
        //     let session = try SessionHandle.fromStateJson(stateJson: stateJson)
        //     let id = generateHandleId()
        //     sessionHandles[id] = session
        //     result(["id": id])
        // } catch {
        //     throw NdrPluginError.ndrError(error.localizedDescription)
        // }
        result(FlutterError(code: "NotImplemented", message: "Build ndr-ffi and integrate UniFFI bindings", details: nil))
    }

    private func handleSessionInit(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let theirEphemeralPubkeyHex = args["theirEphemeralPubkeyHex"] as? String,
              let ourEphemeralPrivkeyHex = args["ourEphemeralPrivkeyHex"] as? String,
              let isInitiator = args["isInitiator"] as? Bool,
              let sharedSecretHex = args["sharedSecretHex"] as? String else {
            throw NdrPluginError.invalidArguments("Missing required arguments")
        }
        let name = args["name"] as? String

        // Uncomment when UniFFI bindings are integrated:
        // do {
        //     let session = try SessionHandle.init(
        //         theirEphemeralPubkeyHex: theirEphemeralPubkeyHex,
        //         ourEphemeralPrivkeyHex: ourEphemeralPrivkeyHex,
        //         isInitiator: isInitiator,
        //         sharedSecretHex: sharedSecretHex,
        //         name: name
        //     )
        //     let id = generateHandleId()
        //     sessionHandles[id] = session
        //     result(["id": id])
        // } catch {
        //     throw NdrPluginError.ndrError(error.localizedDescription)
        // }
        result(FlutterError(code: "NotImplemented", message: "Build ndr-ffi and integrate UniFFI bindings", details: nil))
    }

    // MARK: - Session Methods

    private func handleSessionCanSend(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
            throw NdrPluginError.invalidArguments("Missing id")
        }

        // Uncomment when UniFFI bindings are integrated:
        // guard let session = sessionHandles[id] as? SessionHandle else {
        //     throw NdrPluginError.handleNotFound("Session handle not found: \(id)")
        // }
        // result(session.canSend())
        result(FlutterError(code: "NotImplemented", message: "Build ndr-ffi and integrate UniFFI bindings", details: nil))
    }

    private func handleSessionSendText(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String,
              let text = args["text"] as? String else {
            throw NdrPluginError.invalidArguments("Missing id or text")
        }

        // Uncomment when UniFFI bindings are integrated:
        // guard let session = sessionHandles[id] as? SessionHandle else {
        //     throw NdrPluginError.handleNotFound("Session handle not found: \(id)")
        // }
        // do {
        //     let sendResult = try session.sendText(text: text)
        //     result([
        //         "outerEventJson": sendResult.outerEventJson,
        //         "innerEventJson": sendResult.innerEventJson
        //     ])
        // } catch {
        //     throw NdrPluginError.ndrError(error.localizedDescription)
        // }
        result(FlutterError(code: "NotImplemented", message: "Build ndr-ffi and integrate UniFFI bindings", details: nil))
    }

    private func handleSessionDecryptEvent(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String,
              let outerEventJson = args["outerEventJson"] as? String else {
            throw NdrPluginError.invalidArguments("Missing id or outerEventJson")
        }

        // Uncomment when UniFFI bindings are integrated:
        // guard let session = sessionHandles[id] as? SessionHandle else {
        //     throw NdrPluginError.handleNotFound("Session handle not found: \(id)")
        // }
        // do {
        //     let decryptResult = try session.decryptEvent(outerEventJson: outerEventJson)
        //     result([
        //         "plaintext": decryptResult.plaintext,
        //         "innerEventJson": decryptResult.innerEventJson
        //     ])
        // } catch {
        //     throw NdrPluginError.ndrError(error.localizedDescription)
        // }
        result(FlutterError(code: "NotImplemented", message: "Build ndr-ffi and integrate UniFFI bindings", details: nil))
    }

    private func handleSessionStateJson(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
            throw NdrPluginError.invalidArguments("Missing id")
        }

        // Uncomment when UniFFI bindings are integrated:
        // guard let session = sessionHandles[id] as? SessionHandle else {
        //     throw NdrPluginError.handleNotFound("Session handle not found: \(id)")
        // }
        // do {
        //     let stateJson = try session.stateJson()
        //     result(stateJson)
        // } catch {
        //     throw NdrPluginError.ndrError(error.localizedDescription)
        // }
        result(FlutterError(code: "NotImplemented", message: "Build ndr-ffi and integrate UniFFI bindings", details: nil))
    }

    private func handleSessionIsDrMessage(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String,
              let eventJson = args["eventJson"] as? String else {
            throw NdrPluginError.invalidArguments("Missing id or eventJson")
        }

        // Uncomment when UniFFI bindings are integrated:
        // guard let session = sessionHandles[id] as? SessionHandle else {
        //     throw NdrPluginError.handleNotFound("Session handle not found: \(id)")
        // }
        // result(session.isDrMessage(eventJson: eventJson))
        result(FlutterError(code: "NotImplemented", message: "Build ndr-ffi and integrate UniFFI bindings", details: nil))
    }

    private func handleSessionDispose(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
            throw NdrPluginError.invalidArguments("Missing id")
        }
        sessionHandles.removeValue(forKey: id)
        result(nil)
    }
}

// MARK: - Error Types

enum NdrPluginError: Error {
    case invalidArguments(String)
    case handleNotFound(String)
    case ndrError(String)

    var code: String {
        switch self {
        case .invalidArguments: return "InvalidArguments"
        case .handleNotFound: return "HandleNotFound"
        case .ndrError: return "NdrError"
        }
    }

    var message: String {
        switch self {
        case .invalidArguments(let msg): return msg
        case .handleNotFound(let msg): return msg
        case .ndrError(let msg): return msg
        }
    }
}
