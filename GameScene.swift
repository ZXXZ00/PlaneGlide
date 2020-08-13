//
//  GameScene.swift
//  glide
//
//  Created by Adam Zhao on 5/19/20.
//  Copyright © 2020 Adam Zhao. All rights reserved.
//

import SpriteKit
import CoreMotion
//import GameplayKit

class GameScene: SKScene {
    
    private var updateCount = 0;
    
    private var prevBackground: SKNode?
    private var currBackground: SKNode?
    private var nextBackground: SKNode?
    private var backgroundUpdated = true
    private let snowMountain0 = SKSpriteNode(imageNamed: "snow_mountain")
    private let desertHill0 = SKSpriteNode(imageNamed: "desert_hill")
    private let snowMountain1 = SKSpriteNode(imageNamed: "snow_mountain")
    private let desertHill1 = SKSpriteNode(imageNamed: "desert_hill")
    private let snowMountain2 = SKSpriteNode(imageNamed: "snow_mountain")
    private let desertHill2 = SKSpriteNode(imageNamed: "desert_hill")
    private var queueMountain: [SKNode] = []
    private var queueHill: [SKNode] = []
    private let cameraNode = SKCameraNode()
    private let plane = SKSpriteNode(imageNamed: "plane")
    private var mid: CGFloat = -3000 // used for updating the background
    private var prev = CGPoint(x: -320, y: -608) // inital position of the plane
    // prev is used to record previous location of the plane for detection of end of game
    
    private var enableHeightWarning = UserDefaults.standard.bool(forKey: "Height_Warning")
    
    public let currentBest = SKLabelNode()
    public let loading = SKLabelNode(text: "Loading...")

    private let engineFailure = SKLabelNode(text: "Engine Failure!")
    private let lowerHeight = SKLabelNode(text: "lower the plane")
    
    private var orientation: Double = 1
    private let motion = CMMotionManager()
    let setting = InteractiveSpriteNode(imageNamed: "gear")
    private var menu: Menu? = nil
    var isTutorial = false
    private var slider: UISlider? = nil
    private var sensitivity: Double = 1.43
    
    private final let PIXEL: CGFloat = 150
    private var start = false
    private var isAccelerating = false
    private var ended = false
    private var crashed = false
    private var takenOff = false
    
    private var capacity: CGFloat = 1.0
    private let tank = SKShapeNode(rectOf: CGSize(width: 200, height: 10))
    private let tankFrame = SKShapeNode(rectOf: CGSize(width: 200, height: 10))
    private var thrust: CGFloat = 150 * 150
    private var baseThrust: CGFloat = 52 * 150
    private let maxThrust: CGFloat = 200 * 150
    private let power = SKShapeNode(rectOf: CGSize(width: 100, height: 10))
    private let powerFrame = SKShapeNode(rectOf: CGSize(width: 100, height: 10))
    
    private var timerStarted = false
    private var t: TimeInterval = 0;
    private let velocityLabel = SKLabelNode()
    private let distanceLabel = SKLabelNode()
    private let heightLabel = SKLabelNode()
    private let bestLabel = SKLabelNode()
    
    
    private var airDensity: CGFloat = 1.225 // kg/m^3
    private var airSpeedSq: CGFloat = 100 // m/s
    private var wingArea: CGFloat = 8 // m^2
    private var liftCoeff: CGFloat {
        let AOA: CGFloat = plane.zRotation // angle of attack
        
        if (-CGFloat.pi/2 <= AOA && AOA < -1.11) {
            return -1.689*(AOA+CGFloat.pi)
        }
        if (-1.11 < AOA && AOA < -0.2) {
            return 2.1*(AOA+CGFloat.pi/4)*(AOA+CGFloat.pi/4)-1
        }
        if (-0.2 <= AOA && AOA <= CGFloat.pi/9) {
            return sin(AOA*4.5)+0.5
        }
        if (CGFloat.pi/9 < AOA && AOA < 0.927) {
            return 0.1*(sin(12.5*(AOA-0.8)) - 12.5*(AOA-0.8))+0.876
        }
        if (0.927 <= AOA && AOA <= CGFloat.pi/2) {
            return -1.27*(AOA-CGFloat.pi/2)
        }
        return 0
    }
    
