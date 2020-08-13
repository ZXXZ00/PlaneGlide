//
//  InteractiveShapeNode.swift
//  glide
//
//  Created by Adam Zhao on 5/23/20.
//  Copyright © 2020 Adam Zhao. All rights reserved.
//

import SpriteKit

class InteractiveShapeNode: SKShapeNode {
    override var isUserInteractionEnabled: Bool {
        set {
            // ignore
        }
        get {
            return true
        }
    }
    
    weak var target: AnyObject? = nil
    var action: Selector? = nil
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.alpha -= 0.3
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.alpha += 0.3
        if let t = target, let a = action {
            UIApplication.shared.sendAction(a, to: t, from: self, for: nil)
        }
    }
}
