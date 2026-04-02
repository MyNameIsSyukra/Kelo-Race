//
//  MenuScene.swift
//  KeloRace
//

import SpriteKit

class MenuScene: SKScene {

    override func didMove(to view: SKView) {
//        backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.15, alpha: 1)
        setupMenu()
        setupWalkingKelomang()  // ✅ Tambahkan ini
    }

    // MARK: - Animasi Kelomang Bergerak ke Atas
    func setupWalkingKelomang() {
        // Jumlah kelomang yang tampil bersamaan
        let count = 5
        
        for i in 0..<count {
            spawnKelomang(index: i, total: count)
        }
    }
    
    func spawnKelomang(index: Int, total: Int) {
        let walkAtlas = SKTextureAtlas(named: "Kelong")
        let firstFrame = walkAtlas.textureNamed("Kelong1")
        
        let kelomang = SKSpriteNode(texture: firstFrame)
        kelomang.size = CGSize(width: 40, height: 80)
        kelomang.zPosition = 1
        kelomang.alpha = 0.35
        
        let spacing = frame.width / CGFloat(total)
        let xPos = spacing * CGFloat(index) + spacing / 2 - frame.width / 2
        let startY = frame.minY - CGFloat.random(in: 0...frame.height)
        kelomang.position = CGPoint(x: xPos, y: startY)
        
        // ✅ Animasi jalan loop
        let frames = (1...9).map { walkAtlas.textureNamed("Kelong\($0)") }
        let walkAnim = SKAction.animate(with: frames, timePerFrame: 0.08)
        kelomang.run(SKAction.repeatForever(walkAnim))
        
        addChild(kelomang)
        animateKelomang(kelomang, xPos: xPos)
    }
    
    func animateKelomang(_ kelomang: SKSpriteNode, xPos: CGFloat) {
        // Kecepatan random tiap kelomang biar tidak monoton
        let duration = Double.random(in: 4.0...8.0)
        
        let moveUp = SKAction.moveTo(y: frame.maxY + 100, duration: duration)
        
        let reset = SKAction.run { [weak self, weak kelomang] in
            guard let self = self, let kelomang = kelomang else { return }
            // Setelah sampai atas, reset ke bawah lagi
            kelomang.position = CGPoint(x: xPos, y: self.frame.minY - 100)
        }
        
        let newDuration = SKAction.run { [weak self, weak kelomang] in
            guard let self = self, let kelomang = kelomang else { return }
            self.animateKelomang(kelomang, xPos: xPos)  // Loop dengan kecepatan baru
        }
        
        let sequence = SKAction.sequence([moveUp, reset, newDuration])
        kelomang.run(sequence)
    }

    // MARK: - Setup Menu UI
    func setupMenu() {
        // Judul "KeloRace"
        let titleLabel = SKLabelNode(text: "KeloRace")
        titleLabel.fontName = "AvenirNext-Heavy"
        titleLabel.fontSize = 54
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: frame.midX, y: frame.midY + 80)
        titleLabel.zPosition = 2

        let shadow = SKLabelNode(text: "KeloRace")
        shadow.fontName = "AvenirNext-Heavy"
        shadow.fontSize = 54
        shadow.fontColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 0.4)
        shadow.position = CGPoint(x: frame.midX + 3, y: frame.midY + 77)
        shadow.zPosition = 1
        addChild(shadow)
        addChild(titleLabel)

        let sub = SKLabelNode(text: "Blow to race 💨")
        sub.fontName = "AvenirNext-Regular"
        sub.fontSize = 18
        sub.fontColor = UIColor.white.withAlphaComponent(0.6)
        sub.position = CGPoint(x: frame.midX, y: frame.midY + 30)
        sub.zPosition = 2
        addChild(sub)

        // Tombol Start
        let startBtn = SKShapeNode(rectOf: CGSize(width: 220, height: 60), cornerRadius: 18)
        startBtn.fillColor = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1)
        startBtn.strokeColor = .clear
        startBtn.position = CGPoint(x: frame.midX, y: frame.midY - 60)
        startBtn.zPosition = 2
        startBtn.name = "startButton"

        let startLabel = SKLabelNode(text: "Start")
        startLabel.fontName = "AvenirNext-Bold"
        startLabel.fontSize = 26
        startLabel.fontColor = .white
        startLabel.verticalAlignmentMode = .center
        startLabel.horizontalAlignmentMode = .center
        startLabel.position = .zero
        startLabel.name = "startButton"
        startBtn.addChild(startLabel)
        addChild(startBtn)

        // Animasi pulse tombol Start
        let scaleUp = SKAction.scale(to: 1.06, duration: 0.7)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.7)
        scaleUp.timingMode = .easeInEaseOut
        scaleDown.timingMode = .easeInEaseOut
        startBtn.run(SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown])))
    }

    // MARK: - Touch → Start Game
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        for node in nodes(at: location) {
            if node.name == "startButton" {
                if let view = self.view,
                   let gameScene = SKScene(fileNamed: "GameScene") as? GameScene {
                    gameScene.scaleMode = .aspectFill
                    view.presentScene(gameScene, transition: .fade(withDuration: 0.5))
                }
                return
            }
        }
    }
}
