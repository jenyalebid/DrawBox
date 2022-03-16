//
//  Info.swift
//  DrawBox
//
//  Created by Jenya Lebid on 2/17/22.
//

import Foundation
import MapboxMaps

extension DisplayBox {
    
    //MARK: - Select Feature
    
    func findFeatures(_ sender: UIGestureRecognizer) {
        let tapPoint = sender.location(in: mapView)
        let tapRect = CGRect(x: tapPoint.x-tapAreaWidth/2, y: tapPoint.y-tapAreaWidth/2, width: tapAreaWidth, height: tapAreaWidth)
        mapView.mapboxMap.queryRenderedFeatures(
            in: tapRect,
            options: RenderedQueryOptions(layerIds: editableLayerIDs, filter: nil)) { [weak self] result in
                switch result {
                case .success(let queriedfeatures):
                    if let firstFeature = queriedfeatures.first?.feature {
                        if self?.currentMode == .dmUnion {
                            self?.addSelectedFeature(feature: firstFeature)
                        }
                        else {
                            self?.selectFeature(feature: firstFeature)
                        }
                    }
                    else {
                        self?.selectFeature(feature: nil)
                    }
                case .failure(_):
                    return
                }
            }
    }
    
    func insideHole(feature: Feature, tap: CGPoint) -> Bool {
        let coordinate = mapView.mapboxMap.coordinate(for: tap)
        switch feature.geometry {
        case .polygon(let polygon):
            for hole in polygon.innerRings {
                if hole.contains(coordinate) {
                    return true
                }
            }
        default:
            assertionFailure()
        }
        return false
    }

    func insideSelectedPolygon(_ sender: UIGestureRecognizer, handler: @escaping ((Bool) -> Void)) {
        let tapPoint = sender.location(in: mapView)
        let tapRect = CGRect(x: tapPoint.x-tapAreaWidth/2, y: tapPoint.y-tapAreaWidth/2, width: tapAreaWidth, height: tapAreaWidth)
        mapView.mapboxMap.queryRenderedFeatures(in: tapRect, options: RenderedQueryOptions(layerIds: ["user-select-shape-layer"], filter: nil)) { result in
            switch result {
            case .success(let queriedfeatures):
                if let selectedFeature = queriedfeatures.first?.feature {
                    if (!self.insideHole(feature: selectedFeature, tap: tapPoint)) {
                        handler(true)
                        break
                    }
                    else {
                        handler(false)
                    }
                }
                else {
                    handler(false)
                }
            case .failure(_):
                handler(false)
            }
        }
    }
    
    func selectFeature(feature: Feature?) {
        if let feature = feature {
            selectedFeature = getOriginalSelectedFeature(feature)
            guard selectedFeature != nil else { return }
            isFeatureSelected = true
            let newFeatureCollection = FeatureCollection(features: [selectedFeature!])
            updateMapSource(sourceID: selectedSourceIdentifier, features: newFeatureCollection)
            return
        }
        //clear selection in case feature == nil
        removeSupportPoints()
        removeSelectedFeature()
    }
    
    func addSelectedFeature(feature: Feature) {
        unionFeature = getOriginalSelectedFeature(feature)
        let newFeatureCollection = FeatureCollection(features: [selectedFeature!, unionFeature!])
        updateMapSource(sourceID: selectedSourceIdentifier, features: newFeatureCollection)
    }
    
    func getOriginalSelectedFeature(_ feature: Feature) -> Feature? {
        switch feature.geometry {
        case .point:
            return pointFeatures.first { $0.properties?["ID"] == feature.properties?["ID"] }
        case .lineString:
            return lineFeatures.first { $0.properties?["ID"] == feature.properties?["ID"] }
        case .polygon, .multiPolygon:
            return shapeFeatures.first { $0.properties?["ID"] == feature.properties?["ID"] }
        default:
            return nil
        }
    }
    
    func removeSelectedFeature() {
        selectedFeature = nil
        if isFeatureSelected {
            isFeatureSelected = false
        }
        let newFeatureCollection = FeatureCollection(features: [])
        updateMapSource(sourceID: selectedSourceIdentifier, features: newFeatureCollection)
    }
    
    func removeSupportPoints() {
        supportPointsArray.removeAll()
        supportPointFeatures.removeAll()
        currentVertexFeature = nil
        let newFeatureCollection = FeatureCollection(features: [])
        updateMapSource(sourceID: supportPointSourceIdentifier, features: newFeatureCollection)
    }
}

//MARK: - Gesture Manager

extension DisplayBox: GestureManagerDelegate {
    
    public func gestureManager(_ gestureManager: GestureManager, didBegin gestureType: GestureType) {
        print("\(gestureType) didBegin")
        if gestureType == .pan && locationTracking {
            stopTracking()
        }
    }
    
    public func gestureManager(_ gestureManager: GestureManager, didEnd gestureType: GestureType, willAnimate: Bool) {
        print("\(gestureType) didEnd")
        if gestureType == .singleTap {
            handleTap(gestureManager.singleTapGestureRecognizer)
        }
    }
    
    public func gestureManager(_ gestureManager: GestureManager, didEndAnimatingFor gestureType: GestureType) {
        print("didEndAnimatingFor \(gestureType)")
    }
    
    func startTacking() {
        if !locationTracking {
            locationTracking = true
            cameraLocationConsumer = CameraLocationConsumer(mapView: mapView)
            mapView.location.addLocationConsumer(newConsumer: cameraLocationConsumer!)
        }
    }
    
    func stopTracking() {
        if locationTracking {
            locationTracking = false
            mapView.location.removeLocationConsumer(consumer: cameraLocationConsumer!)
            cameraLocationConsumer = nil
        }
    }
}