    override func didMove(to view: SKView) {
        loadText()
        let storedSensitivity = UserDefaults.standard.double(forKey: "Sensitivity")
        if (storedSensitivity >= 0.5) { sensitivity = storedSensitivity }
        preLoadPhysicsBody()
        initilizeBackground()
        addPlane()
        addBase()
        addLabels()
        addSetting()
        startDeviceMotion()
        physicsWorld.contactDelegate = self
    }
    
    private func convertHeight(_ h: CGFloat) -> Int {
        return Int(h/1.5)
    }
    
    private func convertX(_ x: CGFloat) -> Int {
        return Int(x/10.0)
    }
    
    private func loadText() {
        let best = UserDefaults.standard.integer(forKey: "Best")
        currentBest.text = "Best: \(best) m"
        currentBest.fontName = "ChalkboardSE-Bold"
        currentBest.position = CGPoint(x: 0, y: 100)
        currentBest.zPosition = 9
        cameraNode.addChild(currentBest)
        loading.fontName = "ChalkboardSE-Bold"
        loading.zPosition = 15
        loading.position = CGPoint(x: 0, y: 50)
        loading.alpha = 0
        cameraNode.addChild(loading)
        engineFailure.fontName = "ChalkboardSE-Bold"
        lowerHeight.fontName = "ChalkboardSE-Bold"
        lowerHeight.fontSize = 24
        lowerHeight.position = CGPoint(x: 0, y: -50)
        engineFailure.addChild(lowerHeight)
        engineFailure.zPosition = 9
        engineFailure.alpha = 0
        cameraNode.addChild(engineFailure)
        let turnRed = SKAction.colorize(with: .red, colorBlendFactor: 1.0, duration: 0.2)
        let turnWhite = SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.2)
        let flashing = SKAction.repeatForever(SKAction.sequence([turnRed, turnWhite]))
        engineFailure.run(flashing)
    }
    
    private func addSetting() {
        menu = Menu(scene: self)
        menu!.zPosition = 10
        menu!.alpha = 0        
        cameraNode.addChild(menu!)
        setting.target = self
        setting.action = #selector(GameScene.showMenu)
        setting.position = CGPoint(x: self.frame.minX+34, y: self.frame.maxY-34)
        setting.zPosition = 10
        cameraNode.addChild(setting)
    }
    
    @objc func showMenu() {
        pause()
        slider = UISlider(frame: CGRect(x: self.frame.maxX-75, y: self.frame.maxY-100, width: 150, height: 10))
        slider!.tintColor = .systemGreen
        slider!.minimumValue = 0.5
        slider!.maximumValue = 2
        slider!.setValue(Float(sensitivity), animated: false)
        slider!.isContinuous = true
        slider!.addTarget(self, action: #selector(GameScene.changeSensitivity(_:)), for: .valueChanged)
        if let m = menu {
            m.alpha = 1
        }
        self.view?.addSubview(slider!)
    }
    
    @objc func changeSensitivity(_ sender: UISlider!) {
        sensitivity = Double(sender.value)
        print(sensitivity)
    }
    
    @objc func closeMenu() {
        slider?.removeFromSuperview()
        if let m = menu {
            m.alpha = 0
        }
        UserDefaults.standard.set(Double(sensitivity), forKey: "Sensitivity")
        UserDefaults.standard.set(Bool(enableHeightWarning), forKey: "Height_Warning")
        resume()
    }
    
    private func startDeviceMotion() {
        if UIApplication.shared.statusBarOrientation == .landscapeRight {
            orientation = -1
        }
        if self.motion.isDeviceMotionAvailable {
            self.motion.deviceMotionUpdateInterval = 1.0/60.0
            self.motion.showsDeviceMovementDisplay = true
            self.motion.startDeviceMotionUpdates(using: .xArbitraryZVertical)
        }
        if self.motion.isAccelerometerAvailable {
            self.motion.accelerometerUpdateInterval = 1.0 / 60.0
            self.motion.startAccelerometerUpdates()
        }
    }
    
    private func addLabels() {
        let limitX = self.frame.maxX
        let limitY = self.frame.maxY
        velocityLabel.fontName = "ChalkboardSE-Bold"
        velocityLabel.fontSize = 18
        velocityLabel.text = "speed: 0 m"
        velocityLabel.zPosition = 10
        velocityLabel.position = CGPoint(x: limitX-250, y: limitY-37)
        cameraNode.addChild(velocityLabel)
        distanceLabel.fontName = "ChalkboardSE-Bold"
        distanceLabel.fontSize = 18
        distanceLabel.text = "distance: 0 m"
        distanceLabel.zPosition = 10
        distanceLabel.position = CGPoint(x: limitX-100, y: limitY-37)
        cameraNode.addChild(distanceLabel)
        heightLabel.fontName = "ChalkboardSE-Bold"
        heightLabel.fontSize = 18
        heightLabel.text = "height: 0 m"
        heightLabel.zPosition = 10
        heightLabel.position = CGPoint(x: limitX-400, y: limitY-37)
        cameraNode.addChild(heightLabel)
        bestLabel.text = "best: \(Int(UserDefaults.standard.integer(forKey: "Best"))) m"
        bestLabel.fontName = "ChalkboardSE-Bold"
        bestLabel.fontSize = 14
        bestLabel.zPosition = 10
        bestLabel.position = CGPoint(x: limitX-100, y: limitY-60)
        if !isTutorial {
            cameraNode.addChild(bestLabel)
        }
    }
    
    func heightWarning() {
        heightLabel.color = .red
        heightLabel.colorBlendFactor = 1.0
        let turnRed = SKAction.colorize(with: .red, colorBlendFactor: 1.0, duration: 0.2)
        let turnBack = SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.2)
        let warning = SKAction.repeatForever(SKAction.sequence([turnBack, turnRed]))
        heightLabel.run(warning)
    }
    
    func removeHeightWarning() {
        heightLabel.removeAllActions()
        heightLabel.color = .white
    }
    
    @objc func toggleHeightWarning() {
        enableHeightWarning = !enableHeightWarning
        if enableHeightWarning {
            menu?.checkMark.alpha = 1
        } else {
            menu?.checkMark.alpha = 0
        }
    }
    
    private func addBase() {
        let base = SKSpriteNode(imageNamed: "base")
        base.zPosition = 1
        base.position = CGPoint(x: -100, y: -145-750+96)
        let rect = SKShapeNode(rectOf: CGSize(width: 533, height: 10))
        rect.lineWidth = 0
        rect.position = CGPoint(x: -110, y: 28-750+96)
        rect.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 533, height: 10))
        rect.physicsBody!.isDynamic = false
        rect.physicsBody!.friction = 0.2
        addChild(base)
        addChild(rect)
    }
    
    private func addPlane() {
        plane.position = CGPoint(x: -320, y: 46-750+96)
        plane.zRotation = 0.0917
        plane.zPosition = 2
        plane.physicsBody = SKPhysicsBody(texture: plane.texture!, size: plane.texture!.size())
        plane.physicsBody!.restitution = 0.001
        plane.physicsBody!.linearDamping = 0;
        plane.physicsBody!.density = 2000
        plane.physicsBody!.isDynamic = false
        plane.physicsBody!.friction = 0.01
        plane.physicsBody!.categoryBitMask = CategoryMask.plane.rawValue
        plane.physicsBody!.collisionBitMask = ~(CategoryMask.oil.rawValue)
        //print(plane.physicsBody!.mass)
        addChild(plane)
        
        tank.lineWidth = 0
        tank.fillColor = .systemYellow
        tank.zPosition = 3
        tank.position = CGPoint(x: 0, y: self.frame.minY+50)
        cameraNode.addChild(tank)
        tankFrame.lineWidth = 2
        tankFrame.zPosition = 3
        tankFrame.position = CGPoint(x: 0, y: self.frame.minY+50)
        cameraNode.addChild(tankFrame)
        
        power.lineWidth = 0
        power.fillColor = .systemRed
        power.zPosition = 3
        power.position = CGPoint(x: self.frame.maxX - 599, y: self.frame.maxY-30)
        power.xScale = 0.0
        cameraNode.addChild(power)
        powerFrame.lineWidth = 2
        powerFrame.zPosition = 3
        powerFrame.position = CGPoint(x: self.frame.maxX - 550, y: self.frame.maxY-30)
        cameraNode.addChild(powerFrame)
        let powerOn = SKAction.scaleX(to: thrust/maxThrust, duration: 1)
        let offset = SKAction.moveTo(x: power.position.x+100*0.5*thrust/maxThrust, duration: 1)
        let group = SKAction.group([powerOn, offset])
        power.run(group) /* {
            self.power.xScale = thrust/maxThrust
            self.power.position = CGPoint(x: self.frame.minX+100 + 100*0.5*thrust/maxThrust)
        } */
        
        cameraNode.position = CGPoint(x: -25, y: 51-750+96)
        let range = SKRange(lowerLimit: 0, upperLimit: 25)
        let constraint = SKConstraint.distance(range, to: CGPoint(x: 264, y: -120), in: plane)
        let constraintY = SKConstraint.positionY(SKRange(lowerLimit: -1000+self.frame.maxY, upperLimit: 3000-self.frame.maxY-40))
        cameraNode.constraints = [constraint, constraintY]
        addChild(cameraNode)
        self.camera = cameraNode
    }
    
    private func updatePower(delta: CGFloat) {
        let initalRatio = thrust/maxThrust
        if (delta > 0) {
            thrust = min(maxThrust, thrust+delta)
        }
        if (delta < 0) {
            thrust = max(0.0, thrust+delta)
        }
        let ratio = thrust/maxThrust
        let diff = ratio - initalRatio
        power.xScale = ratio
        power.position = CGPoint(x: power.position.x+100*0.5*diff, y: power.position.y)
    }
    
    private func updateTank(by: CGFloat) {
        let initialCapacity = capacity
        if (by > 0) {
            capacity = min(1.0, capacity+by)
        }
        if (by < 0) {
            capacity = max(0.0, capacity+by)
        }
        let diff = capacity - initialCapacity
        tank.xScale = capacity
        tank.position = CGPoint(x: tank.position.x+200*0.5*diff, y: tank.position.y)
    }
    
    private func preLoadPhysicsBody() {
        snowMountain0.name = "m"
        snowMountain1.name = "m"
        snowMountain2.name = "m"
        desertHill0.name = "h"
        desertHill1.name = "h"
        desertHill2.name = "h"
        queueMountain.append(snowMountain0)
        queueMountain.append(snowMountain1)
        queueMountain.append(snowMountain2)
        queueHill.append(desertHill0)
        queueHill.append(desertHill1)
        queueHill.append(desertHill2)
        snowMountain0.physicsBody = SKPhysicsBody(texture: snowMountain0.texture!,
                                                 size: snowMountain0.texture!.size())
        desertHill0.physicsBody = SKPhysicsBody(texture: desertHill0.texture!,
                                                size: desertHill0.texture!.size())
        snowMountain1.physicsBody = SKPhysicsBody(texture: snowMountain1.texture!,
                                                 size: snowMountain1.texture!.size())
        desertHill1.physicsBody = SKPhysicsBody(texture: desertHill1.texture!,
                                                size: desertHill1.texture!.size())
        snowMountain2.physicsBody = SKPhysicsBody(texture: snowMountain1.texture!,
                                                 size: snowMountain1.texture!.size())
        desertHill2.physicsBody = SKPhysicsBody(texture: desertHill1.texture!,
                                                size: desertHill1.texture!.size())
        snowMountain0.physicsBody!.isDynamic = false
        snowMountain1.physicsBody!.isDynamic = false
        snowMountain2.physicsBody!.isDynamic = false
        desertHill0.physicsBody?.isDynamic = false
        desertHill1.physicsBody?.isDynamic = false
        desertHill2.physicsBody?.isDynamic = false
        snowMountain0.physicsBody!.friction = 0.8
        snowMountain1.physicsBody!.friction = 0.8
        snowMountain2.physicsBody!.friction = 0.8
        desertHill0.physicsBody!.friction = 0.8
        desertHill1.physicsBody!.friction = 0.8
        desertHill2.physicsBody!.friction = 0.8
        snowMountain0.physicsBody!.restitution = 0.01
        snowMountain1.physicsBody!.restitution = 0.01
        snowMountain2.physicsBody!.restitution = 0.01
        desertHill0.physicsBody!.restitution = 0.01
        desertHill1.physicsBody!.restitution = 0.01
        desertHill2.physicsBody!.restitution = 0.01
        snowMountain0.physicsBody!.categoryBitMask = CategoryMask.obstacle.rawValue
        snowMountain1.physicsBody!.categoryBitMask = CategoryMask.obstacle.rawValue
        snowMountain2.physicsBody!.categoryBitMask = CategoryMask.obstacle.rawValue
        desertHill0.physicsBody!.categoryBitMask = CategoryMask.obstacle.rawValue
        desertHill1.physicsBody!.categoryBitMask = CategoryMask.obstacle.rawValue
        desertHill2.physicsBody!.categoryBitMask = CategoryMask.obstacle.rawValue
        snowMountain0.physicsBody!.contactTestBitMask = CategoryMask.plane.rawValue
        snowMountain1.physicsBody!.contactTestBitMask = CategoryMask.plane.rawValue
        snowMountain2.physicsBody!.contactTestBitMask = CategoryMask.plane.rawValue
        desertHill0.physicsBody!.contactTestBitMask = CategoryMask.plane.rawValue
        desertHill1.physicsBody!.contactTestBitMask = CategoryMask.plane.rawValue
        desertHill2.physicsBody!.contactTestBitMask = CategoryMask.plane.rawValue
        snowMountain0.physicsBody!.collisionBitMask = CategoryMask.plane.rawValue
        snowMountain1.physicsBody!.collisionBitMask = CategoryMask.plane.rawValue
        snowMountain2.physicsBody!.collisionBitMask = CategoryMask.plane.rawValue
        desertHill0.physicsBody!.collisionBitMask = CategoryMask.plane.rawValue
        desertHill1.physicsBody!.collisionBitMask = CategoryMask.plane.rawValue
        desertHill2.physicsBody!.collisionBitMask = CategoryMask.plane.rawValue
        /*
        snowMountain0.position = CGPoint(x: 0, y: -750)
        snowMountain1.position = CGPoint(x: -3000, y: 0)
        snowMountain2.position = CGPoint(x: -3000, y: 0)
        desertHill0.position = CGPoint(x: -3000, y: 0)
        desertHill1.position = CGPoint(x: -3000, y: 0)
        desertHill2.position = CGPoint(x: -3000, y: 0) */
        snowMountain0.zPosition = 2
        snowMountain1.zPosition = 2
        snowMountain2.zPosition = 2
        desertHill0.zPosition = 2
        desertHill1.zPosition = 2
        desertHill2.zPosition = 2
        //print(snowMountain0.position)
        //addChild(snowMountain1)
        //addChild(snowMountain2)
        //addChild(desertHill0)
        //addChild(desertHill1)
        //addChild(desertHill2)
    }

    private func initilizeBackground() {
        for i in stride(from: 0, through: 2000, by: 1000) {
            /*
            let background = buildBackground()
            background.position = CGPoint(x: i, y: 0)
            if (i == 0) {
                prevBackground = background
            }
            if (i == 1000) {
                currBackground = background
            }
            if (i == 2000) {
                nextBackground = background
            }
            addChild(background) */
            buildBackground()
            if (i == 0) {
                prevBackground = nextBackground
            }
            if (i == 1000) {
                currBackground = nextBackground
            }
        }
    }
    
    private func updateScene() {
        DispatchQueue.main.async {
            if let bg = self.prevBackground {
                bg.removeFromParent()
                for child in bg.children {
                    if let name = child.name {
                        if name == "m" {
                            self.queueMountain.append(child)
                        }
                        if name == "h" {
                            self.queueHill.append(child)
                        }
                    }
                }
            }
            self.prevBackground = self.currBackground
            self.currBackground = self.nextBackground
            self.buildBackground()
            
            self.backgroundUpdated = true
            self.updateCount += 1
        }
    }

    private func buildBackground() {
        let background = SKSpriteNode(imageNamed: "background")
        self.mid += 1000
        background.position = CGPoint(x: self.mid+1000, y: 0)
        var rect = CGSize(width: 1000, height: 184)
        let water = SKShapeNode(rectOf: rect)
        water.lineWidth = 0
        water.position = CGPoint(x: 0, y: -208-750+48)
        rect = CGSize(width: rect.width, height: rect.height-4)
        water.physicsBody = SKPhysicsBody(rectangleOf: rect)
        water.physicsBody!.isDynamic = false
        water.physicsBody!.restitution = 0.00001
        water.physicsBody!.friction = 0.8
        water.physicsBody!.contactTestBitMask = ~(CategoryMask.obstacle.rawValue)
        water.physicsBody!.collisionBitMask = ~(CategoryMask.obstacle.rawValue)
        background.addChild(water)
        let skyColor = UIColor(red: 15.0/256.0, green: 115.0/256.0, blue: 140.0/256.0, alpha: 1.0)
        let upperSky = SKShapeNode(rectOf: CGSize(width: 1000, height: 2000))
        upperSky.lineWidth = 0
        upperSky.fillColor = skyColor
        upperSky.position = CGPoint(x: 0, y: 2000)
        background.addChild(upperSky)
        rect = CGSize(width: rect.width, height: 100)
        let upperLimit = SKShapeNode(rectOf: rect)
        upperLimit.position = CGPoint(x: 0, y: 3050)
        upperLimit.lineWidth = 0
        upperLimit.physicsBody = SKPhysicsBody(rectangleOf: rect)
        upperLimit.physicsBody!.isDynamic = false
        upperLimit.physicsBody!.restitution = 0.05
        upperLimit.physicsBody!.friction = 0.3
        background.addChild(upperLimit)
        let whichIsland = Int.random(in: 0 ..< 5)
        if (whichIsland == 0) {
            if (mid > 1000 && queueMountain.count > 0) {
                let mountain = queueMountain[0]
                mountain.position = CGPoint(x: 0, y: -734)
                background.addChild(mountain)
                queueMountain.removeFirst()
            }
        }
        if (whichIsland == 1) {
            if (mid > 1000 && queueHill.count > 0) {
                let hill = queueHill[0]
                hill.position = CGPoint(x: 0, y: -790)
                //print("hill")
                background.addChild(hill)
                queueHill.removeFirst()
            }
        }
        for i in stride(from: -1, through: 1, by: 2) {
            for j in stride(from: 0, through: 2750, by: 250) {
                var rand = Int.random(in: 0 ..< 2)
                if (rand == 1) {
                    let cloud = SKSpriteNode(imageNamed: "cloud")
                    let lower = i < 0 ? 400*i : 100*i
                    let upper = i < 0 ? 100*i : 400*i
                    let x = Int.random(in: lower ..< upper)
                    let y = Int.random(in: 0..<250)
                    cloud.position = CGPoint(x: x, y: y+j)
                    cloud.zPosition = 1
                    let scale = Double.random(in: 0.2..<1.5)
                    cloud.setScale(CGFloat(scale))
                    background.addChild(cloud)
                }
                if (j < 1500 && background.position.x > 0) {
                    rand = Int.random(in: 0 ..< 30)
                    if (rand == 1) {
                        let oil = SKSpriteNode(imageNamed: "oil")
                        oil.name = "oil"
                        let lower = i < 0 ? 400*i : 100*i
                        let upper = i < 0 ? 100*i : 400*i
                        let x = Int.random(in: lower ..< upper)
                        let y = Int.random(in: 0..<250)
                        oil.position = CGPoint(x: x, y: y+j)
                        oil.zPosition = 1
                        oil.physicsBody = SKPhysicsBody(rectangleOf: oil.size)
                        oil.physicsBody!.isDynamic = false
                        oil.physicsBody!.categoryBitMask = CategoryMask.oil.rawValue
                        oil.physicsBody!.contactTestBitMask = CategoryMask.plane.rawValue
                        oil.physicsBody!.collisionBitMask = 0b0000
                        background.addChild(oil)
                    }
                }
            }
            if (background.position.x > 0) {
                for k in stride(from: -800, through: 0, by: 250) {
                    let rand = Int.random(in: 0 ..< 12)
                    if (rand == 1) {
                        let oil = SKSpriteNode(imageNamed: "oil")
                        oil.name = "oil"
                        let lower = i < 0 ? 400*i : 100*i
                        let upper = i < 0 ? 100*i : 400*i
                        let x = Int.random(in: lower ..< upper)
                        let y = Int.random(in: 0..<250)
                        oil.position = CGPoint(x: x, y: y+k)
                        oil.zPosition = 1
                        oil.physicsBody = SKPhysicsBody(rectangleOf: oil.size)
                        oil.physicsBody!.isDynamic = false
                        oil.physicsBody!.categoryBitMask = CategoryMask.oil.rawValue
                        oil.physicsBody!.contactTestBitMask = CategoryMask.plane.rawValue
                        oil.physicsBody!.collisionBitMask = 0b0000
                        if (!oil.intersects(snowMountain0) && !oil.intersects(snowMountain1) && !oil.intersects(snowMountain2) && !oil.intersects(desertHill0) && !oil.intersects(desertHill1) && !oil.intersects(desertHill2)) {
                            background.addChild(oil)
                        }
                    }
                }
            }
        }
        self.nextBackground = background
        self.addChild(background)
    }

    private func applyForce() {
        if let body = plane.physicsBody {
            //let m = body.mass
            let v = body.velocity
            airSpeedSq = v.dx * v.dx
            airDensity = 1.2838 / (1 + exp(0.0019*(plane.position.y-1600)))
            //print(airDensity)
            let lift = 0.5 * airDensity * airSpeedSq * wingArea * liftCoeff
            //print("velocity: \(v)")
            //print("speedSq: \(airSpeedSq), liftCoeff: \(liftCoeff), lift: \(lift)")
            let drag = 0.5 * airDensity * airSpeedSq * 4 * 0.05
            let angle = plane.zRotation
            let x = thrust*cos(angle) - drag
            //print("x: \(x), drag: \(drag)")
            let y = thrust*sin(angle) + lift
            //print("y: \(y)")
            body.applyForce(CGVector(dx: x, dy: y))
        }
    }
    
    private func checkIfStopped() -> Bool {
        let position = plane.position
        //print(position)
        let tmp = prev
        prev = position
        if (position.x > 100 && abs(position.x-tmp.x) > 0.00000001) {
            return false
        } else if (capacity < 0.05 || position.y < -805 || crashed) {
            return true
        }
        return false
    }
    
    private func endGame() {
        closeMenu()
        let black = InteractiveShapeNode(rectOf: self.frame.size)
        black.lineWidth = 0
        black.fillColor = .black
        black.alpha = 0.6
        black.zPosition = 10
        black.target = self
        black.action = #selector(GameScene.restart)
        cameraNode.addChild(black)
        let restartLabel = SKLabelNode(text: "touch to restart")
        restartLabel.position = CGPoint(x: 0, y: self.frame.minY+100)
        restartLabel.fontName = "ChalkboardSE-Bold"
        restartLabel.zPosition = 11
        cameraNode.addChild(restartLabel)
        let curr: Int = Int((plane.position.x+320)/10.0)
        let result = SKLabelNode(text: "Traveled: \(curr) m !")
        result.fontName = "ChalkboardSE-Bold"
        result.zPosition = 11
        cameraNode.addChild(result)
        let best = UserDefaults.standard.integer(forKey: "Best")
        if !isTutorial {
            if (curr > best) {
                UserDefaults.standard.set(curr, forKey: "Best")
                currentBest.text = "New Record: \(curr) m !!!"
                currentBest.zPosition = 11
            }
            currentBest.alpha = 1
        }
        start = false
    }
    
    private func addSmoke() {
        let smoke = SKEmitterNode(fileNamed: "Smoke")
        plane.addChild(smoke!)
        smoke?.targetNode = self
    }
    
    @objc func restart() {
        closeMenu()
        loading.alpha = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if let newScene = GameScene(fileNamed: "GameScene") {
                self.view?.presentScene(newScene)
            }
        }
    }
    
    @objc func tutorial() {
        closeMenu()
        loading.alpha = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if let newScene = TutorialScene(fileNamed: "Tutorial") {
                self.view?.presentScene(newScene)
            }
        }
    }
    
    public func addToCamera(node: SKNode) {
        cameraNode.addChild(node)
    }
    
    public func getPlanePosition() -> CGPoint {
        return plane.position
    }
    
    public func pause() {
        self.physicsWorld.speed = 0.0
        start = false
    }
    
    public func resume() {
        self.physicsWorld.speed = 1.0
        start = true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentBest.alpha = 0
        if !crashed {
            start = true
            plane.physicsBody?.isDynamic = true
            isAccelerating = true
        }
        if ended {
            restart()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isAccelerating = false
        //thrust = 100 * 150
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        let pos = plane.position
        if start && enableHeightWarning && pos.y+(pos.y-prev.y)*90 < -800 {
            heightWarning()
        } else {
            removeHeightWarning()
        }
        if checkIfStopped() && !ended {
            endGame()
            ended = true
        }
        if !ended && (pos.x < -1000 || pos.y < -1000 || pos.y > 3000) {
            endGame()
            ended = true
        }
        if !timerStarted {
            t = currentTime
            timerStarted = true
        }
        if start {
            if isAccelerating {
                if (capacity > 0) {
                    //thrust += 50
                    updatePower(delta: 50)
                } else {
                    isAccelerating = false
                }
                updateTank(by: -0.001)
            } else if (plane.position.x > 150) {
                if (capacity > 0) {
                    if thrust != baseThrust {
                        let ratio = baseThrust/maxThrust
                        power.xScale = ratio
                        power.position = CGPoint(x: self.frame.maxX-600 + 100*0.5*ratio,
                                                 y: power.position.y)
                    }
                    thrust = baseThrust
                } else {
                    //thrust = max(thrust-150, 0)
                    updatePower(delta: -150)
                    isAccelerating = false
                }
                updateTank(by: -0.0002)
            }
            if (pos.y > 1500) {
                if (pos.y > 2500) {
                    engineFailure.alpha = 1
                    baseThrust = 0
                    updatePower(delta: -200)
                } else {
                    engineFailure.alpha = 0
                }
                baseThrust = max(0, 52*150 - 10 * (pos.y-1500))
                if (thrust > 52*150 - 10 * (pos.y-1500)) {
                    updatePower(delta: -0.1 * (pos.y-1500))
                }
            } else {
                baseThrust = 52*150
                engineFailure.alpha = 0
            }
            //print(thrust)
            //print(plane.physicsBody?.velocity)
            //print(plane.position)
            applyForce()
        }
        if (currentTime - t > 0.2) {
            if let v = plane.physicsBody?.velocity {
                velocityLabel.text = "speed: \(Int(v.dx/10.0)) m/s"
            }
            distanceLabel.text = "distance: \(Int((plane.position.x+320.0)/10.0)) m"
            heightLabel.text = "height: \(Int((plane.position.y+806.5)/1.5)) m"
            t = currentTime
        }
        if let data = self.motion.deviceMotion {
            if start {
                let x = data.attitude.pitch
                let y = data.attitude.roll
                let z = data.attitude.yaw
                /*
                if !crashed && plane.position.y > -800 && plane.position.x > 150 {
                    plane.zRotation = CGFloat(x * GameViewController.orientation * sensitivity)
                    takenOff = true
                } else {
                    if !takenOff &&
                        (plane.position.y > -608 && plane.position.x > 0) {
                        let angle = CGFloat(x * GameViewController.orientation)
                        if angle > plane.zRotation {
                            plane.zRotation += 0.015
                        } else {
                            plane.zRotation -= 0.015
                        }
                    }
                } */
                let angle: CGFloat
                if !crashed && pos.y > -800 && pos.x > 0 {
                    if (abs(y) > 0.17) {
                        angle = CGFloat(x * orientation)
                    } else {
                        angle = CGFloat(z)
                    }
                    if angle > plane.zRotation {
                        plane.zRotation = min(angle, plane.zRotation + CGFloat(0.007*sensitivity))
                    }
                    if angle < plane.zRotation {
                        plane.zRotation = max(angle, plane.zRotation -
                            CGFloat(0.007*sensitivity))
                    }
                }
            }
        }
        //print(plane.zRotation)
        if plane.position.x > mid + 500 && backgroundUpdated {
            //print("about to update \(updateCount)")
            backgroundUpdated = false
            updateScene()
        }
    }
}


extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        //print(contact.bodyA.categoryBitMask)
        //print(contact.bodyB.categoryBitMask)
        let maskA = CategoryMask(rawValue: contact.bodyA.categoryBitMask)
        let maskB = CategoryMask(rawValue: contact.bodyB.categoryBitMask)
        if (maskA == .plane && maskB == .oil) {
            contact.bodyB.node?.removeFromParent()
            updateTank(by: 0.1)
        }
        if (maskA == .oil && maskB == .plane) {
            contact.bodyA.node?.removeFromParent()
            updateTank(by: 0.1)
        }
        if (maskA == .plane || maskB == .plane) {
            if !crashed && (maskA == .obstacle || maskB == .obstacle) {
                crashed = true
                start = false
                addSmoke()
            }
        }
    }
}
