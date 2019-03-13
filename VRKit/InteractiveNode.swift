//
//  InteractiveNode.swift
//  VRPlay
//
//  Created by Aleksey Bykhun on 13/03/2019.
//  Copyright © 2019 Aleksey Bykhun. All rights reserved.
//

import Foundation
import SceneKit

// MARK: Custom Node Class
class InteractiveNode: SCNNode {
    var color1: UIColor?
    var color2: UIColor?
    
    var firstColor: Bool?
    
    func initWithColors(c1: UIColor, c2: UIColor){
        self.color1 = c1
        self.color2 = c2
    }
}
