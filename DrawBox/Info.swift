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
                        self?.selectFeature(feature: firstFeature)
                    }
                    else {
                        self?.selectFeature(feature: nil)
                    }
                case .failure(_):
                    return
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
        removeSeletedFeature()
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
    
    func removeSeletedFeature() {
        selectedFeature = nil
        if isFeatureSelected {
            isFeatureSelected = false
        }
//        selectedVertex = false
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
}
