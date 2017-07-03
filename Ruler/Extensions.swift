//
//  Extensions.swift
//  Ruler
//
//  Created by Seliz Kaya on 7/3/17.
//  Copyright © 2017 Seliz Kaya. All rights reserved.
//

import Foundation
import ARKit


// MARK: - SCNNode extension

extension SCNNode {
    
    func setUniformScale(_ scale: Float) {
        self.scale = SCNVector3Make(scale, scale, scale)
    }
    
    func renderOnTop() {
        self.renderingOrder = 2
        if let geom = self.geometry {
            for material in geom.materials {
                material.readsFromDepthBuffer = false
            }
        }
        for child in self.childNodes {
            child.renderOnTop()
        }
    }
}

// MARK: - SCNMaterial extensions

extension SCNMaterial {
    
    static func material(withDiffuse diffuse: Any?, respondsToLighting: Bool = true) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = diffuse
        material.isDoubleSided = true
        if respondsToLighting {
            material.locksAmbientWithDiffuse = true
        } else {
            material.ambient.contents = UIColor.black
            material.lightingModel = .constant
            material.emission.contents = diffuse
        }
        return material
    }
}

// MARK: - CGPoint extensions

extension CGPoint {
    
    init(_ size: CGSize) {
        self.x = size.width
        self.y = size.height
    }
    
    init(_ vector: SCNVector3) {
        self.x = CGFloat(vector.x)
        self.y = CGFloat(vector.y)
    }
    
    func distanceTo(_ point: CGPoint) -> CGFloat {
        return (self - point).length()
    }
    
    func length() -> CGFloat {
        return sqrt(self.x * self.x + self.y * self.y)
    }
    
    func midpoint(_ point: CGPoint) -> CGPoint {
        return (self + point) / 2
    }
    
    func friendlyString() -> String {
        return "(\(String(format: "%.2f", x)), \(String(format: "%.2f", y)))"
    }
}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func += (left: inout CGPoint, right: CGPoint) {
    left = left + right
}

func -= (left: inout CGPoint, right: CGPoint) {
    left = left - right
}

func / (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x / right, y: left.y / right)
}

func * (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x * right, y: left.y * right)
}

func /= (left: inout CGPoint, right: CGFloat) {
    left = left / right
}

func *= (left: inout CGPoint, right: CGFloat) {
    left = left * right
}

// MARK: - CGSize extensions

extension CGSize {
    
    init(_ point: CGPoint) {
        self.width = point.x
        self.height = point.y
    }
    
    func friendlyString() -> String {
        return "(\(String(format: "%.2f", width)), \(String(format: "%.2f", height)))"
    }
}

func + (left: CGSize, right: CGSize) -> CGSize {
    return CGSize(width: left.width + right.width, height: left.height + right.height)
}

func - (left: CGSize, right: CGSize) -> CGSize {
    return CGSize(width: left.width - right.width, height: left.height - right.height)
}

func += (left: inout CGSize, right: CGSize) {
    left = left + right
}

func -= (left: inout CGSize, right: CGSize) {
    left = left - right
}

func / (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width / right, height: left.height / right)
}

func * (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width * right, height: left.height * right)
}

func /= (left: inout CGSize, right: CGFloat) {
    left = left / right
}

func *= (left: inout CGSize, right: CGFloat) {
    left = left * right
}

// MARK: - CGRect extensions

extension CGRect {
    
    var mid: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}


extension SCNVector3 {
    enum Axis {
        case x, y, z
    }
    
    static let zero = SCNVector3Zero
    static let one = SCNVector3(x: 1, y: 1, z: 1)
    
    static let axisX = SCNVector3(x: 1, y: 0, z: 0)
    static let axisY = SCNVector3(x: 0, y: 1, z: 0)
    static let axisZ = SCNVector3(x: 0, y: 0, z: 1)
    
    init(_ vec: vector_float3) {
        self.x = vec.x
        self.y = vec.y
        self.z = vec.z
    }
    
    init(_ value: Float) {
        self.x = value
        self.y = value
        self.z = value
    }
    
    init(_ value: CGFloat) {
        self.x = Float(value)
        self.y = Float(value)
        self.z = Float(value)
    }
    
    var length: Float {
        get {
            return sqrtf(x * x + y * y + z * z)
        }
        set {
            self.normalize()
            self *= length
        }
    }
    
    mutating func clamp(to maxLength: Float) {
        if self.length <= maxLength {
            return
        } else {
            self.normalize()
            self *= maxLength
        }
    }
    
