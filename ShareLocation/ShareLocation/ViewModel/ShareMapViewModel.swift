//
//  ShareMapViewModel.swift
//  ShareLocation
//
//  Created by 藤治仁 on 2021/12/19.
//

import SwiftUI
import CoreLocation
import MapKit
import Combine

class ShareMapViewModel: ObservableObject {
    /// 緯度経度
    @Published var mapPinItems: [MapPinItem] = []
    @Published var region = MKCoordinateRegion(center: .init(latitude: 35.4242129, longitude: 139.595221), latitudinalMeters: 2000, longitudinalMeters: 2000)

    private let coreLocation = CoreLocation.shared
    private let shareLocations = ShareLocations.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        shareLocations.delegate = self
    }
    
    func onAppear() {
        coreLocation.oneShot()
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    errorLog("location error")
                }
            } receiveValue: { [weak self] location in
                let coordinate = location.coordinate
                debugLog(coordinate)
                self?.region.center.longitude = coordinate.longitude
                self?.region.center.latitude = coordinate.latitude
                _ = self?.shareLocations.write(coordinate: coordinate)
            }
            .store(in: &cancellables)
    }
    
    func onDisappear() {
    }
    
    func requestShare() {
        //GoogleService-Info.plistへのパスを取得します
        let firebasePlist = "GoogleService-Info"
        guard let googlePlist = Bundle.main.path(forResource: firebasePlist, ofType: "plist") else {
            errorLog("GoogleService-Info.plistの取得失敗")
            return
        }

        //SERVER_KEYを取得します
        if let option = NSDictionary(contentsOfFile: googlePlist){
            guard let serverKey = option["SERVER_KEY"] as? String else {
                errorLog("SERVER_KEYの取得失敗")
                return
            }

            //通知送信用のURL設定
            let url = URL.init(string:"https://fcm.googleapis.com/fcm/send")

            //リクエストの設定
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            //ヘッダーの設定（keyにサーバーキーを設定します）
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")

            do{
                //送信するJSONデータの設定
                var sendData = Dictionary<String,Any>()
                //既定のパラメータに設定を行います
                sendData["to"] = "/topics/ios"
                sendData["content_available"] = true
                
                var data = Dictionary<String,Any>()
                data["uid"] = shareLocations.uuid ?? "none"
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .short
                
                data["date"] = dateFormatter.string(from: Date())
                sendData["data"] = data

                //JSONデータの生成
                let sendJsonData = try JSONSerialization.data(withJSONObject: sendData, options: [])
                request.httpBody = sendJsonData

                //セッションの確立
                let config = URLSessionConfiguration.default
                let session = URLSession(configuration: config, delegate: nil, delegateQueue: .main)

                //JSONデータの送信
                let task = session.dataTask(with: request, completionHandler: {(data, response, error) -> Void in
                    if(error == nil){
                        if data == nil{
                            errorLog("HTTP通信でエラー")
                            return
                        }else{
                            debugLog("data : \(data!.description) \(String(data: data!, encoding: .utf8))")
                        }
                    }else{
                        debugLog("Error : \(error.debugDescription)")
                    }
                })
                task.resume()
            }catch let error{
                errorLog("try-catch Error : \(error.localizedDescription)")
            }
        }

    }
}

extension ShareMapViewModel: ShareLocationsDelegate {
    func locationUpdate(location: ShareLocation) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let date = dateFormatter.string(from: Date())

        if let index = mapPinItems.firstIndex(where: { mapPin in
            return mapPin.uuid == location.id ? true : false
        }) {
            mapPinItems[index].coordinate = location.coordinate
            mapPinItems[index].title = date
        } else {
            let mapPin = MapPinItem(uuid: location.id, coordinate: location.coordinate, title: date)
            mapPinItems.append(mapPin)
        }
    }
}
