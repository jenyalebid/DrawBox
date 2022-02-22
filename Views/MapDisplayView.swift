//
//  MapDisplayView.swift
//  DrawBox
//
//  Created by Jenya Lebid on 2/1/22.
//

import SwiftUI

public struct MapDisplayView: View {
    
    @ObservedObject var viewModel: MapDisplayViewModel
    
    public init(geometry: String? = nil, drawBox: DrawBox? = nil, moveToLocation: Bool = false) {
        viewModel = MapDisplayViewModel(geometry: geometry, drawBox: drawBox, moveToLocation: moveToLocation)
    }
    
    public var body: some View {
        ZStack {
            MapBoxViewWrapper(viewModel: viewModel).ignoresSafeArea(.container, edges: [.leading, .trailing])
            HStack {
                if viewModel.featureSelected() {
                    InfoPanelView().environmentObject(viewModel)
                }
                Spacer()
                LocationButton(highlighted: viewModel.startedLocation, action: viewModel.locationChange)
                    .padding([.bottom, .trailing], 8.0)
            }
        }
    }
}

struct LocationButton: View {
    
    var highlighted: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            if highlighted {
                Image(systemName: "location.fill").font(.title2)
            }
            else {
                Image(systemName: "location").font(.title2)
            }
        }
    }
}

//struct MapDisplayView_Previews: PreviewProvider {
//    static var previews: some View {
//        MapDisplayView()
//    }
//}
