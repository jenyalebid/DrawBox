//
//  TrackingView.swift
//  DrawBox
//
//  Created by Jenya Lebid on 1/4/22.
//

import SwiftUI

public struct TrackingView: View {

    @ObservedObject var viewModel: TrackingViewModel
    
    @State var showAlert = false
    @State var showDeleteAlert = false
    @State var buttonColor = Color.blue
    @State var buttonText = "Start Tracking"

    var formId: String
    var geometry: String?

    public init(geometry: String? = nil, formId: String) {
        self.formId = formId
        viewModel = TrackingViewModel(geometry: geometry, formId: formId)
    }

    public var body: some View {
        VStack {
            Button {
                if !viewModel.trackingElsewhere() {
                    viewModel.showModal.toggle()
                }
                else {
                    showAlert = true
                }
            } label: {
                Text(buttonText)
            }
            .onAppear {
                viewModel.startedTracking = (TrackRecorder.shared.isRecording && TrackRecorder.shared.formId == formId)
                buttonText = viewModel.buttonText().text
                buttonColor = viewModel.buttonText().color
            }
            .padding()
            .buttonStyle(THPButton(stateColor: $buttonColor))
            .alert(isPresented: $showAlert) { () -> Alert in
                Alert(
                    title: Text("Tracking In Progress"),
                    message: Text("There is already an active track, continuing will delete current data."),
                    primaryButton: .destructive(Text("Continue"), action: {
                        viewModel.cleanTracking()
                    }),
                    secondaryButton: .cancel(Text("Cancel"), action: {
                        return
                    })
                )
            }
        }
        .onChange(of: viewModel.showModal) { _ in
            buttonText = viewModel.buttonText().text
            buttonColor = viewModel.buttonText().color
        }
        .sheet(isPresented: $viewModel.showModal) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button {
                        viewModel.showModal.toggle()
                    } label: {
                        Image(systemName: "xmark")
                            .padding()
                    }
                    Spacer()
                    Button {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash").foregroundColor(.red)
                            .padding()
                    }
                    .alert(isPresented: $showDeleteAlert) { () -> Alert in
                        Alert(
                            title: Text("Delete Tracking Data?"),
                            message: Text("This will delete all tracking lines on map."),
                            primaryButton: .destructive(Text("Continue"), action: {
                                viewModel.deleteFeature()
                            }),
                            secondaryButton: .cancel(Text("Cancel"), action: {
                                return
                            })
                        )
                    }
                }
                MapDisplayView(geometry: geometry, drawBox: viewModel.drawBox, moveToLocation: true)
                    .onAppear {
                        viewModel.startedTracking = true
                        viewModel.trackingChanged()
                    }
                    .onDisappear {
                        viewModel.invalidateDrawing()
                    }

                Button {
                    viewModel.startedTracking = false
                    viewModel.trackingChanged()
//                    formViewModel.field.geometry = viewModel.getRecordedTrack()
//
//                    DispatchQueue.main.async {
//                        formViewModel.save(managedObjectContext: Database.shared._mainContext)
//                        form.edited = true
//                    }
                } label: {
                    Text(viewModel.buttonText().text)
                }
                .padding()
                .buttonStyle(THPButton(stateColor: $buttonColor))
            }

        }
    }
}
