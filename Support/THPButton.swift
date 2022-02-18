//
//  THPButton.swift
//  DrawBox
//
//  Created by Jenya Lebid on 1/25/22.
//

import SwiftUI

struct THPButton: ButtonStyle {
    
    @Binding var color: Color
    
    init(stateColor: Binding<Color> = .constant(.blue)) {
        _color = stateColor
    }
    
    func makeBody(configuration: Self.Configuration) -> some View {
        return configuration.label
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
            .background(color)
            .cornerRadius(5)
            .foregroundColor(Color.white)
            .scaleEffect(configuration.isPressed ? 1.03 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
