//
//  MapDisplayView.swift
//  DrawBox
//
//  Created by Jenya Lebid on 2/1/22.
//

import SwiftUI

public struct MapDisplayView: View {
    
    @ObservedObject var viewModel: MapDisplayViewModel
    
    public init(geometry: [String?] = [], drawBox: DrawBox? = nil, displayBox: DisplayBox? = nil) {
        viewModel = MapDisplayViewModel(geometry: geometry, drawBox: drawBox, displayBox: displayBox)
    }
    
    public var body: some View {
        ZStack(alignment: .trailing) {
            MapBoxViewWrapper(viewModel: viewModel).ignoresSafeArea(.container, edges: [.leading, .trailing])
                .onDisappear {
                    viewModel.displayBox.stopTracking()
                }
            VStack(alignment: .trailing) {
                if viewModel.featureSelected() {
                    InfoPanelView().environmentObject(viewModel)
                        .padding(.top, 45)
                }
                Spacer()
                LocationButton(highlighted: viewModel.displayBox.locationTracking, action: viewModel.moveToUserLocation)
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
                Image(systemName: "location.fill").font(.headline)
            }
            else {
                Image(systemName: "location").font(.headline)
            }
        }
        .padding(8.0)
        .background(Color(UIColor.systemBackground)).cornerRadius(50)
        .buttonStyle(BorderlessButtonStyle())
    }
}

//struct MapDisplayView_Previews: PreviewProvider {
//    static var previews: some View {
//        MapDisplayView()
//    }
//}
