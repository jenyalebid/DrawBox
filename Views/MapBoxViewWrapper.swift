//
//  MapBoxViewWrapper.swift
//  DrawBox
//
//  Created by Jenya Lebid on 12/16/21.
//

import SwiftUI
import CoreLocation
import MapboxMaps

struct MapBoxViewWrapper: UIViewControllerRepresentable {
    var viewModel: MapDisplayViewModel
    
    func makeUIViewController(context: Context) -> MapViewController {
        return MapViewController(viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
    }
}

public class MapViewController: UIViewController {
    internal var viewModel: MapDisplayViewModel!
    
    convenience init(viewModel: MapDisplayViewModel) {
        self.init()
        self.viewModel = viewModel
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        let resourceOptions = ResourceOptions(accessToken: "pk.eyJ1IjoiamVueWFsZWJpZCIsImEiOiJja3Y2dDZ2cnQyZDUzMm9xMXl2enR0ODJxIn0.CADXy6tenwyGeBU9Yimv5A")
        let cameraOptions = CameraOptions(center: setLocation(locationManager: locationManager), zoom: 5)
        let mapOptions = MapOptions(optimizeForTerrain: true)
        let myMapInitOptions = MapInitOptions(resourceOptions: resourceOptions, mapOptions: mapOptions, cameraOptions: cameraOptions)
        viewModel.mapView = MapView(frame: view.bounds, mapInitOptions: myMapInitOptions)
        viewModel.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        viewModel.mapView.ornaments.options.scaleBar.margins = CGPoint(x: 42, y: 8)
        viewModel.mapView.ornaments.options.attributionButton.position = .topLeft
        viewModel.mapView.ornaments.options.attributionButton.margins = CGPoint(x: 0, y: -12)
        self.view.addSubview(viewModel.mapView)
        
        viewModel.displayBox.mapView = viewModel.mapView
        viewModel.mapView.location.options.puckType = .puck2D()
        viewModel.mapView.mapboxMap.onNext(.mapLoaded) { _ in
            self.viewModel.onMapLoaded()
        }
    }
    
    func geometryCenter() -> CLLocationCoordinate2D? {
        let focusFeature = viewModel.features.first
        
        switch focusFeature?.geometry {
        case .polygon(let polygon):
            return polygon.center
        default:
            return nil
        }
    }
    
    func setLocation(locationManager: CLLocationManager) -> CLLocationCoordinate2D {
        if viewModel.displayBox.zoomToFeature {
            return geometryCenter() ?? CLLocationCoordinate2D(latitude: 44.0582, longitude: -121.3153)
        }
        return locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 44.0582, longitude: -121.3153)
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.displayBox.clear()
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error Getting User Location \(error)")
    }
}

