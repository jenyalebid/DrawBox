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
    var displayBox: DisplayBox
    
    var geometry: [String?]
    var features: [Turf.Feature] = []
    
    var trackingDefault = UserDefaults.standard.object(forKey: "autoTrackUserLocation") as? Bool ?? false
    
    init(geometry: [String?] = [], drawBox: DrawBox? = nil, displayBox: DisplayBox? = nil) {
        self.geometry = geometry

        if drawBox != nil {
            self.displayBox = drawBox!
        }
        else {
            self.displayBox = displayBox!
        }
        mapView = self.displayBox.mapView
        
        if !geometry.isEmpty {
            self.makeFeatures()
        }
    }
    
    func featureSelected() -> Bool {
        return displayBox.isFeatureSelected
    }
    
    func onMapLoaded() {
        displayBox.prepare()
        if !geometry.isEmpty {
            displayBox.loadFeatures(features: features)
        }
        if trackingDefault {
            displayBox.startTacking()
        }
    }
    
    func moveToUserLocation() {
        if displayBox.locationTracking {
            displayBox.stopTracking()
        }
        else {
            displayBox.startTacking()
        }
    }
    
    func changeMapStyle(style: String) {
        UserDefaults.standard.set(style, forKey: "mapStyle")
        displayBox.changeStyle(style: style)
    }
    
    func showInfo() -> String? {
        let type = displayBox.selectedFeature!.properties!["TYPE"]!
        switch type {
        case .string(let string):
            return string
        default:
            return nil
        }
        
    }
    
    func makeFeatures() {
        for item in geometry {
            guard let wkt = item else { return }
            switch wkt.prefix(8) {
            case "POLYGON(":
                let geosGeometry = try! GPolygon(wkt: wkt)
                let turfGeometry = convert_Geos2Turf_Polygon(geosGeometry)
                features.append(Feature.init(geometry: turfGeometry))
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
        }
    }
}

//    func showGeometry() {
//        let untitSourceIdentifier = "unit-shape-source"
//        var unitSource = GeoJSONSource()
//        var geometrySingle: TGeometry?
//
//        for geometry in geometry {
//            guard let wkt = geometry else { return }
//            //        let centroid: CLLocationCoordinate2D?
//            if wkt.contains("POLYGON") {
//                if wkt.contains("MULTIPOLYGON") {
//                    let geosGeometry = try! GMultiPolygon(wkt: wkt)
//                    let turfGeometry = convert_Geos2Turf_MultiPolygon(geosGeometry)
//                    geometrySingle = Geometry(turfGeometry)
//                    unitSource.data = .feature(Feature(geometry: .multiPolygon(turfGeometry)))
//                    //                centroid = turfGeometry.polygons[0].centroid
//                } else {
//                    let geosGeometry = try! GPolygon(wkt: wkt)
//                    let turfGeometry = convert_Geos2Turf_Polygon(geosGeometry)
//                    geometrySingle = Geometry(turfGeometry)
//                    unitSource.data = .feature(Feature(geometry: .polygon(turfGeometry)))
//                    //                centroid = turfGeometry.centroid
//                }
//            } else { return }
//        }
//
//        var unitLayer = FillLayer(id: "unit-shape-layer")
//        unitLayer.source = untitSourceIdentifier
//        unitLayer.fillColor = .constant(StyleColor(red: 0, green: 255, blue: 50, alpha: 0.7)!)
//        unitLayer.fillOutlineColor = .constant(StyleColor(.blue))
//        unitLayer.fillOpacity = .constant(0.7)
//
//        try! mapView.mapboxMap.style.addSource(unitSource, id: untitSourceIdentifier)
//        try! mapView.mapboxMap.style.addLayer(unitLayer)
//
//        mapView.mapboxMap.setCamera(to: mapView.mapboxMap.camera(for: geometrySingle!, padding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), bearing: nil, pitch: nil))
//    }
