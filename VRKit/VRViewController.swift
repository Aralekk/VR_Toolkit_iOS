//
//  ViewController.swift
//  VR_Toolkit
//
//  Created by Arthur Swiniarski on 19/01/16.
//  Copyright © 2016 Arthur Swiniarski. All rights reserved.
//

import UIKit
import SceneKit
import CoreMotion
import AVFoundation
import Foundation
import Darwin
import CoreGraphics


//MARK: View Controller
class VRViewController: UIViewController, SCNSceneRendererDelegate, VRSceneDelegate {
    
    @IBOutlet weak var leftSceneView: SCNView!
    @IBOutlet weak var rightSceneView: SCNView!
    
    var scene: VRScene!
    
    var motionManager: CMMotionManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // In viewDidLoad we initialize the 3D Space and Cameras
        
        // Create Scene
        scene = VRScene(named: "Scene.scn")!
        scene.setup()
        scene.delegate = self
        
        leftSceneView.scene = scene
        rightSceneView.scene = scene
        
        leftSceneView.pointOfView = scene.leftCameraNode
        rightSceneView.pointOfView = scene.rightCameraNode
        
        // Respond to user head movement. Refreshes the position of the camera 60 times per second.
        motionManager = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager?.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical)
        
        leftSceneView?.delegate = self
        //        rightSceneView.delegate = self
        
        leftSceneView?.isPlaying = true
        rightSceneView?.isPlaying = true
        
        print("using metal", leftSceneView.renderingAPI == .metal)
        
    }
    
    // MARK: Do some stuff
    func trigger() {
        if let node = scene.selectedNode {
            scene.launchSomeAction(nodeToUpdate: node)
        }
    }
 
    // MARK: Scene Renderer
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        guard let mm = self.motionManager, let motion = mm.deviceMotion else { return }
        
        let cameraRotation = (
            roll: motion.attitude.roll,
            pitch: motion.attitude.pitch,
            yaw: motion.attitude.yaw)
        
        scene.updateCameraRotation(eulerAngles: cameraRotation)
        
        
    }
    
    
    
}
