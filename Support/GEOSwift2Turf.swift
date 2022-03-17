//
//  GEOSwift2Turf.swift
//  DrawBox
//
//  Created by mkv on 1/13/22.
//

import MapboxMaps
import GEOSwift

private func convertGeosPointArray2CoordinateArray(_ geosPointArray: [GEOSwift.Point]) -> [LocationCoordinate2D] {
    var result: [LocationCoordinate2D] = []
    for geosPoint in geosPointArray {
        result.append(LocationCoordinate2D(latitude: geosPoint.y, longitude: geosPoint.x))
    }
    return result
}

func convertGeosToTurf(feature: GEOSwift.Feature) -> Turf.Feature? {
    switch feature.geometry {
    case .multiPolygon(let multiPolygon):
        return Turf.Feature(geometry: convert_Geos2Turf_MultiPolygon(multiPolygon))
    case .polygon(let polygon):
        return Turf.Feature(geometry: convert_Geos2Turf_Polygon(polygon))
    default:
        assertionFailure()
    }
    return nil
}

func convert_Geos2Turf_Point(_ geosPoint: GEOSwift.Point) -> Turf.Point {
    return Turf.Point(LocationCoordinate2D(latitude: geosPoint.y, longitude: geosPoint.x))
}

func convert_Geos2Turf_MultiPoint(_ geosMultiPoint: GEOSwift.MultiPoint) -> Turf.MultiPoint {
    var turfPoints: [LocationCoordinate2D] = []
    for point in geosMultiPoint.points {
        turfPoints.append(LocationCoordinate2D(latitude: point.y, longitude: point.x))
    }
    return Turf.MultiPoint.init(turfPoints)
}
func convert_Geos2Turf_LineString(_ geosLineString: GEOSwift.LineString) -> Turf.LineString {
    let turfLinePoints = convertGeosPointArray2CoordinateArray(geosLineString.points)
    return Turf.LineString(turfLinePoints)
}

func convert_Geos2Turf_MultiLineString(_ geosMultiLineString: GEOSwift.MultiLineString) -> Turf.MultiLineString {
    var turfLines: [[LocationCoordinate2D]] = []
    for geosLine in geosMultiLineString.lineStrings {
        turfLines.append(convertGeosPointArray2CoordinateArray(geosLine.points))
    }
    return Turf.MultiLineString(turfLines)
}

func convert_Geos2Turf_Polygon(_ geosPolygon: GEOSwift.Polygon) -> Turf.Polygon {
    let outerTurfRing = Turf.Ring(coordinates: convertGeosPointArray2CoordinateArray(geosPolygon.exterior.points))
    var innerTurfRings: [Turf.Ring] = []
    for holeGeosRing in geosPolygon.holes {
        let innerTurfRing = Turf.Ring(coordinates: convertGeosPointArray2CoordinateArray(holeGeosRing.points))
        innerTurfRings.append(innerTurfRing)
    }
    return Turf.Polygon(outerRing: outerTurfRing, innerRings: innerTurfRings)
}

func convert_Geos2Turf_MultiPolygon(_ geosMultiPolygon: GEOSwift.MultiPolygon) -> Turf.MultiPolygon {
    var turfPolygons: [Turf.Polygon] = []
    for geosPolygon in geosMultiPolygon.polygons {
        turfPolygons.append(convert_Geos2Turf_Polygon(geosPolygon))
    }
    return Turf.MultiPolygon(turfPolygons)
}
