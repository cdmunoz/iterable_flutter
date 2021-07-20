import Flutter
import UIKit
import IterableSDK


public class SwiftIterableFlutterPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "iterable_flutter", binaryMessenger: registrar.messenger())
        let instance = SwiftIterableFlutterPlugin()
        registrar.addApplicationDelegate(instance)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            if let args = try getPropertiesFromArguments(call.arguments) {
                switch call.method {
                case "register":
                    if let deviceToken = args["deviceToken"] as? Data {
                        register(deviceToken: deviceToken)
                    }
                case "initialUrl":
                    result(url?.absoluteString ?? "")
                case "initialize":
                    if let apiKey = args["apiKey"] as? String {
                        initialize(apiKey: apiKey)
                    }
                case "setUserIdentity":
                    if let userEmail = args["userEmail"] as? String,
                       let userId = args["userId"] as? String {
                        setUserIdentity(
                            userEmail: userEmail,
                            userId: userId,
                            firstName: args["firstName"] as? String
                        )
                    }
                case "track":
                    if let eventName = args["eventName"] as? String {
                        track(eventName, params: args["params"] as? [String : Any])
                    }
                case "signOut":
                    signOut()
                default:
                    result(FlutterMethodNotImplemented)
                }
            }
            result(true)
        } catch {
            result(
                FlutterError(
                    code: "EXCEPTION_IN_HANDLE",
                    message: "Exception happened in handle.", details: nil
                )
            )
        }
        result(true)
        
    }
    
    public func getPropertiesFromArguments(_ callArguments: Any?) throws -> [String: Any]? {
        if let arguments = callArguments as? [String: Any] {
            return arguments;
        }
        return [:];
    }

    private func initialize(apiKey: String) {
        let config = IterableConfig()
        config.urlDelegate = self
        IterableAPI.initialize(
            apiKey: apiKey,
            config: config
        )
    }
    
    private func register(deviceToken: Data) {
        IterableAPI.register(token: deviceToken)
    }
    
    private func registerUserNotificationCenter(center: UNUserNotificationCenter?,
                                                didReceive response: UNNotificationResponse,
                                                withCompletionHandler completionHandler: (() -> Void)?) {
        IterableAppIntegration.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }
    
    private func registerApplication(_ application: UIApplication,
                                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                                     fetchCompletionHandler completionHandler: ((UIBackgroundFetchResult) -> Void)?) {
        IterableAppIntegration.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    private func setUserIdentity(userEmail: String, userId: String, firstName: String?) {
        IterableAPI.email = userEmail
        
        IterableAPI.updateEmail(userEmail, onSuccess: { (_) in
            IterableAPI.updateUser(["userId": userId], mergeNestedObjects: false, onSuccess: { (_) in
                IterableAPI.userId = userId
            }, onFailure: { (_, _) in
                ITBError()
            })
        }, onFailure: { (reason, _) in
            IterableAPI.updateUser(["userId": userId], mergeNestedObjects: false, onSuccess: { (_) in
                IterableAPI.userId = userId
            }, onFailure: { (_, _) in
                ITBError()
            })
        })
                
        if let firstName = firstName {
            IterableAPI.updateUser(["firstName": firstName], mergeNestedObjects: false)
        }
    }
    
    private func signOut() {
        IterableAPI.disableDeviceForCurrentUser()
    }
    
    private func track(_ eventName: String, params: [String : Any]?) {
        IterableAPI.track(event: eventName, dataFields: params)
    }
}

extension SwiftIterableFlutterPlugin: IterableURLDelegate {

    public func handle(iterableURL url: URL, inContext context: IterableActionContext) -> Bool {
        return true
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let webpageURL = userActivity.webpageURL else {
            return false
        }

        return IterableAPI.handle(universalLink: webpageURL)
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        IterableAPI.register(token: deviceToken)
    }

    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        IterableAppIntegration.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }

    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return true
    }
}