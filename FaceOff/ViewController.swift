//
//  ViewController.swift
//  FaceOff
//
//  Created by David McGavern.
//  Copyright © 2018 Made by Windmill. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var actionLabel: UILabel!
    @IBOutlet weak var timeLeftBar: UIProgressView!
    @IBOutlet weak var pointsLeftLabel: UILabel!
    @IBOutlet weak var totalPointsLabel: UILabel!
    @IBOutlet weak var livesLeftLabel: UILabel!
    @IBOutlet weak var livesLeftTitleLabel: UILabel!
    @IBOutlet weak var startGameButton: UIButton!
    @IBOutlet weak var faceImageView: UIImageView!
    
    let session = ARSession()
    var maskNode: Mask?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.backgroundColor = .clear
        self.sceneView.scene = SCNScene()
        self.sceneView.rendersContinuously = true
        
        // floating mask node
        if let device = MTLCreateSystemDefaultDevice(), let geo = ARSCNFaceGeometry(device: device) {
            self.maskNode = Mask(geometry: geo)
            self.sceneView.scene?.rootNode.addChildNode(self.maskNode!)
            self.maskNode?.position = SCNVector3(x: 0.0, y: 0.0, z: 0.0)
        }
        
        // configure our ARKit tracking session for facial recognition
        let config = ARFaceTrackingConfiguration()
        config.worldAlignment = .gravity
        session.delegate = self
        session.run(config, options: [])
        
        self.updateUI()
    }
    
    
    // MARK: - User Actions
    
    @IBAction func startGame(_ sender: Any) {
        self.startGame()
    }
    
    
    // MARK: - AR Session
    
    var currentFaceAnchor: ARFaceAnchor?
    var currentFrame: ARFrame?
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        self.currentFrame = frame
        DispatchQueue.main.async {
            // need to call heart beat on main thread
            self.processNewARFrame()
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }
        self.currentFaceAnchor = faceAnchor
        self.maskNode?.update(withFaceAnchor: faceAnchor)
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        
    }
    
    
    // MARK: - Game Logic
    
    var gameActive = false {
        didSet {
            self.updateUI()
            UIApplication.shared.isIdleTimerDisabled = self.gameActive
        }
    }

    var expressionsToUse: [Expression] = [SmileExpression(), EyebrowsRaisedExpression(), EyeBlinkLeftExpression(), EyeBlinkRightExpression(), JawOpenExpression(), LookLeftExpression(), LookRightExpression()] // all the possible expressions shown during a game session
    var currentExpression: Expression? = nil {
        didSet {
            if currentExpression != nil {
                self.currentExpressionShownAt = Date()
            } else {
                self.currentExpressionShownAt = nil
            }
            self.updateUI()
        }
    }
    var currentExpressionShownAt: Date? = nil

    var livesLeft = 3 {
        didSet {
            self.updateUI()
        }
    }
    var currentPoints = 0 {
        didSet {
            self.updateUI()
        }
    }
    
    var totalExpressionsShown = 0
    var totalExpressionsSucceeded = 0
    var maxPointsAwardedPerExpression = 999 // changes dynamically during a game session
    var currentStage = 0 // changes dynamically during a game session
    var timeIntervalPerExpression: TimeInterval = 999.0 // changes dynamically during a game session
    var timeIntervalBetweenExpressions: TimeInterval = 999.0 // changes dynamically during a game session
    
    let feedbackGenerator = UINotificationFeedbackGenerator()
    
    
    // MARK: -
    
    func startGame() {
        // reset all game state and start a new game!
        self.totalFaceImages = 0
        self.currentStage = 0
        self.totalExpressionsShown = 0
        self.totalExpressionsSucceeded = 0
        self.currentPoints = 0
        self.maxPointsAwardedPerExpression = 10
        self.livesLeft = 3
        self.timeIntervalPerExpression = 2.0
        self.timeIntervalBetweenExpressions = 1.3
        self.gameActive = true
        self.showNextExpressionWhenReady()
        self.actionLabel.text = "Ready…"
        self.timeLeftBar.progress = 1.0
        self.pointsLeftLabel.text = ""
        self.hideFaceImages()
        self.updateUI()
    }
    
    
    func processNewARFrame() {
        // called each time ARKit updates our frame (aka we have new facial recognition data)
        guard self.gameActive == true else {
            return
        }
        
        if let currentExpression = self.currentExpression, let shownAt = self.currentExpressionShownAt, let faceAnchor = self.currentFaceAnchor {
            let timeSinceShown = Date().timeIntervalSince(shownAt)
            let percentLeft = 1.0 - (timeSinceShown / self.timeIntervalPerExpression)
            self.timeLeftBar.progress = Float(percentLeft)
            self.pointsLeftLabel.text = "\(self.pointsToAwardFromCurrentExpression()) points"
            
            if percentLeft < 0.0 {
                // failed :(
                self.failedCurrentExpression()
            } else if currentExpression.isExpressing(from: faceAnchor) && !currentExpression.isDoingWrongExpression(from: faceAnchor) {
                // succeeded! (but only if they're not also doing the wrong expression, like raising both eyebrows)
                self.hasSatisifiedCurrentExpression()
            }
        }
        
    }
    
    func showNextExpressionWhenReady() {
        self.currentExpression = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntervalBetweenExpressions) {
            self.totalExpressionsShown += 1
            
            // adjust the "stage" we're on (aka difficulty)
            if self.currentStage < 1 && self.totalExpressionsShown > 8 {
                // speed things up
                self.timeIntervalPerExpression = 1.5
                self.maxPointsAwardedPerExpression = 50
                self.timeIntervalBetweenExpressions = 1.0
                self.currentStage = 1
            } else if self.currentStage == 1 && self.totalExpressionsShown > 16 {
                // speed up even more!
                self.timeIntervalPerExpression = 1.1
                self.maxPointsAwardedPerExpression = 100
                self.timeIntervalBetweenExpressions = 0.8
                self.currentStage = 2
            } else if self.currentStage == 2 && self.totalExpressionsShown > 25 {
                // ultra hard
                self.timeIntervalPerExpression = 0.9
                self.maxPointsAwardedPerExpression = 400
                self.timeIntervalBetweenExpressions = 0.6
                self.currentStage = 3
            }
            
            let randomExpression = self.expressionsToUse.randomItem()!
            self.currentExpression = randomExpression
            
        }
    }
    
    func hasSatisifiedCurrentExpression() {
        self.currentPoints += self.pointsToAwardFromCurrentExpression()
        self.totalExpressionsSucceeded += 1
        feedbackGenerator.notificationOccurred(.success)
        if let frame = self.currentFrame, let image = UIImage(pixelBuffer: frame.capturedImage) {
            self.saveImageToFaceDirectory(image)
        }
        self.showNextExpressionWhenReady()
    }
    
    func failedCurrentExpression() {
        feedbackGenerator.notificationOccurred(.error)
        self.actionLabel.doIncorrectAttemptShakeAnimation()
        self.livesLeft -= 1
        
        if self.livesLeft == 0 {
            self.currentExpression = nil
            self.showFaceImages()
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                self.gameActive = false
            })
        } else {
            self.showNextExpressionWhenReady()
        }
    }
    
    func pointsToAwardFromCurrentExpression() -> Int {
        guard let shownAt = self.currentExpressionShownAt else {
            return 0
        }
        
        // figure out percentage through current expression
        let timeSinceShown = Date().timeIntervalSince(shownAt)
        let points = Int(Double(self.maxPointsAwardedPerExpression) * (1.0 - (timeSinceShown / self.timeIntervalPerExpression))) + 1
        
        if points > 0 {
            return points
        } else {
            return 0
        }
    }

    
    // MARK: - Rotating Face Image (post-game)
    
    let delayBetweenImages: TimeInterval = 0.3
    var faceImageIndex = 0
    var totalFaceImages = 0
    
    func showFaceImages() {
        self.faceImageIndex = 0
        self.showNextImage()
        self.faceImageView.isHidden = false
    }
    
    func saveImageToFaceDirectory(_ image: UIImage) {
        let index = self.totalFaceImages
        DispatchQueue.global(qos: .userInitiated).async {
            // we do this on a secondary thread since rotating & saving actually takes quite a bit of time
            let rotatedImage = image.rotated(by: Measurement(value: 90.0, unit: .degrees))!
            try? UIImagePNGRepresentation(rotatedImage)?.write(to: URL(fileURLWithPath: self.pathForImageWith(index: index)))
        }
        self.totalFaceImages += 1
    }
    
    func pathForImageWith(index: Int) -> String {
        let documentsUrl =  FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first! as URL
        let documentsPath = documentsUrl.path
        return (documentsPath as NSString).appendingPathComponent("\(String(index)).png")
    }
    
    @objc func showNextImage() {
        guard let image = UIImage(contentsOfFile: self.pathForImageWith(index: self.faceImageIndex)) else {
            return
        }
        
        self.faceImageView.image = image
        
        faceImageIndex += 1
        if faceImageIndex >= self.totalFaceImages {
            faceImageIndex = 0
        }
        
        self.perform(#selector(showNextImage), with: nil, afterDelay: self.delayBetweenImages)
    }
    
    func hideFaceImages() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showNextImage), object: nil)
        self.faceImageView.isHidden = true
    }
    
    
    // MARK: - Update UI
    
    func updateUI() {
        if gameActive {
            if let expression = self.currentExpression {
                self.actionLabel.text = expression.name()
            }
            self.actionLabel.isHidden = false
            self.startGameButton.isHidden = true
            self.timeLeftBar.isHidden = false
            self.pointsLeftLabel.isHidden = false
        } else {
            self.actionLabel.isHidden = true
            self.startGameButton.isHidden = false
            self.pointsLeftLabel.isHidden = true
            self.timeLeftBar.isHidden = true

        }
        
        self.livesLeftLabel.text = "\(self.livesLeft)"
        self.livesLeftTitleLabel.text = (self.livesLeft == 1) ? "Life Left" : "Lives Left"
        self.totalPointsLabel.text = "\(self.currentPoints)"
    }
    
}
