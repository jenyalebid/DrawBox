//
//  Turf2GEOSwift.swift
//  DrawBox
//
//  Created by mkv on 1/27/22.
//

import MapboxMaps
import GEOSwift
import SwiftUI


func convert_Turf2Geos_Feature(_ turfFeature: Turf.Feature) throws -> GEOSwift.Feature? {
    switch turfFeature.geometry {
    case .point(let point):
        return GEOSwift.Feature(geometry: GEOSwift.Geometry.point(convert_Turf2Geos_Point(point)))
    case .multiPoint(let multiPoint):
        return try GEOSwift.Feature(geometry: GEOSwift.Geometry.multiPoint(convert_Turf2Geos_MultiPoint(multiPoint)))
    case .lineString(let line):
        return try GEOSwift.Feature(geometry: GEOSwift.Geometry.lineString(convert_Turf2Geos_LineString(line)))
    case .multiLineString(let multiLine):
        return try GEOSwift.Feature(geometry: GEOSwift.Geometry.multiLineString(convert_Turf2Geos_MultiLineString(multiLine)))
    case .polygon(let polygon):
        return try GEOSwift.Feature(geometry: GEOSwift.Geometry.polygon(convert_Turf2Geos_Polygon(polygon)))
    case .multiPolygon(let multiPolygon):
        return try GEOSwift.Feature(geometry: GEOSwift.Geometry.multiPolygon(convert_Turf2Geos_MultiPolygon(multiPolygon)))
    default:
        assertionFailure()
    }
    return nil
}

private func convertCoordinateArray2GeosPointArray(_ turfPointArray: [LocationCoordinate2D]) -> [GEOSwift.Point] {
    var result: [GPoint] = []
    for turfPoint in turfPointArray {
        result.append(GPoint(x: turfPoint.longitude, y: turfPoint.latitude))
    }
    return result
}

func convert_Turf2Geos_Point(_ turfPoint: Turf.Point) -> GEOSwift.Point {
    return GEOSwift.Point(x: turfPoint.coordinates.longitude, y: turfPoint.coordinates.latitude)
}

func convert_Turf2Geos_MultiPoint(_ turfMultiPoint: Turf.MultiPoint) throws -> GEOSwift.MultiPoint {
    var geosPoints: [GEOSwift.Point] = []
    for point in turfMultiPoint.coordinates {
        let geosPoint = GEOSwift.Point(x: point.longitude, y: point.latitude)
        geosPoints.append(geosPoint)
    }
    let geosMultiPoint = GEOSwift.MultiPoint(points: geosPoints)
    return geosMultiPoint
}

func convert_Turf2Geos_LineString(_ turfLine: Turf.LineString) throws -> GEOSwift.LineString {
    return try GEOSwift.LineString(points: convertCoordinateArray2GeosPointArray(turfLine.coordinates))
}

func convert_Turf2Geos_MultiLineString(_ turfMultiLineString: Turf.MultiLineString) throws -> GEOSwift.MultiLineString {
    var geosLines: [GEOSwift.LineString] = []
    for line in turfMultiLineString.coordinates {
        do {
            let geosLine = try GEOSwift.LineString(points: convertCoordinateArray2GeosPointArray(line))            
            geosLines.append(geosLine)
        }
        catch {
            fatalError("\(error)")
        }
    }
    let geosMultiLine = GEOSwift.MultiLineString(lineStrings: geosLines)
    return geosMultiLine
}

func convert_Turf2Geos_Polygon(_ turfPolygon: Turf.Polygon) throws -> GEOSwift.Polygon {
    let exterior = try GEOSwift.Polygon.LinearRing(points: convertCoordinateArray2GeosPointArray(turfPolygon.outerRing.coordinates))
    var holes: [GEOSwift.Polygon.LinearRing] = []
    for innerRing in turfPolygon.innerRings {
        let hole = try GEOSwift.Polygon.LinearRing(points: convertCoordinateArray2GeosPointArray(innerRing.coordinates))
        holes.append(hole)
    }
    return GEOSwift.Polygon(exterior: exterior, holes: holes)
}

func convert_Turf2Geos_MultiPolygon(_ turfMultiPolygon: Turf.MultiPolygon) throws -> GEOSwift.MultiPolygon {
    var geosPolygons: [GEOSwift.Polygon] = []
    for polygon in turfMultiPolygon.polygons {
        do {
            let geosPolygon = try convert_Turf2Geos_Polygon(polygon)
            geosPolygons.append(geosPolygon)
        }
        catch {
            fatalError("\(error)")
        }
    }
    let geosMultiPolygon = GEOSwift.MultiPolygon(polygons: geosPolygons)
    return geosMultiPolygon
}

