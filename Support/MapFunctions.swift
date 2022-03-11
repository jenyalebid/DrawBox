//
//  MapFunctions.swift
//  DrawBox
//
//  Created by mkv on 1/27/22.
//

import GEOSwift
import MapboxMaps
import CoreLocation


typealias GPoint = GEOSwift.Point
typealias GMultiPoint = GEOSwift.MultiPoint
typealias GLineString = GEOSwift.LineString
typealias GMultiLineString = GEOSwift.MultiLineString
typealias GPolygon = GEOSwift.Polygon
typealias GMultiPolygon = GEOSwift.MultiPolygon
typealias GGeometry = GEOSwift.Geometry

typealias TPoint = Turf.Point
typealias TMultiPoint = Turf.MultiPoint
typealias TLineString = Turf.LineString
typealias TMultiLineString = Turf.MultiLineString
typealias TPolygon = Turf.Polygon
typealias TMultiPolygon = Turf.MultiPolygon
typealias TGeometry = Turf.Geometry

func getOuterRing(feature: Turf.Feature) -> [CLLocationCoordinate2D] {
    switch feature.geometry {
    case .polygon(let polygon):
        return polygon.coordinates[0]
    default:
        assertionFailure()
    }
    return []
}

func getCoordinates(feature: Turf.Feature) -> [CLLocationCoordinate2D] {
    switch feature.geometry {
    case .point(let point):
        return [point.coordinates]
    case .lineString(let line):
        return line.coordinates
    case .polygon(let polygon):
        var coords: [CLLocationCoordinate2D] = []
        for coordSet in polygon.coordinates {
            coords.append(contentsOf: coordSet)
        }
        return coords
    default:
        assertionFailure()
    }
    return []
}

func getAllPolygonCooordinates(feature: Turf.Feature, index: Int? = nil) -> (modified: [CLLocationCoordinate2D], outer: [CLLocationCoordinate2D], inner: [[CLLocationCoordinate2D]], innerIndex: Int, newIndex: Int) {
    var modified: [CLLocationCoordinate2D] = []
    var outer: [CLLocationCoordinate2D] = []
    var inner: [[CLLocationCoordinate2D]] = []
    var localIndex = 0
    var innerIndex = 0
    var counter = 0
    var newIndex = 0
    var outSideCounter = 0
    
    switch feature.geometry {
    case .polygon(let polygon):
        outer = polygon.coordinates[0]
        for coordSet in polygon.coordinates {
            if index != nil {
                var localSet = coordSet
                localSet.removeLast()
                for _ in localSet {
                    if counter == index && modified.isEmpty {
                        modified.append(contentsOf: coordSet)
                        innerIndex = outSideCounter
                        newIndex = localIndex
                    }
                    localIndex += 1
                    counter += 1
                }
                localIndex = 0
            }
            outSideCounter += 1
            if coordSet != outer {
                inner.append(contentsOf: [coordSet])
            }
        }
    default:
        assertionFailure()
    }
    return (modified, outer, inner, innerIndex, newIndex)
}

func getPoints(feature: Turf.Feature) throws -> [[GEOSwift.Point]] {
    switch feature.geometry {
    case .point(let point):
        let coord = point.coordinates
        return [[GPoint(x: coord.longitude, y: coord.latitude)]]
    case .lineString(let line):
        return [try convert_Turf2Geos_LineString(line).points]
    case .polygon(let polygon):
        let geoPolygon = try convert_Turf2Geos_Polygon(polygon)
        var allArray: [[GEOSwift.Point]] = [geoPolygon.exterior.points]
        for hole in geoPolygon.holes {
            allArray.append(hole.points)
        }
        return allArray
    default:
        assertionFailure()
    }
    return []
}

