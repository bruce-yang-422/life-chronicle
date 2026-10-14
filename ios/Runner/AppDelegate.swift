import Flutter
import UIKit
import ImageIO
import UniformTypeIdentifiers
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "life_chronicle/attachments",
                                         binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { call, result in
        guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
          result(FlutterError(code: "invalid_path", message: "缺少檔案路徑", details: nil))
          return
        }
        do {
          switch call.method {
          case "availableBytes":
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: path)
            result(attributes[.systemFreeSize])
          case "metadata":
            let url = URL(fileURLWithPath: path)
            var mediaType = "application/octet-stream"
            if #available(iOS 14.0, *) {
              mediaType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? mediaType
            }
            var metadata: [String: Any] = ["mediaType": mediaType]
            if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
               let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
               let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any],
               let date = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String,
               date.count >= 19 {
              metadata["capturedAt"] = String(date.prefix(10)).replacingOccurrences(of: ":", with: "-") + "T" + String(date.suffix(8))
            }
            if mediaType.hasPrefix("video/") || mediaType.hasPrefix("audio/") {
              let asset = AVURLAsset(url: url)
              if let date = asset.commonMetadata.first(where: { $0.commonKey == .commonKeyCreationDate })?.dateValue {
                metadata["capturedAt"] = ISO8601DateFormatter().string(from: date)
              }
            }
            result(metadata)
          default: result(FlutterMethodNotImplemented)
          }
        } catch {
          result(FlutterError(code: "attachment_error", message: "附件操作失敗", details: nil))
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
