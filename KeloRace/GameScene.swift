//
//  GameScene.swift
//  KeloRace
//
//  Created by Syukra Wahyu Ramadhan on 17/03/26.
//

import SpriteKit
import GameplayKit
import AVFoundation
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    let player = SKSpriteNode()
    let motionManager = CMMotionManager()

    // MARK: - Player State
    enum PlayerState {
        case idle
        case blowing
        case walking
    }

    var playerState: PlayerState = .idle
    var currentAnimationKey = "playerAnim"

    // MARK: - Scene Nodes
    var background = SKSpriteNode(imageNamed: "Background")
    var finishLine = SKSpriteNode(imageNamed: "FinishLine")

    // MARK: - Audio
    var micAudioEngine = AVAudioEngine()
    var inputNode: AVAudioInputNode!
    var isBlowing = false

    // MARK: - Game State
    var elapsedTime: TimeInterval = 0
    var isGameRunning = false
    var isPaused_game = false
    var pauseOverlay: SKNode?
    var stopwatchLabel: SKLabelNode!

    // MARK: - Star System
    var collectedStars: Int = 0
    let totalStars: Int = 3
    var starNodes: [SKSpriteNode] = []
    var starCountLabel: SKLabelNode!

    // MARK: - didMove
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        setupPlayer()
        startListening()
        setupFinishLine()
        startMotion()
        setupObstacle()
        setupStopwatch()
        setupPauseButton()
        setupStars()
        setupStarUI()

        view.showsPhysics = true
    }

    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        if isGameRunning {
            elapsedTime += 1.0 / 60.0
            stopwatchLabel.text = formatTime(elapsedTime)
        }
    }

    // MARK: - Setup Player
    func setupPlayer() {
        let idleAtlas = SKTextureAtlas(named: "Kelong")
        player.texture = idleAtlas.textureNamed("Idle1")
        player.size = CGSize(width: 40, height: 80)
        player.position = CGPoint(x: frame.midX, y: -500)
        player.zPosition = 3

        player.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = 1
        player.physicsBody?.contactTestBitMask = 2 | 4 | 8
        player.physicsBody?.collisionBitMask = 0

        addChild(player)
    }

    // MARK: - Setup Finish Line
    func setupFinishLine() {
        finishLine.position = CGPoint(x: frame.midX, y: 500)
        finishLine.size = CGSize(width: 850, height: 80)

        finishLine.physicsBody = SKPhysicsBody(rectangleOf: finishLine.size)
        finishLine.physicsBody?.isDynamic = false
        finishLine.physicsBody?.affectedByGravity = false
        finishLine.physicsBody?.categoryBitMask = 4
        finishLine.physicsBody?.contactTestBitMask = 1
        finishLine.physicsBody?.collisionBitMask = 0

        addChild(finishLine)
    }

    // MARK: - Setup Obstacle
    func setupObstacle() {
        enumerateChildNodes(withName: "//obstacleHit") { node, _ in
            guard let sprite = node as? SKSpriteNode else { return }

            sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
            sprite.physicsBody?.isDynamic = false
            sprite.physicsBody?.affectedByGravity = false
            sprite.physicsBody?.categoryBitMask = 2
            sprite.physicsBody?.contactTestBitMask = 1
            sprite.physicsBody?.collisionBitMask = 0

            print("✅ Obstacle setup di posisi: \(sprite.position)")
        }
    }

    // MARK: - Setup Stars
    // Taruh bintang di GameScene.sks dengan name: star_0, star_1, star_2
    // Fungsi ini hanya assign physics & animasi saja
    func setupStars() {
        enumerateChildNodes(withName: "//star_*") { node, _ in
            guard let star = node as? SKSpriteNode else { return }

            star.physicsBody = SKPhysicsBody(circleOfRadius: 20)
            star.physicsBody?.isDynamic = false
            star.physicsBody?.affectedByGravity = false
            star.physicsBody?.categoryBitMask = 8
            star.physicsBody?.contactTestBitMask = 1
            star.physicsBody?.collisionBitMask = 0

            // Animasi mengambang naik turun
            let moveUp = SKAction.moveBy(x: 0, y: 8, duration: 0.6)
            let moveDown = SKAction.moveBy(x: 0, y: -8, duration: 0.6)
            moveUp.timingMode = .easeInEaseOut
            moveDown.timingMode = .easeInEaseOut
            let float = SKAction.repeatForever(SKAction.sequence([moveUp, moveDown]))
            star.run(float)

            self.starNodes.append(star)
            print("⭐ Star setup di posisi: \(star.position)")
        }
    }

    // MARK: - Setup Star UI
    func setupStarUI() {
        let pill = SKShapeNode(rectOf: CGSize(width: 100, height: 36), cornerRadius: 18)
        pill.fillColor = UIColor.black.withAlphaComponent(0.45)
        pill.strokeColor = .clear
        pill.position = CGPoint(x: -200, y: size.height / 2 - 100)
        pill.zPosition = 99
        pill.name = "starPill"

        starCountLabel = SKLabelNode(text: "⭐ 0/3")
        starCountLabel.fontName = "AvenirNext-Bold"
        starCountLabel.fontSize = 16
        starCountLabel.fontColor = .white
        starCountLabel.horizontalAlignmentMode = .center
        starCountLabel.verticalAlignmentMode = .center
        starCountLabel.position = .zero
        starCountLabel.zPosition = 1

        pill.addChild(starCountLabel)
        addChild(pill)
    }

    // MARK: - Collect Star
    func collectStar(node: SKNode) {
        guard node.parent != nil else { return }

        // Efek pop lalu hilang
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)
        let remove = SKAction.removeFromParent()
        node.run(SKAction.sequence([scaleUp, fadeOut, remove]))

        collectedStars += 1
        starCountLabel.text = "⭐ \(collectedStars)/\(totalStars)"

        print("⭐ Bintang terkumpul: \(collectedStars)/\(totalStars)")
    }

    // MARK: - Stopwatch
    func setupStopwatch() {
        let topY = size.height / 2 - 100

        let pill = SKShapeNode(rectOf: CGSize(width: 160, height: 44), cornerRadius: 22)
        pill.fillColor = UIColor.black.withAlphaComponent(0.45)
        pill.strokeColor = .clear
        pill.position = CGPoint(x: 0, y: topY)
        pill.zPosition = 99

        stopwatchLabel = SKLabelNode(text: "00:00.0")
        stopwatchLabel.fontName = "Courier-Bold"
        stopwatchLabel.fontSize = 22
        stopwatchLabel.fontColor = .white
        stopwatchLabel.position = CGPoint(x: 0, y: 0)
        stopwatchLabel.zPosition = 1
        stopwatchLabel.horizontalAlignmentMode = .center
        stopwatchLabel.verticalAlignmentMode = .center

        pill.addChild(stopwatchLabel)
        addChild(pill)

        isGameRunning = true
    }

    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time - Double(Int(time))) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }

    // MARK: - Win Modal
    func playerReachedFinish() {
        isGameRunning = false

        player.removeAllActions()
        motionManager.stopAccelerometerUpdates()
        micAudioEngine.stop()
        inputNode.removeTap(onBus: 0)

        print("🏆 Player menang! Waktu: \(formatTime(elapsedTime))")
        showWinModal(finalTime: elapsedTime)
    }

    func showWinModal(finalTime: TimeInterval) {
        let overlay = SKShapeNode(rectOf: self.size)
        overlay.position = CGPoint(x: frame.midX, y: frame.midY)
        overlay.fillColor = UIColor.black.withAlphaComponent(0.6)
        overlay.strokeColor = .clear
        overlay.zPosition = 10
        overlay.name = "winOverlay"
        addChild(overlay)

        // Card
        let card = SKShapeNode(rectOf: CGSize(width: 300, height: 300), cornerRadius: 20)
        card.position = CGPoint(x: frame.midX, y: frame.midY)
        card.fillColor = UIColor.white
        card.strokeColor = .clear
        card.zPosition = 11
        addChild(card)

        // Trophy
        let trophy = SKLabelNode(text: "🏆")
        trophy.fontSize = 64
        trophy.position = CGPoint(x: frame.midX, y: frame.midY + 100)
        trophy.zPosition = 12
        addChild(trophy)

        // Judul
        let title = SKLabelNode(text: "You Win!")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 32
        title.fontColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        title.position = CGPoint(x: frame.midX, y: frame.midY + 45)
        title.zPosition = 12
        addChild(title)

        // Finish Time caption
        let timeCaption = SKLabelNode(text: "Finish Time")
        timeCaption.fontName = "AvenirNext-Regular"
        timeCaption.fontSize = 14
        timeCaption.fontColor = .gray
        timeCaption.position = CGPoint(x: frame.midX, y: frame.midY + 5)
        timeCaption.zPosition = 12
        addChild(timeCaption)

        // Waktu final
        let timeLabel = SKLabelNode(text: formatTime(finalTime))
        timeLabel.fontName = "Courier-Bold"
        timeLabel.fontSize = 28
        timeLabel.fontColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1)
        timeLabel.position = CGPoint(x: frame.midX, y: frame.midY - 30)
        timeLabel.zPosition = 12
        addChild(timeLabel)

        // ✅ Bintang terkumpul
        let starResult = SKLabelNode(text: "⭐ \(collectedStars) / \(totalStars) Stars")
        starResult.fontName = "AvenirNext-Bold"
        starResult.fontSize = 20
        starResult.fontColor = UIColor(red: 1.0, green: 0.75, blue: 0.0, alpha: 1)
        starResult.position = CGPoint(x: frame.midX, y: frame.midY - 65)
        starResult.zPosition = 12
        addChild(starResult)

        // Tap to play again
        let sub = SKLabelNode(text: "Tap to play again")
        sub.fontName = "AvenirNext-Regular"
        sub.fontSize = 15
        sub.fontColor = .gray
        sub.position = CGPoint(x: frame.midX, y: frame.midY - 105)
        sub.zPosition = 12
        addChild(sub)

        // Animasi slide-up
        let nodes: [SKNode] = [card, trophy, title, timeCaption, timeLabel, starResult, sub]
        nodes.forEach { $0.position.y -= 300 }
        let slideUp = SKAction.moveBy(x: 0, y: 300, duration: 0.4)
        slideUp.timingMode = .easeOut
        nodes.forEach { $0.run(slideUp) }
    }

    // MARK: - Contact Detection
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB

        // Obstacle
        if (bodyA.categoryBitMask == 1 && bodyB.categoryBitMask == 2) ||
           (bodyA.categoryBitMask == 2 && bodyB.categoryBitMask == 1) {
            playerHitObstacle()
        }

        // Finish line
        if (bodyA.categoryBitMask == 1 && bodyB.categoryBitMask == 4) ||
           (bodyA.categoryBitMask == 4 && bodyB.categoryBitMask == 1) {
            playerReachedFinish()
        }

        // ✅ Bintang
        if bodyA.categoryBitMask == 1 && bodyB.categoryBitMask == 8 {
            if let node = bodyB.node { collectStar(node: node) }
        } else if bodyA.categoryBitMask == 8 && bodyB.categoryBitMask == 1 {
            if let node = bodyA.node { collectStar(node: node) }
        }
    }

    func playerHitObstacle() {
        player.removeAllActions()

        let moveDown = SKAction.moveBy(x: 0, y: -80, duration: 0.2)
        let wait = SKAction.wait(forDuration: 0.3)
        player.run(SKAction.sequence([moveDown, wait]))

        // Kembalikan animasi idle setelah kena obstacle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.playerState = .walking // reset state supaya idle bisa jalan
            self.playIdleAnimation()
        }

        print("💥 Player hit obstacle!")
    }

    // MARK: - Animations
    func playIdleAnimation() {
        playerState = .idle

        player.removeAction(forKey: currentAnimationKey)

        let idleAtlas = SKTextureAtlas(named: "Kelong")
        let frames = [
            idleAtlas.textureNamed("Idle1"),
            idleAtlas.textureNamed("Idle2"),
            idleAtlas.textureNamed("Idle3"),
            idleAtlas.textureNamed("Idle4")
        ]

        // Animate sekali saja, berhenti di frame terakhir (Idle4 = masuk cangkang)
        let anim = SKAction.animate(with: frames, timePerFrame: 0.08)
        player.run(anim, withKey: currentAnimationKey)
    }

    func playBlowAnimation() {
        guard playerState != .blowing else { return }
        playerState = .blowing

        player.removeAction(forKey: currentAnimationKey)

        let idleAtlas = SKTextureAtlas(named: "Kelong")
        let frames = [
            idleAtlas.textureNamed("Idle4"),
            idleAtlas.textureNamed("Idle3"),
            idleAtlas.textureNamed("Idle2"),
            idleAtlas.textureNamed("Idle1")
        ]

        // Keluar dari cangkang, lalu langsung walk
        let anim = SKAction.animate(with: frames, timePerFrame: 0.05)
        player.run(anim) {
            self.playWalkAnimation()
        }
    }

    func playWalkAnimation() {
        guard playerState != .walking else { return }
        playerState = .walking

        player.removeAction(forKey: currentAnimationKey)

        let walkAtlas = SKTextureAtlas(named: "Kelong")
        let frames = [
            walkAtlas.textureNamed("Kelong1"),
            walkAtlas.textureNamed("Kelong2"),
            walkAtlas.textureNamed("Kelong3"),
            walkAtlas.textureNamed("Kelong4"),
            walkAtlas.textureNamed("Kelong5"),
            walkAtlas.textureNamed("Kelong6"),
            walkAtlas.textureNamed("Kelong7"),
            walkAtlas.textureNamed("Kelong8"),
            walkAtlas.textureNamed("Kelong9")
        ]

        let anim = SKAction.animate(with: frames, timePerFrame: 0.05)
        player.run(SKAction.repeatForever(anim), withKey: currentAnimationKey)
    }

    // MARK: - Microphone
    func startListening() {
        inputNode = micAudioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, time in
            let channelData = buffer.floatChannelData![0]
            let frameLength = Int(buffer.frameLength)

            var sum: Float = 0
            for i in 0..<frameLength {
                sum += channelData[i] * channelData[i]
            }

            let rms = sqrt(sum / Float(frameLength))
            let power = 20 * log10(rms)

            DispatchQueue.main.async {
                self.handleSoundLevel(power: power)
            }
        }

        do {
            try micAudioEngine.start()
        } catch {
            print("Audio Engine Error: \(error)")
        }
    }

    func handleSoundLevel(power: Float) {
        let threshold: Float = -30

        if power > threshold {
            if !isBlowing {
                isBlowing = true
                blowDetected()
            }
        } else {
            isBlowing = false
        }
    }

    func blowDetected() {
        let moveUp = SKAction.moveBy(x: 0, y: 20, duration: 0.1)
        player.run(moveUp)

        playBlowAnimation()

        NSObject.cancelPreviousPerformRequests(withTarget: self,
            selector: #selector(returnToIdle), object: nil)
        perform(#selector(returnToIdle), with: nil, afterDelay: 0.4)
    }

    @objc func returnToIdle() {
        playerState = .walking // reset state supaya idle bisa dijalankan
        playIdleAnimation()
    }

    // MARK: - Motion
    func startMotion() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.02
            motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { data, error in
                guard let data = data else { return }
                DispatchQueue.main.async {
                    self.movePlayerHorizontally(tilt: data.acceleration.x)
                }
            }
        }
    }

    func movePlayerHorizontally(tilt: Double) {
        let sensitivity: CGFloat = 500
        let newX = player.position.x + CGFloat(tilt) * sensitivity * 0.02

        let minX = -self.size.width / 2 + player.size.width / 2
        let maxX = self.size.width / 2 - player.size.width / 2
        player.position.x = max(minX, min(maxX, newX))

        if tilt > 0.05 {
            player.xScale = abs(player.xScale) * -1
        } else if tilt < -0.05 {
            player.xScale = abs(player.xScale)
        }
    }

    // MARK: - Touch Handler
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        for node in tappedNodes {
            if node.name == "pauseButton" && !isPaused_game {
                showPauseMenu()
                return
            }
            if node.name == "resumeButton" {
                resumeGame()
                return
            }
            if node.name == "mainMenuButton" {
                goToMainMenu()
                return
            }
        }

        if childNode(withName: "winOverlay") != nil {
            restartGame()
        }
    }

    func goToMainMenu() {
        micAudioEngine.stop()
        motionManager.stopAccelerometerUpdates()
        if let view = self.view,
           let menuScene = SKScene(fileNamed: "MenuScene") as? MenuScene {
            menuScene.scaleMode = .aspectFill
            view.presentScene(menuScene, transition: .fade(withDuration: 0.4))
        }
    }

    func restartGame() {
        if let view = self.view,
           let newScene = SKScene(fileNamed: "GameScene") as? GameScene {
            newScene.scaleMode = .aspectFill
            view.presentScene(newScene, transition: .fade(withDuration: 0.4))
        }
    }

    // MARK: - Pause Button
    func setupPauseButton() {
        let pauseBtn = SKShapeNode(rectOf: CGSize(width: 44, height: 44), cornerRadius: 10)
        pauseBtn.fillColor = UIColor.black.withAlphaComponent(0.45)
        pauseBtn.strokeColor = .clear
        pauseBtn.position = CGPoint(x: frame.maxX - 120, y: frame.maxY - 100)
        pauseBtn.zPosition = 5
        pauseBtn.name = "pauseButton"

        let pauseIcon = SKLabelNode(text: "⏸")
        pauseIcon.fontSize = 22
        pauseIcon.verticalAlignmentMode = .center
        pauseIcon.horizontalAlignmentMode = .center
        pauseIcon.position = .zero
        pauseIcon.name = "pauseButton"

        pauseBtn.addChild(pauseIcon)
        addChild(pauseBtn)
    }

    // MARK: - Pause Menu
    func showPauseMenu() {
        isPaused_game = true
        isGameRunning = false
        self.physicsWorld.speed = 0
        motionManager.stopAccelerometerUpdates()

        let overlay = SKShapeNode(rectOf: self.size)
        overlay.position = CGPoint(x: frame.midX, y: frame.midY)
        overlay.fillColor = UIColor.black.withAlphaComponent(0.55)
        overlay.strokeColor = .clear
        overlay.zPosition = 20
        overlay.name = "pauseOverlay"
        addChild(overlay)

        let card = SKShapeNode(rectOf: CGSize(width: 280, height: 220), cornerRadius: 20)
        card.position = CGPoint(x: frame.midX, y: frame.midY)
        card.fillColor = .white
        card.strokeColor = .clear
        card.zPosition = 21
        card.name = "pauseOverlay"
        addChild(card)

        let title = SKLabelNode(text: "Paused")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 30
        title.fontColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        title.position = CGPoint(x: frame.midX, y: frame.midY + 60)
        title.zPosition = 22
        title.name = "pauseOverlay"
        addChild(title)

        let resumeBtn = makeMenuButton(text: "▶  Resume", color: UIColor(red: 0.2, green: 0.7, blue: 0.4, alpha: 1))
        resumeBtn.position = CGPoint(x: frame.midX, y: frame.midY + 10)
        resumeBtn.name = "resumeButton"
        resumeBtn.zPosition = 22
        addChild(resumeBtn)

        let menuBtn = makeMenuButton(text: "🏠  Main Menu", color: UIColor(red: 0.9, green: 0.35, blue: 0.3, alpha: 1))
        menuBtn.position = CGPoint(x: frame.midX, y: frame.midY - 55)
        menuBtn.name = "mainMenuButton"
        menuBtn.zPosition = 22
        addChild(menuBtn)
    }

    func makeMenuButton(text: String, color: UIColor) -> SKShapeNode {
        let btn = SKShapeNode(rectOf: CGSize(width: 220, height: 48), cornerRadius: 14)
        btn.fillColor = color
        btn.strokeColor = .clear

        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 18
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
        btn.addChild(label)
        return btn
    }

    func resumeGame() {
        isPaused_game = false
        isGameRunning = true
        self.physicsWorld.speed = 1
        startMotion()

        children.filter {
            $0.name == "pauseOverlay" ||
            $0.name == "resumeButton" ||
            $0.name == "mainMenuButton"
        }.forEach { $0.removeFromParent() }
    }
}
