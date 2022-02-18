//
//  TrackRecorder.swift
//  DrawBox
//
//  Created by mkv on 2/2/22.
//

import CoreLocation

public class TrackRecorder: NSObject {
    
    public static var shared = TrackRecorder()
    private var _locationManager: CLLocationManager?
    var coordinates: [CLLocationCoordinate2D] = []
    var delegate: TrackRecorderDelegate?
    var isRecording = false
    var formId: String?
    
    func startRecording() {
        if _locationManager == nil {
            _locationManager = CLLocationManager()
            _locationManager?.requestAlwaysAuthorization()
            _locationManager?.delegate = self
            _locationManager?.requestLocation()
            _locationManager?.allowsBackgroundLocationUpdates = true
            _locationManager?.distanceFilter = 5
            _locationManager?.showsBackgroundLocationIndicator = true
            _locationManager?.pausesLocationUpdatesAutomatically = false
            _locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        }
        _locationManager?.startUpdatingLocation()
        isRecording = true
    }
    
    func stopRecording() {
        isRecording = false
        _locationManager?.stopUpdatingLocation()
        _locationManager = nil
    }
    
    func clearTrackCoorditates() {
        coordinates.removeAll()
    }
}

// MARK: - Location Manager Delegate

extension TrackRecorder: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation = locations.last
        if let currentCoordiante = currentLocation?.coordinate {
            print("\(currentCoordiante.latitude), \(currentCoordiante.longitude)")
            coordinates.append(currentCoordiante)
            delegate?.newCoordinate(currentCoordiante)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error) {
        print("locationManager didFailWithError: " + error.localizedDescription)
    }
}

protocol TrackRecorderDelegate {    
    func newCoordinate(_ coordinate: CLLocationCoordinate2D)
}
