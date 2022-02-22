//
//  MapBoxViewWrapper.swift
//  DrawBox
//
//  Created by Jenya Lebid on 12/16/21.
//

import SwiftUI
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
        print(#function)
        super.viewDidLoad()        
        let resourceOptions = ResourceOptions(accessToken: "pk.eyJ1IjoiamVueWFsZWJpZCIsImEiOiJja3Y2dDZ2cnQyZDUzMm9xMXl2enR0ODJxIn0.CADXy6tenwyGeBU9Yimv5A")
        let cameraOptions = CameraOptions(center: CLLocationCoordinate2D(latitude: 44.0582, longitude: -121.3153), zoom: 5)
        let mapOptions = MapOptions(optimizeForTerrain: true)
        let myMapInitOptions = MapInitOptions(resourceOptions: resourceOptions, mapOptions: mapOptions, cameraOptions: cameraOptions)
        viewModel.mapView = MapView(frame: view.bounds, mapInitOptions: myMapInitOptions)
        viewModel.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewModel.mapView.ornaments.options.scaleBar.margins = CGPoint(x: 42, y: 8)
//        viewModel.mapView.ornaments.options.compass.position = .topLeft
        viewModel.mapView.ornaments.options.attributionButton.position = .topLeft
        viewModel.mapView.ornaments.options.attributionButton.margins = CGPoint(x: 0, y: -12)
//        viewModel.mapView.ornaments.options.logo.margins = CGPoint(x: 42, y: 8)
        self.view.addSubview(viewModel.mapView)
        viewModel.displayBox.mapView = viewModel.mapView
        viewModel.mapView.location.options.puckType = .puck2D()
        viewModel.mapView.mapboxMap.onNext(.mapLoaded) { _ in
            self.viewModel.onMapLoaded()
        }
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.displayBox.clear()
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
}

