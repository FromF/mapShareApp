//
//  ShareLocation.swift
//  ShareLocation
//
//  Created by 藤治仁 on 2021/12/19.
//

import SwiftUI
import CoreLocation

struct ShareLocation: Identifiable {
    let id: String
    var coordinate: CLLocationCoordinate2D
}
