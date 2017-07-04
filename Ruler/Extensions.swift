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


extension SCNVector3 {
    enum Axis {
        case x
    }
    
    static let zero = SCNVector3Zero
    static let axisX = SCNVector3(x: 1, y: 0, z: 0)
    
    var length: Float {
        get {
            return sqrtf(x * x)
        }
        set {
            self.normalize()
            self *= length
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
    
    
    
    
    mutating func setAxis(_ axis: Axis, to value: Float) {
        switch axis {
        case .x: x = value
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

func / (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3Make(left.x / right, left.y / right, left.z / right)
}

func * (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3Make(left.x * right, left.y * right, left.z * right)
}

func *= (left: inout SCNVector3, right: Float) {
    left = left * right
}

func * (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x * right.x, left.y * right.y, left.z * right.z)
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

}

