//
//  DrawBoxView.swift
//  DrawBox
//
//  Created by Jenya Lebid on 12/16/21.
//

import SwiftUI

public struct DrawBoxView: View {
    
    @ObservedObject var viewModel: DrawBoxViewModel
    
    var drawType: String
    
    @Binding var geometry: String?
    @Binding var changes: Bool
    
    @State var showAlert = false
    
    public init(drawBox: DrawBox, drawType: String, geometry: Binding<String?>?, changes: Binding<Bool>) {
        self.viewModel = DrawBoxViewModel(drawBox: drawBox)
        self.drawType = drawType
        self._geometry = geometry ?? Binding.constant(nil)
        self._changes = changes
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            MapDisplayView(geometry: [geometry], drawBox: viewModel.drawBox)
            Group {
                if !viewModel.drawBox.isFeatureSelected {
                    HStack(spacing: 10) {
                        MapButton(voidAction: viewModel.editing, drawingShape: true, highlighted: viewModel.startedDrawing, label: "\(drawType)", image: "plus", showAlert: $showAlert).environmentObject(viewModel)
                    }
                    .padding()
                }
                else {
                    HStack(spacing: 10) {
                        MapButton(voidAction: viewModel.editing, highlighted: viewModel.drawBox.isEditingStarted, label: "Stop Editing", image: "square.and.pencil", showAlert: $showAlert).environmentObject(viewModel)
                        MapButton(voidAction: viewModel.delete, highlighted: viewModel.deleteType(), label: "\(viewModel.deleteText)", image: "trash", selectedColor: Color.red, showAlert: $showAlert).environmentObject(viewModel)
                        
                        if viewModel.drawBox.isEditingStarted && drawType != "Point" {
                            MapButton(voidAction: viewModel.addingVertex, highlighted: viewModel.checkControl(control: .addVertices), label: "End Vertex Adding", image: "plus", showAlert: $showAlert).environmentObject(viewModel)
                        }
                        
                        if viewModel.drawBox.isEditingStarted && drawType == "Polygon" {
                            MapButton(voidAction: viewModel.addingHole, highlighted: viewModel.checkControl(control: .addHole), label: "End Cutting", image: "scissors", showAlert: $showAlert).environmentObject(viewModel)
                        }
                    }
                    .padding()
                }
            }
            .padding(.bottom)
        }
        .onDisappear {
            viewModel.onDisappear()
            if viewModel.checkChanges() {
                geometry = viewModel.saveGeometry()
                changes = true
            }
        }
        .navigationTitle("Draw \(drawType)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MapButton: View {
    
    @EnvironmentObject var viewModel: DrawBoxViewModel
    
    let voidAction: () -> Void
    
    var drawingShape = false
    var highlighted: Bool = false
    
    let label: String
    let image: String
    
    var defaultColor: Color = Color(UIColor.systemBackground)
    var selectedColor: Color = Color.blue
    
    @Binding var showAlert: Bool
    
    var body: some View {
        Button {
            if drawingShape {
                viewModel.drawing(type: label)
            }
            else {
                voidAction()
                
            }
            if viewModel.drawBox.editMode == .deleteFeature {
                showAlert = true
            }
        } label: {
            HStack {
                if !highlighted {
                    Image(systemName: image)
                        .foregroundColor(highlighted ? Color.white : selectedColor)
                }
                if highlighted && !label.isEmpty {
                    Text("\(label)").font(.footnote).foregroundColor(Color.white)
                }
            }
        }
        .padding()
        .background(highlighted ? selectedColor : defaultColor).cornerRadius(50)
        .alert(isPresented: $showAlert) { () -> Alert in
            Alert(
                title: Text("Deleting Geometry"),
                message: Text("Are you sure?"),
                primaryButton: .destructive(Text("Delete"), action: {
                    viewModel.deleteFeature()
                }),
                secondaryButton: .cancel(Text("Cancel"), action: {
                    viewModel.drawBox.editMode = .none
                })
            )
        }
    }
    
}
