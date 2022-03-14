//
//  Init.swift
//  DrawBox
//
//  Created by Jenya Lebid on 2/17/22.
//

import MapboxMaps
import Combine

enum DrawMode: Int {
    case dmNONE = 0
    case dmAddPoint = 1
    case dmAddLine = 2
    case dmAddShape = 3
    case dmAddTrack = 4
    case dmEditAddVertex = 11
    case dmAddHole = 5
    case dmCut = 6
    case dmUnion = 7
}

public class InitBox: NSObject, ObservableObject {
    
    weak var mapView: MapView!
    
    @Published var isFeatureSelected = false
    @Published var isEditingStarted = false
    @Published var isVertexSelected = false
    
    @Published var showNotice = false
    @Published var toastText = "Edit Mode"

    
    enum buttonControl: Int {
        case none = 0
        case addVertices = 1
        case addHole = 2
        case deleteMode = 3
        case deleteVertex = 4
        case deleteFeature = 5
        case cut = 6
        case union = 7
    }
    
    @Published var editMode = buttonControl.none
    
    public var zoomToFeature = false
    
    @Published var locationTracking = false
    var cameraLocationConsumer: CameraLocationConsumer?
    
    //MARK: Helper Variables
    internal var currentMode = DrawMode.dmNONE
    var isDrawModeEnabled = false
    var isDrawingValid = false
    var isMapViewOpen = false
    var isTrackFeatureCreated = false
    var isGeometryChanged = false
    var isGeometryLoaded = false
    internal var isLongStarted: Bool = false
    
    
    internal let tapAreaWidth = 20.0 // width of area under finger while finding features and annotationns on gestures processing
    internal var gestureLong: UILongPressGestureRecognizer?
        
    //MARK: - ____________FEATURES, SELECTION data storage
    
    var pointSource: GeoJSONSource!
    var lineSource: GeoJSONSource!
    var shapeSource: GeoJSONSource!
    
    internal var selectedSource: GeoJSONSource!
    internal var supportPointsSource: GeoJSONSource!
    
    let pointSourceIdentifier = "user-point-source"
    let lineSourceIdentifier = "user-line-source"
    internal let shapeSourceIdentifier = "user-shape-source"
    
    internal let selectedSourceIdentifier = "user-selected-source"
    internal let supportPointSourceIdentifier = "user-support-point-source"
    
    internal var pointFeatures: [Feature] = []
    internal var lineFeatures: [Feature] = []
    var shapeFeatures: [Feature] = []
    
    internal var selectedFeature: Feature?
//    internal var unionFeature: Feature?
    internal var supportPointFeatures: [Feature] = []
    
    internal var currentVertexFeature: Feature?
    internal var dragView: DraggableView?
    internal var isDragViewMoved: Bool = false
    
    internal var supportPointsArray: [CLLocationCoordinate2D] = []
    internal var editableLayerIDs: [String] = []
    internal var supportPointLayerID: String!
    
    deinit {
        print("DEINIT <DrawBox>")
        NotificationCenter.default.removeObserver(self)
    }
}
