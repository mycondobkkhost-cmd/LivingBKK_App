import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey("AIzaSyAVg6zlrKulbuRxlEsAK3YC946I01BaQl8") // LIVINGBKK_GOOGLE_MAPS_INIT
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
