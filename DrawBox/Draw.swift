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
        makeEditSources()
        makeSelectionSource()
        gestureLong = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        gestureLong!.delegate = self
        mapView.addGestureRecognizer(gestureLong!)
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
            break
        case .dmAddHole:
            removeSupportFeatures()
            break
        case .dmCut:
            removeSupportFeatures()
            break
        case .dmUnion:
            removeSupportFeatures()
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
            break
        case .dmAddHole:
            endAddingHoles()
        case .dmCut:
            addCut()
        case .dmUnion:
            makeUnion()
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
                isVertexSelected = false
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
        case .dmAddHole:
            insideSelectedPolygon(gesture) { result in
                if result {
                    self.addLinePoint(locationCoord)
                }
                else {
                    self.showNotice = true
                }
            }
        case .dmEditAddVertex:
            addPointToSelectedFeature(locationCoord)
        case .dmCut:
            addLinePoint(locationCoord)
        case .dmUnion:
            findFeatures(gesture)
        case .dmNONE:
            break
        default:
            return
        }
    }
    
    func handleControls(control: buttonControl) {
        switch control {
        case .none:
            toastText = "Edit Mode"
            editMode = .none
            changeMode(.dmNONE)
            isVertexSelected = false
        case .addVertices:
            toastText = "Vertex Add Mode"
            changeMode(.dmEditAddVertex)
        case .deleteMode:
            toastText = "Vertex Delete Mode"
            return
        case .deleteVertex:
            deleteFeaturePoint()
            if currentMode != .dmEditAddVertex {
                editMode = .none
            }
        case .deleteFeature:
            return
        case .addHole:
            toastText = "Hole Add Mode"
            changeMode(.dmAddHole)
        case .cut:
            toastText = "Geometry Cut Mode"
            changeMode(.dmCut)
            return
        case .union:
            toastText = "Union Mode"
            changeMode(.dmUnion)
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
        if currentMode == .dmAddHole {
            addHole()
        }
    }
    
    func removeSupportFeatures() {
        isVertexSelected = false
        supportPointsArray = []
        supportPointFeatures = []
        let newFeatureCollection = FeatureCollection(features: [])
        updateMapSource(sourceID: supportPointSourceIdentifier, features: newFeatureCollection)
    }
    
    func addCut() {
        guard validateCut() else { return }
        
        let splitShapes = try! splitGeometry(feature: selectedFeature!, line: supportPointsArray)
        let idx = getFeatureIndex(feature: selectedFeature!)
        shapeFeatures.remove(at: idx)
        removeSelectedFeature()
                
        for shape in splitShapes!.geometries {
            switch shape {
            case .lineString(let line):
                var newFeature = Feature(geometry: .lineString(convert_Geos2Turf_LineString(line)))
                newFeature.properties = ["TYPE": "Line",
                                         "ID": JSONValue(UUID().uuidString)]
                updateMapLines(feature: newFeature)
            case .polygon(let polygon):
                let turfPolygon = convert_Geos2Turf_Polygon(polygon)
                var newFeature = Feature(geometry: Polygon(outerRing: turfPolygon.outerRing, innerRings: turfPolygon.innerRings))
                newFeature.properties = ["TYPE": "Polygon",
                                      "ID": JSONValue(UUID().uuidString)]
                updateMapPolygons(feature: newFeature)
            default:
                return
            }
        }
        removeSupportPoints()
        clearEditingVertex()
    }
    
    func validateCut() -> Bool {
        if !lineFeatures.isEmpty {
            lineFeatures.removeLast()
            updateMapLines()
        }
        else {
            removeSupportPoints()
            createEditingVerticies()
            return false
        }
        return true
    }

    func addHole() {
        if supportPointsArray.count < 3 { return }
        isGeometryChanged = true
        
        var points = supportPointsArray
        points.append(supportPointsArray.first!)

        let featureInfo = getAllPolygonCooordinates(feature: selectedFeature!)

        var innerRing = featureInfo.inner
        let outerRing = featureInfo.outer

        if !innerRing.isEmpty && supportPointsArray.count > 3 {
            innerRing.removeLast()
        }
        innerRing.append(points)

        var ringArray: [Ring] = []
        for array in innerRing {
            ringArray.append(Ring(coordinates: array))
        }

        let newPolygon = makeClockwise(polygon: Polygon(outerRing: Ring(coordinates: outerRing), innerRings: ringArray))
        var newFeature = Feature(geometry: newPolygon)
        newFeature.properties = ["TYPE": "Polygon",
                              "ID": JSONValue(UUID().uuidString)]
        
        shapeFeatures.remove(at: getFeatureIndex(feature: selectedFeature!))
        selectedFeature = newFeature
        updateMapPolygons(feature: newFeature)
        let newFeatureCollection = FeatureCollection(features: [selectedFeature!])
        updateMapSource(sourceID: selectedSourceIdentifier, features: newFeatureCollection)
    }
    
    
    func endAddingHoles() {
        if !lineFeatures.isEmpty {
            lineFeatures.removeLast()
            updateMapLines()
        }
        if editMode == .addHole {
            editMode = .none
        }
        removeSupportPoints()
        createEditingVerticies()
    }
    
    func makeUnion() {
        guard (selectedFeature != nil && unionFeature != nil) && (selectedFeature != unionFeature) else {
            return
        }
        if var newFeature = makeUnionFeature(feature1: selectedFeature!, feature2: unionFeature!) {
            
//            switch newFeature.geometry {
//            case .multiPolygon(let multiPolygon):
//            case .polygon()
//            }
            shapeFeatures.remove(at: getFeatureIndex(feature: selectedFeature!))
            shapeFeatures.remove(at: getFeatureIndex(feature: unionFeature!))
            newFeature.properties = ["TYPE": "Polygon",
                                  "ID": JSONValue(UUID().uuidString)]
            selectedFeature = newFeature
            unionFeature = nil
            updateMapPolygons(feature: newFeature)
            let newFeatureCollection = FeatureCollection(features: [selectedFeature!])
            updateMapSource(sourceID: selectedSourceIdentifier, features: newFeatureCollection)
            createEditingVerticies()
        }
    }
    
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
        if editMode == .addHole {
            deleteSelectedFeature()
        }
        var points = supportPointsArray
        points.append(supportPointsArray.first!)
        let polygon = makeClockwise(polygon: Polygon(outerRing: Ring(coordinates: points)))
        print(polygon.outerRing.area)
        var feature = Feature(geometry: polygon)
        feature.properties = ["TYPE": "Polygon",
                              "ID": JSONValue(UUID().uuidString)]
        shapeFeatures[shapeFeatures.count - 1] = feature
        updateMapPolygons()
        
//        if var feature = shapeFeatures.last(where: { feature in feature.properties?["TYPE"] == "temp" }) {
//            feature.properties = ["TYPE": "Polygon",
//                                  "ID": JSONValue(UUID().uuidString)]
//            shapeFeatures[shapeFeatures.count - 1] = feature
//            updateMapPolygons()
//        }
    }
    
    func makeClockwise(polygon: Polygon) -> Polygon {
        var innerRings: [Ring] = []
        var outerRing: [LocationCoordinate2D] = []
        
        if polygon.outerRing.area < 0 {
            outerRing.append(contentsOf: polygon.outerRing.coordinates.reversed())
        }
        else {
            outerRing.append(contentsOf: polygon.outerRing.coordinates)
        }
        
        for polygon in polygon.innerRings {
            if polygon.area > 0 {
                innerRings.append(Ring(coordinates: polygon.coordinates.reversed()))
            }
            else {
                innerRings.append(Ring(coordinates: polygon.coordinates))
            }
        }
        return Polygon(outerRing: Ring(coordinates: outerRing), innerRings: innerRings)
    }
        
    //MARK: - Editing
    var vertexIndex = 0
    func createEditingVerticies(feature: Feature? = nil) {
        var editingFeature = feature
        if feature == nil {
            guard selectedFeature != nil else { return }
            editingFeature = selectedFeature
            vertexIndex = 0
        }
        
        if validateGeometry() {
            switch editingFeature!.geometry {
            case .point(let point):
                var newFeature = Feature(geometry: .point(point))
                newFeature.properties = ["INDEX": JSONValue(String(0)),
                                         "CURRENT": JSONValue("0")]
                supportPointFeatures.append(newFeature)
            case .lineString(let line):
                for coord in line.coordinates {
                    var newFeature = Feature(geometry: .point(Point(coord)))
                    newFeature.properties = ["INDEX": JSONValue(String(vertexIndex)),
                                             "CURRENT": JSONValue("0")]
                    vertexIndex += 1
                    supportPointFeatures.append(newFeature)
                }
            case .polygon(let polygon):
                for coordSet in polygon.coordinates {
                    for coord in coordSet {
                        print("Shape Coord:    ", coord)
                        var newFeature = Feature(geometry: .point(Point(coord)))
                        newFeature.properties = ["INDEX": JSONValue(String(vertexIndex)),
                                                 "CURRENT": JSONValue("0")]
                        vertexIndex += 1
                        supportPointFeatures.append(newFeature)
                    }
                    vertexIndex -= 1
                    supportPointFeatures.removeLast()
                }
            case .multiPolygon(let multiPolygon):
                for polygon in multiPolygon.polygons {
                    createEditingVerticies(feature: Feature(geometry: polygon))
                }
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
            print(indx)
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
            let (vertexIndex, vertexPoint) = try findVertexOn(feature: selectedFeature!, addingPoint: locationCoord, threshold: tapAreaWidth, map: mapView)
            guard vertexPoint != nil else {
                showNotice = true
                return
            }
            updateFeature(vertexIndex: vertexIndex!, newCoord: CLLocationCoordinate2D(latitude: vertexPoint!.y, longitude: vertexPoint!.x), addingPoint: true)
        } catch {
            print("ERROR adding point: \(error)")
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
                            if self.editMode == .deleteMode {
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
            updateFeature(vertexIndex: Int(index!.rawValue as! String)!, newCoord: newCoordinate)
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
    
    func updateFeature(feature: Feature? = nil, vertexIndex: Int, newCoord: CLLocationCoordinate2D? = nil, deletingPoint: Bool = false, addingPoint: Bool = false) {
        var editingFeature = feature
        if feature == nil {
            guard selectedFeature != nil else { return }
            editingFeature = selectedFeature!
        }
        
        isGeometryChanged = true
        var newFeature: Feature?
        let idx = getFeatureIndex(feature: editingFeature!)
        
        switch editingFeature!.geometry {
        case .point:
            if deletingPoint {
                deleteSelectedFeature()
                return
            }
            else {
                newFeature = Feature(geometry: .point(Point(newCoord!)))
                newFeature!.properties = editingFeature!.properties
                pointFeatures[idx] = newFeature!
                updateMapSource(sourceID: selectedSourceIdentifier, features: FeatureCollection(features: []))
                updateMapPoints()
            }
        case .lineString:
            if let line = updateLine(feature: editingFeature!, vertexIndex: vertexIndex, newCoord: newCoord, deletingPoint: deletingPoint, addingPoint: addingPoint) {
                newFeature = Feature(geometry: line)
                newFeature!.properties = editingFeature!.properties
                lineFeatures[idx] = newFeature!
                updateMapLines()
            }
        case .polygon:
            if let polygon = updatePolygon(feature: editingFeature!, vertexIndex: vertexIndex, newCoord: newCoord, deletingPoint: deletingPoint, addingPoint: addingPoint) {
                newFeature = Feature(geometry: polygon)
                newFeature!.properties = editingFeature!.properties
                shapeFeatures[idx] = newFeature!
                updateMapPolygons()
            }
        case .multiPolygon(let multiPolygon):
            if let updatedMultiPolygon = updateMultiPolygon(multiPolygon: multiPolygon, vertexIndex: vertexIndex, newCoord: newCoord, deletingPoint: deletingPoint, addingPoint: addingPoint) {
                newFeature = Feature(geometry: updatedMultiPolygon)
                newFeature!.properties = editingFeature!.properties
                shapeFeatures[idx] = newFeature!
                updateMapPolygons()
            }
        default:
            assertionFailure()
        }

        guard newFeature != nil else { return }
        updateSelectedMapFeature(feature: newFeature!)
        
        if addingPoint {
            removeSupportPoints()
            createEditingVerticies()
        } else if !deletingPoint {
            var newSupportFeature = Feature(geometry: .point(Point(newCoord!)))
            newSupportFeature.properties = ["INDEX": JSONValue(String(vertexIndex)),
                                            "CURRENT": JSONValue("1")]
            supportPointFeatures[vertexIndex] = newSupportFeature
            updateMapSupportPoints()
        }
    }
    
    func separateMultiPolygon(multiPolygon: MultiPolygon, polygon: Polygon) -> (MultiPolygon, Polygon) {
        var polygons: [Polygon] = []
        var dePolygon: Polygon? = nil
        
        for poly in multiPolygon.polygons {
            if poly != polygon {
                polygons.append(poly)
            }
            else {
                dePolygon = poly
            }
        }
        
        return (MultiPolygon(polygons), Polygon(dePolygon!.coordinates))
    }
    
    func deletePolygonFromMultiPolygon(multiPolygon: MultiPolygon, polygon: Polygon) {
        let polygons = separateMultiPolygon(multiPolygon: multiPolygon, polygon: polygon).0
        
        // return the new polygon. Delete here is only one left?
    }
    
    func updateMultiPolygon(multiPolygon: MultiPolygon, vertexIndex: Int, newCoord: CLLocationCoordinate2D? = nil, deletingPoint: Bool = false, addingPoint: Bool = false) -> MultiPolygon? {
        var polygons: [Polygon] = []
        var vertexCount = 0
        var wasAdded = false
        var newFeature: Feature?
        
        for polygon in multiPolygon.polygons {
            let polygonVertexCount = polygonVertexCount(polygon: polygon)
            if deletingPoint && polygonVertexCount <= 3 {
                
            }
            vertexCount += polygonVertexCount
            
            if vertexCount > vertexIndex && !wasAdded {
                if let updatedPolygon = updatePolygon(feature: Feature(geometry: polygon), vertexIndex: abs(vertexCount - vertexIndex - polygonVertexCount), newCoord: newCoord, deletingPoint: deletingPoint, addingPoint: addingPoint) {
                    polygons.append(updatedPolygon)
                    wasAdded = true
                }
            }
            else {
                polygons.append(polygon)
            }
        }
        if !polygons.isEmpty {

        }
        
        return MultiPolygon(polygons)
    }
    
    
//    func deUnionFeature(feature: Feature, coordinates: [[LocationCoordinate2D]]) -> (MultiPolygon, Polygon) {
//        var polygons: [Polygon] = []
//        let dePolygon: Polygon
//
//        switch feature.geometry {
//        case .multiPolygon(let multiPolygon):
//            for polygon in multiPolygon.polygons {
//                if polygon.coordinates != coordinates {
//                    polygons.append(polygon)
//                }
//                else {
//                    dePolygon = polygon
//                }
//            }
//        default:
//            assertionFailure()
//        }
//
////        if polygons.count > 1 {
////            return (MultiPolygon(polygons), nil)
////        }
////        else {
////            return (nil, polygons.first)
////        }
//
//
//
//    }
    
//    func updatePoint(feature: Feature, vertexIndex: Int, newCoord: CLLocationCoordinate2D? = nil, deletingPoint: Bool = false, addingPoint: Bool = false) -> Point? {
//
//    }
    
    func polygonVertexCount(polygon: Polygon) -> Int {
        var count = polygon.coordinates[0].count - 1
        for ring in polygon.innerRings {
            count += ring.coordinates.count - 1
        }
        return count
    }
    
    func updateLine(feature: Feature, vertexIndex: Int, newCoord: CLLocationCoordinate2D? = nil, deletingPoint: Bool = false, addingPoint: Bool = false) -> LineString? {
        var coordArray = getCoordinates(feature: feature)
        if addingPoint {
            coordArray.insert(newCoord!, at: vertexIndex + 1)
        }
        else if deletingPoint {
            coordArray.remove(at: vertexIndex)
            if coordArray.count < 2 {
                deleteSelectedFeature()
                return nil
            }
        }
        else {
            coordArray[vertexIndex] = newCoord!
        }
        
        return LineString(coordArray)
    }
    
    func updatePolygon(feature: Feature, vertexIndex: Int, newCoord: CLLocationCoordinate2D? = nil, deletingPoint: Bool = false, addingPoint: Bool = false) -> Polygon? {
        var (modifiedArray, outerArray, innerArray, innerIndex, newIndex) = getAllPolygonCooordinates(feature: feature, index: vertexIndex)
        var coordArray = modifiedArray
        var deleteHole = false
        
        coordArray.removeLast()
        if addingPoint {
            coordArray.insert(newCoord!, at: newIndex + 1)
        }
        else if deletingPoint {
            coordArray.remove(at: newIndex)
            if coordArray.count < 3 {
                if outerArray == modifiedArray {
                    deleteSelectedFeature()
                    return nil
                }
                deleteHole = true
            }
        }
        else {
            coordArray[newIndex] = newCoord!
        }
        coordArray.append(coordArray[0])
        
        if outerArray == modifiedArray {
                outerArray = coordArray
        }
        else {
            innerArray.remove(at: innerIndex - 1)
            if !deleteHole {
                innerArray.insert(coordArray, at: innerIndex - 1)
            }
        }
        
        var ringArray: [Ring] = []
        for array in innerArray {
            ringArray.append(Ring(coordinates: array))
        }
        
        return Polygon(outerRing: Ring(coordinates: outerArray), innerRings: ringArray)
    }
    
    //MARK: - Delete
    
    func deleteSelectedFeature() {
        guard selectedFeature != nil else { return }
        isGeometryChanged = true
        editMode = .deleteFeature
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
//        case .multiPolygon(let multiPolygon):
//            return
        default:
            assertionFailure()
        }
    }
    
    func deleteFeaturePoint() {
        let index = currentVertexFeature?.properties?["INDEX"]
        if let index = index {
            isGeometryChanged = true
            removeSupportPoints()
            updateFeature(vertexIndex: Int(index!.rawValue as! String)!, deletingPoint: true)
            isVertexSelected = false
            createEditingVerticies()
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
        case .polygon, .multiPolygon:
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
        case .multiPolygon(let multiPolygon):
            for polygon in multiPolygon.polygons {
                if polygon.coordinates[0].count < 4 {
                    return false
                }
            }
            return true
        default:
            return false
        }
        clearEditingVertex()
        return false
    }
    
    func clearEditingVertex() {
        editMode = .none
        currentMode = .dmNONE
        isEditingStarted = false
        isVertexSelected = false
        removeSupportPoints()
    }
}
