import Flutter
import UIKit

public class DevGuardHardwarePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "dev_guard/hardware",
      binaryMessenger: registrar.messenger()
    )
    let instance = DevGuardHardwarePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getStorageTotal":
      result(Self.formatStorageTotal())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func formatStorageTotal() -> String? {
    do {
      let attrs = try FileManager.default.attributesOfFileSystem(
        forPath: NSHomeDirectory()
      )
      if let total = attrs[.systemSize] as? NSNumber {
        let gb = Double(truncating: total) / (1024.0 * 1024.0 * 1024.0)
        return String(format: "%.1f GB Total", gb)
      }
    } catch {}
    return nil
  }
}
