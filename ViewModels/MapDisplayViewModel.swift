//
//  MapDisplayViewModel.swift
//  DrawBox
//
//  Created by Jenya Lebid on 2/1/22.
//

import MapboxMaps
import Combine

class MapDisplayViewModel: ObservableObject {
    
    var mapView: MapView!
    var geometry: String?
    
    @Published var displayBox: DisplayBox
    
    private var cancellables = Set<AnyCancellable>()
    
    init(geometry: String? = nil, drawBox: DrawBox? = nil, displayBox: DisplayBox? = nil) {
        self.geometry = geometry
        
        if drawBox != nil {
            self.displayBox = drawBox!
            
            drawBox!.objectWillChange
                .sink(receiveValue: { self.objectWillChange.send() })
                .store(in: &cancellables)
        }
        else {
            self.displayBox = displayBox!
            self.displayBox.objectWillChange
                .sink(receiveValue: { self.objectWillChange.send() })
                .store(in: &cancellables)
        }
        
        mapView = self.displayBox.mapView
    }

    func featureSelected() -> Bool {
        return displayBox.isFeatureSelected
    }
    
    func onMapLoaded() {
        displayBox.prepare()
        if geometry != nil {
            if displayBox is DrawBox {
                showDrawnGeometry()
            } else {
                showGeometry()
            }
        }
    }
    
//    func moveCameraToCurrentLocation() {
//        let _locationManager = CLLocationManager()
//        _locationManager.requestWhenInUseAuthorization()
//        _locationManager.startUpdatingLocation()
//        moveCameraToLocation(_locationManager.location)
//    }
//
//    func moveCameraToLocation(_ location: CLLocation?) {
//        if let location = location {
//            mapView.camera.ease(
//                to: CameraOptions(center: location.coordinate, zoom: 15),
//                duration: 0.5)
//        }
//    }
    
//    func toggleTracking() {
//        if !displayBox.locationTracking {
//
//        }
//        else {
//            displayBox.locationTracking = false
//            mapView.location.removeLocationConsumer(consumer: displayBox.cameraLocationConsumer!)
//            displayBox.cameraLocationConsumer = nil
//        }
//    }
    

    func moveToUserLocation() {
        if displayBox.locationTracking {
            displayBox.stopTracking()
        }
        else {
            displayBox.startTacking()
        }
    }
    
    func showGeometry() {
        let untitSourceIdentifier = "unit-shape-source"
        var unitSource = GeoJSONSource()
        guard let wkt = geometry else { return }
        //        let centroid: CLLocationCoordinate2D?
        var geometry: TGeometry
        if wkt.contains("POLYGON") {
            if wkt.contains("MULTIPOLYGON") {
                let geosGeometry = try! GMultiPolygon(wkt: wkt)
                let turfGeometry = convert_Geos2Turf_MultiPolygon(geosGeometry)
                geometry = Geometry(turfGeometry)
                unitSource.data = .feature(Feature(geometry: .multiPolygon(turfGeometry)))
                //                centroid = turfGeometry.polygons[0].centroid
            } else {
                let geosGeometry = try! GPolygon(wkt: wkt)
                let turfGeometry = convert_Geos2Turf_Polygon(geosGeometry)
                geometry = Geometry(turfGeometry)
                unitSource.data = .feature(Feature(geometry: .polygon(turfGeometry)))
                //                centroid = turfGeometry.centroid
            }
        } else { return }
        
        var unitLayer = FillLayer(id: "unit-shape-layer")
        unitLayer.source = untitSourceIdentifier
        unitLayer.fillColor = .constant(StyleColor(red: 0, green: 255, blue: 50, alpha: 0.7)!)
        unitLayer.fillOutlineColor = .constant(StyleColor(.blue))
        unitLayer.fillOpacity = .constant(0.7)
        
        try! mapView.mapboxMap.style.addSource(unitSource, id: untitSourceIdentifier)
        try! mapView.mapboxMap.style.addLayer(unitLayer)
        
        mapView.mapboxMap.setCamera(to: mapView.mapboxMap.camera(for: geometry, padding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), bearing: nil, pitch: nil))
    }
    
    func showDrawnGeometry() {
        guard let wkt = geometry else { return }
        var features: [Turf.Feature] = []
        
        switch wkt.prefix(8) {
        case "MULTIPOL":
            let geosGeometry = try! GMultiPolygon(wkt: wkt)
            let turfGeometry = convert_Geos2Turf_MultiPolygon(geosGeometry)
            for polygon in turfGeometry.polygons {
                features.append(Feature.init(geometry: polygon))
            }
        case "MULTILIN":
            let geosGeometry = try! GMultiLineString(wkt: wkt)
            let turfGeometry = convert_Geos2Turf_MultiLineString(geosGeometry)
            for line in turfGeometry.coordinates {
                let turfLine = Turf.LineString.init(line)
                features.append(Feature.init(geometry: turfLine))
            }
        case "MULTIPOI":
            let geosGeometry = try! GMultiPoint(wkt: wkt)
            let turfGeometry = convert_Geos2Turf_MultiPoint(geosGeometry)
            for point in turfGeometry.coordinates {
                let turfPoint = Turf.Point.init(point)
                features.append(Feature.init(geometry: turfPoint))
            }
        default:
            assertionFailure()
        }
        displayBox.loadFeatures(features: features)
    }
}
