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
import Photos

class ViewController: UIViewController, ARSCNViewDelegate, UIPopoverPresentationControllerDelegate {
    
    
    @IBOutlet var refresh: UIButton!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var plusSymbol: UIImageView!
    @IBOutlet var button: UIButton!
    @IBOutlet var Label: UILabel!
    @IBOutlet weak var planeVisual: UISwitch!
    @IBOutlet weak var SSbutton: UIButton!
    
    
    var line: Line?
    var lines: [Line] = []
    var hitTestPlane: SCNNode!
    var floor: SCNNode!
    
    var currentAnchor: ARAnchor?
    
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
                
                hitTestPlane.isHidden = true
                floor.isHidden = true
                
                showPlanes = true
                
            case .draggingLine:
                
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
        sceneView.autoenablesDefaultLighting = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a session configuration
        restart()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    
    
    @IBAction func drawLine(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected;
        if line == nil {
            let startPos = realWorldHit(plusSymbol.center, objectPos: nil, infinitePlane: true)
            if let p = startPos.position {
                line = Line(startPos: p, sceneV: sceneView)
            }
        }else{
            lines.append(line!)
            line = nil
        }
        
    }
    
    @IBAction func showPlaneVisual(_ sender: UISwitch) {
        
        if planeVisual.isOn {
            
        }
        else {
            
        }
    }
    
    
    @IBAction func takeSS(_ sender: UIButton) {
        guard SSbutton.isEnabled else {
            return
        }
        
        let SSBlock = {
            UIImageWriteToSavedPhotosAlbum(self.sceneView.snapshot(), nil, nil, nil)
            DispatchQueue.main.async {
                let flash = UIView(frame: self.sceneView.frame)
                flash.backgroundColor = UIColor.white
                self.sceneView.addSubview(flash)
                UIView.animate(withDuration: 0.25, animations: {
                    flash.alpha = 0.0
                }, completion: { _ in
                    flash.removeFromSuperview()
                })
            }
        }
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            SSBlock()
        case .restricted, .denied:
            let title = "Photos access denied"
            let message = "Please enable Photos access for this application in Settings > Privacy to allow saving screenshots."
            
            let popUp = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
            
            popUp.addAction(UIAlertAction(title: "Got it!", style: UIAlertActionStyle.default, handler: nil))
            
            self.present(popUp, animated: true, completion: nil)
            UIView.animate(withDuration: 1) {
                self.Label.alpha = 1
            }
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (authorizationStatus) in
                if authorizationStatus == .authorized {
                    SSBlock()
                }
            })
        }
    }
    
    @IBAction func Refreshing(_ sender: UIButton) {
        
        UIView.animate(withDuration: 1){
            self.line?.removeFromParent()
            self.line = nil
            for node in self.lines {
            node.removeFromParent()
        }
            self.restart()
    }
    }
    struct Rendering: OptionSet {
        let rawValue: Int
        static let planes = Rendering(rawValue: 1 << 2)
    }
    
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateLine()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.addPlane(node: node, anchor: planeAnchor)
            }
        }
    }
    
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
    
    
    func restart() {
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        button.isEnabled = false
        Label.alpha = 1
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
    
    func updateLine() -> Void {
        let startPos = self.realWorldHit(self.plusSymbol.center, objectPos: nil, infinitePlane: true)
        if let p = startPos.position {
            let length = self.line?.updatePosition(pos: p, camera: self.sceneView.session.currentFrame?.camera) ?? 0
            updateDistanceLabel(distance: length)
        }
    }
    
    func updateDistanceLabel(distance:Float) -> Void {
        let cm = NSAttributedString(string: Float.LengthUnit.CentiMeter.rate.1, attributes: [NSAttributedStringKey.font:UIFont.systemFont(ofSize: 15)])
        var dis = String(format: "%.1f", arguments: [distance*Float.LengthUnit.Ruler.rate.0])
        var result = NSMutableAttributedString(string: dis, attributes:[NSAttributedStringKey.font:UIFont.boldSystemFont(ofSize: 18)])
        dis = String(format: "%.1f", arguments: [distance*Float.LengthUnit.CentiMeter.rate.0])
        result = NSMutableAttributedString(string: dis, attributes:[NSAttributedStringKey.font:UIFont.boldSystemFont(ofSize: 25)])
        result.append(cm)
        Label.attributedText = result
    }
    
    // MARK: - Planes
    
    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {
        
        button.isEnabled = true
        
        let popupController = UIAlertController(title: "You Can Start Measuring Now!", message: "", preferredStyle: UIAlertControllerStyle.alert)
        popupController.addAction(UIAlertAction(title: "Ok, bye", style: UIAlertActionStyle.default,handler: nil))
        
        self.present(popupController, animated: true, completion: nil)
        UIView.animate(withDuration: 1) {
            self.Label.alpha = 1
        }
    }
    
}




func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    guard let planeAnchor = anchor as? ARPlaneAnchor, let plane = node.geometry as? SCNBox else {
        return
    }
    
    plane.width = CGFloat(planeAnchor.extent.x)
    plane.length = CGFloat(planeAnchor.extent.z)
    
    node.pivot = SCNMatrix4(translationByX: -planeAnchor.center.x, y: -planeAnchor.center.y, z: -planeAnchor.center.z)
}

extension ViewController {
    func realWorldHit(_ position: CGPoint,
                      objectPos: SCNVector3?,
                      infinitePlane: Bool = false) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {
            
            let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeAnchor = result.anchor
            
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }
        return (nil, nil, false)
    }
}

