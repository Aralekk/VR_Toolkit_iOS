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

// MARK: Custom Node Class
class NodeClass: SCNNode {
    var color1:UIColor?
    var color2:UIColor?
    var firstColor:Bool?
    
    func initWithColors(c1: UIColor, c2: UIColor){
        self.color1 = c1
        self.color2 = c2
    }
}

//MARK: View Controller
class ViewController: UIViewController, SCNSceneRendererDelegate {

    @IBOutlet weak var leftSceneView: SCNView!
    @IBOutlet weak var rightSceneView: SCNView!
    
    var scene : SCNScene?
    
    var camerasNode : SCNNode?
    var cameraRollNode : SCNNode?
    var cameraPitchNode : SCNNode?
    var cameraYawNode : SCNNode?
    
    var motionManager : CMMotionManager?
    
    var viewfinderNode1 : SCNNode?
    var viewfinderNode2 : SCNNode?
    var viewfinderNode3 : SCNNode?
    var loadingRadius: Float! = 0.03
    
    var firstInteractiveNode : NodeClass?
    var secondInteractiveNode : NodeClass?
    
    var selectedNode : NodeClass?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //In viewDidLoad we initialize the 3D Space and Cameras
        
        // Create Scene
        scene = SCNScene(named: "Scene.scn")
        leftSceneView?.scene = scene
        rightSceneView?.scene = scene
        
        // Create cameras
        let camX = 0.0 as Float
        let camY = 0.0 as Float
        let camZ = 0.0 as Float
        let zFar = 30.0
        
        let leftCamera = SCNCamera()
        let rightCamera = SCNCamera()
        
        leftCamera.zFar = zFar
        rightCamera.zFar = zFar
        
        let leftCameraNode = SCNNode()
        leftCameraNode.camera = leftCamera
        leftCameraNode.position = SCNVector3(x: camX - 0.000, y: camY, z: camZ)
        
        let rightCameraNode = SCNNode()
        rightCameraNode.camera = rightCamera
        rightCameraNode.position = SCNVector3(x: camX + 0.000, y: camY, z: camZ)
        
        camerasNode = SCNNode()
        camerasNode!.position = SCNVector3(x: camX, y:camY, z:camZ)
        camerasNode!.addChildNode(leftCameraNode)
        camerasNode!.addChildNode(rightCameraNode)
        
        let camerasNodeAngles = getCamerasNodeAngle()
        camerasNode!.eulerAngles = SCNVector3Make(Float(camerasNodeAngles[0]), Float(camerasNodeAngles[1]), Float(camerasNodeAngles[2]))
        
        cameraRollNode = SCNNode()
        cameraRollNode!.addChildNode(camerasNode!)
        
        cameraPitchNode = SCNNode()
        cameraPitchNode!.addChildNode(cameraRollNode!)
        
        cameraYawNode = SCNNode()
        cameraYawNode!.addChildNode(cameraPitchNode!)
        
        scene!.rootNode.addChildNode(cameraYawNode!)
        
        leftSceneView?.pointOfView = leftCameraNode
        rightSceneView?.pointOfView = rightCameraNode
        
