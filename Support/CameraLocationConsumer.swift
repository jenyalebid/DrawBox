//
//  CameraLocationConsumer.swift
//  DrawBox
//
//  Created by mkv on 2/9/22.
//

import MapboxMaps


public class CameraLocationConsumer: LocationConsumer {
    weak var mapView: MapView?
    private var first = true
    
    init(mapView: MapView) {
        self.mapView = mapView
    }
    
    public func locationUpdate(newLocation: Location) {
        print(">>>>> locationUpdate: \(newLocation.coordinate)")
        if first {
            if let mapView = mapView {
                let screenPoint = mapView.mapboxMap.point(for: newLocation.coordinate)
                if !mapView.bounds.contains(screenPoint) {
                    mapView.camera.ease(to: CameraOptions(center: newLocation.coordinate, zoom: 5),
                                         duration: 0.5,
                                         completion: { _ in
                        mapView.camera.ease(
                            to: CameraOptions(center: newLocation.coordinate, zoom: 15),
                            duration: 0.5)
                    })
                } else {
                    mapView.camera.ease(
                        to: CameraOptions(center: newLocation.coordinate, zoom: 15),
                        duration: 0.5)
                }
            }
            first = false
        } else {
            mapView?.camera.ease(
                to: CameraOptions(center: newLocation.coordinate, zoom: nil),
                duration: 0.5)
        }
    }
}
