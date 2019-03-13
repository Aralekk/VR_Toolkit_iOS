//
//  VRScene.swift
//  VRPlay
//
//  Created by Aleksey Bykhun on 13/03/2019.
//  Copyright © 2019 Aleksey Bykhun. All rights reserved.
//

import Foundation
import SceneKit
import CoreMotion
import AVFoundation
import Darwin
import CoreGraphics

protocol VRSceneDelegate {
    func trigger()
}

class VRScene: SCNScene {
    
    var leftCameraNode: SCNNode!
    var rightCameraNode: SCNNode!
    
    var camerasNode: SCNNode?
    var cameraRollNode: SCNNode?
    var cameraPitchNode: SCNNode?
    var cameraYawNode: SCNNode?
    
    var viewfinderNode1: SCNNode?
    var viewfinderNode2: SCNNode?
    var viewfinderNode3: SCNNode?
    var loadingRadius: Float! = 0.03
    
    var firstInteractiveNode: InteractiveNode?
    var secondInteractiveNode: InteractiveNode?
    
    var selectedNode: InteractiveNode?
    
    var delegate: VRSceneDelegate?
    
    func setup() {
        // initialize the 3D Space and Cameras

        // Create cameras
        let camX = 0.0 as Float
        let camY = 0.0 as Float
        let camZ = 0.0 as Float
        let zFar = 30.0
        
        let leftCamera = SCNCamera()
        let rightCamera = SCNCamera()
        
        // Mi VR Play 2 FOV: 93 degrees.
        leftCamera.fieldOfView = 93
        rightCamera.fieldOfView = 93
        
        leftCamera.zFar = zFar
        rightCamera.zFar = zFar
        
        leftCameraNode = SCNNode()
        leftCameraNode.camera = leftCamera
        leftCameraNode.position = SCNVector3(x: camX - 0.000, y: camY, z: camZ)
        
        rightCameraNode = SCNNode()
        rightCameraNode.camera = rightCamera
        rightCameraNode.position = SCNVector3(x: camX + 0.000, y: camY, z: camZ)
        
        camerasNode = SCNNode()
        camerasNode!.position = SCNVector3(x: camX, y:camY, z:camZ)
        camerasNode!.addChildNode(leftCameraNode)
        camerasNode!.addChildNode(rightCameraNode)
        
        camerasNode!.eulerAngles = SCNVector3Make(-Float.pi/2, -Float.pi/2, 0)
        
        cameraRollNode = SCNNode()
        cameraRollNode!.addChildNode(camerasNode!)
        
        cameraPitchNode = SCNNode()
        cameraPitchNode!.addChildNode(cameraRollNode!)
        
        cameraYawNode = SCNNode()
        cameraYawNode!.addChildNode(cameraPitchNode!)
        
        rootNode.addChildNode(cameraYawNode!)
        
        createviewFinder()
        displayInteractiveNodes()
    }
    
    
    func selectNode(node: InteractiveNode?) {
        selectedNode = node
    }
    
