import Flutter
import Network
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Kept alive briefly so iOS presents the Local Network permission dialog.
  private var localNetworkBrowser: NWBrowser?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Plist keys alone do not show Settings → Local Network or the Allow dialog.
    // Flutter Dart VM discovery (mDNS / Bonjour) needs an active LAN probe first.
    triggerLocalNetworkPermissionProbe()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  /// Browse for Flutter observatory Bonjour services to force the iOS 14+ Local Network prompt.
  private func triggerLocalNetworkPermissionProbe() {
    let params = NWParameters()
    params.includePeerToPeer = true
    let browser = NWBrowser(
      for: .bonjour(type: "_dartobservatory._tcp", domain: "local."),
      using: params
    )
    // NWBrowser.stateUpdateHandler is (NWBrowser.State) -> Void — one arg only.
    // A two-arg closure makes Swift 6 fail with "Failed to produce diagnostic".
    browser.stateUpdateHandler = { _ in }
    browser.browseResultsChangedHandler = { _, _ in }
    browser.start(queue: .main)
    localNetworkBrowser = browser
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
      self?.localNetworkBrowser?.cancel()
      self?.localNetworkBrowser = nil
    }
  }
}
