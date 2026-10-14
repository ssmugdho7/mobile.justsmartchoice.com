import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate,
  UIDocumentInteractionControllerDelegate {
  private var documentChannel: FlutterMethodChannel?
  private var documentPreview: UIDocumentInteractionController?
  private weak var documentPresenter: UIViewController?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "com.justsmartchoice.mobile/documents",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    documentChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(FlutterError(
        code: "unavailable", message: "Document viewer unavailable", details: nil)) }
      guard let arguments = call.arguments as? [String: Any] else {
        return result(FlutterError(code: "invalid", message: "Missing document information", details: nil))
      }
      switch call.method {
      case "saveDownload":
        guard let path = arguments["path"] as? String,
          let name = arguments["name"] as? String,
          let mime = arguments["mime"] as? String else {
          return result(FlutterError(code: "invalid", message: "Missing document information", details: nil))
        }
        DispatchQueue.global(qos: .userInitiated).async {
          do {
            let url = try DocumentStore().save(path: path, name: name, mime: mime)
            DispatchQueue.main.async { result(url.absoluteString) }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "save_failed", message: "Unable to save document", details: nil))
            }
          }
        }
      case "openDownload":
        guard let uri = arguments["uri"] as? String,
          let mime = arguments["mime"] as? String else {
          return result(FlutterError(code: "invalid", message: "Missing document information", details: nil))
        }
        do {
          let url = try DocumentStore().document(uri: uri, mime: mime)
          guard let presenter = self.visibleViewController(), presenter.view.window != nil else {
            return result(FlutterError(code: "open_failed", message: "Document viewer unavailable", details: nil))
          }
          let preview = UIDocumentInteractionController(url: url)
          preview.delegate = self
          self.documentPresenter = presenter
          self.documentPreview = preview
          if preview.presentPreview(animated: true) {
            result(nil)
          } else if preview.presentOptionsMenu(
            from: presenter.view.bounds, in: presenter.view, animated: true) {
            result(nil)
          } else {
            self.documentPreview = nil
            result(FlutterError(code: "open_failed", message: "No document viewer available", details: nil))
          }
        } catch {
          result(FlutterError(code: "open_failed", message: "Unable to open document", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func documentInteractionControllerViewControllerForPreview(
    _ controller: UIDocumentInteractionController
  ) -> UIViewController {
    // presentPreview is called only after verifying an active scene above.
    return documentPresenter ?? UIViewController()
  }

  private func visibleViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    var current = scenes.first { $0.activationState == .foregroundActive }?
      .windows.first { $0.isKeyWindow }?.rootViewController
    while let controller = current {
      if let presented = controller.presentedViewController, !presented.isBeingDismissed {
        current = presented
      } else if let navigation = controller as? UINavigationController {
        current = navigation.visibleViewController
      } else if let tabs = controller as? UITabBarController {
        current = tabs.selectedViewController
      } else {
        break
      }
    }
    return current
  }
}