    func normalized() -> SCNVector3 {
        let length = self.length
        guard length != 0 else {
            return self
        }
        
        return self / length
    }
    
    mutating func normalize() {
        self = self.normalized()
    }
    
    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return transform.position
    }
    
    var description: String {
        return "(\(String(format: "%.2f", x)), \(String(format: "%.2f", y)), \(String(format: "%.2f", z)))"
    }
    
    func dot(_ vec: SCNVector3) -> Float {
        return (self.x * vec.x) + (self.y * vec.y) + (self.z * vec.z)
    }
    
    func cross(_ vec: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            self.y * vec.z - self.z * vec.y,
            self.z * vec.x - self.x * vec.z,
            self.x * vec.y - self.y * vec.x
        )
    }
    
    func value(for axis: Axis) -> Float {
        switch axis {
        case .x: return x
        case .y: return y
        case .z: return z
        }
    }
    
    mutating func setAxis(_ axis: Axis, to value: Float) {
        switch axis {
        case .x: x = value
        case .y: y = value
        case .z: z = value
        }
    }
}

//MARK: - Vector arithmetic

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

func += (left: inout SCNVector3, right: SCNVector3) {
    left = left + right
}

func -= (left: inout SCNVector3, right: SCNVector3) {
    left = left - right
}

func / (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3Make(left.x / right, left.y / right, left.z / right)
}

func * (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3Make(left.x * right, left.y * right, left.z * right)
}

func /= (left: inout SCNVector3, right: Float) {
    left = left / right
}

func *= (left: inout SCNVector3, right: Float) {
    left = left * right
}

func / (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x / right.x, left.y / right.y, left.z / right.z)
}

func * (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x * right.x, left.y * right.y, left.z * right.z)
}

func /= (left: inout SCNVector3, right: SCNVector3) {
    left = left / right
}

func *= (left: inout SCNVector3, right: SCNVector3) {
    left = left * right
}

// MARK: - Vectors from matrices

extension matrix_float4x4 {
    var position: SCNVector3 {
        return SCNVector3(x: columns.3.x,
                          y: columns.3.y,
                          z: columns.3.z)
    }
}

extension SCNQuaternion {
   //rotation
    init(radians angle: Float, around axis: SCNVector3) {
        let s = sin(angle/2)
        self.x = axis.x * s
        self.y = axis.y * s
        self.z = axis.z * s
        self.w = cos(angle/2)
    }
    
    //combine
    func concatenating(_ other: SCNQuaternion) -> SCNQuaternion {
        return SCNQuaternion(
            x: (x *  other.w) + (y *  other.z) + (z * -other.y) + (w * other.x),
            y: (x * -other.z) + (y *  other.w) + (z *  other.x) + (w * other.y),
            z: (x * -other.y) + (y * -other.x) + (z *  other.w) + (w * other.z),
            w: (x *  other.x) + (y * -other.y) + (z * -other.z) + (w * other.w)
        )
    }
}

extension SCNBoundingVolume {
    func pointInBounds(at normalizedLocation: SCNVector3) -> SCNVector3 {
        let boundsSize = boundingBox.max - boundingBox.min
        let locationInPoints = boundsSize * normalizedLocation
        return locationInPoints + boundingBox.min
    }
}

extension SCNMatrix4 {
    //MARK: - Initializers
    
    init(translation: SCNVector3) {
        self = SCNMatrix4MakeTranslation(translation.x, translation.y, translation.z)
    }
    
    init(translationByX x: Float, y: Float, z: Float) {
        self = SCNMatrix4MakeTranslation(x, y, z)
    }
    
    init(scale: SCNVector3) {
        self = SCNMatrix4MakeScale(scale.x, scale.y, scale.z)
    }
    
    init(scaleByX x: Float, y: Float, z: Float) {
        self = SCNMatrix4MakeScale(x, y, z)
    }
    
    init(rotationByRadians angle: Float, around axis: SCNVector3) {
        self = SCNMatrix4MakeRotation(angle, axis.x, axis.y, axis.z)
    }
    
    //MARK: - Operations
    
    func translated(by translation: SCNVector3) -> SCNMatrix4 {
        return SCNMatrix4Translate(self, translation.x, translation.y, translation.z)
    }
    
    func rotated(byRadians angle: Float, around axis: SCNVector3) -> SCNMatrix4 {
        return SCNMatrix4Rotate(self, angle, axis.x, axis.y, axis.z)
    }
    
    func scaled(byX x: Float, y: Float, z: Float) -> SCNMatrix4 {
        return SCNMatrix4Scale(self, x, y, z)
    }
}

