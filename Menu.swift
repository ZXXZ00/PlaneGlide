//
//  Menu.swift
//  glide
//
//  Created by Adam Zhao on 5/24/20.
//  Copyright © 2020 Adam Zhao. All rights reserved.
//

import SpriteKit

class Menu: SKNode {
    let bg = InteractiveShapeNode(rectOf: CGSize(width: 400, height: 300), cornerRadius: 20)
    let restart = InteractiveShapeNode(rectOf: CGSize(width: 100, height: 50),
                                       cornerRadius: 10)
    let tutorial = InteractiveShapeNode(rectOf: CGSize(width: 100, height: 50),
                                        cornerRadius: 10)
    let close = InteractiveShapeNode(circleOfRadius: 20)
    let mask = InteractiveShapeNode(rectOf: CGSize(width: 4000, height: 3000))
    let checkMark = SKLabelNode(text: "✓")
    
    init(scene: SKScene) {
        super.init()
        bg.lineWidth = 0
        bg.fillColor = .orange
        addChild(bg)
        let restartLabel = SKLabelNode(text: "restart")
        restartLabel.fontName = "ChalkboardSE-Bold"
        restartLabel.fontSize = 20
        restartLabel.position = CGPoint(x: 0, y: -7)
        restart.addChild(restartLabel)
        restart.position = CGPoint(x: -85, y: 0)
        restart.lineWidth = 0
        restart.fillColor = .systemOrange
        restart.target = scene
        restart.action = #selector(GameScene.restart)
        bg.addChild(restart)
        let cross = SKLabelNode(text: "x")
        cross.fontName = "ChalkboardSE-Bold"
        cross.fontSize = 20
        cross.position = CGPoint(x: 0, y: -5)
        close.addChild(cross)
        close.position = CGPoint(x: 200-10, y: 150-10)
        close.fillColor = .red
        close.lineWidth = 0
        close.target = scene
        close.action = #selector(GameScene.closeMenu)
        bg.addChild(close)
        mask.fillColor = .black
        mask.alpha = 0.4
        mask.zPosition = -1
        mask.lineWidth = 0
        addChild(mask)
        let tutorialLabel = SKLabelNode(text: "tutorial")
        tutorialLabel.fontName = "ChalkboardSE-Bold"
        tutorialLabel.fontSize = 20
        tutorialLabel.position = CGPoint(x: 0, y: -7)
        tutorial.addChild(tutorialLabel)
        tutorial.position = CGPoint(x: -85, y: -100)
        tutorial.lineWidth = 0
        tutorial.fillColor = .systemOrange
        tutorial.target = scene
        tutorial.action = #selector(GameScene.tutorial)
        bg.addChild(tutorial)
        let moreSensitive = SKLabelNode(text: "more sensitive")
        let lessSensitive = SKLabelNode(text: "less sensitive")
        moreSensitive.fontName = "ChalkboardSE-Bold"
        lessSensitive.fontName = "ChalkboardSE-Bold"
        moreSensitive.fontSize = 16
        lessSensitive.fontSize = 16
        moreSensitive.position = CGPoint(x: 130, y: 89)
        lessSensitive.position = CGPoint(x: -130, y: 89)
        bg.addChild(moreSensitive)
        bg.addChild(lessSensitive)
        let checkbox = InteractiveShapeNode(rectOf: CGSize(width: 20, height: 20))
        let enableHeightWarning = SKLabelNode(text: "height warning")
        enableHeightWarning.fontName = "ChalkboardSE-Bold"
        enableHeightWarning.fontSize = 18
        enableHeightWarning.position = CGPoint(x: -85, y: -5)
        checkbox.addChild(enableHeightWarning)
        checkMark.fontName = "ChalkboardSE-Bold"
        checkMark.alpha = UserDefaults.standard.bool(forKey: "Height_Warning") ? 1 : 0
        checkMark.fontSize = 32
        checkMark.position = CGPoint(x: 2, y: -10)
        checkbox.addChild(checkMark)
        checkbox.position = CGPoint(x: 140, y: -2)
        checkbox.target = scene
        checkbox.action = #selector(GameScene.toggleHeightWarning)
        bg.addChild(checkbox)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
