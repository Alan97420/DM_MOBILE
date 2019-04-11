//
//  GameScene.swift
//  test_jeux
//
//  Created by Alan CHAN CHUN TIM on 02/04/2019.
//  Copyright © 2019 Alan CHAN CHUN TIM. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion // pour l'acceleromettre

class GameScene: SKScene,SKPhysicsContactDelegate {
    
    var starfield:SKEmitterNode!
    var player:SKSpriteNode!
    var scoreLabel:SKLabelNode!
    var score:Int = 0{
        didSet{
            scoreLabel.text = "Score: \(score)"
        }
    }
    var gameTimer : Timer!
    var possibleAlien  = ["alien","alien2","alien3"] // tableau d'alien
    let alienCategory:UInt32 = 0x1 << 1 // 1*2^1 = 2
    let photonTorpedoCategory:UInt32 = 0x1 << 0 // 1*2^0 =1
    
    var motionManager = CMMotionManager() // variable qui prend en parametre les donner de l'accelerometre
    var xAccelaration: CGFloat = 0
    
    
    override func didMove(to view: SKView) {
        starfield = SKEmitterNode(fileNamed: "Starfield")
        starfield.position = CGPoint(x: 0, y: 1472)
        starfield.advanceSimulationTime(10)
        self.addChild(starfield)
        
        starfield.zPosition = -1
        
        player  = SKSpriteNode(imageNamed: "shuttle") // recupere l'image
        player.position = CGPoint(x:0, y:-self.frame.size.height+740)// recupere l'image 
        self.addChild(player)
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: -200, y: 550)
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = UIColor.white
        self.addChild(scoreLabel)
        self.physicsWorld.contactDelegate = self
        
        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
        motionManager.accelerometerUpdateInterval = 0.2 // acctualise toute les 0.2 seconde l'acceleromettre.
        motionManager.startAccelerometerUpdates(to:OperationQueue.current!){(data:CMAccelerometerData?, error:Error?)in
            if let accelerometerData = data{

                let acceleration = accelerometerData.acceleration
                self.xAccelaration = CGFloat(acceleration.x)*0.75 + self.xAccelaration * 0.25
            }
        }
    }
    @objc func addAlien(){
        possibleAlien = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAlien) as! [String] // prend dans le tableau un element random
        let alien  = SKSpriteNode(imageNamed: possibleAlien[0]) // attribut à la variable un element
        let randomAlienPosition  = GKRandomDistribution(lowestValue: -300, highestValue:300) // choisit de maniere random une posisiton entre 300 et -300
        let position = CGFloat(randomAlienPosition.nextInt()) // attribut à la variable position le random alien que l'on met en entier et en CGFloat
        alien.position = CGPoint(x: position, y: self.frame.size.height + alien.size.height)//positionne alien au dessu de l'ecrant plus la taille de l'image
        alien.physicsBody  = SKPhysicsBody(rectangleOf: alien.size) // creation de la hitbox de l'alien
        alien.physicsBody?.isDynamic = true
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = photonTorpedoCategory
        alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(alien) // ajout de l'alien
        let animationDuration = 6 // variable qui permet de regler la vitesse
        var ActionArray = [SKAction] () // creation du tableau d'action
        ActionArray.append(SKAction.move(to: CGPoint(x: position, y: -frame.size.height), duration: TimeInterval(animationDuration))) // permet de gere la position des aliens et la vitesse.
        ActionArray.append(SKAction.removeFromParent())
        alien.run(SKAction.sequence(ActionArray))
        print(alien.size)


    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
     fireTorpedo()
     }
    func fireTorpedo (){
     self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false)) // met un bruit
     let torpedoNode = SKSpriteNode(imageNamed: "torpedo") // met dans une constante
     torpedoNode.position = player.position// la possition de torpedoNode est la meme que celui du player
     torpedoNode.position.y += 5 // ajout de 5px en plus
     torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width/2)// creation de la hitbox
     torpedoNode.physicsBody?.isDynamic = true // ajout dynamique de torpedoNode
     
     torpedoNode.physicsBody?.categoryBitMask = photonTorpedoCategory
     torpedoNode.physicsBody?.contactTestBitMask = alienCategory
     torpedoNode.physicsBody?.collisionBitMask = 0
     torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
     self.addChild(torpedoNode)
     let animationDuration:TimeInterval = 0.3
     var actionArray = [SKAction]()
     actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: self.frame.height+8), duration: TimeInterval(animationDuration))) // permet de gere la position des aliens et la vitesse de deplacemennt du torpedo
     actionArray.append(SKAction.removeFromParent())
     torpedoNode.run(SKAction.sequence(actionArray )) // lance torpedoNode
        
     
     
     }
    func didBegin(_ contact: SKPhysicsContact) {// fonction de la gestion  des collisions
        var firstBody: SKPhysicsBody
        var secondBody:SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask{
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }
        else{
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if (firstBody.categoryBitMask & photonTorpedoCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0 {
            torpedoDicollideWithAlien(torpedoNode: firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode)
        }
    }
    
    func torpedoDicollideWithAlien(torpedoNode:SKSpriteNode, alienNode:SKSpriteNode){
        let explosion = SKEmitterNode(fileNamed: "Explosion")! // constante qui prend le sks de l'explosion
        explosion.position = alienNode.position// la possition de l'explosion est la meme que celui de alien
        self.addChild(explosion) // ajoue de l'explosion
        self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))// lance la musique de l'explosion
        torpedoNode.removeFromParent()// supprime torpedo
        alienNode.removeFromParent()// supprime alien
        self.run(SKAction.wait(forDuration: 2)){ // au bout de  2 seconde supprime l'explosion
            explosion.removeFromParent()
        }
        score += 5 // ajoue du score
    }
    
    override func didSimulatePhysics() {
        player.position.x += xAccelaration * 70// ajoute a la position x de player les donner de l'accelerometre*70
        if player.position.x < -300{ // si la position du player en x est inferieur -300 du coup on le remet en 300 de l'ecrant
            player.position = CGPoint(x: self.size.width + 300, y: player.position.y)
        }else if player.position.x > self.size.width + 300{ // sinon si la position du player en x est superieur 300 on le remet en -300
            player.position = CGPoint(x: -300, y: player.position.y)
        }
    }
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
