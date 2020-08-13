//
//  GameViewController.swift
//  glide
//
//  Created by Adam Zhao on 5/19/20.
//  Copyright © 2020 Adam Zhao. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let lastVersion = UserDefaults.standard.double(forKey: "LastRunVersion")
        if (lastVersion < 0.3) {
            let best = Double(UserDefaults.standard.integer(forKey: "Best"))
            UserDefaults.standard.set(Int(best/10.0), forKey: "Best")
        }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        if let str = version {
            let versionNumber = Double(str)
            if let number = versionNumber {
                UserDefaults.standard.set(number, forKey: "LastRunVersion")
            }
        }
        UserDefaults.standard.register(defaults: ["Height_Warning": true])
        
        if let view = self.view as! SKView? {
            if UserDefaults.standard.double(forKey: "LastRun") == 0.0 {
                if let scene = TutorialScene(fileNamed: "Tutorial") {
                    // Set the scale mode to scale to fit the window
                    scene.scaleMode = .aspectFill
                    scene.size = view.frame.size
                    
                    // Present the scene
                    view.presentScene(scene)
                }
                
                view.ignoresSiblingOrder = true
            } else {
                if let scene = GameScene(fileNamed: "GameScene") {
                    scene.scaleMode = .aspectFill
                    scene.size = view.frame.size
                    
                    view.presentScene(scene)
                }
            }
        }
        let date = Date()
        let time: Double = Double(date.timeIntervalSince1970)
        UserDefaults.standard.set(time, forKey: "LastRun")
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
