//
//  DrawBoxViewModel.swift
//  DrawBox
//
//  Created by Jenya Lebid on 1/18/22.
//

import MapboxMaps

class DrawBoxViewModel: ObservableObject {
    
    @Published var drawBox: DrawBox
    
    @Published var startedDrawing = false
    @Published var location = false
        
    var deleteText: String = ""
    var editMode = DrawBox.buttonControl.none
    
    init(drawBox: DrawBox) {
        self.drawBox = drawBox
        self.startedDrawing = drawBox.currentMode != .dmNONE
        self.drawBox.isDrawModeEnabled = true
        self.editMode = drawBox.editMode
    }
    
    func onDisappear() {
        drawBox.clear()
    }

    func checkChanges() -> Bool {
        return drawBox.isGeometryChanged
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
    
    func showNotice() {
        
    }
    
    func toggleControl(control: DrawBox.buttonControl) {
        if drawBox.editMode == control {
            drawBox.editMode = .none
        }
        else {
            drawBox.editMode = control
        }
        drawBox.changeMode(.dmNONE)
        drawBox.handleControls(control: drawBox.editMode)
    }
    
    func checkControl(control: DrawBox.buttonControl) -> Bool {
        if drawBox.editMode == control {
            return true
        }
        return false
    }
    
    func editing() {
        drawBox.isEditingStarted.toggle()
        if drawBox.isEditingStarted {
            drawBox.createEditingVertex4SelectedFeature()
        } else {
            drawBox.clearEditingVertex()
        }
    }
    
    func addingVertex() {
        toggleControl(control: .addVertices)
    }
    
    func addingHole() {
        toggleControl(control: .addHole)
    }
    
    func deleteFeature() {
        drawBox.deleteSelectedFeature()
    }
    
    func delete() {
        if !drawBox.isVertexSelected && drawBox.isEditingStarted {
            toggleControl(control: .deleteMode)
        }
        else if drawBox.isVertexSelected {
            toggleControl(control: .deleteVertex)
        }
        else if drawBox.isFeatureSelected && !drawBox.isEditingStarted  {
            toggleControl(control: .deleteFeature)
        }
        else {
            toggleControl(control: .none)
        }
    }
    
    func deleteType() -> Bool {
        if drawBox.isVertexSelected {
            deleteText = "Delete Vertex"
            return true
        }
        else if drawBox.editMode == .deleteMode {
            deleteText = "Vertex Delete Mode"
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
