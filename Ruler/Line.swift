//
//  Line.swift
//  Ruler
//
//  Created by Seliz Kaya on 7/3/17.
//  Copyright © 2017 Seliz Kaya. All rights reserved.
//

import Foundation
import SceneKit

class Line: SCNNode {
    enum Edge {
        case min, max
    }
    
    enum Side: String {
        case left, right
        case front, back
        case top, bottom
        
        var axis: SCNVector3.Axis {
            switch self {
            case .left, .right: return .x
            case .top, .bottom: return .y
            case .front, .back: return .z
            }
        }
        
        var edge: Edge {
            switch self {
            case  .back, .bottom, .left: return .min
            case  .front, .top, .right: return .max
            }
        }
    }
    
    enum HorizontalAlignment {
        case left, right, center
        
        var anchor: Float {
            switch self {
            case .left: return 0
            case .right: return 1
            case .center: return 0.5
            }
        }
    }
    
    enum VerticalAlignment {
        case top, bottom, center
        
        var anchor: Float {
            switch self {
            case .bottom: return 0
            case .top: return 1
            case .center: return 0.5
            }
        }
    }
    
    let labelMargin = Float(0.01)
    
    let lineWidth = CGFloat(0.003)
    
    let vertexRadius = CGFloat(0.003)
    
    let fontSize = Float(0.035)
    
    let minLabelLimit = Float(0.01)
    
    let lengthFormatter: NumberFormatter
    
    lazy var vertexA: SCNNode = self.makeVertex()
    lazy var vertexB: SCNNode = self.makeVertex()
    lazy var lineAB: SCNNode = self.makeLine()
    lazy var widthLabel: SCNNode = self.makeLabel()
    
    //MARK: - Constructors
    
    override init() {
        self.lengthFormatter = NumberFormatter()
        self.lengthFormatter.numberStyle = .decimal
        self.lengthFormatter.maximumFractionDigits = 1
        self.lengthFormatter.multiplier = 100
        
        super.init()
        
        resizeTo(min: .zero, max: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func makeNode(with geometry: SCNGeometry) -> SCNNode {
        for material in geometry.materials {
            material.lightingModel = .constant
            material.diffuse.contents = UIColor.white
            material.isDoubleSided = false
        }
        
        let node = SCNNode(geometry: geometry)
        self.addChildNode(node)
        return node
    }
    
    fileprivate func makeVertex() -> SCNNode {
        let ball = SCNSphere(radius: vertexRadius)
        return makeNode(with: ball)
    }
    
    fileprivate func makeLine() -> SCNNode {
        let line = SCNBox(width: lineWidth, height: lineWidth, length: lineWidth, chamferRadius: 0)
        return makeNode(with: line)
    }
    
    fileprivate func makeLabel() -> SCNNode {
        
        let text = SCNText(string: "", extrusionDepth: 0.0)
        text.font = UIFont.boldSystemFont(ofSize: 1.0)
        text.flatness = 0.01
        
        let node = makeNode(with: text)
        node.setUniformScale(fontSize)
        
        return node
    }
    
    
    //MARK: - Transformation
    
    func move(side: Side, to extent: Float) {
        var (min, max) = boundingBox
        switch side.edge {
        case .min: min.setAxis(side.axis, to: extent)
        case .max: max.setAxis(side.axis, to: extent)
        }
        
        resizeTo(min: min, max: max)
    }
    
    func resizeTo(min minExtents: SCNVector3, max maxExtents: SCNVector3) {
        let absMin = SCNVector3(x: min(minExtents.x, maxExtents.x), y: min(minExtents.y, maxExtents.y), z: min(minExtents.z, maxExtents.z))
        let absMax = SCNVector3(x: max(minExtents.x, maxExtents.x), y: max(minExtents.y, maxExtents.y), z: max(minExtents.z, maxExtents.z))
        boundingBox = (absMin, absMax)
        update()
    }
    
    fileprivate func update() {
        let (minBounds, maxBounds) = boundingBox
        
        let size = maxBounds - minBounds
        
        assert(size.x >= 0 && size.y >= 0 && size.z >= 0)
        
        let A = SCNVector3(x: minBounds.x, y: minBounds.y, z: minBounds.z)
        let B = SCNVector3(x: maxBounds.x, y: minBounds.y, z: minBounds.z)
        
        vertexA.position = A
        vertexB.position = B
        
        updateLine(lineAB, from: A, distance: size.x, axis: .x)
        
        updateLabel(widthLabel, distance: size.x, horizontalAlignment: .center, verticalAlignment: .top)
        widthLabel.position = pointInBounds(at: SCNVector3(x: 0.5, y: 0, z: 1)) + SCNVector3(x: 0, y: 0, z: labelMargin)
        widthLabel.orientation = SCNQuaternion(radians: -Float.pi / 2, around: .axisX)
        
        
        widthLabel.isHidden = size.x < minLabelLimit
        
        
    }
    
    fileprivate func updateLine(_ line: SCNNode, from position: SCNVector3, distance: Float, axis: SCNVector3.Axis) {
        guard let Line = line.geometry as? SCNBox else {
            fatalError("Tried to update something that is not a line")
        }
        
        let absDistance = CGFloat(abs(distance))
        let offset = distance * 0.5
        switch axis {
        case .x:
            Line.width = absDistance
            line.position = position + SCNVector3(x: offset, y: 0, z: 0)
        case .y:
            Line.height = absDistance
            line.position = position + SCNVector3(x: 0, y: offset, z: 0)
        case .z:
            Line.length = absDistance
            line.position = position + SCNVector3(x: 0, y: 0, z: offset)
        }
    }
    
    
    fileprivate func updateLabel(_ label: SCNNode, distance distanceInMetres: Float, horizontalAlignment: HorizontalAlignment, verticalAlignment: VerticalAlignment) {
        guard let text = label.geometry as? SCNText else {
            fatalError("Tried to update something that is not a label")
        }
        
        text.string = lengthFormatter.string(for: NSNumber(value: distanceInMetres))! + " cm"
        let textAnchor = text.pointInBounds(at: SCNVector3(x: horizontalAlignment.anchor, y: verticalAlignment.anchor, z: 0))
        label.pivot = SCNMatrix4(translation: textAnchor)
    }
}
