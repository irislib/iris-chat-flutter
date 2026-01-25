import Flutter
import UIKit

// Import UniFFI-generated bindings (will be generated from ndr-ffi)
// import NdrFfi

/// Flutter plugin for ndr-ffi bindings.
///
/// This plugin bridges Flutter's platform channels to the UniFFI-generated
/// Swift bindings for the Rust ndr-ffi library.
public class NdrFfiPlugin: NSObject, FlutterPlugin {
    private var inviteHandles: [String: Any] = [:] // InviteHandle
    private var sessionHandles: [String: Any] = [:] // SessionHandle

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
        } catch {
            result(FlutterError(code: "NdrError", message: error.localizedDescription, details: nil))
        }
    }

    // MARK: - Version

    private func handleVersion(result: FlutterResult) {
        // TODO: Replace with actual call when UniFFI bindings available
        // result(version())
        result("0.0.39")
    }

    // MARK: - Keypair

    private func handleGenerateKeypair(result: FlutterResult) {
        // TODO: Replace with actual call when UniFFI bindings available
        // let keypair = generateKeypair()
        // result([
        //     "publicKeyHex": keypair.publicKeyHex,
        //     "privateKeyHex": keypair.privateKeyHex
        // ])
        result(FlutterError(code: "NotImplemented", message: "UniFFI bindings not yet integrated", details: nil))
    }

    // MARK: - Invite

    private func handleCreateInvite(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let inviterPubkeyHex = args["inviterPubkeyHex"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        let deviceId = args["deviceId"] as? String
        let maxUses = args["maxUses"] as? UInt32

        // TODO: Implement
        result(FlutterError(code: "NotImplemented", message: "UniFFI bindings not yet integrated", details: nil))
    }

    private func handleInviteFromUrl(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let url = args["url"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        // TODO: Implement
        result(FlutterError(code: "NotImplemented", message: "UniFFI bindings not yet integrated", details: nil))
    }

    private func handleInviteFromEventJson(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let eventJson = args["eventJson"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        // TODO: Implement
        result(FlutterError(code: "NotImplemented", message: "UniFFI bindings not yet integrated", details: nil))
    }

    private func handleInviteDeserialize(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let json = args["json"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        // TODO: Implement
        result(FlutterError(code: "NotImplemented", message: "UniFFI bindings not yet integrated", details: nil))
    }

    private func handleInviteToUrl(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String,
              let root = args["root"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        // TODO: Implement
        result(FlutterError(code: "NotImplemented", message: "UniFFI bindings not yet integrated", details: nil))
    }

    private func handleInviteToEventJson(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        // TODO: Implement
        result(FlutterError(code: "NotImplemented", message: "UniFFI bindings not yet integrated", details: nil))
    }

    private func handleInviteSerialize(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        // TODO: Implement
        result(FlutterError(code: "NotImplemented", message: "UniFFI bindings not yet integrated", details: nil))
    }

    private func handleInviteAccept(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String,
              let inviteePubkeyHex = args["inviteePubkeyHex"] as? String,
              let inviteePrivkeyHex = args["inviteePrivkeyHex"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        let deviceId = args["deviceId"] as? String
        // TODO: Implement
        result(FlutterError(code: "NotImplemented", message: "UniFFI bindings not yet integrated", details: nil))
    }

    private func handleInviteGetInviterPubkeyHex(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        // TODO: Implement
        result(FlutterError(code: "NotImplemented", message: "UniFFI bindings not yet integrated", details: nil))
    }

    private func handleInviteGetSharedSecretHex(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        // TODO: Implement
        result(FlutterError(code: "NotImplemented", message: "UniFFI bindings not yet integrated", details: nil))
    }

    private func handleInviteDispose(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        inviteHandles.removeValue(forKey: id)
        result(nil)
    }

    // MARK: - Session

    private func handleSessionFromStateJson(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let stateJson = args["stateJson"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        // TODO: Implement
        result(FlutterError(code: "NotImplemented", message: "UniFFI bindings not yet integrated", details: nil))
    }

    private func handleSessionInit(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let theirEphemeralPubkeyHex = args["theirEphemeralPubkeyHex"] as? String,
              let ourEphemeralPrivkeyHex = args["ourEphemeralPrivkeyHex"] as? String,
              let isInitiator = args["isInitiator"] as? Bool,
              let sharedSecretHex = args["sharedSecretHex"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        let name = args["name"] as? String
        // TODO: Implement
        result(FlutterError(code: "NotImplemented", message: "UniFFI bindings not yet integrated", details: nil))
    }

    private func handleSessionCanSend(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        // TODO: Implement
        result(FlutterError(code: "NotImplemented", message: "UniFFI bindings not yet integrated", details: nil))
    }

    private func handleSessionSendText(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String,
              let text = args["text"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        // TODO: Implement
        result(FlutterError(code: "NotImplemented", message: "UniFFI bindings not yet integrated", details: nil))
    }

    private func handleSessionDecryptEvent(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String,
              let outerEventJson = args["outerEventJson"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        // TODO: Implement
        result(FlutterError(code: "NotImplemented", message: "UniFFI bindings not yet integrated", details: nil))
    }

    private func handleSessionStateJson(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        // TODO: Implement
        result(FlutterError(code: "NotImplemented", message: "UniFFI bindings not yet integrated", details: nil))
    }

    private func handleSessionIsDrMessage(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String,
              let eventJson = args["eventJson"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        // TODO: Implement
        result(FlutterError(code: "NotImplemented", message: "UniFFI bindings not yet integrated", details: nil))
    }

    private func handleSessionDispose(call: FlutterMethodCall, result: FlutterResult) throws {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String else {
            throw NdrPluginError.invalidArguments
        }
        sessionHandles.removeValue(forKey: id)
        result(nil)
    }
}

enum NdrPluginError: Error {
    case invalidArguments
    case handleNotFound
}