func splitGeometry(feature: Turf.Feature, line: [CLLocationCoordinate2D]) throws -> GEOSwift.GeometryCollection? {
    let pLine = try GEOSwift.LineString(points: convertCoordinateArray2GeosPointArray(line))
    let geom = try convert_Turf2Geos_Feature(feature)?.geometry
    let newGeo = try geom?.difference(with: pLine)
    
    switch newGeo?.geometry {
    case .polygon(let polygon):
        var counter = 0
        var collection = try! polygon.boundary().union(with: pLine).polygonize()
        for geometry in collection.geometries {
            switch geometry {
            case .polygon(let cutPolygon):
                for hole in polygon.holes {
                    if hole.points.reversed() == cutPolygon.exterior.points {
                        collection.geometries.remove(at: counter)
                        counter -= 1
                    }
                }
            default:
                assertionFailure()
            }
            counter += 1
        }
        return collection
    case .lineString(let line):
        let newPolyg = try! line.boundary().union(with: pLine).polygonize()
        return newPolyg
    default:
        assertionFailure()
    }
    return nil
}

func findVertexOn(feature: Turf.Feature, addingPoint point: LocationCoordinate2D, threshold: Double, map: MapView) throws -> (Int?, GPoint?) {
    let pgeom = try GGeometry(wkt: "POINT(\(point.longitude) \(point.latitude))")
    let geom = try convert_Turf2Geos_Feature(feature)?.geometry
    let points = try pgeom.nearestPoints(with: geom!) // provided function is not working properly finding points inside polygon. TODO: make better custom function?
    guard points.count == 2 else { return (nil, nil) }
        
    // a point either on side or not to whitch will be added a new point
    // convert nearest points to position on screen
    let screenPoint0 = map.mapboxMap.point(for: CLLocationCoordinate2D(latitude: points[1].y, longitude: points[1].x))
    let screenPoint1 = map.mapboxMap.point(for: CLLocationCoordinate2D(latitude: points[0].y, longitude: points[0].x))
    // get distance between two screen points
    let d = distance(screenPoint0, screenPoint1)
    // if point is inside polygon
    if d == 0 {
        return (nil, nil)
    }
    // if distance between points is more than treshhold place point on where user clicked, else place point on slope line
    let addingToSide = d < threshold
    let vertexPoint = addingToSide ? points[1] : points[0]
    
    var minScalarProduct = Double.greatestFiniteMagnitude
    var vertexIndex = 0

    let p = points[1] //point on feature side
    
    let shapePoints = try getPoints(feature: feature)
    var arrayCount = 0
    
    for array in shapePoints {
        for i in 0..<array.count {
            let lp1 = array[i]
            let lp2 = array[i == array.count - 1 ? 0 : i + 1]
            let d = scalarProduct(fromPoint: p, lp1, lp2)
            // finding MIN near 0 value (means we are on the side of feature) AND we need the point lies between two nearby vertex
            if d < minScalarProduct && ((lp1.x <= p.x && p.x <= lp2.x) || (lp1.x >= p.x && p.x >= lp2.x))
                                    && ((lp1.y <= p.y && p.y <= lp2.y) || (lp1.y >= p.y && p.y >= lp2.y)) {
                minScalarProduct = d
                vertexIndex = i + arrayCount
                return (vertexIndex, vertexPoint)
            }
        }
        arrayCount += array.count - 1
    }
    return (nil, nil)
}

func distance(_ p1: CGPoint, _ p2: CGPoint) -> Double {
    return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2))
}

func scalarProduct(fromPoint p: GPoint, _ l1: GPoint, _ l2: GPoint) -> Double {
    return abs((p.x-l1.x)*(l2.y-l1.y) - (p.y-l1.y)*(l2.x-l1.x))
}

// Alternative
//for i in 0...array.count {
//    if i > 0 && i != array.count {
//        let s1 = Double(round(100000 * ((array[i].y - array[i - 1].y) / (array[i].x - array[i - 1].x))) / 100000)
//        let s2 = Double(round(100000 * ((points[1].y - array[i - 1].y) / (points[1].x - array[i - 1].x))) / 100000)
//        let s3 =  Double(round(100000 * ((array[i].y - points[1].y) / (array[i].x - points[1].x))) / 100000)
//
//        if s1 == s2 && s2 == s3 {
//            vertexIndex = i + arrayCount
//            return (vertexIndex, vertexPoint)
//        }
//    }
//}
//arrayCount = array.count - 1
