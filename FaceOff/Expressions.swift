//
//  Expressions.swift
//  FaceOff
//
//  Created by David McGavern.
//  Copyright © 2018 Made by Windmill. All rights reserved.
//

import UIKit
import ARKit

class Expression: NSObject {
    func name() -> String {
        return ""
    }
    func isExpressing(from: ARFaceAnchor) -> Bool {
        // should return true when the ARFaceAnchor is performing the expression we want
        return false
    }
    func isDoingWrongExpression(from: ARFaceAnchor) -> Bool {
        // should return true when the ARFaceAnchor is performing the WRONG expression from what we want. for example, if the expression is "Blink Left", then this should return true if the user's right eyelid is also closed.
        return false
    }
}


class SmileExpression: Expression {
    override func name() -> String {
        return "Smile"
    }
    override func isExpressing(from: ARFaceAnchor) -> Bool {
        guard let smileLeft = from.blendShapes[.mouthSmileLeft], let smileRight = from.blendShapes[.mouthSmileRight] else {
            return false
        }
        
        // from testing: 0.5 is a lightish smile, and 0.9 is an exagerrated smile
        return smileLeft.floatValue > 0.5 && smileRight.floatValue > 0.5
    }
}


class JawOpenExpression: Expression {
    override func name() -> String {
        return "Open Wide"
    }
    override func isExpressing(from: ARFaceAnchor) -> Bool {
        guard let jawOpen = from.blendShapes[.jawOpen] else {
            return false
        }
        
        // from testing: 0.4 is casual open (aka casual breathing)
        return jawOpen.floatValue > 0.7
    }
}


class LookLeftExpression: Expression {
    override func name() -> String {
        return "Look Left"
    }
    override func isExpressing(from: ARFaceAnchor) -> Bool {
        // note: what we think of "look left" is opposite from ARKit (ARKit describes looking at our face externally)
        guard let eyeLookOutRight = from.blendShapes[.eyeLookOutRight] else {
            return false
        }
        
        // from testing: >1.1 is hard look left
        return eyeLookOutRight.floatValue > 0.9
    }
}


class LookRightExpression: Expression {
    override func name() -> String {
        return "Look Right"
    }
    override func isExpressing(from: ARFaceAnchor) -> Bool {
        // note: what we think of "look left" is opposite from ARKit (ARKit describes looking at our face externally)
        guard let eyeLookOutLeft = from.blendShapes[.eyeLookOutLeft] else {
            return false
        }
        
        // from testing: >1.1 is hard look right
        return eyeLookOutLeft.floatValue > 0.9
    }
}


class EyebrowsRaisedExpression: Expression {
    override func name() -> String {
        return "Raise Eyebrows"
    }
    override func isExpressing(from: ARFaceAnchor) -> Bool {
        guard let browInnerUp = from.blendShapes[.browInnerUp] else {
            return false
        }
        
        // from testing: at least 0.9 is raised eyebrows
        return browInnerUp.doubleValue > 0.7
    }
}


class EyeBlinkLeftExpression: Expression {
    override func name() -> String {
        return "Blink Right"
    }
    // note: "left" is your personal left
    override func isExpressing(from: ARFaceAnchor) -> Bool {
        guard let eyeBlink = from.blendShapes[.eyeBlinkLeft] else {
            return false
        }
        
        // from testing: at least 0.6 is closed eye lid
        return eyeBlink.doubleValue > 0.6
    }
    override func isDoingWrongExpression(from: ARFaceAnchor) -> Bool {
        return EyeBlinkRightExpression().isExpressing(from: from)
    }
}


class EyeBlinkRightExpression: Expression {
    override func name() -> String {
        return "Blink Left"
    }
    override func isExpressing(from: ARFaceAnchor) -> Bool {
        guard let eyeBlink = from.blendShapes[.eyeBlinkRight] else {
            return false
        }
        
        // from testing: at least 0.6 is closed eye lid
        return eyeBlink.doubleValue > 0.6
    }
    override func isDoingWrongExpression(from: ARFaceAnchor) -> Bool {
        return EyeBlinkLeftExpression().isExpressing(from: from)
    }
}


class CheekPuffExpression: Expression {
    override func name() -> String {
        return "Puff Cheeks"
    }
    override func isExpressing(from: ARFaceAnchor) -> Bool {
        guard let cheekPuff = from.blendShapes[.cheekPuff] else {
            return false
        }
        
        // from testing: 0.4 is mid-level puff; 0.7 is high intensity puff
        return cheekPuff.doubleValue > 0.4
    }
}
