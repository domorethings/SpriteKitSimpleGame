//
//  GameOverScene.swift
//  SpriteKitSimpleGame
//
//  Created by Eric Yang on 3/15/17.
//  Copyright © 2017 Eric Liu Yang. All rights reserved.
//

import Foundation
import GameplayKit
import SceneKit

class GameOverScene: SKScene {

    //Initializes the scene with size and win condition
    init(size: CGSize, won: Bool) {
        
        super.init(size: size)
        
        //Sets background color to white
        backgroundColor = SKColor.white
    
        //Creates an optional message with two conditions of win
        let message = won ? "You win" : "You Lose!"
        //Creates a label
        let label = SKLabelNode(fontNamed: "Copperplate")
        label.fontSize = 40
        label.fontColor = SKColor.red
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        
        //Runs a sequence of two actions inline. First, it waits for 3 seconds, then it runs a block of code
        run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.run(){
                
                //Transitions to a new scene in SpriteKit.
                let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
                let scene = GameScene(size: size)
                self.view?.presentScene(scene, transition: reveal)
            }
        ]))
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been initialized")
    }
}
