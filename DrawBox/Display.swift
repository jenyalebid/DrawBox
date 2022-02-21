//
//  Display.swift
//  DrawBox
//
//  Created by Jenya Lebid on 2/16/22.
//

import Foundation
import MapboxMaps

public class DisplayBox: InitBox, UIGestureRecognizerDelegate {

    func prepare() {
        editableLayerIDs.removeAll()
        selectedFeature = nil
        isFeatureSelected = false
    }
    
    //MARK: - Make Sources
    
    func makeSelectionSource() {
        selectedSource = GeoJSONSource()
        selectedSource.data = .featureCollection(FeatureCollection(features: []))
        
        var pointLayer = CircleLayer(id: "user-select-point-layer")
        pointLayer.source = selectedSourceIdentifier
        pointLayer.circleColor = .constant(StyleColor(red: 0, green: 240, blue: 200, alpha: 1)!)
        pointLayer.circleRadius = .constant(8)
        pointLayer.filter = Exp(.eq) {
            "$type"
            "Point"
        }
        var lineLayer = LineLayer(id: "user-select-line-layer")
        lineLayer.source = selectedSourceIdentifier
        lineLayer.lineColor = .constant(StyleColor(red: 0, green: 240, blue: 200, alpha: 1)!)
        lineLayer.lineWidth = .constant(4)
        lineLayer.filter = Exp(.eq) {
            "$type"
            "LineString"
        }
        var shapeLayer = FillLayer(id: "user-select-shape-layer")
        shapeLayer.source = selectedSourceIdentifier
        shapeLayer.fillColor = .constant(StyleColor(red: 0, green: 240, blue: 200, alpha: 0.5)!) //this 0.5 alpha affect only on fill color
        shapeLayer.fillOutlineColor = .constant(StyleColor(.blue))
//        shapeLayer.fillOpacity = .constant(0.5) // this opacity makes an outline translucent as well
        shapeLayer.filter = Exp(.eq) {
            "$type"
            "Polygon"
        }
        
        try! mapView.mapboxMap.style.addSource(selectedSource, id: selectedSourceIdentifier)
        try! mapView.mapboxMap.style.addLayer(shapeLayer, layerPosition: .below("user-support-point-layer"))
        try! mapView.mapboxMap.style.addLayer(lineLayer, layerPosition: .below("user-support-point-layer"))
        try! mapView.mapboxMap.style.addLayer(pointLayer, layerPosition: .below("user-support-point-layer"))
    }

    func makeEditSources() {
        pointSource = GeoJSONSource()
        pointSource.data = .featureCollection(FeatureCollection(features: pointFeatures))
        lineSource = GeoJSONSource()
        lineSource.data = .featureCollection(FeatureCollection(features: lineFeatures))
        shapeSource = GeoJSONSource()
        shapeSource.data = .featureCollection(FeatureCollection(features: shapeFeatures))
        supportPointsSource = GeoJSONSource()
        supportPointsSource.data = .featureCollection(FeatureCollection(features: []))

        var pointLayer = CircleLayer(id: "user-point-layer")
        pointLayer.source = pointSourceIdentifier
        pointLayer.circleColor = .constant(StyleColor(.blue))
        pointLayer.circleRadius = .constant(8)
        pointLayer.circleOpacity = .constant(0.5)
        pointLayer.circleStrokeColor = .constant(StyleColor(.black))
        pointLayer.circleStrokeWidth = .constant(1)
        pointLayer.circleStrokeOpacity = .constant(1)

        var lineLayer = LineLayer(id: "user-line-layer")
        lineLayer.source = lineSourceIdentifier
        lineLayer.lineColor = .constant(StyleColor(.blue))
        lineLayer.lineWidth = .constant(2)

        var shapeLayer = FillLayer(id: "user-shape-layer")
        shapeLayer.source = shapeSourceIdentifier
        shapeLayer.fillColor = .constant(StyleColor(UIColor.blue.withAlphaComponent(0.3)))
        shapeLayer.fillOutlineColor = .constant(StyleColor(.black))
//        shapeLayer.fillOpacity = .constant(0.3)

        var supportPointLayer = CircleLayer(id: "user-support-point-layer")
        supportPointLayer.source = supportPointSourceIdentifier
        supportPointLayer.circleRadius = .constant(8)
        supportPointLayer.circleColor = .expression(Exp(.match) {
            Exp(.get) { "CURRENT" }
            "0"
            UIColor.orange
            "1"
            UIColor.red
            UIColor.green //default value - used when property["CURRENT"] is not set
        })
        
        try! mapView.mapboxMap.style.addSource(shapeSource, id: shapeSourceIdentifier)
        try! mapView.mapboxMap.style.addLayer(shapeLayer)
        try! mapView.mapboxMap.style.addSource(lineSource, id: lineSourceIdentifier)
        try! mapView.mapboxMap.style.addLayer(lineLayer)
        try! mapView.mapboxMap.style.addSource(pointSource, id: pointSourceIdentifier)
        try! mapView.mapboxMap.style.addLayer(pointLayer)
        try! mapView.mapboxMap.style.addSource(supportPointsSource, id: supportPointSourceIdentifier)
        try! mapView.mapboxMap.style.addLayer(supportPointLayer)

        editableLayerIDs.append(pointLayer.id)
        editableLayerIDs.append(lineLayer.id)
        editableLayerIDs.append(shapeLayer.id)
        supportPointLayerID = supportPointLayer.id
        
        isDrawingValid = true
    }
    
