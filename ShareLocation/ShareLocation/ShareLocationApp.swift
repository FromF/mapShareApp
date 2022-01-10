//
//  ShareLocationApp.swift
//  ShareLocation
//
//  Created by 藤治仁 on 2021/12/17.
//

import SwiftUI
import Firebase
import UserNotifications
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        //APNS
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { granted, error in
              if let error = error {
                  errorLog("プッシュ通知許可要求エラー : \(error.localizedDescription)")
                  return
              }
              if !granted {
                  debugLog("プッシュ通知が拒否されました。")
                  return
              }
              DispatchQueue.main.async {
                  // APNs への登録
                  UIApplication.shared.registerForRemoteNotifications()
              }
          }
        )
        application.registerForRemoteNotifications()
        
//        UIApplication.shared.registerForRemoteNotifications()
        Messaging.messaging().delegate = self

        Messaging.messaging().token { token, error in
            if let error = error {
                errorLog("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                debugLog(token)
            }
        }
        Messaging.messaging().subscribe(toTopic: "ios") { error in
            if let error = error {
                errorLog(error)
            } else {
                debugLog("Subscribed to ios topic")
            }
        }

        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        debugLog(deviceToken)
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        debugLog("PUSH arrived. \(userInfo)")
        let shareLocations = ShareLocations.shared
        let coreLocation = CoreLocation.shared
        coreLocation.oneShot()
        
        while true {
            if coreLocation.isUpdate , let coodinate = coreLocation.coordinate {
                if shareLocations.write(coordinate: coodinate) {
                    break
                }
            }
            sleep(1)
        }
        
        completionHandler(.noData)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        errorLog(String(format: "Remote Notification Error: %@", error.localizedDescription))
    }
}

extension AppDelegate : UNUserNotificationCenterDelegate {
    // フォアグラウンドで通知が到着した時の挙動
   func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
       let userInfo = notification.request.content.userInfo

       if let messageID = userInfo["gcm.message_id"] {
           debugLog("Message ID: \(messageID)")
       }

       debugLog(userInfo)

       completionHandler([.banner, .sound])
   }

    // 通知を選択した時の挙動
   func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
       let userInfo = response.notification.request.content.userInfo
       if let messageID = userInfo["gcm.message_id"] {
           debugLog("Message ID: \(messageID)")
       }

       debugLog(userInfo)

       completionHandler()
   }
}

extension AppDelegate : MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        debugLog("Firebase registration token: \(String(describing: fcmToken))")

        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
          name: Notification.Name("FCMToken"),
          object: nil,
          userInfo: dataDict
        )
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
}

@main
struct ShareLocationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            ShareMapView()
                .onChange(of: scenePhase) { scene in
                    switch scene {
                    case .active:
                        debugLog("scenePhase: active")
                        UNUserNotificationCenter.current().getDeliveredNotifications(
                            completionHandler: { deliveredNotifications in
                                deliveredNotifications.forEach({ notification in
                                    let userInfo = notification.request.content.userInfo
                                    // 以下で、配信済みの通知のUserInfoをもとに
                                    // 各通知に対しての処理を行う
                                    debugLog(userInfo)
                                })
                        })
                    case .inactive:
                        debugLog("scenePhase: inactive")
                    case .background:
                        debugLog("scenePhase: background")
//                        CoreLocation.shared.oneShot()
                    @unknown default: break
                    }
                }
        }
    }
}
