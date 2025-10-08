import SpriteKit

class ParkScene: SKScene, SKPhysicsContactDelegate {
    private let player = SKSpriteNode(color: .systemBlue, size: CGSize(width: 28, height: 28))
    private var movementDirections: Set<Direction> = []
    private var dpadButtons: [Direction: SKSpriteNode] = [:]
    private var touchDirectionMap: [UITouch: Direction] = [:]
    private let playerSpeed: CGFloat = 140
    private var lastUpdateTime: TimeInterval = 0
    private let cameraNode = SKCameraNode()
    private let hudNode = SKNode()
    private let hudTicketsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let backButton = ButtonNode(size: CGSize(width: 140, height: 44), text: "Back", color: .systemRed)
    private var bottlePortal: SKSpriteNode!
    private var plinkoPortal: SKSpriteNode!
    private var coasterRide: SKSpriteNode!
    private var rideVisited = false
    private var rideAnimating = false

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(displayP3Red: 0.4, green: 0.75, blue: 0.4, alpha: 1)
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        setupWorld()
        setupPlayer()
        setupCamera()
        setupHUD()
        setupDPad()
        updateTicketsLabel()

        view.isMultipleTouchEnabled = true
    }

    private func setupWorld() {
        let ground = SKSpriteNode(color: .init(red: 0.5, green: 0.85, blue: 0.5, alpha: 1), size: CGSize(width: 2000, height: 2000))
        ground.zPosition = -20
        addChild(ground)

        // Paths (placeholder art)
        for offset in stride(from: -400, through: 400, by: 200) {
            let path = SKSpriteNode(color: .brown, size: CGSize(width: 1200, height: 60))
            path.position = CGPoint(x: 0, y: CGFloat(offset))
            path.zPosition = -10
            addChild(path)
        }

        // Fences / walls
        let fenceSize = CGSize(width: 1400, height: 40)
        let bottomFence = SKSpriteNode(color: .darkGray, size: fenceSize)
        bottomFence.position = CGPoint(x: 0, y: -500)
        configureFence(bottomFence)

        let topFence = bottomFence.copy() as! SKSpriteNode
        topFence.position = CGPoint(x: 0, y: 500)
        configureFence(topFence)

        let leftFence = SKSpriteNode(color: .darkGray, size: CGSize(width: 40, height: 1000))
        leftFence.position = CGPoint(x: -650, y: 0)
        configureFence(leftFence)

        let rightFence = leftFence.copy() as! SKSpriteNode
        rightFence.position = CGPoint(x: 650, y: 0)
        configureFence(rightFence)

        // Bottle Toss portal pad
        bottlePortal = createPortal(color: .systemYellow, text: "🎯 Bottle Toss")
        bottlePortal.position = CGPoint(x: -250, y: 150)
        addChild(bottlePortal)

        // Plinko portal pad
        plinkoPortal = createPortal(color: .systemPurple, text: "🟣 Plinko")
        plinkoPortal.position = CGPoint(x: 250, y: 150)
        addChild(plinkoPortal)

        // Roller coaster ride pad
        coasterRide = SKSpriteNode(color: .systemRed, size: CGSize(width: 180, height: 90))
        coasterRide.name = "coaster"
        coasterRide.position = CGPoint(x: 0, y: -100)
        coasterRide.zPosition = 1
        coasterRide.physicsBody = SKPhysicsBody(rectangleOf: coasterRide.size)
        coasterRide.physicsBody?.isDynamic = false
        coasterRide.physicsBody?.categoryBitMask = PhysicsCategory.ridePads
        coasterRide.physicsBody?.collisionBitMask = 0
        coasterRide.physicsBody?.contactTestBitMask = PhysicsCategory.player
        addChild(coasterRide)

        let rideLabel = SKLabelNode(text: "🎢 Roller Coaster")
        rideLabel.fontName = "AvenirNext-Bold"
        rideLabel.fontSize = 18
        rideLabel.fontColor = .white
        rideLabel.position = CGPoint(x: 0, y: 0)
        rideLabel.zPosition = 2
        coasterRide.addChild(rideLabel)

        // Ferris wheel decoration (placeholder art)
        createFerrisWheel(at: CGPoint(x: -400, y: -200))
    }

    private func configureFence(_ node: SKSpriteNode) {
        node.zPosition = 5
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.walls
        node.physicsBody?.collisionBitMask = PhysicsCategory.player
        node.physicsBody?.contactTestBitMask = PhysicsCategory.none
        addChild(node)
    }

    private func createPortalLabel(text: String) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = 16
        label.fontColor = .black
        label.verticalAlignmentMode = .center
        label.zPosition = 2
        return label
    }

    private func createPortal(color: SKColor, text: String) -> SKSpriteNode {
        let pad = SKSpriteNode(color: color, size: CGSize(width: 200, height: 80))
        pad.zPosition = 1
        pad.physicsBody = SKPhysicsBody(rectangleOf: pad.size)
        pad.physicsBody?.isDynamic = false
        pad.physicsBody?.categoryBitMask = PhysicsCategory.portalPads
        pad.physicsBody?.collisionBitMask = 0
        pad.physicsBody?.contactTestBitMask = PhysicsCategory.player
        let label = createPortalLabel(text: text)
        pad.addChild(label)
        return pad
    }

    private func createFerrisWheel(at position: CGPoint) {
        let wheelRadius: CGFloat = 80
        let circle = SKShapeNode(circleOfRadius: wheelRadius)
        circle.strokeColor = .white
        circle.lineWidth = 4
        circle.position = position
        circle.zPosition = 1
        addChild(circle)

        let hub = SKShapeNode(circleOfRadius: 10)
        hub.fillColor = .systemOrange
        hub.strokeColor = .clear
        hub.position = position
        hub.zPosition = 2
        addChild(hub)

        let spokes = SKNode()
        spokes.position = position
        spokes.zPosition = 1
        addChild(spokes)

        for i in 0..<6 {
            let spoke = SKShapeNode(rectOf: CGSize(width: 6, height: wheelRadius * 2))
            spoke.fillColor = .lightGray
            spoke.strokeColor = .clear
            spoke.zPosition = 1
            spoke.zRotation = CGFloat(i) * (.pi / 6)
            spokes.addChild(spoke)
        }

        let cabins = SKNode()
        cabins.position = position
        cabins.zPosition = 2
        addChild(cabins)

        for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 3) {
            let cabin = SKShapeNode(rectOf: CGSize(width: 18, height: 18), cornerRadius: 4)
            cabin.fillColor = .systemBlue
            cabin.strokeColor = .clear
            cabin.position = CGPoint(x: position.x + wheelRadius * cos(angle),
                                     y: position.y + wheelRadius * sin(angle))
            cabins.addChild(cabin)
        }

        let rotation = SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 6))
        spokes.run(rotation)
        cabins.run(rotation)
    }

    private func setupPlayer() {
        player.position = CGPoint(x: 0, y: 0)
        player.zPosition = 10
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 3
        player.physicsBody?.friction = 0
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.collisionBitMask = PhysicsCategory.walls
        player.physicsBody?.contactTestBitMask = PhysicsCategory.portalPads | PhysicsCategory.ridePads
        addChild(player)
    }

    private func setupCamera() {
        camera = cameraNode
        addChild(cameraNode)
        cameraNode.position = player.position
        cameraNode.addChild(hudNode)
        hudNode.zPosition = 100
    }

    private func setupHUD() {
        hudTicketsLabel.fontSize = 18
        hudTicketsLabel.horizontalAlignmentMode = .right
        hudTicketsLabel.verticalAlignmentMode = .top
        hudTicketsLabel.fontColor = .white
        hudTicketsLabel.position = CGPoint(x: size.width / 2 - 16, y: size.height / 2 - 20)
        hudNode.addChild(hudTicketsLabel)

        backButton.position = CGPoint(x: -size.width / 2 + 100, y: size.height / 2 - 40)
        backButton.zPosition = 101
        hudNode.addChild(backButton)
    }

    private func setupDPad() {
        let dpadSize: CGFloat = 60
        let positions: [Direction: CGPoint] = [
            .up: CGPoint(x: -size.width / 2 + dpadSize, y: -size.height / 2 + dpadSize * 2.3),
            .down: CGPoint(x: -size.width / 2 + dpadSize, y: -size.height / 2 + dpadSize * 0.7),
            .left: CGPoint(x: -size.width / 2 + dpadSize - 50, y: -size.height / 2 + dpadSize * 1.5),
            .right: CGPoint(x: -size.width / 2 + dpadSize + 50, y: -size.height / 2 + dpadSize * 1.5)
        ]

        for (direction, position) in positions {
            let node = SKSpriteNode(color: .darkGray, size: CGSize(width: 54, height: 54))
            node.alpha = 0.8
            node.position = position
            node.name = "dpad_\(direction)"
            hudNode.addChild(node)
            dpadButtons[direction] = node
        }
    }

    private func updateTicketsLabel() {
        hudTicketsLabel.text = "Tickets: \(TicketStore.tickets)"
    }

    private func updateVelocity() {
        guard !movementDirections.isEmpty else {
            player.physicsBody?.velocity = .zero
            return
        }
        var dx: CGFloat = 0
        var dy: CGFloat = 0
        for direction in movementDirections {
            dx += direction.vector.dx
            dy += direction.vector.dy
        }
        let vector = CGVector(dx: dx, dy: dy)
        let length = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
        let normalized = length > 0 ? CGVector(dx: vector.dx / length, dy: vector.dy / length) : .zero
        player.physicsBody?.velocity = CGVector(dx: normalized.dx * playerSpeed, dy: normalized.dy * playerSpeed)
    }

    private func handleWorldTap(at location: CGPoint) {
        guard !rideAnimating else { return }
        if player.frame.intersects(coasterRide.frame) {
            triggerCoasterRide()
            return
        }
        if player.frame.intersects(bottlePortal.frame) {
            goToBottleToss()
            return
        }
        if player.frame.intersects(plinkoPortal.frame) {
            goToPlinko()
            return
        }
    }

    private func triggerCoasterRide() {
        guard !rideAnimating else { return }
        rideAnimating = true
        movementDirections.removeAll()
        updateVelocity()

        let woo = SKLabelNode(text: "Woo!")
        woo.fontName = "AvenirNext-Bold"
        woo.fontColor = .white
        woo.fontSize = 32
        woo.position = CGPoint(x: 0, y: 40)
        woo.alpha = 0
        cameraNode.addChild(woo)

        let focusPosition = coasterRide.position
        let focusAction = SKAction.move(to: focusPosition, duration: 0.4)
        focusAction.timingMode = .easeInEaseOut

        let sequence = SKAction.sequence([
            SKAction.run { woo.run(SKAction.fadeIn(withDuration: 0.1)) },
            focusAction,
            SKAction.run { [weak self] in self?.cameraShake() },
            SKAction.wait(forDuration: 0.5),
            SKAction.run { woo.run(SKAction.sequence([SKAction.wait(forDuration: 0.2), SKAction.fadeOut(withDuration: 0.2), SKAction.removeFromParent()])) }
        ])

        cameraNode.run(sequence) { [weak self] in
            guard let self = self else { return }
            self.rideAnimating = false
            self.cameraNode.position = self.player.position
            if !self.rideVisited {
                self.rideVisited = true
                TicketStore.addTickets(1)
                self.updateTicketsLabel()
            }
        }
    }

    private func goToBottleToss() {
        guard let view = view else { return }
        let scene = BottleTossScene(size: size)
        view.transition(to: scene)
    }

    private func goToPlinko() {
        guard let view = view else { return }
        let scene = PlinkoScene(size: size)
        view.transition(to: scene)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let cameraLocation = touch.location(in: hudNode)
            var handled = false
            for (direction, button) in dpadButtons where button.contains(cameraLocation) {
                button.colorBlendFactor = 0.6
                movementDirections.insert(direction)
                touchDirectionMap[touch] = direction
                handled = true
                updateVelocity()
                break
            }
            if handled { continue }

            if backButton.contains(cameraLocation) {
                backButton.colorBlendFactor = 0.4
            } else {
                let worldLocation = touch.location(in: self)
                handleWorldTap(at: worldLocation)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let direction = touchDirectionMap[touch], let button = dpadButtons[direction] {
                let cameraLocation = touch.location(in: hudNode)
                if button.contains(cameraLocation) {
                    button.colorBlendFactor = 0.6
                } else {
                    button.colorBlendFactor = 0
                    movementDirections.remove(direction)
                    touchDirectionMap.removeValue(forKey: touch)
                    updateVelocity()
                }
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouchCompletion(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouchCompletion(touches)
    }

    private func handleTouchCompletion(_ touches: Set<UITouch>) {
        for touch in touches {
            if let direction = touchDirectionMap.removeValue(forKey: touch), let button = dpadButtons[direction] {
                button.colorBlendFactor = 0
                movementDirections.remove(direction)
            } else {
                let cameraLocation = touch.location(in: hudNode)
                if backButton.contains(cameraLocation) {
                    backButton.colorBlendFactor = 0
                    if let view = view {
                        let scene = MainMenuScene(size: size)
                        view.transition(to: scene)
                    }
                }
            }
        }
        updateVelocity()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var updated = false
        for press in presses {
            guard let key = press.key?.charactersIgnoringModifiers.lowercased() else { continue }
            switch key {
            case "w": movementDirections.insert(.up); updated = true
            case "s": movementDirections.insert(.down); updated = true
            case "a": movementDirections.insert(.left); updated = true
            case "d": movementDirections.insert(.right); updated = true
            default: break
            }
        }
        if updated { updateVelocity() }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var updated = false
        for press in presses {
            guard let key = press.key?.charactersIgnoringModifiers.lowercased() else { continue }
            switch key {
            case "w": movementDirections.remove(.up); updated = true
            case "s": movementDirections.remove(.down); updated = true
            case "a": movementDirections.remove(.left); updated = true
            case "d": movementDirections.remove(.right); updated = true
            default: break
            }
        }
        if updated { updateVelocity() }
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        lastUpdateTime = currentTime
        if !rideAnimating {
            cameraNode.position = player.position
        }
    }
}
