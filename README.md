# mapShareApp
位置情報をシェアするアプリ

## 概要

Silent NotificationとBackground Mode-Location Updateを使ってSilent Notificationをトリガーにして位置情報をバックグラウンドで取得し、Firebase CloudStoreに位置情報を保持するプロジェクトです。



## 技術要素

### FCMからSilent Noticaitonを通知する

curlコマンドで下記を実行するとSilent Noticaitonが発行できる

```
curl --header "Authorization: key=[SERVER_KEY]" --header Content-Type:"application/json" https://fcm.googleapis.com/fcm/send -d "{\"to\": \"/topics/ios\",\"content_available\":true}"
```



### Background Mode-Location Updateするとき

`CLLocationManager()`のプロパティー`allowsBackgroundLocationUpdates`を`true`にする必要がある



## 参考

- [【iOS】Firebase Cloud Messaging を使って Silent Notification 受信する](https://qiita.com/kenny_J_7/items/e3f659f7b54492c53bd6)
- [【iOS10】Firebaseでサイレント通知を行う](https://qiita.com/shiba1014/items/099f8e7aa37d5e2540da)
- [Background Notification (Silent Push)](https://qiita.com/chocoyama/items/56cd3ac2daaf69dffa0f)
- [iOS の Push 通知の種類](https://zenn.dev/attomicgm/articles/about_ios_push_type)
- [search:"silent push notification ios swift firebase"](https://www.google.com/search?q=silent+push+notification+ios+swift+firebase&biw=1800&bih=928&tbs=qdr%3Ay&sxsrf=AOaemvLTagIhvLIEdCwNpfWGe7Uy3aQjgg%3A1639902817738&ei=Ye6-YbmULJyO2roPsLWqmA8&ved=0ahUKEwj5yKqHuu_0AhUch1YBHbCaCvMQ4dUDCA4&uact=5&oq=silent+push+notification+ios+swift+firebase&gs_lcp=Cgdnd3Mtd2l6EAM6BwgjELADECc6CQgAELADEAcQHjoFCAAQywE6BAgAEB46BQghEKABSgQIQRgBSgQIRhgAUGFYyTpgujxoAXAAeACAAZMBiAHMB5IBAzguMpgBAKABAcgBCsABAQ&sclient=gws-wiz)
- [Swiftでのローカル通知・リモート通知の実装メモ](https://qiita.com/koishi/items/28ad65f944c43487d584)
- [FirebaseでiOSのプッシュ通知を実装](https://qiita.com/ausssxi/items/89305cdb3935d6f6f2b8)
- [Send silent push notification from Firebase console](https://coderedirect.com/questions/338718/send-silent-push-notification-from-firebase-console)
- [How to Send Silent Push Notifications](https://swiftsenpai.com/testing/send-silent-push-notifications/)

