//
//  ShareLocations.swift
//  ShareLocation
//
//  Created by 藤治仁 on 2021/12/19.
//

import Foundation
import CoreLocation
import Firebase

protocol ShareLocationsDelegate: AnyObject {
    func locationUpdate(location: ShareLocation)
}

class ShareLocations: NSObject {
    static let shared = ShareLocations()
    weak var delegate: ShareLocationsDelegate?
    
    var locations: [ShareLocation] = []
    
    private var uuid:String?
    private var listenerUsers: ListenerRegistration!
    
    override init() {
        super.init()
        Auth.auth().signInAnonymously() { (authResult, error) in
            if let user = authResult?.user {
                self.uuid = user.uid
                self.setupFirebase()
            }
        }
    }
    
    func write(coordinate: CLLocationCoordinate2D) -> Bool {
        var result = false
        if let uuid = uuid {
            let param: [String : Any] = [
                "uuid" : uuid,
                "latitude" : coordinate.latitude,
                "longitude" : coordinate.longitude,
            ]
            let db = Firestore.firestore()
            db.collection("users").document("\(uuid)").setData(param)
            result = true
        }
        return result
    }
    
    private func setupFirebase() {
        let db = Firestore.firestore()
        listenerUsers = db.collection("users") .addSnapshotListener({ [unowned self]  (snap, error) in
            if let error = error {
                errorLog("Error fetching snapshot results: \(error)")
                return
            }
            guard let snap = snap else {
                errorLog("Error fetching snapshot results: \(error!)")
                return
            }
            for dic in snap.documentChanges {
                if dic.type == .added || dic.type == .modified ,
                   let uuid = dic.document.get("uuid") as? String,
                   let latitude = dic.document.get("latitude") as? Double,
                   let longitude = dic.document.get("longitude") as? Double {
                    debugLog("uuid:\(uuid) , latitude:\(latitude) , longitude:\(longitude)")
                    if let index = locations.firstIndex(where: { shareLocation in
                        return shareLocation.id == uuid ? true : false
                    }) {
                        locations[index].coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        DispatchQueue.main.async { [weak self] in
                            self?.delegate?.locationUpdate(location: locations[index])
                        }
                    } else {
                        let location = ShareLocation(id: uuid, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                        locations.append(location)
                        DispatchQueue.main.async { [weak self] in
                            self?.delegate?.locationUpdate(location: location)
                        }
                    }
                }
            }
        })
    }
}
