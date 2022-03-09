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
        ZStack(alignment: .bottomLeading) {
            MapDisplayView(geometry: [geometry], drawBox: viewModel.drawBox)
            VStack {
                if viewModel.drawBox.showNotice {
                    NoticeBar(text: "Cannot Add Vertex Inside Polygon", duration: 1, isShowing: $viewModel.drawBox.showNotice)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                Spacer()
                ZStack(alignment: .bottom) {
                    NoticeBar(text: viewModel.drawBox.toastText, persistant: true, customOpacity: 0.75, isShowing: $viewModel.drawBox.isEditingStarted)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Group {
                        if !viewModel.drawBox.isFeatureSelected {
                            addButton
                        }
                        else {
                            withAnimation {
                                editButtons
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 24.0)
                }
            }
            
            
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
    
    private var editButtons: some View {
        VStack(alignment: .leading, spacing: 10) {
            if viewModel.drawBox.isEditingStarted && drawType == "Polygon" {
                MapButton(voidAction: viewModel.addingHole, highlighted: viewModel.checkControl(control: .addHole), label: "End Cutting", image: "scissors", showAlert: $showAlert).environmentObject(viewModel)
            }
            if viewModel.drawBox.isEditingStarted && drawType != "Point" {
                MapButton(voidAction: viewModel.addingVertex, highlighted: viewModel.checkControl(control: .addVertices), label: "End Vertex Adding", image: "plus", showAlert: $showAlert).environmentObject(viewModel)
            }
            MapButton(voidAction: viewModel.delete, highlighted: viewModel.deleteType(), label: "\(viewModel.deleteText)", image: "trash", selectedColor: Color.red, showAlert: $showAlert).environmentObject(viewModel)
            MapButton(voidAction: viewModel.editing, highlighted: viewModel.drawBox.isEditingStarted, label: "Stop Editing", image: "square.and.pencil", showAlert: $showAlert).environmentObject(viewModel)
        }
        .padding()
    }
    
    private var addButton: some View {
        MapButton(voidAction: viewModel.editing, drawingShape: true, highlighted: viewModel.startedDrawing, label: "End \(drawType)", image: "plus", drawType: "\(drawType)", showAlert: $showAlert).environmentObject(viewModel)
            .padding()
    }
}

private struct MapButton: View {
    
    @EnvironmentObject var viewModel: DrawBoxViewModel
    
    let voidAction: () -> Void
    
    var drawingShape = false
    var highlighted = false
    
    let label: String
    let image: String
    
    var defaultColor: Color = Color(UIColor.systemBackground)
    var selectedColor: Color = Color.blue
    var drawType: String = ""
    
    @Binding var showAlert: Bool
    
    var body: some View {
        Button {
            if drawingShape {
                withAnimation {
                    viewModel.drawing(type: drawType)
                }
            }
            else {
                withAnimation {
                    voidAction()
                }
            }
            if viewModel.drawBox.editMode == .deleteFeature {
                showAlert = true
            }
        } label: {
            Image(systemName: image)
                .foregroundColor(highlighted ? Color.white : selectedColor)
        }
        .frame(minWidth: 25, idealHeight: 25, maxHeight: 25)
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

struct NoticeBar: View {
    
    var text: String
    var duration: Double = 1
    var persistant = false
    var customOpacity: Double?
    
    @State var opacity = 1.0
    @Binding var isShowing: Bool
    
    
    var body: some View {
        if isShowing {
            ZStack {
                Text("\(text)")
                    .foregroundColor(Color(UIColor.label))
                    .font(.caption)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(50)
            .padding()
            .opacity((customOpacity == nil ? opacity : customOpacity)!)
            .onAppear {
                if !persistant {
                    Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { timer in
                        withAnimation {
                            opacity = 0
                            isShowing = false
                        }
                        timer.invalidate()
                    }
                }
            }
        }
    }
}
