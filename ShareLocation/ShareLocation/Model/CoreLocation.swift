//
//  CoreLocation.swift
//  ShareLocation
//
//  Created by 藤治仁 on 2021/12/17.
//

import SwiftUI
import Combine
import CoreLocation

enum LocationManagerError: Error {
    case authorizationDenied
}

class CoreLocation: NSObject ,ObservableObject {
    static let shared = CoreLocation()
    private let locationSubject: PassthroughSubject<CLLocation, Error> = .init()
    private let locationManager = CLLocationManager()
    private var status: CLAuthorizationStatus {
        debugLog("\(locationManager.authorizationStatus.rawValue)")
        return locationManager.authorizationStatus
    }
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        //バックグランド中に位置情報を取得するか
        locationManager.allowsBackgroundLocationUpdates = true
        //システムが場所の更新を一時停止できるかどうか
        locationManager.pausesLocationUpdatesAutomatically = false
        authorization()
    }
    
    func authorization() {
        if status == .restricted || status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse {
            // バックグラウンドで場所へのアクセスを許可
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func oneShot()  -> AnyPublisher<CLLocation, Error> {
        debugLog("oneShot start")
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        } else {
            locationSubject.send(completion: .failure(LocationManagerError.authorizationDenied))
        }
        
        return locationSubject.eraseToAnyPublisher()
    }
}


extension CoreLocation: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            locationManager.stopUpdatingLocation()
            debugLog(location)
            locationSubject.send(location)
        }
    }
}

