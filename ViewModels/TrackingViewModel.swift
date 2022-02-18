//
//  TrackingViewModel.swift
//  DrawBox
//
//  Created by Jenya Lebid on 2/1/22.
//

import MapboxMaps
import GEOSwift
import SwiftUI

class TrackingViewModel: ObservableObject {

    @Published var startedTracking = false
    @Published var showModal = false

    var drawBox = DrawBox()
    var formId: String
    var geometry: String?

    init(geometry: String? = nil, formId: String) {
        self.geometry = geometry
        self.formId = formId
        self.drawBox.isDrawModeEnabled = true
        self.startedTracking = (TrackRecorder.shared.isRecording && TrackRecorder.shared.formId == formId)
    }

    func buttonText() -> (text: String, color: Color) {
        if !showModal && startedTracking && !trackingElsewhere() {
            return ("Tracking in Progress", Color.red)
        }
        if !showModal && trackingElsewhere() {
            return ("Tracking Already Active", Color.gray)
        }
        if !showModal && !startedTracking && (geometry != nil || getRecordedTrack() != nil)  && !trackingElsewhere() {
            return ("Continue Tracking", Color.blue)
        }
        if startedTracking || showModal {
            return ("Stop Tracking", Color.red)
        }
        return ("Start Tracking", Color.blue)
    }


    func invalidateDrawing() {
        drawBox.isDrawingValid = false
        TrackRecorder.shared.delegate = nil
    }

    func trackingElsewhere() -> Bool {
        if TrackRecorder.shared.formId != nil && TrackRecorder.shared.formId != formId {
            return true
        }
        return false
    }

    func cleanTracking() {
        TrackRecorder.shared.formId = nil
        TrackRecorder.shared.delegate = nil
        TrackRecorder.shared.stopRecording()
        drawBox.stopDrawMode(.dmAddTrack)
        TrackRecorder.shared.clearTrackCoorditates()
        showModal.toggle()
    }

    func deleteFeature() {
        drawBox.deleteFeatureType(type: .dmAddLine)
        TrackRecorder.shared.clearTrackCoorditates()
    }

    func trackingChanged() {
        if startedTracking {
            drawBox.startDrawMode(.dmAddTrack)
            TrackRecorder.shared.formId = formId
            TrackRecorder.shared.delegate = drawBox
            TrackRecorder.shared.startRecording()
        } else {
            cleanTracking()
        }
    }

    func getRecordedTrack() -> String? {
        let features = drawBox.getAllFeatures()
        var lines: [[LocationCoordinate2D]] = []

        for feature in features {
            switch feature.geometry {
            case .lineString(let line):
                lines.append(line.coordinates)
            default:
                return nil
            }
        }
        do {
            if !lines.isEmpty {
                let geosMultiLine = try convert_Turf2Geos_MultiLineString(Turf.MultiLineString.init(lines))
                let wkt = try geosMultiLine.wkt(trim: true, roundingPrecision: 14)
                return wkt
            }
        }
        catch {
            fatalError("\(error)")
        }
        return nil
    }
}
