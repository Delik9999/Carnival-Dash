import SpriteKit

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 1 << 0
    static let walls: UInt32 = 1 << 1
    static let ridePads: UInt32 = 1 << 2
    static let portalPads: UInt32 = 1 << 3
    static let projectiles: UInt32 = 1 << 4
    static let bottles: UInt32 = 1 << 5
    static let pegs: UInt32 = 1 << 6
    static let slots: UInt32 = 1 << 7
}

enum Direction: CaseIterable {
    case up, down, left, right

    var vector: CGVector {
        switch self {
        case .up: return CGVector(dx: 0, dy: 1)
        case .down: return CGVector(dx: 0, dy: -1)
        case .left: return CGVector(dx: -1, dy: 0)
        case .right: return CGVector(dx: 1, dy: 0)
        }
    }
}

struct TicketStore {
    private static let key = "tickets"

    static var tickets: Int {
        get { UserDefaults.standard.integer(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    static func addTickets(_ amount: Int) {
        tickets += amount
    }
}

extension SKView {
    func transition(to scene: SKScene, transition: SKTransition = .fade(withDuration: 0.5)) {
        scene.scaleMode = .resizeFill
        presentScene(scene, transition: transition)
    }
}

extension SKNode {
    func cameraShake(duration: TimeInterval = 0.4, amplitude: CGFloat = 12) {
        guard let camera = scene?.camera else { return }
        let numberOfShakes = Int(duration / 0.04)
        var actions: [SKAction] = []
        for _ in 0..<numberOfShakes {
            let dx = CGFloat.random(in: -amplitude...amplitude)
            let dy = CGFloat.random(in: -amplitude...amplitude)
            actions.append(SKAction.moveBy(x: dx, y: dy, duration: 0.02))
            actions.append(SKAction.moveBy(x: -dx, y: -dy, duration: 0.02))
        }
        camera.run(SKAction.sequence(actions))
    }
}

class ButtonNode: SKSpriteNode {
    var action: (() -> Void)?

    init(size: CGSize, text: String, color: SKColor) {
        super.init(texture: nil, color: color, size: size)
        isUserInteractionEnabled = false
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 18
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.fontColor = .white
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
