//
//  InfoPanelView.swift
//  DrawBox
//
//  Created by Jenya Lebid on 2/21/22.
//

import SwiftUI

struct InfoPanelView: View {
    
//    @EnvironmentObject var displayViewModel: MapDisplayViewModel
    
    @State private var panelWidth = 0.0
    
    var body: some View {
        ZStack {
            HStack {
                if panelWidth > 200 {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Geometry Information").foregroundColor(Color.black)
//                        Text("\(displayViewModel.drawBox?.selectedFeature?.identifier!)")
                        Spacer()
                    }
                    .padding(8.0)
                    Spacer()
                }
                Button {
                    panelWidth = (panelWidth == 0 ? 240 : 0)
                } label: {
                    Image(systemName: "control")
                        .font(.title)
                        .rotationEffect(.degrees(panelWidth > 60 ? 90 : -90))
                }
            }
        }
        .frame(width: (panelWidth >= 30 ? panelWidth : 30), height: 200, alignment: .leading)
        .background(Color.white)
        .cornerRadius(10, corners: [.topRight, .bottomRight])
        .cornerRadius(panelWidth > 30 ? 10 : 0, corners: [.topLeft, .bottomLeft])
        .padding(.horizontal, panelWidth > 30 ? 12 : 0)
        .padding(.vertical)
        .animation(.easeIn, value: panelWidth)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    panelWidth = gesture.translation.width
                }
                .onEnded { _ in
                    if panelWidth < -10 {
                        panelWidth = 0
                    }
                    else {
                        panelWidth = 240
                    }
                }
        )
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct InfoPanelView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            InfoPanelView()
            Spacer()
        }
        .background(Color.gray)
    }
}
