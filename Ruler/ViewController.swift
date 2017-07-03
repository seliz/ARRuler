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
    
    struct RenderingCategory: OptionSet {
        let rawValue: Int
        static let reflected = RenderingCategory(rawValue: 1 << 1)
        static let planes = RenderingCategory(rawValue: 1 << 2)
    }
    
    enum InteractionMode {
        case waitingForLocation
        case draggingInitialWidth
    }
    
    var planesShown: Bool {
        get { return RenderingCategory(rawValue: sceneView.pointOfView!.camera!.categoryBitMask).contains(.planes) }
        set {
            var mask = RenderingCategory(rawValue: sceneView.pointOfView!.camera!.categoryBitMask)
            if newValue == true {
                mask.formUnion(.planes)
            } else {
                mask.subtract(.planes)
            }
            sceneView.pointOfView!.camera!.categoryBitMask = mask.rawValue
        }
    }
    
    var mode: InteractionMode = .waitingForLocation {
        didSet {
            switch mode {
            case .waitingForLocation:
                
                line.isHidden = true
                
                hitTestPlane.isHidden = true
                floor.isHidden = true
                
                planesShown = true
                
            case .draggingInitialWidth:
                
                line.isHidden = false
                
                floor.isHidden = false
                
                hitTestPlane.isHidden = false
                hitTestPlane.position = .zero
                hitTestPlane.boundingBox.min = SCNVector3(x: -1000, y: 0, z: -1000)
                hitTestPlane.boundingBox.max = SCNVector3(x: 1000, y: 0, z: 1000)
                
                planesShown = false
                
                
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        sceneView.antialiasingMode = .multisampling4X
        sceneView.autoenablesDefaultLighting = true
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        
        sceneView.addGestureRecognizer(panGesture)
        
        line = Line()
        line.isHidden = true
        sceneView.scene.rootNode.addChildNode(line)
        
        hitTestPlane = SCNNode()
        hitTestPlane.isHidden = true
        line.addChildNode(hitTestPlane)
        
        let floorSurface = SCNFloor()
        floorSurface.reflectivity = 0.2
        floorSurface.reflectionFalloffEnd = 0.05
        floorSurface.reflectionCategoryBitMask = RenderingCategory.reflected.rawValue
        
        floorSurface.firstMaterial?.diffuse.contents = UIColor.black
        floorSurface.firstMaterial?.writesToDepthBuffer = false
        floorSurface.firstMaterial?.blendMode = .add
        
        floor = SCNNode(geometry: floorSurface)
        floor.isHidden = true
        
        line.addChildNode(floor)
        line.categoryBitMask |= RenderingCategory.reflected.rawValue
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
        case .waitingForLocation:
            findStartingLocation(gestureRecognizer)
        case .draggingInitialWidth:
            handleInitialWidthDrag(gestureRecognizer)
        }
    }
    
    // MARK: Drag Gesture handling
    
    func findStartingLocation(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began, .changed:
            let touchPos = gestureRecognizer.location(in: sceneView)
            
            let hit = realWorldHit(at: touchPos)
            if let startPos = hit.position, let plane = hit.planeAnchor {
                line.position = startPos
                currentAnchor = plane
                mode = .draggingInitialWidth
            }
        default:
            break
        }
    }
    
    func handleInitialWidthDrag(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            mode = .waitingForLocation
        case .changed:
            let touchPos = gestureRecognizer.location(in: sceneView)
            if let locationInWorld = scenekitHit(at: touchPos, within: hitTestPlane) {
                let delta = line.position - locationInWorld
                let distance = delta.length
                
                let angleInRadians = atan2(delta.z, delta.x)
                
                line.move(side: .right, to: distance)
                line.rotation = SCNVector4(x: 0, y: 1, z: 0, w: -(angleInRadians + Float.pi))
            }
        case .ended, .cancelled:
            mode = .draggingInitialWidth
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
            material.lightingModel = .constant
            material.diffuse.contents = UIColor.red
            material.transparency = 0.1
            material.writesToDepthBuffer = false
        }
        
        let node = SCNNode(geometry: plane)
        node.categoryBitMask = RenderingCategory.planes.rawValue
        
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, let plane = node.geometry as? SCNBox else {
            return
        }
        
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.length = CGFloat(planeAnchor.extent.z)
        
        node.pivot = SCNMatrix4(translationByX: -planeAnchor.center.x, y: -planeAnchor.center.y, z: -planeAnchor.center.z)
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