        // Respond to user head movement. Refreshes the position of the camera 60 times per second.
        motionManager = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager?.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrame.XArbitraryZVertical)
        
        leftSceneView?.delegate = self
        
        leftSceneView?.playing = true
        rightSceneView?.playing = true
        
        createviewFinder()
        displayInteractiveNodes()
    }
    
    //MARK: Viewfinder, used to aim and select, methods
    func createviewFinder(){
        
        // Create the viewFinder Nodes
        let viewFinder1 = SCNCylinder(radius:CGFloat(self.loadingRadius), height:0.0001)
        self.viewfinderNode1 = SCNNode(geometry: viewFinder1)
        self.viewfinderNode1!.position = SCNVector3(x: 0, y: 0, z:-1.9)
        self.viewfinderNode1!.pivot = SCNMatrix4MakeRotation(Float(M_PI) / 2, 1.0, 0.0, 0.0)
        self.camerasNode!.addChildNode(self.viewfinderNode1!)
        
        let viewFinder2 = SCNCylinder(radius: 0.1, height:0.0001)
        viewfinderNode2 = SCNNode(geometry: viewFinder2)
        viewfinderNode2!.position = SCNVector3(x: 0, y: 0, z:-2)
        viewfinderNode2!.pivot = SCNMatrix4MakeRotation(Float(M_PI) / 2, 1.0, 0.0, 0.0)
        self.camerasNode!.addChildNode(self.viewfinderNode2!)
        
        let viewFinder3 = SCNCylinder(radius: 0.1, height:0.0001)
        viewfinderNode3 = SCNNode(geometry: viewFinder3)
        viewfinderNode3!.position = SCNVector3(x: 0, y: 0, z:-6)
        viewfinderNode3!.pivot = SCNMatrix4MakeRotation(Float(M_PI) / 2, 1.0, 0.0, 0.0)
        self.camerasNode!.addChildNode(self.viewfinderNode3!)
        
        let material1 = SCNMaterial()
        material1.diffuse.contents = UIColor(red: 42/255.0, green: 128/255.0, blue: 185/255.0, alpha: 0.7)
        material1.specular.contents = UIColor(red: 42/255.0, green: 128/255.0, blue: 185/255.0, alpha: 0.7)
        material1.shininess = 1.0
        
        let material2 = SCNMaterial()
        material2.diffuse.contents = UIColor(white: 1.0, alpha: 0.5)
        material2.specular.contents = UIColor(white: 1.0, alpha: 0.5)
        material2.shininess = 1.0
        
        let material3 = SCNMaterial()
        material3.diffuse.contents = UIColor(white: 1.0, alpha: 0.0)
        material3.specular.contents = UIColor(white: 1.0, alpha: 0.0)
        material3.shininess = 0.0
        
        viewFinder1.materials = [ material1 ]
        viewFinder2.materials = [ material2 ]
        viewFinder3.materials = [ material3 ]
    }
    
    func updateViewFinder(isLoading: Bool) {
        
        // Update the viewFinder Nodes
        if isLoading {
            self.viewfinderNode2!.hidden = false
            self.loadingRadius = self.loadingRadius + 0.0005
            self.viewfinderNode1!.geometry?.setValue(CGFloat(self.loadingRadius!), forKey: "radius")
            self.viewfinderNode1!.geometry?.firstMaterial!.diffuse.contents = UIColor(red: 42/255.0, green: 128/255.0, blue: 185/255.0, alpha: 1)
            if self.loadingRadius > 0.1 {
                self.launchSomeAction(selectedNode!)
                self.loadingRadius = 0.03
            }
        } else {
            self.viewfinderNode2?.hidden = true
            self.loadingRadius = 0.03
            self.viewfinderNode1!.geometry?.setValue(CGFloat(self.loadingRadius!), forKey: "radius")
            self.viewfinderNode1!.geometry?.firstMaterial!.diffuse.contents = UIColor(red: 42/255.0, green: 128/255.0, blue: 185/255.0, alpha: 0.7)
        }
    }
    
    //MARK: Do some stuff
    func launchSomeAction(nodeToUpdate:NodeClass){
        //stuff
        if (selectedNode != nil){
            if(nodeToUpdate.firstColor == true){
                nodeToUpdate.geometry?.firstMaterial?.diffuse.contents = nodeToUpdate.color2
                nodeToUpdate.firstColor = false
            }else{
                nodeToUpdate.geometry?.firstMaterial?.diffuse.contents = nodeToUpdate.color1
                nodeToUpdate.firstColor = true
            }
        }
    }
    
    //MARK: Interactive Nodes
    func displayInteractiveNodes(){
        
        //first node
        firstInteractiveNode = NodeClass()
        firstInteractiveNode!.geometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.1)
        firstInteractiveNode!.pivot = SCNMatrix4MakeRotation(Float(M_PI_2), 0.0, 1.0, 0.0)
        firstInteractiveNode!.position = SCNVector3(x: 4, y: 0, z: -1)
        
        firstInteractiveNode?.initWithColors(UIColor.blueColor(), c2: UIColor.yellowColor())
        firstInteractiveNode!.geometry?.firstMaterial?.diffuse.contents = firstInteractiveNode?.color1
        firstInteractiveNode?.firstColor = true
        
        scene!.rootNode.addChildNode(firstInteractiveNode!)
        
        //second node
        secondInteractiveNode = NodeClass()
        secondInteractiveNode!.geometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.1)
        secondInteractiveNode!.pivot = SCNMatrix4MakeRotation(Float(M_PI_2), 0.0, 1.0, 0.0)
        secondInteractiveNode!.position = SCNVector3(x: 4, y: 0, z: 1)
        
        secondInteractiveNode?.initWithColors(UIColor.purpleColor(), c2: UIColor.yellowColor())
        secondInteractiveNode!.geometry?.firstMaterial?.diffuse.contents = secondInteractiveNode?.color1
        secondInteractiveNode?.firstColor = true
        
        scene!.rootNode.addChildNode(secondInteractiveNode!)
    }
    
    //MARK: Scene Renderer
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval){
        
        // Render the scene
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if let mm = self.motionManager, let motion = mm.deviceMotion {
                let currentAttitude = motion.attitude
                
                var roll : Double = currentAttitude.roll
                if(UIApplication.sharedApplication().statusBarOrientation == UIInterfaceOrientation.LandscapeRight){ roll = -1.0 * (-M_PI - roll)}
                
                self.cameraRollNode!.eulerAngles.x = Float(roll)
                self.cameraPitchNode!.eulerAngles.z = Float(currentAttitude.pitch)
                self.cameraYawNode!.eulerAngles.y = Float(currentAttitude.yaw)
                
                //Checks if the user looks at an interactive node
                let pFrom = self.camerasNode!.convertPosition(self.viewfinderNode2!.position, toNode: self.scene?.rootNode)
                let pTo = self.camerasNode!.convertPosition(self.viewfinderNode3!.position, toNode: self.scene?.rootNode)
                
                let hitNodes = self.scene?.rootNode.hitTestWithSegmentFromPoint(pFrom, toPoint: pTo, options:nil)
                var hitNode: SCNNode?
                for hn in hitNodes! {
                    if hn.node is NodeClass{
                        hitNode = hn.node
                        break
                    }
                }
                
                if (hitNode != nil) {
                    if let sNode = hitNode as? NodeClass {
                        self.selectedNode = sNode
                        self.updateViewFinder(true)
                    }
                } else {
                    self.selectedNode = nil
                    self.updateViewFinder(false)
                }
            }
        }
    }
    
    //MARK: Camera Orientation methods
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        let camerasNodeAngles = getCamerasNodeAngle()
        camerasNode!.eulerAngles = SCNVector3Make(Float(camerasNodeAngles[0]), Float(camerasNodeAngles[1]), Float(camerasNodeAngles[2]))
    }
    
    func getCamerasNodeAngle() -> [Double] {
        var camerasNodeAngle1: Double! = 0.0
        var camerasNodeAngle2: Double! = 0.0
        let orientation = UIApplication.sharedApplication().statusBarOrientation.rawValue
        if orientation == 1 {
            camerasNodeAngle1 = -M_PI_2
        } else if orientation == 2 {
            camerasNodeAngle1 = M_PI_2
        } else if orientation == 3 {
            camerasNodeAngle1 = 0.0
            camerasNodeAngle2 = M_PI
        }
    
        return [ -M_PI_2, camerasNodeAngle1, camerasNodeAngle2 ]
    }
    
    //MARK: Memory Warning
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}