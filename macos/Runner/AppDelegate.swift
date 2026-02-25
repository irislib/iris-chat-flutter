import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    let registrar = controller.registrar(forPlugin: "NdrFfiPlugin")
    NdrFfiPlugin.register(with: registrar)
    let hashtreeRegistrar = controller.registrar(forPlugin: "HashtreePlugin")
    HashtreePlugin.register(with: hashtreeRegistrar)
    super.applicationDidFinishLaunching(notification)
  }
}
