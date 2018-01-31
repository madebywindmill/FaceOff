//
//  RoundedRectButton.swift
//  FaceOff
//
//  Created by David McGavern.
//  Copyright © 2018 Made by Windmill. All rights reserved.
//

import UIKit

class RoundedRectButton: UIButton {

    enum Style: Int {
        case rounded
        case roundedLine
    }
    
    @IBInspectable var styleAdapter: Int {
        get {
            return self.style.rawValue
        }
        set(i) {
            self.style = RoundedRectButton.Style(rawValue: i) ?? .rounded
        }
    }
 
    var style: Style = .rounded {
        didSet {
            self.updateStyle()
        }
    }
    
    @IBInspectable var color: UIColor = .white {
        didSet {
            self.updateStyle()
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            self.updateStyle()
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.updateStyle()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        get {
            var size = super.intrinsicContentSize
            if self.style == .rounded || self.style == .roundedLine {
                let roundedPadding = 40.0 as CGFloat
                size.width += roundedPadding
            }
            return size
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.updateStyle()
    }
    
    override func prepareForInterfaceBuilder() {
        self.updateStyle()
    }
    
    func updateStyle() {
        switch style {
        case .rounded:
            self.backgroundColor = self.color
            self.setTitleColor(#colorLiteral(red: 0.4235294118, green: 0.7490196078, blue: 1, alpha: 1), for: .normal)
            self.layer.cornerRadius = 5.0
            self.clipsToBounds = true
            self.contentHorizontalAlignment = .center
        case .roundedLine:
            self.backgroundColor = nil
            self.setTitleColor(self.color, for: .normal)
            self.layer.cornerRadius = 5.0
            self.layer.borderColor = self.color.cgColor
            self.layer.borderWidth = 1.0
        }
        if self.isHighlighted {
            self.alpha = 0.6
        } else {
            self.alpha = (self.isEnabled) ? 1.0 : 0.1
        }
    }

}
