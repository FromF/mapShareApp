//
//  CoreLocation.swift
//  ShareLocation
//
//  Created by 藤治仁 on 2021/12/17.
//

import SwiftUI
import CoreLocation

protocol CoreLocationDelegate: AnyObject {
    func locationUpdate(coordinate: CLLocationCoordinate2D)
}


class CoreLocation: NSObject ,ObservableObject {
    static let shared = CoreLocation()
    weak var delegate: CoreLocationDelegate?
    var isUpdate = false
    var coordinate: CLLocationCoordinate2D?
    
    private let locationManager = CLLocationManager()
    private var status: CLAuthorizationStatus {
        debugLog("\(locationManager.authorizationStatus.rawValue)")
        return locationManager.authorizationStatus
    }
    private var isOneShot = false
    private var isStarted = false
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
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
    
    func start() {
        if status == .authorizedAlways {
            debugLog("")
            //検出範囲 kCLDistanceFilterNoneにすると最高精度になる。通常は10とか100にするとよい
            locationManager.distanceFilter = kCLDistanceFilterNone
            locationManager.startUpdatingLocation()
            isStarted = true
        }
    }
    
    func stop() {
        debugLog("")
        locationManager.stopUpdatingLocation()
        isStarted = false
    }
    
    func oneShot() {
        debugLog("oneShot start")
        if isStarted , let _ = coordinate {
            isUpdate = true
        } else {
            isOneShot = true
            isUpdate = false
            start()
        }
    }
    
}


extension CoreLocation: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            coordinate = location.coordinate
            debugLog(location)
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.locationUpdate(coordinate: location.coordinate)
            }
            
            if isOneShot {
                stop()
                isOneShot = false
                isUpdate = true
                debugLog("oneShot end")
            }
        }
    }
}

