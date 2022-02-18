//
//  Turf2GEOSwift.swift
//  DrawBox
//
//  Created by mkv on 1/27/22.
//

import CoreLocation
import UIKit

let gestureOffset = 30.0

class DraggableView: UIView
{
    var position: CGPoint {
        get { return layer.position }
        set { layer.position = CGPoint(x: newValue.x - gestureOffset, y: newValue.y - gestureOffset) }
    }
    
    init(size: CGFloat, position: CGPoint) {
        super.init(frame: CGRect(x: position.x - size/2, y: position.y - size/2, width: size, height: size))
        backgroundColor = .red
        layer.opacity = 0.5
        
        layer.cornerRadius = size / 2
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 1.0
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startDragging() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
//            self.layer.opacity = 0.5
//            self.centerOffset = CGVector(dx: -gestureOffset, dy: -gestureOffset)
            self.frame = CGRect(origin: CGPoint(x: self.frame.origin.x-gestureOffset, y: self.frame.origin.y-gestureOffset), size: self.frame.size)
        }, completion: {_ in self.layer.opacity = 0.5})
        let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
        hapticFeedback.impactOccurred()
    }
    
    func endDragging() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
//            self.layer.opacity = 0.5
//            self.centerOffset = CGVector(dx: 0, dy: 0)
        }, completion: {_ in self.layer.opacity = 0.0})
        let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
        hapticFeedback.impactOccurred()
    }
}
