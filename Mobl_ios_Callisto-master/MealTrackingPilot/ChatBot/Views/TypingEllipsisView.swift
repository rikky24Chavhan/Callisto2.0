//
//  TypingEllipsisView.swift
//  QuickGuru
//
//  Created by Andrew Dolce on 12/16/16.
//  Copyright © 2016 Eli Lilly. All rights reserved.
//

import UIKit
import Intrepid

class TypingEllipsisView: UIView {
    var ellipsisColor = UIColor.black {
        didSet {
            configureDots()
        }
    }

    var dotRadius = CGFloat(3) {
        didSet {
            configureDots()
        }
    }

    var dotSpacing = CGFloat(10) {
        didSet {
            configureDots()
        }
    }

    private var dots = [UIView]()

    override init(frame: CGRect) {
        super.init(frame: frame)
        createDots()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createDots()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        createDots()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        configureDots()
    }

    private func createDots() {
        guard dots.count == 0 else {
            return
        }

        dots = (0..<3).map { _ in
            let dot = UIView()
            self.addSubview(dot)
            return dot
        }
    }

    private func configureDots() {
        let dotDiameter = dotRadius * 2
        for dot in dots {
            dot.backgroundColor = ellipsisColor
            dot.frame = CGRect(x: 0, y: 0, width: dotDiameter, height: dotDiameter)
            dot.layer.cornerRadius = dotRadius
        }
        dots[1].center = bounds.ip_center
        dots[0].center = dots[1].frame.ip_leftMiddle - CGPoint(x: dotSpacing, y: 0)
        dots[2].center = dots[1].frame.ip_rightMiddle + CGPoint(x: dotSpacing, y: 0)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: dotRadius * 6 + dotSpacing * 2, height: dotRadius * 2)
    }
}
