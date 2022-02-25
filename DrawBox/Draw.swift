//
//  Draw.swift
//  DrawBox
//
//  Created by Jenya Lebid on 12/20/21.
//  mkv 01/11/2022

import Foundation
import MapboxMaps

public class DrawBox: DisplayBox {
    
    override func prepare() {
        print(#function)
        mapView.gestures.delegate = self
        editableLayerIDs.removeAll()
        selectedFeature = nil
        isFeatureSelected = false
//        if isDrawModeEnabled {
            makeEditSources()
            makeSelectionSource()
            gestureLong = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            gestureLong!.delegate = self
            mapView.addGestureRecognizer(gestureLong!)
//        }
    }

    //MARK: - Draw Mode
    
    // Button tap mode switcher
    func changeMode(_ newMode: DrawMode) {
        if newMode == currentMode {
            stopDrawMode(currentMode)
        } else {
            stopDrawMode(currentMode)
            startDrawMode(newMode)
        }
    }
    
    func startDrawMode(_ newMode: DrawMode) {
    currentMode = newMode
        switch newMode {
        case .dmAddPoint:
            break
        case .dmAddLine:
            break
        case .dmAddShape:
            break
        case .dmAddTrack:
            createFeatureFromTrackRecorded()
            break
        case .dmEditAddVertex:
            isVertexAdding = true
//            setCurrentVertex(vertexFeature: nil)
            break
        case .dmNONE:
            return
        }
    }
    
    func stopDrawMode(_ mode: DrawMode) {
        switch mode {
        case .dmAddPoint:
            break
        case .dmAddLine:
            removeSupportPoints()
        case .dmAddShape:
            endAddingShape()
            removeSupportPoints()
        case .dmAddTrack:
            if isDrawingValid {
                removeSupportPoints()
                // To delete geometry on resume tracking
                // removeLines()
            }
        case .dmEditAddVertex:
            isVertexAdding = false
            break
        case .dmNONE:
            return
        }
        currentMode = .dmNONE
    }

    //MARK: - Interaction
    
    override func handleTap(_ gesture: UIGestureRecognizer) {
        guard currentMode != .dmAddTrack else { return }
        if isDrawModeEnabled {
            if currentMode != .dmNONE {
                drawModeTapHandler(gesture)
                return
            }
            if isEditingStarted {
                findEditingVertex(gesture)
                return
            }
            findFeatures(gesture)
        }
    }
    
    func drawModeTapHandler(_ gesture: UIGestureRecognizer) {
        let locationCoord = mapView.mapboxMap.coordinate(for: gesture.location(in: mapView))
        switch currentMode {
        case .dmAddPoint:
            addPoint(locationCoord)
        case .dmAddLine:
            addLinePoint(locationCoord)
        case .dmAddShape:
            addLinePoint(locationCoord)
        case .dmEditAddVertex:
            addPointToSelectedFeature(locationCoord)
        case .dmNONE:
            break
        default:
            return
        }
    }
    
    override func clear() {
        if currentMode == .dmAddShape {
            stopDrawMode(.dmAddShape)
        }
    }
    
    //MARK: - Adding
    
    func addPoint(_ locCoord: CLLocationCoordinate2D) {
        isGeometryChanged = true
        var newFeature = Feature(geometry: .point(Point(locCoord)))
        newFeature.properties = ["TYPE": "Point",
                                 "ID": JSONValue(UUID().uuidString)]
        updateMapPoints(feature: newFeature)
    }
    
    func addLinePoint(_ locCoord: CLLocationCoordinate2D) {
        var newFeature = Feature(geometry: .point(Point(locCoord)))
        newFeature.properties = ["CURRENT": JSONValue("0")]
        updateMapSupportPoints(feature: newFeature)
        supportPointsArray.append(locCoord)
        
        addLine()
    }
    
    func addLine() {
        if supportPointsArray.count < 2 { return }
        if supportPointsArray.count > 2 && !lineFeatures.isEmpty {
            lineFeatures.removeLast()
        }
        isGeometryChanged = true
        var newFeature = Feature(geometry: .lineString(LineString(supportPointsArray)))
        newFeature.properties = ["TYPE": "Line",
                                 "ID": JSONValue(UUID().uuidString)]
        updateMapLines(feature: newFeature)
        
        if currentMode == .dmAddShape {
            addShape()
        }
//        addHole()
    }
    
    // TODO: Add holes to shapes feature
//    func addHole() {
//        if supportPointsArray.count < 3 { return }
//        if supportPointsArray.count >= 4 {
//            shapeFeatures.removeAll { feature in
//                feature.properties?["TYPE"] == "temp"
//            }
//        }
//        isGeometryChanged = true
//        var points = supportPointsArray
//        points.append(supportPointsArray.first!)
//
//        let innerRing = Ring(coordinates: points)
//        let outerRing = Ring(coordinates: getFeatureCoordinates(feature: selectedFeature!)!)
//        var newFeature = Feature(geometry: .polygon(Polygon(outerRing: outerRing, innerRings: [innerRing])))
//        newFeature.properties = ["TYPE": "temp"]
//        updateMapPolygons(feature: newFeature)
//    }
//
//    func getFeatureCoordinates(feature: Feature) -> [LocationCoordinate2D]? {
////        var coordinates: [LocationCoordinate2D] = []
//
//        switch feature.geometry {
//        case .polygon(let polygon):
//            for coord in polygon.coordinates {
//                return coord
////                coordinates.append(LocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude))
//            }
//        default:
//            assertionFailure()
//        }
//        return nil
//    }
    
    func addShape() {
        if supportPointsArray.count < 3 { return }
        if supportPointsArray.count >= 4 {
            shapeFeatures.removeAll { feature in
                feature.properties?["TYPE"] == "temp"
            }
        }
        isGeometryChanged = true
        var points = supportPointsArray
        points.append(supportPointsArray.first!)
        var newFeature = Feature(geometry: .polygon(Polygon([points])))
        newFeature.properties = ["TYPE": "temp"]
        updateMapPolygons(feature: newFeature)
    }
    
    func endAddingShape() {
        if supportPointsArray.count < 2 { return }
        lineFeatures.removeLast() // clear support lines
        updateMapLines()
        if var feature = shapeFeatures.last(where: { feature in feature.properties?["TYPE"] == "temp" }) {
            feature.properties = ["TYPE": "Polygon",
                                  "ID": JSONValue(UUID().uuidString)]
            shapeFeatures[shapeFeatures.count - 1] = feature
            updateMapPolygons()
        }
    }
        
    //MARK: - Editing
    
    func createEditingVertex4SelectedFeature() {
        guard selectedFeature != nil else { return }
        if validateGeometry() {
            switch selectedFeature?.geometry {
            case .point(let point):
                var newFeature = Feature(geometry: .point(point))
                newFeature.properties = ["INDEX": JSONValue(String(0)),
                                         "CURRENT": JSONValue("0")]
                supportPointFeatures.append(newFeature)
            case .lineString(let line):
                var index: Int = 0
                for coord in line.coordinates {
                    var newFeature = Feature(geometry: .point(Point(coord)))
                    newFeature.properties = ["INDEX": JSONValue(String(index)),
                                             "CURRENT": JSONValue("0")]
                    index += 1
                    supportPointFeatures.append(newFeature)
                }
            case .polygon(let polygon):
                var index: Int = 0
                for coord in polygon.coordinates[0] {
                    var newFeature = Feature(geometry: .point(Point(coord)))
                    newFeature.properties = ["INDEX": JSONValue(String(index)),
                                             "CURRENT": JSONValue("0")]
                    index += 1
                    supportPointFeatures.append(newFeature)
                }
                supportPointFeatures.removeLast()
            default:
                return
            }
            isEditingStarted = true
        }
        updateMapSupportPoints()
    }
    
    func setCurrentVertex(vertexFeature: Feature?) {
        self.currentVertexFeature = vertexFeature
        for (indx, _) in supportPointFeatures.enumerated() {
            supportPointFeatures[indx].properties?["CURRENT"] = JSONValue("0")
        }
        if let index = vertexFeature?.properties?["INDEX"] {
            isVertexSelected = true
            let index = Int(index?.rawValue as! String)!
            supportPointFeatures[index].properties?["CURRENT"] = JSONValue("1")
        } else {
            isVertexSelected = false
        }
        updateMapSupportPoints()
    }
    
    func addPointToSelectedFeature(_ locationCoord: CLLocationCoordinate2D) {
        guard selectedFeature != nil else { return }
        do {
            let feature = selectedFeature!
            let (vertexIndex, vertexPoint) = try findVertexOn(feature: feature, addingPoint: locationCoord, threshold: tapAreaWidth, map: mapView)
            guard vertexPoint != nil else { return }
            updateSelectedFeature(vertexIndex: vertexIndex!, newCoord: CLLocationCoordinate2D(latitude: vertexPoint!.y, longitude: vertexPoint!.x), addingPoint: true)
        } catch {
            print("ERROR adding point: \(error.localizedDescription)")
        }
    }

    //MARK: - Move
        
    @objc
    func handleLongPress(_ gesture: UIGestureRecognizer) {
        guard currentMode != .dmAddTrack else { return }
        let locationCoord = mapView.mapboxMap.coordinate(for: gesture.location(in: mapView))
        print("handleLongPress: \(locationCoord)")
        if isDrawModeEnabled {
            if currentMode == .dmNONE || currentMode == .dmEditAddVertex {
                switch gesture.state {
                case .began:
                    isLongStarted = true
                    isDragViewMoved = false
                    findEditingVertex(gesture)
                    break
                case .changed:
                    moveVertex(gesture)
                    break
                case .ended:
                    isLongStarted = false
                    endVertexOffset(gesture)
                    break
                default:
                    isLongStarted = false
                    return
                }
                return
            }
        }
    }
    
    func findEditingVertex(_ sender: UIGestureRecognizer) {
        let tapPoint = sender.location(in: mapView)
        let tapRect = CGRect(x: tapPoint.x-tapAreaWidth/2, y: tapPoint.y-tapAreaWidth/2, width: tapAreaWidth, height: tapAreaWidth)
        mapView.mapboxMap.queryRenderedFeatures(
            in: tapRect,
            options: RenderedQueryOptions(layerIds: [supportPointLayerID], filter: nil)) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let queriedfeatures):
                    if let firstFeature = queriedfeatures.first?.feature {
                        self.setCurrentVertex(vertexFeature: firstFeature)
                        if self.isLongStarted {
                            self.startVertexOffset(position: tapPoint)
                        } else {
                            if self.isVertexDeleting {
                                self.deleteFeaturePoint()
                            }
                        }
                    } else { //not found - clearing
                        self.setCurrentVertex(vertexFeature: nil)
                    }
                case .failure(_):
                    return
                }
            }
    }
    
    func startVertexOffset(position: CGPoint) {
        guard currentVertexFeature != nil else { return }
        dragView = DraggableView(size: 20, position: position)
        mapView.addSubview(dragView!)
        dragView!.startDragging()
    }
    
    func moveVertex(_ sender: UIGestureRecognizer) {
        guard currentVertexFeature != nil else { return }
        let movePoint = sender.location(in: mapView)
        isDragViewMoved = true
        dragView?.position = movePoint
        //comment this to stop realtime updating feature
        let index = currentVertexFeature?.properties?["INDEX"]
        if let index = index, dragView != nil {
            let newCoordinate = mapView.mapboxMap.coordinate(for: dragView!.position)
            updateSelectedFeature(vertexIndex: Int(index!.rawValue as! String)!, newCoord: newCoordinate)
        }
        // to HERE <-
    }
    
    func endVertexOffset(_ sender: UIGestureRecognizer) {
        guard currentVertexFeature != nil else { return }
        dragView?.endDragging()
//        if isDragViewMoved {
//            let index = selectedVertexFeature?.properties?["INDEX"]
//            if let index = index {
//                let newCoordinate = mapView.mapboxMap.coordinate(for: dragView!.position)
//                updateSelectedFeature(vertexIndex: Int(index!.rawValue as! String)!, newCoord: newCoordinate)
//            }
//        } //uncomment this to finish feature modification in case non using reaeltime update
        dragView?.removeFromSuperview()
        dragView = nil
        isDragViewMoved = false
    }
    
    func updateSelectedFeature(vertexIndex: Int, newCoord: CLLocationCoordinate2D, deletingPoint: Bool = false, addingPoint: Bool = false) {
        guard selectedFeature != nil else { return }
        guard supportPointFeatures.count > vertexIndex else { return }
        
        isGeometryChanged = true
        var newFeature: Feature?
        let idx = getFeatureIndex(feature: selectedFeature!)
        switch selectedFeature!.geometry {
        case .point:
            newFeature = Feature(geometry: .point(Point(newCoord)))
            newFeature!.properties = selectedFeature!.properties
            pointFeatures[idx] = newFeature!
            updateMapSource(sourceID: selectedSourceIdentifier, features: FeatureCollection(features: []))
            updateMapPoints()
        case .lineString:
            var coordArray = getCoordinates(feature: lineFeatures[idx])
            if addingPoint {
                coordArray.insert(newCoord, at: vertexIndex+1)
            } else {
                coordArray[vertexIndex] = newCoord
            }
            newFeature = Feature(geometry: .lineString(LineString(coordArray)))
            newFeature!.properties = selectedFeature!.properties
            lineFeatures[idx] = newFeature!
            updateMapLines()
        case .polygon:
            var coordArray = getCoordinates(feature: shapeFeatures[idx])
            coordArray.removeLast()
            if addingPoint {
                coordArray.insert(newCoord, at: vertexIndex+1)
            } else {
                coordArray[vertexIndex] = newCoord
            }
            coordArray.append(coordArray[0])
            newFeature = Feature(geometry: .polygon(Polygon([coordArray])))
            newFeature!.properties = selectedFeature!.properties
            shapeFeatures[idx] = newFeature!
            updateMapPolygons()
        default:
            assertionFailure()
        }
        selectedFeature = newFeature
        let newSelectedFeatureCollection = FeatureCollection(features: [selectedFeature!])
        updateMapSource(sourceID: selectedSourceIdentifier, features: newSelectedFeatureCollection)
        
        if addingPoint {
            removeSupportPoints()
            createEditingVertex4SelectedFeature()
        } else {
            var newSupportFeature = Feature(geometry: .point(Point(newCoord)))
            newSupportFeature.properties = ["INDEX": JSONValue(String(vertexIndex)),
                                            "CURRENT": JSONValue("1")]
            supportPointFeatures[vertexIndex] = newSupportFeature
            updateMapSupportPoints()
        }
    }
    
    //MARK: - Delete
    
    func deleteSelectedFeature() {
        guard selectedFeature != nil else { return }
        isGeometryChanged = true
        isFeatureDeleting = true
        let idx = getFeatureIndex(feature: selectedFeature!)
        switch selectedFeature?.geometry {
        case .point:
            pointFeatures.remove(at: idx)
            selectFeature(feature: nil)
            updateMapPoints()
            clearEditingVertex()
            return
        case .lineString:
            lineFeatures.remove(at: idx)
            selectFeature(feature: nil)
            updateMapLines()
            clearEditingVertex()
            return
        case .polygon:
            shapeFeatures.remove(at: idx)
            selectFeature(feature: nil)
            updateMapPolygons()
            clearEditingVertex()
            return
        default:
            assertionFailure()
        }
    }
    
    func deleteFeaturePoint() {
        let index = currentVertexFeature?.properties?["INDEX"]
        if let index = index {
            isGeometryChanged = true
            let removeIndex = Int(index!.rawValue as! String)!
            removeSupportPoints()
            var newFeature: Feature?
            let idx = getFeatureIndex(feature: selectedFeature!)
            switch selectedFeature!.geometry {
            case .point:
                pointFeatures.remove(at: idx)
                selectedFeature = nil
                selectFeature(feature: nil)
                updateMapPoints()
                clearEditingVertex()
                return
            case .lineString:
                var coordArray = getCoordinates(feature: lineFeatures[idx])
                coordArray.remove(at: removeIndex)
                if coordArray.count < 2 {
                    deleteSelectedFeature()
                    return
                }
                newFeature = Feature(geometry: .lineString(LineString(coordArray)))
                newFeature!.properties = selectedFeature!.properties
                lineFeatures[idx] = newFeature!
                updateMapLines()
            case .polygon:
                var coordArray = getCoordinates(feature: shapeFeatures[idx])
                coordArray.removeLast()
                coordArray.remove(at: removeIndex)
                coordArray.append(coordArray[0])
                if coordArray.count < 4 {
                    deleteSelectedFeature()
                    return
                }
                newFeature = Feature(geometry: .polygon(Polygon([coordArray])))
                newFeature!.properties = selectedFeature!.properties
                shapeFeatures[idx] = newFeature!
                updateMapPolygons()
            default:
                assertionFailure()
            }
            
            selectedFeature = newFeature
            let newSelectedFeatureCollection = FeatureCollection(features: [selectedFeature!])
            updateMapSource(sourceID: selectedSourceIdentifier, features: newSelectedFeatureCollection)
            
            isVertexSelected = false
            createEditingVertex4SelectedFeature()
        }
    }
    
    func deleteFeatureType(type: DrawMode) {
        switch type {
        case .dmAddLine:
            selectFeature(feature: nil)
            removeLines()
            clearEditingVertex()
        default:
            return
        }
    }
    
    func removeLines() {
        isGeometryChanged = true
        lineFeatures.removeAll()
        let newFeatureCollection = FeatureCollection(features: [])
        updateMapSource(sourceID: lineSourceIdentifier, features: newFeatureCollection)
    }
    
    //MARK: - Support Functions
    
    func getFeatureIndex(feature: Feature) -> Int {
        switch feature.geometry {
        case .point:
            return pointFeatures.firstIndex(where: {feature.properties?["ID"] == $0.properties?["ID"] })!
        case .lineString:
            return lineFeatures.firstIndex(where: {feature.properties?["ID"] == $0.properties?["ID"] })!
        case .polygon:
            return shapeFeatures.firstIndex(where: {feature.properties!["ID"] == $0.properties!["ID"] })!
        default:
            assertionFailure()
        }
        return -1
    }
    
    func validateGeometry() -> Bool {
        guard selectedFeature != nil else { return false }
        
        switch selectedFeature?.geometry {
        case .point(_):
            return true
        case .lineString(let line):
            if line.coordinates.count >= 2 {
                return true
            }
        case .polygon(let polygon):
            if polygon.coordinates[0].count >= 4 {
                return true
            }
        default:
            return false
        }
        
        clearEditingVertex()
        return false
    }
    
    func clearEditingVertex() {
//        isFeatureSelected = false
        isVertexDeleting = false
        isVertexSelected = false
        isEditingStarted = false
        isFeatureDeleting = false
        removeSupportPoints()
    }
}