    //MARK: - Load Data
    
    func loadFeatures(features: [Feature]) {
        guard !isGeometryLoaded else { return }
        
        for feature in features {
            var newFeature = feature
            switch feature.geometry {
            case .point:
                newFeature.properties = ["TYPE": "Point", "ID": JSONValue(UUID().uuidString)]
                updateMapPoints(feature: newFeature)
            case .lineString:
                newFeature.properties = ["TYPE": "LineString", "ID": JSONValue(UUID().uuidString)]
                updateMapLines(feature: newFeature)
            case .polygon:
                newFeature.properties = ["TYPE": "Polygon", "ID": JSONValue(UUID().uuidString)]
                updateMapPolygons(feature: newFeature)
            default:
                assertionFailure()
            }
        }
        isGeometryLoaded = true
    }
    
    //MARK: - Update Map
    
    func getAllFeatures() -> [Feature] {
        var allFeatures: [Feature] = []
        allFeatures.append(contentsOf: pointFeatures)
        allFeatures.append(contentsOf: lineFeatures)
        allFeatures.append(contentsOf: shapeFeatures)
        
        return allFeatures
    }
    
    func updateMapPoints(feature: Feature? = nil) {
        if feature != nil {
            pointFeatures.append(feature!)
        }
        let newFeatureCollection = FeatureCollection(features: pointFeatures)
        updateMapSource(sourceID: pointSourceIdentifier, features: newFeatureCollection)
    }
    
    func updateMapLines(feature: Feature? = nil) {
        if feature != nil {
            lineFeatures.append(feature!)
        }
        let newFeatureCollection = FeatureCollection(features: lineFeatures)
        updateMapSource(sourceID: lineSourceIdentifier, features: newFeatureCollection)
    }
    
    func updateMapPolygons(feature: Feature? = nil) {
        if feature != nil {
            shapeFeatures.append(feature!)
        }
        let newFeatureCollection = FeatureCollection(features: shapeFeatures)
        updateMapSource(sourceID: shapeSourceIdentifier, features: newFeatureCollection)
    }
    
    func updateMapSupportPoints(feature: Feature? = nil) {
        if feature != nil {
            supportPointFeatures.append(feature!)
        }
        let newFeatureCollection = FeatureCollection(features: supportPointFeatures)
        updateMapSource(sourceID: supportPointSourceIdentifier, features: newFeatureCollection)
    }
    
    func updateMapSource(sourceID: String, features: FeatureCollection) {
        try! mapView.mapboxMap.style.updateGeoJSONSource(withId: sourceID, geoJSON: .featureCollection(features))
    }
    
    //MARK: - Interaction
    
    func handleTap(_ gesture: UIGestureRecognizer) {
        guard currentMode != .dmAddTrack else { return }
    }
}