    // MARK: Viewfinder, used to aim and select, methods
    func createviewFinder(){
        
        // Create the viewFinder Nodes
        let viewFinder1 = SCNCylinder(radius:CGFloat(self.loadingRadius), height:0.0001)
        self.viewfinderNode1 = SCNNode(geometry: viewFinder1)
        self.viewfinderNode1!.position = SCNVector3(x: 0, y: 0, z:-1.9)
        self.viewfinderNode1!.pivot = SCNMatrix4MakeRotation(Float.pi / 2, 1.0, 0.0, 0.0)
        self.camerasNode!.addChildNode(self.viewfinderNode1!)
        
        let viewFinder2 = SCNCylinder(radius: 0.1, height:0.0001)
        viewfinderNode2 = SCNNode(geometry: viewFinder2)
        viewfinderNode2!.position = SCNVector3(x: 0, y: 0, z:-2)
        viewfinderNode2!.pivot = SCNMatrix4MakeRotation(Float.pi / 2, 1.0, 0.0, 0.0)
        self.camerasNode!.addChildNode(self.viewfinderNode2!)
        
        let viewFinder3 = SCNCylinder(radius: 0.1, height:0.0001)
        viewfinderNode3 = SCNNode(geometry: viewFinder3)
        viewfinderNode3!.position = SCNVector3(x: 0, y: 0, z:-6)
        viewfinderNode3!.pivot = SCNMatrix4MakeRotation(Float.pi / 2, 1.0, 0.0, 0.0)
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
            viewfinderNode2!.isHidden = false
            loadingRadius = self.loadingRadius + 0.0005
            viewfinderNode1!.geometry?.setValue(CGFloat(self.loadingRadius!), forKey: "radius")
            viewfinderNode1!.geometry?.firstMaterial!.diffuse.contents = UIColor(red: 42/255.0, green: 128/255.0, blue: 185/255.0, alpha: 1)
            if self.loadingRadius > 0.1 {
                self.delegate?.trigger()
                self.loadingRadius = 0.03
            }
        } else {
            viewfinderNode2?.isHidden = true
            loadingRadius = 0.03
            viewfinderNode1!.geometry?.setValue(CGFloat(self.loadingRadius!), forKey: "radius")
            viewfinderNode1!.geometry?.firstMaterial!.diffuse.contents = UIColor(red: 42/255.0, green: 128/255.0, blue: 185/255.0, alpha: 0.7)
        }
    }
    
    // MARK: Do some stuff
    func launchSomeAction(nodeToUpdate: InteractiveNode) {
        //stuff
        if selectedNode != nil {
            if nodeToUpdate.firstColor == true {
                nodeToUpdate.geometry?.firstMaterial?.diffuse.contents = nodeToUpdate.color2
                nodeToUpdate.firstColor = false
            } else {
                nodeToUpdate.geometry?.firstMaterial?.diffuse.contents = nodeToUpdate.color1
                nodeToUpdate.firstColor = true
            }
        }
    }
    
    // MARK: Interactive Nodes
    func displayInteractiveNodes() {
        
        //first node
        firstInteractiveNode = InteractiveNode()
        firstInteractiveNode!.geometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.1)
        firstInteractiveNode!.pivot = SCNMatrix4MakeRotation(Float.pi / 2, 0.0, 1.0, 0.0)
        firstInteractiveNode!.position = SCNVector3(x: 4, y: 0, z: -1)
        
        firstInteractiveNode?.initWithColors(c1: UIColor.blue, c2: UIColor.yellow)
        firstInteractiveNode!.geometry?.firstMaterial?.diffuse.contents = firstInteractiveNode?.color1
        firstInteractiveNode?.firstColor = true
        
        rootNode.addChildNode(firstInteractiveNode!)
        
        //second node
        secondInteractiveNode = InteractiveNode()
        secondInteractiveNode!.geometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.1)
        secondInteractiveNode!.pivot = SCNMatrix4MakeRotation(Float.pi / 2, 0.0, 1.0, 0.0)
        secondInteractiveNode!.position = SCNVector3(x: 4, y: 0, z: 1)
        
        secondInteractiveNode?.initWithColors(c1: UIColor.purple, c2: UIColor.yellow)
        secondInteractiveNode!.geometry?.firstMaterial?.diffuse.contents = secondInteractiveNode?.color1
        secondInteractiveNode?.firstColor = true
        
        rootNode.addChildNode(secondInteractiveNode!)
    }
    
    func updateCameraRotation(eulerAngles: (roll: Double, pitch: Double, yaw: Double)) {
        

        self.cameraRollNode!.eulerAngles.x = Float(eulerAngles.roll)
        self.cameraPitchNode!.eulerAngles.z = Float(eulerAngles.pitch)
        self.cameraYawNode!.eulerAngles.y = Float(eulerAngles.yaw)
        
        // Checks if the user looks at an interactive node
        let pFrom = self.camerasNode!.convertPosition(self.viewfinderNode2!.position, to: rootNode)
        let pTo = self.camerasNode!.convertPosition(self.viewfinderNode3!.position, to: rootNode)
        
        let hitNodes = rootNode.hitTestWithSegment(from: pFrom, to: pTo, options: nil)
        
        let hitTestInteractiveNode = hitNodes.first { hittest in hittest.node is InteractiveNode }

        if let ht = hitTestInteractiveNode {
            if let sNode = ht.node as? InteractiveNode {
                self.selectedNode = sNode
                self.updateViewFinder(isLoading: true)
            }
        } else {
            self.selectedNode = nil
            self.updateViewFinder(isLoading: false)
        }
        
        
    }
    
}
