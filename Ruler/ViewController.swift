//
//  ViewController.swift
//  Ruler
//
//  Created by Seliz Kaya on 7/3/17.
//  Copyright © 2017 Seliz Kaya. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var panGesture: UIPanGestureRecognizer!
    
    
    var line: Line!
    var hitTestPlane: SCNNode!
    var floor: SCNNode!
    
    var currentAnchor: ARAnchor?
    
    struct Rendering: OptionSet {
        let rawValue: Int
        static let planes = Rendering(rawValue: 1 << 2)
    }
    
    enum Interaction {
        case waitingForPlane
        case draggingLine
    }
    
    var showPlanes: Bool {
        get { return Rendering(rawValue: sceneView.pointOfView!.camera!.categoryBitMask).contains(.planes) }
        set {
            var layer = Rendering(rawValue: sceneView.pointOfView!.camera!.categoryBitMask)
            if newValue == true {
                layer.formUnion(.planes)
            } else {
                layer.subtract(.planes)
            }
            sceneView.pointOfView!.camera!.categoryBitMask = layer.rawValue
        }
    }
    
    var mode: Interaction = .waitingForPlane {
        didSet {
            switch mode {
            case .waitingForPlane:
                
                line.isHidden = true
                hitTestPlane.isHidden = true
                floor.isHidden = true
                showPlanes = true
                
            case .draggingLine:
                
                line.isHidden = false
                floor.isHidden = false
                hitTestPlane.isHidden = false
                hitTestPlane.position = .zero
                hitTestPlane.boundingBox.min = SCNVector3(x: -1000, y: 0, z: -1000)
                hitTestPlane.boundingBox.max = SCNVector3(x: 1000, y: 0, z: 1000)
                showPlanes = false
                
                
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        sceneView.antialiasingMode = .multisampling4X
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        sceneView.addGestureRecognizer(panGesture)
        
        line = Line()
        line.isHidden = true
        sceneView.scene.rootNode.addChildNode(line)
        
        hitTestPlane = SCNNode()
        hitTestPlane.isHidden = true
        line.addChildNode(hitTestPlane)
        
        let floorTop = SCNFloor()
        floorTop.firstMaterial?.diffuse.contents = UIColor.black
        floorTop.firstMaterial?.blendMode = .add
        
        floor = SCNNode(geometry: floorTop)
        floor.isHidden = true
        
        line.addChildNode(floor)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    

    // MARK: - Touch handling
    
    @objc dynamic func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch mode {
        case .waitingForPlane:
            findStart(gestureRecognizer)
        case .draggingLine:
            handleLineDrag(gestureRecognizer)
        }
    }
    
    // MARK: Drag Gesture handling
    
    func findStart(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began, .changed:
            let touched = gestureRecognizer.location(in: sceneView)
            
            let hit = realWorldHit(at: touched)
            if let start = hit.position, let plane = hit.planeAnchor {
                line.position = start
                currentAnchor = plane
                mode = .draggingLine
            }
        default:
            break
        }
    }
    
    func handleLineDrag(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            mode = .waitingForPlane
        case .changed:
            let touched = gestureRecognizer.location(in: sceneView)
            if let specificLocation = scenekitHit(at: touched, within: hitTestPlane) {
                let delta = line.position - specificLocation
                let distance = delta.length
                
                let angle = atan2(delta.z, delta.x)
                
                line.move(side: .right, to: distance)
                line.rotation = SCNVector4(x: 0, y: 1, z: 0, w: -(angle + Float.pi))
            }
        case .ended, .cancelled:
            mode = .draggingLine
        default:
            break
        }
    }
    
    
    // MARK: - Hit-testing
    
    func scenekitHit(at screenPos: CGPoint, within rootNode: SCNNode) -> SCNVector3? {
        let hits = sceneView.hitTest(screenPos, options: [
            .boundingBoxOnly: true,
            .firstFoundOnly: true,
            .rootNode: rootNode,
            .ignoreChildNodes: true
            ])
        
        return hits.first?.worldCoordinates
    }
    
    func realWorldHit(at screenPos: CGPoint) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        let planeHitTestResults = sceneView.hitTest(screenPos, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {
            
            let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeAnchor = result.anchor
            
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }
        
        return (nil, nil, false)
    }
    
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return nil
        }
        
        let plane = SCNBox(width: CGFloat(planeAnchor.extent.x),
                           height: 0.0001,
                           length: CGFloat(planeAnchor.extent.z), chamferRadius: 0)
        
        if let material = plane.firstMaterial {
            material.diffuse.contents = UIColor.red
            material.transparency = 0.1
        }
        
        let node = SCNNode(geometry: plane)
        node.categoryBitMask = Rendering.planes.rawValue
        
        return node
    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
