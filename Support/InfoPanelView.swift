//
//  InfoPanelView.swift
//  DrawBox
//
//  Created by Jenya Lebid on 2/21/22.
//

import SwiftUI

struct InfoPanelView: View {
    
    @EnvironmentObject var displayViewModel: MapDisplayViewModel
    
    @State private var pin = UserDefaults.standard.object(forKey: "infoPinned") as? Bool ?? false
    @State private var notes = false
    @State private var panelWidth = UserDefaults.standard.object(forKey: "infoPinned") as? Bool ?? false ? 240.0 : 0.0
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                VStack {
                    Button {
                        pin.toggle()
                        UserDefaults.standard.set(pin, forKey: "infoPinned")
                    } label: {
                        if panelWidth == 240 {
                            Image(systemName: pin == false ? "pin" : "pin.fill")
                                .foregroundColor(.orange)
                                .rotationEffect(.degrees(45))
                                .padding([.top, .leading, .trailing], 6.0)
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    Spacer()
                    Button {
                        panelWidth = (panelWidth == 0 ? 240 : 0)
                    } label: {
                        Image(systemName: "control")
                            .font(.title)
                            .rotationEffect(.degrees(panelWidth > 60 ? 90 : -90))
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    Spacer()
                    Button {
                        notes.toggle()
                    } label: {
                        if panelWidth == 240 {
                            Image(systemName: "note.text")
                                .foregroundColor(.teal)
                                .padding([.bottom, .leading, .trailing], 6.0)
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                if panelWidth > 200 {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Geometry Information").foregroundColor(Color(UIColor.label))
                        HStack {
                            Text("Type:")
                            Text("\(displayViewModel.showInfo()!)")
                        }
                        Spacer()
                    }
                    .padding(8.0)
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $notes) {
            Text("Geometry Notes")
        }
        .frame(width: (panelWidth >= 30 ? panelWidth : 30), height: 200)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10, corners: [.topLeft, .bottomLeft])
        .cornerRadius(panelWidth > 30 ? 10 : 0, corners: [.topRight, .bottomRight])
        .padding(.horizontal, panelWidth > 30 ? 12 : 0)
        .padding(.vertical)
        .animation(.easeIn, value: panelWidth)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    panelWidth = gesture.translation.width
                }
                .onEnded { _ in
                    if panelWidth > -150 {
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
            Spacer()
            InfoPanelView()
        }
        .background(Color.gray)
    }
}
