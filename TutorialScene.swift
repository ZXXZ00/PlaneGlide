//
//  Background.swift
//  glide
//
//  Created by Adam Zhao on 5/22/20.
//  Copyright © 2020 Adam Zhao. All rights reserved.
//

import SpriteKit

class TutorialScene: GameScene {
    
    private let touchToStart = SKLabelNode(text: "touch and hold to accelerate")
    private var showedInstruction = false
    private let black = InteractiveShapeNode(rectOf: CGSize(width: 3000, height: 2000))
    private let rotateToControl = SKLabelNode(text: "rotate your device to control the plane")
    private let changeSensitivity = SKLabelNode(text: "you can change the control sensitivity in the setting menu located on the top left corner")
    private let explainPower = SKLabelNode(text: "the red bar indicates the power of the plane")
    private let touchToContinue = SKLabelNode(text: "touch to continue")
    
    private let explainOil = SKLabelNode(text: "the yellow bar indicates fuel left in the plane")
    private let collectOil = SKLabelNode(text: "collect oil to refuel your plane")
    private let explainHeightWarning0 = SKLabelNode(text: "When the plane drops too quickly and is about to hit the water")
    private let explainHeightWarning1 = SKLabelNode(text: "height label will flash like this")
    private let flashingHeightLabel = SKLabelNode(text: "height: 200.0")
    
    override func didMove(to view: SKView) {
        print("tutorial")
        //setting.alpha = 0
        isTutorial = true
        addOil()
        touchToStart.zPosition = 11
        addToCamera(node: touchToStart)
        currentBest.alpha = 0
        super.didMove(to: view)
    }
    
    private func addOil() {
        for i in 0...5 {
            let x = Int.random(in: 0..<500)
            let y = Int.random(in: -200..<400)
            let oil = SKSpriteNode(imageNamed: "oil")
            if i == 0 {
                oil.position = CGPoint(x: 350, y: -400)
            } else {
                oil.position = CGPoint(x: 350+x, y: y-400)
            }
            oil.zPosition = 1
            oil.physicsBody = SKPhysicsBody(rectangleOf: oil.size)
            oil.physicsBody!.isDynamic = false
            oil.physicsBody!.categoryBitMask = CategoryMask.oil.rawValue
            oil.physicsBody!.contactTestBitMask = CategoryMask.plane.rawValue
            oil.physicsBody!.collisionBitMask = 0b0000
            addChild(oil)
        }
    }
    
    private func addControlInstructions() {
        black.fillColor = .black
        black.lineWidth = 0
        black.zPosition = 10
        black.alpha = 0.7
        black.target = self
        black.action = #selector(TutorialScene.removeControlInstructions)
        addToCamera(node: black)
        rotateToControl.zPosition = 11
        addToCamera(node: rotateToControl)
        changeSensitivity.fontSize = 18
        changeSensitivity.zPosition = 11
        changeSensitivity.position = CGPoint(x: 0, y: -50)
        addToCamera(node: changeSensitivity)
        explainPower.fontSize = 26
        explainPower.position = CGPoint(x: self.frame.maxX-430, y: self.frame.maxY-100)
        explainPower.zPosition = 11
        addToCamera(node: explainPower)
        touchToContinue.zPosition = 11
        touchToContinue.fontSize = 24
        touchToContinue.position = CGPoint(x: 0, y: -100)
        addToCamera(node: touchToContinue)
        pause()
    }
    
    private func flashHeightWarning() {
        black.action = #selector(TutorialScene.removeFlashHeightWarning)
        black.alpha = 0.7
        explainHeightWarning0.fontSize = 26
        explainHeightWarning0.zPosition = 11
        explainHeightWarning0.position = CGPoint(x: 0, y: 100)
        explainHeightWarning1.fontSize = 26
        explainHeightWarning1.zPosition = 11
        explainHeightWarning1.position = CGPoint(x: 0, y: 50)
        addToCamera(node: explainHeightWarning0)
        addToCamera(node: explainHeightWarning1)
        flashingHeightLabel.fontName = "ChalkboardSE-Bold"
        flashingHeightLabel.fontSize = 18
        flashingHeightLabel.setScale(1.5)
        flashingHeightLabel.zPosition = 11
        let turnRed = SKAction.colorize(with: .red, colorBlendFactor: 1.0, duration: 0.1)
        let turnBack = SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.1)
        let flashing = SKAction.repeatForever(SKAction.sequence([turnRed, turnBack]))
        flashingHeightLabel.run(flashing)
        addToCamera(node: flashingHeightLabel)
    }
    
    private func addOilInstructions() {
        black.action = #selector(TutorialScene.removeOilInstructions)
        black.alpha = 0.7
        explainOil.zPosition = 11
        explainOil.position = CGPoint(x: 0, y: self.frame.minY+120)
        addToCamera(node: explainOil)
        collectOil.zPosition = 11
        addToCamera(node: collectOil)
        pause()
    }
    
    @objc func removeControlInstructions() {
        rotateToControl.removeFromParent()
        explainPower.removeFromParent()
        changeSensitivity.removeFromParent()
        touchToContinue.removeFromParent()
        flashHeightWarning()
    }
    
    @objc func removeFlashHeightWarning() {
        explainHeightWarning0.removeFromParent()
        explainHeightWarning1.removeFromParent()
        flashingHeightLabel.removeFromParent()
        addOilInstructions()
    }
    
    @objc func removeOilInstructions() {
        black.removeFromParent()
        explainOil.removeFromParent()
        collectOil.removeFromParent()
        resume()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchToStart.alpha = 0
        super.touchesBegan(touches, with: event)
    }
    
    override func update(_ currentTime: TimeInterval) {
        let p = getPlanePosition()
        if (p.x > 0 && !showedInstruction) {
            addControlInstructions()
            showedInstruction = true
        }
        super.update(currentTime)
    }
}
