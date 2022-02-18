//
//  MapDisplayViewModel.swift
//  DrawBox
//
//  Created by Jenya Lebid on 2/1/22.
//

import MapboxMaps

class MapDisplayViewModel: ObservableObject {
    
    var mapView: MapView!
    
    internal var cameraLocationConsumer: CameraLocationConsumer?
    
    private var moveToLocation = false
    var geometry: String?
    var drawBox: DrawBox?
    @Published var startedLocation = false
    
    init(geometry: String? = nil, drawBox: DrawBox? = nil, moveToLocation: Bool = false) {
        self.geometry = geometry
        self.drawBox = drawBox
        self.moveToLocation = moveToLocation
        
        if drawBox?.mapView != nil {
            self.mapView = drawBox?.mapView
        }
    }
    
    func onMapLoaded() {
        drawBox?.prepare()
        if geometry != nil {
            if drawBox != nil {
                showDrawnGeometry()
            } else {
                showGeometry()
            }
        }
        if moveToLocation {
            let _locationManager = CLLocationManager()
            _locationManager.requestWhenInUseAuthorization()
            _locationManager.startUpdatingLocation()
            moveCamera2Location(_locationManager.location)
//            cameraLocationConsumer = CameraLocationConsumer(mapView: mapView)
//            mapView.location.addLocationConsumer(newConsumer: cameraLocationConsumer!)
//            DispatchQueue.main.asyncAfter(deadline: .now()+1) { [weak self] in
//                if let self = self, self.cameraLocationConsumer != nil {
//                    self.mapView.location.removeLocationConsumer(consumer: self.cameraLocationConsumer!)
//                    self.cameraLocationConsumer = nil
//                }
//            }
        }
    }
    
    func moveCamera2Location(_ location: CLLocation?) {
//        print(">>>>> moveCamera2Location: \(location?.coordinate)")
        if let location = location {
            let screenPoint = mapView.mapboxMap.point(for: location.coordinate)
            if !mapView.bounds.contains(screenPoint) {
                mapView.camera.ease(to: CameraOptions(center: location.coordinate, zoom: 5),
                                    duration: 0.5,
                                    completion: { _ in
                    self.mapView.camera.ease(
                        to: CameraOptions(center: location.coordinate, zoom: 15),
                        duration: 0.5)
                })
            } else {
                mapView.camera.ease(
                    to: CameraOptions(center: location.coordinate, zoom: 15),
                    duration: 0.5)
            }
        }
    }
    
    func locationChange() {
        startedLocation.toggle()
        guard mapView != nil else { return }
        if startedLocation {
            cameraLocationConsumer = CameraLocationConsumer(mapView: mapView)
            mapView.location.addLocationConsumer(newConsumer: cameraLocationConsumer!)
        } else {
            mapView.location.removeLocationConsumer(consumer: cameraLocationConsumer!)
            cameraLocationConsumer = nil
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
        drawBox!.loadFeatures(features: features)
    }
}
