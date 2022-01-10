//
//  ShareMapView.swift
//  ShareLocation
//
//  Created by 藤治仁 on 2021/12/17.
//

import SwiftUI
import MapKit
struct ShareMapView: View {
    @StateObject private var viewModel = ShareMapViewModel()
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    
    var body: some View {
        VStack {
            Map(coordinateRegion: $viewModel.region,
                interactionModes: .all,
                showsUserLocation: true,
                userTrackingMode: $userTrackingMode,
                annotationItems: viewModel.mapPinItems) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                        .frame(width: 40, height: 40)
                        .onTapGesture(count: 1) {
                            //nop
                        }
                }
            }
            Button {
                viewModel.requestShare()
            } label: {
                Text("Reload")
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color.gray)
            Divider()
        }
        .onAppear() {
            viewModel.onAppear()
        }
        .onDisappear(perform: {
            viewModel.onDisappear()
        })
    }
}

struct ShareMapView_Previews: PreviewProvider {
    static var previews: some View {
        ShareMapView()
    }
}
