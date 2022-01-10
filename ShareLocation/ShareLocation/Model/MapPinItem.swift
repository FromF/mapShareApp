//
//  MapPinItem.swift
//  ShareLocation
//
//  Created by 藤治仁 on 2021/12/17.
//

import SwiftUI
import CoreLocation

struct MapPinItem: Identifiable {
    let id = UUID()
    let uuid: String
    var coordinate: CLLocationCoordinate2D
    var title: String
}
