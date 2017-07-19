//
//  Extensions.swift
//  Ruler
//
//  Created by Seliz Kaya on 7/3/17.
//  Copyright © 2017 Seliz Kaya. All rights reserved.
//

import Foundation
import ARKit

// MARK: - Collection extensions


extension Array where Iterator.Element == SCNVector3 {
    var average: SCNVector3? {
        guard !isEmpty else {
            return nil
        }
        
        var ret = self.reduce(SCNVector3Zero) { (cur, next) -> SCNVector3 in
            var cur = cur
            cur.x += next.x
            cur.y += next.y
            cur.z += next.z
            return cur
        }
        let fcount = Float(count)
        ret.x /= fcount
        ret.y /= fcount
        ret.z /= fcount
        
        return ret
    }
}

extension RangeReplaceableCollection where IndexDistance == Int {
    mutating func keepLast(_ elementsToKeep: Int) {
        if count > elementsToKeep {
            self.removeFirst(count - elementsToKeep)
        }
    }
}

// MARK: - SCNNode extension

extension SCNNode {
    
    func setUniformScale(_ scale: Float) {
        self.scale = SCNVector3Make(scale, scale, scale)
    }
    
    func setPivot() {
        let minVec = self.boundingBox.min
        let maxVec = self.boundingBox.max
        let bound = SCNVector3Make( maxVec.x - minVec.x, maxVec.y - minVec.y, maxVec.z - minVec.z);
        self.pivot = SCNMatrix4MakeTranslation(bound.x / 2, bound.y / 2, bound.z / 2);
    }
}

// MARK: - SCNVector3 extensions

extension SCNVector3 {
    
    static let zero = SCNVector3Zero
    
    func length() -> Float {
        return sqrtf(x * x + y * y + z * z)
    }
    
    func distanceFromPos(pos: SCNVector3) -> Float {
        let diff = SCNVector3(self.x - pos.x, self.y - pos.y, self.z - pos.z);
        return diff.length()
    }
    
    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
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
            material.lightingModel = .constant
            material.emission.contents = diffuse
        }
        return material
    }
}



func + (left: CGSize, right: CGSize) -> CGSize {
    return CGSize(width: left.width + right.width, height: left.height + right.height)
}

func - (left: CGSize, right: CGSize) -> CGSize {
    return CGSize(width: left.width - right.width, height: left.height - right.height)
}

func / (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width / right, height: left.height / right)
}

func * (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width * right, height: left.height * right)
}

func *= (left: inout CGSize, right: CGFloat) {
    left = left * right
}


// MARK: - Float extensions
extension Float {
    enum LengthUnit: Int {
        case CentiMeter
        case Ruler
        
        var rate:(Float,String) {
            switch self {
            case .CentiMeter:
                return (100.0, "cm")
            case .Ruler:
                return (3.0, "")
            }
        }
        
    }
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


extension SCNBoundingVolume {
    func pointInBounds(at normalizedLocation: SCNVector3) -> SCNVector3 {
        let boundsSize = boundingBox.max - boundingBox.min
        let locationInPoints = boundsSize * normalizedLocation
        return locationInPoints + boundingBox.min
    }
}







