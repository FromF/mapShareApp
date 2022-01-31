//
//  AppDelegate.swift
//  ShareLocation
//
//  Created by 藤治仁 on 2022/01/09.
//

import UIKit
    import Firebase
import UserNotifications
import FirebaseMessaging

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



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
        //UIApplication.shared.registerForRemoteNotifications()
        
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

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Push Notification
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        debugLog(deviceToken)
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        debugLog("PUSH arrived. \(userInfo)")
        let shareLocations = ShareLocations.shared
        let coreLocation = CoreLocation.shared
        coreLocation.oneShot()
        
        for _ in 0...10 {
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

// MARK: - UNUserNotificationCenterDelegate
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

// MARK: - MessagingDelegate
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
