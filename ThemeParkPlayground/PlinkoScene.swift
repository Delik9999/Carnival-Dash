import SpriteKit

class PlinkoScene: SKScene, SKPhysicsContactDelegate {
    private let backButton = ButtonNode(size: CGSize(width: 160, height: 44), text: "Back to Park", color: .systemRed)
    private let playAgainButton = ButtonNode(size: CGSize(width: 160, height: 44), text: "Play Again", color: .systemGreen)
    private let overlayNode = SKSpriteNode(color: SKColor(white: 0, alpha: 0.65), size: CGSize(width: 300, height: 200))
    private let hudTicketsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var slotValues: [SKNode: Int] = [:]
    private var ballsDropped = 0
    private var activeBalls: Set<SKNode> = []
    private let resultLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let maxBalls = 3

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.05, green: 0.08, blue: 0.12, alpha: 1)
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
        setupHUD()
        setupBoard()
    }

    private func setupHUD() {
        camera = SKCameraNode()
        if let camera = camera {
            addChild(camera)
            camera.addChild(backButton)
            camera.addChild(hudTicketsLabel)
            camera.addChild(overlayNode)
        }

        backButton.position = CGPoint(x: -size.width / 2 + 110, y: size.height / 2 - 50)

        hudTicketsLabel.fontSize = 18
        hudTicketsLabel.fontColor = .white
        hudTicketsLabel.horizontalAlignmentMode = .right
        hudTicketsLabel.verticalAlignmentMode = .top
        hudTicketsLabel.position = CGPoint(x: size.width / 2 - 16, y: size.height / 2 - 20)
        updateTicketsLabel()

        overlayNode.isHidden = true
        overlayNode.zPosition = 50
        overlayNode.position = CGPoint(x: 0, y: 60)

        resultLabel.fontSize = 20
        resultLabel.verticalAlignmentMode = .center
        resultLabel.numberOfLines = 2
        overlayNode.addChild(resultLabel)

        playAgainButton.position = CGPoint(x: 0, y: -60)
        overlayNode.addChild(playAgainButton)

        let overlayBack = ButtonNode(size: CGSize(width: 160, height: 44), text: "Back", color: .systemBlue)
        overlayBack.position = CGPoint(x: 0, y: -110)
        overlayBack.name = "overlayBack"
        overlayNode.addChild(overlayBack)
    }

    private func setupBoard() {
        physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 40, y: 60, width: size.width - 80, height: size.height - 120))
        physicsBody?.categoryBitMask = PhysicsCategory.walls
        physicsBody?.restitution = 0.2

        addPegGrid()
        addSlots()
    }

    private func addPegGrid() {
        let columns = 7
        let rows = 8
        let spacingX = (size.width - 160) / CGFloat(columns - 1)
        let spacingY: CGFloat = 70
        let startY = size.height - 180
        for row in 0..<rows {
            for column in 0..<columns {
                var x = CGFloat(column) * spacingX + 80
                if row % 2 == 1 { x += spacingX / 2 }
                let y = startY - CGFloat(row) * spacingY
                let peg = SKShapeNode(circleOfRadius: 14)
                peg.fillColor = .systemOrange
                peg.strokeColor = .white
                peg.position = CGPoint(x: x, y: y)
                peg.physicsBody = SKPhysicsBody(circleOfRadius: 14)
                peg.physicsBody?.isDynamic = false
                peg.physicsBody?.restitution = 0.8
                peg.physicsBody?.categoryBitMask = PhysicsCategory.pegs
                peg.physicsBody?.contactTestBitMask = PhysicsCategory.projectiles
                addChild(peg)
            }
        }
    }

    private func addSlots() {
        let slotWidth = (size.width - 120) / 3
        let slotHeight: CGFloat = 80
        let slotValuesOrder = [10, 20, 50]
        for index in 0..<3 {
            let colors: [SKColor] = [.systemBlue, .systemPurple, .systemYellow]
            let slot = SKSpriteNode(color: colors[index], size: CGSize(width: slotWidth - 10, height: slotHeight))
            let x = CGFloat(index) * slotWidth + slotWidth / 2 + 60
            slot.position = CGPoint(x: x, y: 80)
            slot.physicsBody = SKPhysicsBody(rectangleOf: slot.size)
            slot.physicsBody?.isDynamic = false
            slot.physicsBody?.categoryBitMask = PhysicsCategory.slots
            slot.physicsBody?.contactTestBitMask = PhysicsCategory.projectiles
            slot.physicsBody?.collisionBitMask = PhysicsCategory.none
            slotValues[slot] = slotValuesOrder[index]
            addChild(slot)

            let label = SKLabelNode(text: "\(slotValuesOrder[index])")
            label.fontName = "AvenirNext-Bold"
            label.fontColor = .black
            label.fontSize = 22
            label.position = CGPoint(x: 0, y: -10)
            label.verticalAlignmentMode = .center
            slot.addChild(label)
        }

        for index in 0...3 {
            let guide = SKSpriteNode(color: .darkGray, size: CGSize(width: 4, height: 140))
            let x = CGFloat(index) * ((size.width - 120) / 3) + 60
            guide.position = CGPoint(x: x, y: 150)
            guide.physicsBody = SKPhysicsBody(rectangleOf: guide.size)
            guide.physicsBody?.isDynamic = false
            guide.physicsBody?.categoryBitMask = PhysicsCategory.walls
            guide.physicsBody?.collisionBitMask = PhysicsCategory.projectiles
            guide.physicsBody?.contactTestBitMask = PhysicsCategory.none
            addChild(guide)
        }
    }

    private func spawnBall(at x: CGFloat) {
        guard ballsDropped < maxBalls else { return }
        let jitter = CGFloat.random(in: -12...12)
        let clampedX = min(max(x + jitter, 60), size.width - 60)
        let ball = SKShapeNode(circleOfRadius: 16)
        ball.fillColor = .systemTeal
        ball.strokeColor = .white
        ball.position = CGPoint(x: clampedX, y: size.height - 80)
        ball.zPosition = 5
        let body = SKPhysicsBody(circleOfRadius: 16)
        body.restitution = 0.75
        body.friction = 0.1
        body.linearDamping = 0.1
        body.categoryBitMask = PhysicsCategory.projectiles
        body.contactTestBitMask = PhysicsCategory.slots | PhysicsCategory.pegs | PhysicsCategory.walls
        body.collisionBitMask = PhysicsCategory.pegs | PhysicsCategory.walls
        ball.physicsBody = body
        addChild(ball)
        activeBalls.insert(ball)
        ballsDropped += 1
    }

    private func updateTicketsLabel() {
        hudTicketsLabel.text = "Tickets: \(TicketStore.tickets)"
    }

    private func showOverlay(with message: String) {
        overlayNode.isHidden = false
        overlayNode.alpha = 0
        resultLabel.text = message
        overlayNode.run(SKAction.fadeIn(withDuration: 0.25))
    }

    private func handleBackToPark() {
        guard let view = view else { return }
        let scene = ParkScene(size: size)
        view.transition(to: scene)
    }

    private func handlePlayAgain() {
        overlayNode.isHidden = true
        overlayNode.alpha = 1
        resultLabel.text = ""
        ballsDropped = 0
        for ball in activeBalls { ball.removeFromParent() }
        activeBalls.removeAll()
        playAgainButton.colorBlendFactor = 0
        if let backNode = overlayNode.childNode(withName: "overlayBack") as? ButtonNode {
            backNode.colorBlendFactor = 0
        }
    }

    private func handleSlotWin(value: Int, at position: CGPoint) {
        TicketStore.addTickets(value)
        updateTicketsLabel()

        let label = SKLabelNode(text: "+\(value)")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 22
        label.fontColor = .white
        label.position = position
        label.zPosition = 20
        addChild(label)
        let action = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 60, duration: 0.6),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])
        label.run(action)
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let first = contact.bodyA.categoryBitMask
        let second = contact.bodyB.categoryBitMask
        if first == PhysicsCategory.slots && second == PhysicsCategory.projectiles {
            handleBall(contact.bodyB.node, in: contact.bodyA.node)
        } else if second == PhysicsCategory.slots && first == PhysicsCategory.projectiles {
            handleBall(contact.bodyA.node, in: contact.bodyB.node)
        }
    }

    private func handleBall(_ ballNode: SKNode?, in slotNode: SKNode?) {
        guard let ball = ballNode, let slot = slotNode, let value = slotValues[slot] else { return }
        if activeBalls.contains(ball) {
            activeBalls.remove(ball)
            ball.removeFromParent()
            handleSlotWin(value: value, at: slot.position + CGPoint(x: 0, y: 50))
            if ballsDropped >= maxBalls && activeBalls.isEmpty {
                showOverlay(with: "All balls used!\nTap Play Again or Back")
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        if !overlayNode.isHidden {
            let location = touch.location(in: overlayNode)
            if playAgainButton.contains(location) {
                playAgainButton.colorBlendFactor = 0.4
            } else if let backNode = overlayNode.childNode(withName: "overlayBack") as? ButtonNode, backNode.contains(location) {
                backNode.colorBlendFactor = 0.4
            }
            return
        }

        let cameraLocation = touch.location(in: camera ?? self)
        if backButton.contains(cameraLocation) {
            backButton.colorBlendFactor = 0.4
            return
        }

        let location = touch.location(in: self)
        spawnBall(at: location.x)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        if !overlayNode.isHidden {
            let location = touch.location(in: overlayNode)
            if playAgainButton.contains(location) {
                playAgainButton.colorBlendFactor = 0
                handlePlayAgain()
                return
            }
            if let backNode = overlayNode.childNode(withName: "overlayBack") as? ButtonNode, backNode.contains(location) {
                backNode.colorBlendFactor = 0
                handleBackToPark()
                return
            }
            playAgainButton.colorBlendFactor = 0
            if let backNode = overlayNode.childNode(withName: "overlayBack") as? ButtonNode {
                backNode.colorBlendFactor = 0
            }
            return
        }

        let cameraLocation = touch.location(in: camera ?? self)
        if backButton.contains(cameraLocation) {
            backButton.colorBlendFactor = 0
            handleBackToPark()
            return
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    override func update(_ currentTime: TimeInterval) {
        var toRemove: [SKNode] = []
        for ball in activeBalls where ball.position.y < 40 {
            toRemove.append(ball)
        }
        for ball in toRemove {
            activeBalls.remove(ball)
            ball.removeFromParent()
        }
        if !overlayNode.isHidden { return }
        if ballsDropped >= maxBalls && activeBalls.isEmpty {
            showOverlay(with: "All balls used!\nTap Play Again or Back")
        }
    }
}

private extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}
