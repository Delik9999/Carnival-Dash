import SpriteKit

class BottleTossScene: SKScene, SKPhysicsContactDelegate {
    private let backButton = ButtonNode(size: CGSize(width: 160, height: 44), text: "Back to Park", color: .systemRed)
    private let playAgainButton = ButtonNode(size: CGSize(width: 160, height: 44), text: "Play Again", color: .systemGreen)
    private let overlayNode = SKSpriteNode(color: SKColor(white: 0, alpha: 0.65), size: CGSize(width: 280, height: 180))
    private let hudTicketsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var bottles: [SKSpriteNode] = []
    private var downedBottles: Set<SKSpriteNode> = []
    private var currentBall: SKShapeNode?
    private var touchStartLocation: CGPoint?
    private var ballsRemaining = 3
    private var roundActive = true
    private let resultLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.15, blue: 0.18, alpha: 1)
        physicsWorld.gravity = CGVector(dx: 0, dy: -12)
        physicsWorld.contactDelegate = self
        setupHUD()
        setupLane()
        spawnBottleStack()
        spawnNextBall()
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
        resultLabel.preferredMaxLayoutWidth = 240
        overlayNode.addChild(resultLabel)

        playAgainButton.position = CGPoint(x: 0, y: -50)
        overlayNode.addChild(playAgainButton)

        let overlayBack = ButtonNode(size: CGSize(width: 160, height: 44), text: "Back", color: .systemBlue)
        overlayBack.position = CGPoint(x: 0, y: -100)
        overlayBack.name = "overlayBack"
        overlayNode.addChild(overlayBack)
    }

    private func setupLane() {
        let lane = SKSpriteNode(color: .darkGray, size: CGSize(width: size.width, height: 200))
        lane.position = CGPoint(x: size.width / 2, y: 100)
        lane.zPosition = -1
        addChild(lane)

        let ground = SKNode()
        ground.position = CGPoint(x: size.width / 2, y: 80)
        ground.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: -size.width / 2, y: 0), to: CGPoint(x: size.width / 2, y: 0))
        ground.physicsBody?.categoryBitMask = PhysicsCategory.walls
        ground.physicsBody?.contactTestBitMask = PhysicsCategory.projectiles
        addChild(ground)
    }

    private func spawnBottleStack() {
        for node in bottles { node.removeFromParent() }
        bottles.removeAll()
        downedBottles.removeAll()

        let baseWidth: CGFloat = 40
        let baseHeight: CGFloat = 80
        let spacing: CGFloat = 8
        let rows: [[CGFloat]] = [[-1, 0, 1], [-0.5, 0.5], [0]]
        for (index, row) in rows.enumerated() {
            let y = 200 + CGFloat(index) * (baseHeight + spacing)
            for offset in row {
                let bottle = SKSpriteNode(color: .lightGray, size: CGSize(width: baseWidth, height: baseHeight))
                bottle.position = CGPoint(x: size.width / 2 + offset * (baseWidth + spacing), y: y)
                bottle.physicsBody = SKPhysicsBody(rectangleOf: bottle.size)
                bottle.physicsBody?.allowsRotation = true
                bottle.physicsBody?.restitution = 0.2
                bottle.physicsBody?.friction = 0.8
                bottle.physicsBody?.mass = 0.4
                bottle.physicsBody?.categoryBitMask = PhysicsCategory.bottles
                bottle.physicsBody?.contactTestBitMask = PhysicsCategory.projectiles
                bottle.physicsBody?.collisionBitMask = PhysicsCategory.projectiles | PhysicsCategory.bottles | PhysicsCategory.walls
                bottle.name = "bottle"
                addChild(bottle)
                bottles.append(bottle)
            }
        }
    }

    private func spawnNextBall() {
        guard ballsRemaining > 0 else { return }
        let ball = SKShapeNode(circleOfRadius: 18)
        ball.fillColor = .systemTeal
        ball.strokeColor = .white
        ball.position = CGPoint(x: size.width / 2, y: 110)
        ball.zPosition = 5
        let body = SKPhysicsBody(circleOfRadius: 18)
        body.categoryBitMask = PhysicsCategory.projectiles
        body.contactTestBitMask = PhysicsCategory.bottles | PhysicsCategory.walls
        body.collisionBitMask = PhysicsCategory.bottles | PhysicsCategory.walls
        body.restitution = 0.4
        body.friction = 0.2
        body.mass = 0.6
        ball.physicsBody = body
        ball.physicsBody?.isDynamic = false
        addChild(ball)
        currentBall = ball
        touchStartLocation = nil
    }

    private func updateTicketsLabel() {
        hudTicketsLabel.text = "Tickets: \(TicketStore.tickets)"
    }

    private func checkRoundStatus() {
        for bottle in bottles where !downedBottles.contains(bottle) {
            if abs(bottle.zRotation) > .pi / 6 || bottle.position.y < 180 {
                downedBottles.insert(bottle)
            }
        }

        if downedBottles.count == bottles.count {
            endRound(won: true)
        } else if ballsRemaining == 0 && currentBall == nil {
            endRound(won: false)
        }
    }

    private func endRound(won: Bool) {
        guard roundActive else { return }
        roundActive = false
        overlayNode.isHidden = false
        overlayNode.alpha = 0
        overlayNode.run(SKAction.fadeIn(withDuration: 0.25))

        if won {
            TicketStore.addTickets(2)
            updateTicketsLabel()
            resultLabel.text = "You win!\n+2 tickets"
        } else {
            resultLabel.text = "Try again!"
        }
    }

    private func resetRound() {
        roundActive = true
        ballsRemaining = 3
        currentBall?.removeFromParent()
        currentBall = nil
        spawnBottleStack()
        spawnNextBall()
    }

    private func handleBackToPark() {
        guard let view = view else { return }
        let scene = ParkScene(size: size)
        view.transition(to: scene)
    }

    private func handlePlayAgain() {
        overlayNode.isHidden = true
        resultLabel.text = ""
        resetRound()
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

        guard let ball = currentBall, ball.contains(touch.location(in: self)) else { return }
        touchStartLocation = touch.location(in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard overlayNode.isHidden, let touch = touches.first, let ball = currentBall, let start = touchStartLocation else { return }
        let location = touch.location(in: self)
        let dx = location.x - start.x
        let dy = location.y - start.y
        let clampedY = max(90, min(200, start.y + dy))
        ball.position = CGPoint(x: start.x + dx, y: clampedY)
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

        guard let ball = currentBall, let start = touchStartLocation else { return }
        let releaseLocation = touch.location(in: self)
        let dx = releaseLocation.x - start.x
        let dy = releaseLocation.y - start.y
        let impulse = CGVector(dx: dx * 0.6, dy: max(dy, 40) * 0.9)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.applyImpulse(impulse)
        ballsRemaining -= 1
        currentBall = nil
        touchStartLocation = nil
        run(SKAction.wait(forDuration: 0.6)) { [weak self] in
            self?.spawnNextBall()
        }
        checkRoundStatus()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    override func update(_ currentTime: TimeInterval) {
        if roundActive { checkRoundStatus() }

        enumerateChildNodes(withName: "//*") { node, _ in
            if let shape = node as? SKShapeNode,
               shape.physicsBody?.categoryBitMask == PhysicsCategory.projectiles,
               shape.position.y < -100 {
                shape.removeFromParent()
            }
        }
    }
}
