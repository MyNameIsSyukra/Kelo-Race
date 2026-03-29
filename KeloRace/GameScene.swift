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
    let player = SKSpriteNode(imageNamed: "Player")
    let motionManager = CMMotionManager()
    
    var background = SKSpriteNode(imageNamed: "Background")
    var finishLine = SKSpriteNode(imageNamed: "FinishLine")
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    var micAudioEngine = AVAudioEngine()
    var inputNode: AVAudioInputNode!
    var lastBlowTime: TimeInterval = 0
    var isBlowing = false
    var elapsedTime: TimeInterval = 0
    var isGameRunning = false
    var stopwatchLabel: SKLabelNode!
     
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self

        setupBackground()
        setupPlayer()
        startListening()
        setupFinishLine()
        startMotion()
        setupObstacle()
        setupStopwatch()
        
        view.showsPhysics = true // DEBUG: hapus kalau sudah oke
    }
    
    // MARK: - Finish Line Reached
    override func update(_ currentTime: TimeInterval) {
        if isGameRunning {
            elapsedTime += 1.0 / 60.0  // ~60fps
            stopwatchLabel.text = formatTime(elapsedTime)
        }
    }

    func playerReachedFinish() {
        isGameRunning = false  // ✅ Stop stopwatch
        
        player.removeAllActions()
        motionManager.stopAccelerometerUpdates()
        micAudioEngine.stop()
        inputNode.removeTap(onBus: 0)
        
        print("🏆 Player menang! Waktu: \(formatTime(elapsedTime))")
        showWinModal(finalTime: elapsedTime)  // ✅ Kirim waktu final
    }
    func setupStopwatch() {
        stopwatchLabel = SKLabelNode(text: "00:00.0")
        stopwatchLabel.fontName = "Courier-Bold"
        stopwatchLabel.fontSize = 22
        stopwatchLabel.fontColor = .white
        stopwatchLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 60)
        stopwatchLabel.zPosition = 5
        stopwatchLabel.horizontalAlignmentMode = .center
        
        // Background pill supaya terbaca di atas semua background
        let pill = SKShapeNode(rectOf: CGSize(width: 140, height: 36), cornerRadius: 18)
        pill.fillColor = UIColor.black.withAlphaComponent(0.45)
        pill.strokeColor = .clear
        pill.position = stopwatchLabel.position
        pill.zPosition = 4
        
        addChild(pill)
        addChild(stopwatchLabel)
        
        isGameRunning = true
    }

    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time - Double(Int(time))) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
    // MARK: - Win Modal
    func showWinModal(finalTime: TimeInterval) {
        let overlay = SKShapeNode(rectOf: self.size)
        overlay.position = CGPoint(x: frame.midX, y: frame.midY)
        overlay.fillColor = UIColor.black.withAlphaComponent(0.6)
        overlay.strokeColor = .clear
        overlay.zPosition = 10
        overlay.name = "winOverlay"
        addChild(overlay)

        // Card
        let card = SKShapeNode(rectOf: CGSize(width: 300, height: 260), cornerRadius: 20)
        card.position = CGPoint(x: frame.midX, y: frame.midY)
        card.fillColor = UIColor.white
        card.strokeColor = .clear
        card.zPosition = 11
        addChild(card)

        // Emoji
        let trophy = SKLabelNode(text: "🏆")
        trophy.fontSize = 64
        trophy.position = CGPoint(x: frame.midX, y: frame.midY + 80)
        trophy.zPosition = 12
        addChild(trophy)

        // Judul
        let title = SKLabelNode(text: "You Win!")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 32
        title.fontColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        title.position = CGPoint(x: frame.midX, y: frame.midY + 30)
        title.zPosition = 12
        addChild(title)

        // ✅ Label "Finish Time"
        let timeCaption = SKLabelNode(text: "Finish Time")
        timeCaption.fontName = "AvenirNext-Regular"
        timeCaption.fontSize = 14
        timeCaption.fontColor = .gray
        timeCaption.position = CGPoint(x: frame.midX, y: frame.midY - 10)
        timeCaption.zPosition = 12
        addChild(timeCaption)

        // ✅ Waktu final — pakai font monospace supaya angka tidak geser
        let timeLabel = SKLabelNode(text: formatTime(finalTime))
        timeLabel.fontName = "Courier-Bold"
        timeLabel.fontSize = 28
        timeLabel.fontColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1)
        timeLabel.position = CGPoint(x: frame.midX, y: frame.midY - 40)
        timeLabel.zPosition = 12
        addChild(timeLabel)

        // Subtitle restart
        let sub = SKLabelNode(text: "Tap to play again")
        sub.fontName = "AvenirNext-Regular"
        sub.fontSize = 15
        sub.fontColor = .gray
        sub.position = CGPoint(x: frame.midX, y: frame.midY - 80)
        sub.zPosition = 12
        addChild(sub)

        // Animasi slide-up — kumpulkan semua node
        let nodes: [SKNode] = [card, trophy, title, timeCaption, timeLabel, sub]
        nodes.forEach { $0.position.y -= 300 }
        let slideUp = SKAction.moveBy(x: 0, y: 300, duration: 0.4)
        slideUp.timingMode = .easeOut
        nodes.forEach { $0.run(slideUp) }
    }
    
    // MARK: - Contact Detection
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        
        if (bodyA.categoryBitMask == 1 && bodyB.categoryBitMask == 2) ||
           (bodyA.categoryBitMask == 2 && bodyB.categoryBitMask == 1) {
            playerHitObstacle()
        }
        if (bodyA.categoryBitMask == 1 && bodyB.categoryBitMask == 4) ||
               (bodyA.categoryBitMask == 4 && bodyB.categoryBitMask == 1) {
                playerReachedFinish()
            }
    }
    
    func playerHitObstacle() {
        player.removeAllActions()
        
        let moveDown = SKAction.moveBy(x: 0, y: -80, duration: 0.2)
        let wait = SKAction.wait(forDuration: 0.3)
        let sequence = SKAction.sequence([moveDown, wait])
        player.run(sequence)
        
        print("💥 Player hit obstacle!")
    }
    
    // MARK: - Setup Background
    func setupBackground() {
        background.size = self.size
        background.position = CGPoint(x: 0, y: 0)
        background.zPosition = -1
        addChild(background)
    }
    
    // MARK: - Setup Player
    func setupPlayer() {
        player.position = CGPoint(x: frame.midX, y: -500)
        player.size = CGSize(width: 40, height: 80)
        player.zPosition = 3
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = 1
        player.physicsBody?.contactTestBitMask = 2
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
        // Cari semua node bernama "obstacleHit" di scene (yang kamu buat manual di GameScene.sks)
        enumerateChildNodes(withName: "//obstacleHit") { node, _ in
            guard let sprite = node as? SKSpriteNode else { return }
            
//            sprite.alpha = 0 // invisible tapi tetap ada collision
            sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
            sprite.physicsBody?.isDynamic = false
            sprite.physicsBody?.affectedByGravity = false
            sprite.physicsBody?.categoryBitMask = 2
            sprite.physicsBody?.contactTestBitMask = 1
            sprite.physicsBody?.collisionBitMask = 0
            
            print("✅ Obstacle setup di posisi: \(sprite.position)")
        }
    }
    
    // MARK: - Microphone Listening
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
    
    // MARK: - Detect Blow
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
    
    // MARK: - Move Player Up
    func blowDetected() {
        let step: CGFloat = 20
        let moveUp = SKAction.moveBy(x: 0, y: step, duration: 0.1)
        player.run(moveUp)
    }
    
    // MARK: - Motion / Tilt
    func startMotion() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.02
            
            motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { data, error in
                guard let data = data else { return }
                
                let tilt = data.acceleration.x
                
                DispatchQueue.main.async {
                    self.movePlayerHorizontally(tilt: tilt)
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
    }
    // MARK: - Restart on Tap
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Hanya restart jika win modal sedang tampil
        if childNode(withName: "winOverlay") != nil {
            if let view = self.view,
               let newScene = SKScene(fileNamed: "GameScene") as? GameScene {
                newScene.scaleMode = .aspectFill
                view.presentScene(newScene, transition: .fade(withDuration: 0.4))
            }
        }
    }
}
