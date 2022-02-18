//
//  DrawBoxViewModel.swift
//  DrawBox
//
//  Created by Jenya Lebid on 1/18/22.
//

import MapboxMaps

class DrawBoxViewModel: ObservableObject {
    
    @Published var drawBox = DrawBox()
    
    @Published var startedDrawing = false
    @Published var startedEditing = false
    @Published var startedAdding = false
    @Published var vertexSelected = false
    @Published var deleteVertices = false
    @Published var showAlert = false
    
    
    var deleteText: String = ""
    
    var currentButtonMode = buttonControl.none
    
    enum buttonControl: Int {
        case none = 0
        case addVertices = 1
        case deleteMode  = 2
        case deleteVertex = 3
        case deleteFeature = 4
    }
    
    init() {
        self.drawBox.isDrawModeEnabled = true
        self.vertexSelected = drawBox.isVertexSelected
        self.startedEditing = drawBox.isEditModeEnabled
        self.deleteVertices = drawBox.removeVertices
        self.showAlert = drawBox.deletingFeature
        
        if deleteVertices {
            currentButtonMode = .deleteMode
        }
    }
    
    func onDisappear() {
        drawBox.clear()
    }

    func handleButtons(clickType: buttonControl) {
        switch clickType {
        case .none:
            drawBox.removeVertices = false
            clearButtonSelection()
            currentButtonMode = .none
        case .addVertices:
            clearButtonSelection()
            drawBox.changeMode(.dmEditAddVertex)
            startedAdding = true
            currentButtonMode = .addVertices
        case .deleteMode:
            clearButtonSelection()
            drawBox.removeVertices = true
            deleteVertices = true
            currentButtonMode = .deleteMode
        case .deleteVertex:
            clearButtonSelection()
            drawBox.deleteFeaturePoint()
            currentButtonMode = .deleteVertex
        case .deleteFeature:
            showAlert = true
        }
    }
    
    func checkChanges() -> Bool {
        return drawBox.isGeometryChanged
    }
    
    func clearButtonSelection() {
        drawBox.changeMode(.dmNONE)
        startedAdding = false
        vertexSelected = false
        deleteVertices = false
    }
    
    func drawing(type: String) {
        switch type {
        case "Point":
            startedDrawing.toggle()
            drawBox.changeMode(.dmAddPoint)
        case "Line":
            startedDrawing.toggle()
            drawBox.changeMode(.dmAddLine)
        case "Polygon":
            startedDrawing.toggle()
            drawBox.changeMode(.dmAddShape)
        default:
            return
        }
    }
    
    func editing() {
        startedEditing.toggle()
        if startedEditing {
            drawBox.createEditingVertex4SelectedFeature()
        } else {
            drawBox.clearEditingVertex()
        }
    }
    
    func addingVertex() {
        if currentButtonMode != .addVertices {
            handleButtons(clickType: .addVertices)
        }
        else {
            handleButtons(clickType: .none)
        }
    }
    
    func deleteFeature() {
        drawBox.deleteSelectedFeature()
        showAlert = false
    }
    
    func delete() {
        if currentButtonMode != .deleteMode && !vertexSelected && startedEditing {
            handleButtons(clickType: .deleteMode)
        }
        else if vertexSelected {
            handleButtons(clickType: .deleteVertex)
        }
        else if drawBox.isFeatureSelected && !startedEditing  {
            handleButtons(clickType: .deleteFeature)
        }
        else {
            handleButtons(clickType: .none)
        }
    }
    
    func deleteType() -> Bool {
        if vertexSelected {
            drawBox.changeMode(.dmNONE)
            deleteText = "Delete Vertex"
            return true
        }
        else if deleteVertices {
            deleteText = "Delete Mode"
            return true
        }
        return false
    }
    
    func saveGeometry() -> String? {
        let features = drawBox.getAllFeatures()
        
        var points: [LocationCoordinate2D] = []
        var lines: [[LocationCoordinate2D]] = []
        var polygons: [Turf.Polygon] = []
        
        for feature in features {
            switch feature.geometry {
            case .point(let point):
                points.append(point.coordinates)
            case .lineString(let line):
                lines.append(line.coordinates)
            case.polygon(let polygon):
                polygons.append(polygon)
            default:
                return nil
            }
        }
        
        do {
            if !points.isEmpty {
                let geosMultiPoint = try convert_Turf2Geos_MultiPoint(Turf.MultiPoint.init(points))
                let wkt = try geosMultiPoint.wkt(trim: true, roundingPrecision: 14)
                return wkt
            }
            else if !lines.isEmpty {
                let geosMultiLine = try convert_Turf2Geos_MultiLineString(Turf.MultiLineString.init(lines))
                let wkt = try geosMultiLine.wkt(trim: true, roundingPrecision: 14)
                return wkt
            }
            else if !polygons.isEmpty {
                let geosMultiPolygon = try convert_Turf2Geos_MultiPolygon(Turf.MultiPolygon.init(polygons))
                let wkt = try geosMultiPolygon.wkt(trim: true, roundingPrecision: 14)
                return wkt
            }
        }
        catch {
            fatalError("\(error)")
        }
        
        return nil
    }
}
