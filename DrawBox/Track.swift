//
//  Track.swift
//  DrawBox
//
//  Created by Jenya Lebid on 2/17/22.
//

import Foundation
import MapboxMaps

extension DrawBox: TrackRecorderDelegate {
    
    func newCoordinate(_ coordinate: CLLocationCoordinate2D) {
        if isDrawingValid && isDrawModeEnabled && isTrackFeatureCreated {
            supportPointsArray.append(coordinate)
            addLine()
        }
    }
    
    func createFeatureFromTrackRecorded() {
        let block: () -> Void = {
            if !TrackRecorder.shared.coordinates.isEmpty {
                self.supportPointsArray.removeAll()
                self.supportPointsArray.append(contentsOf: TrackRecorder.shared.coordinates)
                self.addLine()
            }
            self.isTrackFeatureCreated = true
        }
        if isDrawingValid {
            block()
            return
        }
        DispatchQueue.global().async {
            while !self.isDrawingValid {
                sleep(1)
                print(".......waiting for preparing of DrawBox sources.......")
            }
            DispatchQueue.main.async {
                block()
            }
        }
    }
}
