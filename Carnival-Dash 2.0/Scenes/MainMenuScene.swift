import SpriteKit

class MainMenuScene: SKScene {
    private var playButton: ButtonNode!

    override func didMove(to view: SKView) {
        backgroundColor = .black

        let title = SKLabelNode(text: "ThemeParkPlayground")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 36
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.65)
        addChild(title)

        playButton = ButtonNode(size: CGSize(width: 180, height: 60), text: "Play", color: .systemGreen)
        playButton.position = CGPoint(x: size.width / 2, y: size.height * 0.4)
        addChild(playButton)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if playButton.contains(location) {
            playButton.colorBlendFactor = 0.4
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        playButton.colorBlendFactor = 0
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if playButton.contains(location), let view = view {
            let scene = ParkScene(size: size)
            view.transition(to: scene)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        playButton.colorBlendFactor = 0
    }
}
