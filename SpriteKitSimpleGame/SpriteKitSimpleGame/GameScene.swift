//
//  GameScene.swift
//  SpriteKitSimpleGame
//
//  Created by Eric Yang on 3/8/17.
//  Copyright © 2017 Eric Liu Yang. All rights reserved.
//

import SpriteKit
import GameplayKit

struct PhysicsCategory {
    static let None: UInt32 = 0
    static let All: UInt32 = UInt32.max
    static let Monster: UInt32 = 0b1
    static let Projectile: UInt32 = 0b10
}

//Standard implementations for vector math
func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    func normalized() -> CGPoint {
        return self / length()
    }
}
//End Implementation for Vector Math

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //MARK: Properties
    //Declares a private constant of a sprite
    let player = SKSpriteNode(imageNamed: "player")
    var monsterDestroyed = 0
    
    //MARK:Functions
    override func didMove(to view: SKView) {
        //Sets backgroundColor to white
        backgroundColor = SKColor.white
        
        //Positions sprite 10% across horizontally, halfway vertically
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        
        //Adds sprite as a child 
        addChild(player)
        
        //Adds the monster
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addMonster),
                SKAction.wait(forDuration: 1.0)])
        ))
        
        //Sets the physics world with no gravity
        physicsWorld.gravity = CGVector.zero
        
        //Sets the scene as the delegate to be notified when two physics bodies collide
        physicsWorld.contactDelegate = self
    }

    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addMonster() {
    
        //Creates a sprite
        let monster = SKSpriteNode(imageNamed: "monster")
        
        //Creates a physics body for the monster sprite with the shape of a rectangle
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size)
        
        //Sets the category of the monster to Monster
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster
        
        //Shows which category of objects that the physics engine uses to handle contact responses
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None
        
        //Sets the contact bit mask to be the projectile
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile
        
        //Determine where to spawn along the Y-axis
        let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
        
        /*Position the monster slightly offscreen to the right
        and along a random position along the Y-axis, calculated above*/
        monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
        
        //Add the monster to the scene
        addChild(monster)
        
        //Determine the speed of the monster
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        //Create the action
        let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY), duration: TimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        monster.run(SKAction.sequence([actionMove, actionMoveDone]))
        
        let loseAction = SKAction.run(){
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        monster.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        //Choose one of the touches to work with
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in:self)
        
        //Setup initial location of the project
        let projectile = SKSpriteNode(imageNamed: "projectile")
        projectile.position = player.position
        
        //Creates a physics body for the sprite of the projectile
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        
        //Creates a physics body for the Sprite with a shape of a circle, with radius half of the sprite's size
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        //Physics Body needs to be connected to a Sprite Node
        
        
        //Sets the category bit mask of the sprite as a projectile
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
        
        //Contact bit mask is what category of object should contact the listener
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
        
        //Collision bit mask is the object which the physics engine uses to handle collision
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
        
        //Determine the offset location of the projectile
        let offset = touchLocation - projectile.position
        
        //Bail out if you are shooting down or backwards
        if (offset.x < 0) { return }
        
        //OK to add the projectile now
        addChild(projectile)
        
        //Get the direction of where to shoot
        let direction = offset.normalized()
        
        //Shoot far enough to be guaranteed off screen
        let shootAmount = direction * 1000
        
        //Add the shoot amount to the current position
        let realDest = shootAmount + projectile.position
        
        //Create the actions
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
        
        //Plays a sound for shooting with one line
        run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
    }
    
    //Function to check if two sprite nodes collided with each other
    func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
        print("Hit!")
        projectile.removeFromParent()
        monster.removeFromParent()
        
        //Checks to see for game winning condition
        monstersDestroyed += 1
        if (monstersDestroyed > 30) {
            let reveal = SKTransition.flipHorizontal(withDuration: 3.0)
            let gameOverScene = GameOverScene(size: self.size, transition: reveal)
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
       
        //Passes the bodies that collide with no particular order
        if contact.bodyA.categoryBitMask > contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        //Checks to see if the two bodies that collide are projectile and monster. Then, it passes the collision detection function
        if ((firstBody.categoryBitMask & PhysicsCategory.Projectile != 0) && (secondBody.categoryBitMask & PhysicsCategory.Monster != 0)) {
            if let monster = firstBody.node as? SKSpriteNode, let projectile = secondBody.node as? SKSpriteNode {
                projectileDidCollideWithMonster(projectile: projectile, monster: monster)
            }
        }
        
        //Still needs to add background music in this section
        let backgroundMusic = SKAudioNode(fileNamed:"background-music-aac.caf")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
        
    }
}
