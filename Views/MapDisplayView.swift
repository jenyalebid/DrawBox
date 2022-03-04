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
                .onAppear {
                    if viewModel.trackingDefault {
                        viewModel.displayBox.startTacking()
                    }
                }
            VStack(alignment: .trailing) {
                if viewModel.featureSelected() {
                    InfoPanelView().environmentObject(viewModel)
                        .padding(.top, 45)
                }
                Spacer()
                Group {
                    MapLayerType().environmentObject(viewModel)
                    LocationButton(highlighted: viewModel.displayBox.locationTracking, action: viewModel.moveToUserLocation)
                }
                .padding([.bottom, .trailing], 8.0)
            }
        }
    }
}

private struct LocationButton: View {
    
    var highlighted: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            if highlighted {
                Image(systemName: "location.fill")
                    .frame(width: 30, height: 30)
            }
            else {
                Image(systemName: "location")
                    .frame(width: 30, height: 30)

            }
        }
        .padding(8.0)
        .background(Color(UIColor.systemBackground)).cornerRadius(50)
        .buttonStyle(BorderlessButtonStyle())
    }
}

private struct MapLayerType: View {
    
    @State var buttonClick = false
    @EnvironmentObject var viewModel: MapDisplayViewModel
    
    var body: some View {
        HStack {
            if buttonClick {
                layerSelection
            }
            layerButton
        }
    }
    
    var layerButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                buttonClick.toggle()
            }
        } label: {
            Image(systemName: "map")
                .frame(width: 30, height: 30)
        }
        .padding(8.0)
        .background(Color(UIColor.systemBackground)).cornerRadius(50)
        .buttonStyle(BorderlessButtonStyle())
    }
    
    var layerSelection: some View {
        let currentStyle = UserDefaults.standard.object(forKey: "mapStyle") as? String ?? "terrain"
        return HStack {
            Button {
                viewModel.changeMapStyle(style: "terrain")
                buttonClick.toggle()
            } label: {
                Text("Terrain")
            }
            .disabled(currentStyle == "terrain")
            Divider()
            Button {
                viewModel.changeMapStyle(style: "satellite")
                buttonClick.toggle()
            } label: {
                Text("Satellite")
            }
            .disabled(currentStyle == "satellite")
        }
        .frame(height: 30)
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
