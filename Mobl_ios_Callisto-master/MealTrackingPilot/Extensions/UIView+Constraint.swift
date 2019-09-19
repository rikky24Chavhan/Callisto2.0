//
//  UIView+Extensions.swift
//  MealTrackingPilot
//
//  Created by Max Litteral on 3/24/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import UIKit

typealias ConstraintDictionary = [String : NSLayoutConstraint]

let IPConstraintKeyTop = "IPConstraintKeyTop"
let IPConstraintKeyLeft = "IPConstraintKeyLeft"
let IPConstraintKeyBottom = "IPConstraintKeyBottom"
let IPConstraintKeyRight = "IPConstraintKeyRight"

extension UIView {

    func constrainView(_ view: UIView?, top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) -> ConstraintDictionary? {
        return constrainView(view, to: UIEdgeInsets(top: top, left: left, bottom: bottom, right: right))
    }
    
    func constrainView(_ view: UIView?, to insets: UIEdgeInsets) -> ConstraintDictionary? {
        var constraints: ConstraintDictionary = [:]
        if insets.top != CGFloat(NSNotFound) {
            var top: NSLayoutConstraint? = nil
            if let view = view {
                top = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: insets.top)
            }
            if let top = top {
                constraints[IPConstraintKeyTop] = top
            }
        }
        if insets.left != CGFloat(NSNotFound)  {
            var left: NSLayoutConstraint? = nil
            if let view = view {
                left = NSLayoutConstraint(item: view, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: insets.`left`)
            }
            if let aLeft = left {
                constraints[IPConstraintKeyLeft] = aLeft
            }
        }
        if insets.bottom != CGFloat(NSNotFound) {
            var bottom: NSLayoutConstraint? = nil
            if let view = view {
                bottom = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -insets.bottom)
            }
            if let bottom = bottom {
                constraints[IPConstraintKeyBottom] = bottom
            }
        }
        if insets.right != CGFloat(NSNotFound)  {
            var right: NSLayoutConstraint? = nil
            if let view = view {
                right = NSLayoutConstraint(item: view, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -insets.`right`)
            }
            if let aRight = right {
                constraints[IPConstraintKeyRight] = aRight
            }
        }
    
        view?.translatesAutoresizingMaskIntoConstraints = false
        addConstraints(Array(constraints.values))
        return constraints
    }
    
    
    func constrainView(toEqualWidth view: UIView?) -> NSLayoutConstraint? {
        return constrainView(toEqualWidth: view, constant: 0.0, multiplier: 1.0)
    }
    
    func constrainView(toEqualWidth view: UIView?, constant: CGFloat, multiplier: CGFloat) -> NSLayoutConstraint? {
        var width: NSLayoutConstraint? = nil
        if let view = view {
            width = NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: multiplier, constant: constant)
        }
        view?.translatesAutoresizingMaskIntoConstraints = false
        if let width = width {
            addConstraint(width)
        }
        return width
    }
    
    func constrainView(toEqualHeight view: UIView?) -> NSLayoutConstraint? {
        return constrainView(toEqualHeight: view, constant: 0.0, multiplier: 1.0)
    }
    
    func constrainView(toEqualHeight view: UIView?, constant: CGFloat, multiplier: CGFloat) -> NSLayoutConstraint? {
        var height: NSLayoutConstraint? = nil
        if let view = view {
            height = NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: multiplier, constant: constant)
        }
        view?.translatesAutoresizingMaskIntoConstraints = false
        if let height = height {
            addConstraint(height)
        }
        return height
    }
    
    
    func constrainView(_ view: UIView?, toWidth width: CGFloat) -> NSLayoutConstraint? {
        var widthConstraint: NSLayoutConstraint? = nil
        if let view = view {
            widthConstraint = NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: width)
        }
        view?.translatesAutoresizingMaskIntoConstraints = false
        if let widthConstraint = widthConstraint {
            addConstraint(widthConstraint)
        }
        return widthConstraint
    }
    
    func constrainView(_ view: UIView?, toHeight height: CGFloat) -> NSLayoutConstraint? {
        var heightConstraint: NSLayoutConstraint? = nil
        if let view = view {
            heightConstraint = NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: height)
        }
        view?.translatesAutoresizingMaskIntoConstraints = false
        if let heightConstraint = heightConstraint {
            addConstraint(heightConstraint)
        }
        return heightConstraint
    }
    
    
    func constrainView(_ view: UIView?, toAspectRatio aspectRatio: CGFloat) -> NSLayoutConstraint? {
        return constrainView(view, attribute: .width, to: view, attribute: .height, constant: 0.0, multiplier: aspectRatio)
    }
    
    func constrainView(_ view: UIView?, above positioningView: UIView?) -> NSLayoutConstraint? {
        return constrainView(view, attribute: .bottom, to: positioningView, attribute: .top)
    }
    
    func constrainView(_ view: UIView?, above positioningView: UIView?, withOffset offset: CGFloat) -> NSLayoutConstraint? {
        return constrainView(view, attribute: .bottom, to: positioningView, attribute: .top, constant: offset, multiplier: 1.0)
    }
    
    func constrainView(_ view: UIView?, below positioningView: UIView?) -> NSLayoutConstraint? {
        return constrainView(view, attribute: .top, to: positioningView, attribute: .bottom)
    }
    
    func constrainView(_ view: UIView?, below positioningView: UIView?, withOffset offset: CGFloat) -> NSLayoutConstraint? {
        return constrainView(view, attribute: .top, to: positioningView, attribute: .bottom, constant: offset, multiplier: 1.0)
    }
    
    func constrainView(_ view: UIView?, leftOf positioningView: UIView?) -> NSLayoutConstraint? {
        return constrainView(view, attribute: NSLayoutConstraint.Attribute.right, to: positioningView, attribute: NSLayoutConstraint.Attribute.left)
    }
    
    func constrainView(_ view: UIView?, leftOf positioningView: UIView?, withOffset offset: CGFloat) -> NSLayoutConstraint? {
        return constrainView(view, attribute: NSLayoutConstraint.Attribute.right, to: positioningView, attribute: NSLayoutConstraint.Attribute.left, constant: offset, multiplier: 1.0)
    }
    
    func constrainView(_ view: UIView?, rightOf positioningView: UIView?) -> NSLayoutConstraint? {
        return constrainView(view, attribute: NSLayoutConstraint.Attribute.left, to: positioningView, attribute: NSLayoutConstraint.Attribute.right)
    }
    
    func constrainView(_ view: UIView?, rightOf positioningView: UIView?, withOffset offset: CGFloat) -> NSLayoutConstraint? {
        return constrainView(view, attribute: NSLayoutConstraint.Attribute.left, to: positioningView, attribute: NSLayoutConstraint.Attribute.right, constant: offset, multiplier: 1.0)
    }
    
    func constrainView(_ view: UIView?, toTopOf positioningView: UIView?) -> NSLayoutConstraint? {
        return constrainView(view, attribute: NSLayoutConstraint.Attribute.top, to: positioningView, attribute: NSLayoutConstraint.Attribute.top)
    }
    
    func constrainView(_ view: UIView?, toBottomOf positioningView: UIView?) -> NSLayoutConstraint? {
        return constrainView(view, attribute: NSLayoutConstraint.Attribute.bottom, to: positioningView, attribute: NSLayoutConstraint.Attribute.bottom)
    }
    
    func constrainView(_ view: UIView?, toWidthOf sizingView: UIView?) -> NSLayoutConstraint? {
        return constrainView(view, attribute: NSLayoutConstraint.Attribute.width, to: sizingView, attribute: NSLayoutConstraint.Attribute.width)
    }
    
    func constrainView(_ view: UIView?, toHeightOf sizingView: UIView?) -> NSLayoutConstraint? {
        return constrainView(view, attribute: NSLayoutConstraint.Attribute.height, to: sizingView, attribute: NSLayoutConstraint.Attribute.height)
    }
    
    func constrainView(_ viewA: UIView?, attribute attributeA: NSLayoutConstraint.Attribute, to viewB: UIView?, attribute attributeB: NSLayoutConstraint.Attribute) -> NSLayoutConstraint? {
        return constrainView(viewA, attribute: attributeA, to: viewB, attribute: attributeB, constant: 0.0, multiplier: 1.0)
    }
    
    func constrainView(_ viewA: UIView?, attribute attributeA: NSLayoutConstraint.Attribute, to viewB: UIView?, attribute attributeB: NSLayoutConstraint.Attribute, constant: CGFloat, multiplier: CGFloat) -> NSLayoutConstraint? {
        return constrainView(viewA, attribute: attributeA, to: viewB, attribute: attributeB, constant: constant, multiplier: multiplier, relation: .equal)
    }
    
    func constrainView(_ viewA: UIView?, attribute attributeA: NSLayoutConstraint.Attribute, to viewB: UIView?, attribute attributeB: NSLayoutConstraint.Attribute, constant: CGFloat, multiplier: CGFloat, relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint? {
        var bind: NSLayoutConstraint? = nil
        if let viewA = viewA {
            bind = NSLayoutConstraint(item: viewA, attribute: attributeA, relatedBy: relation, toItem: viewB, attribute: attributeB, multiplier: multiplier, constant: constant)
        }
        viewA?.translatesAutoresizingMaskIntoConstraints = false
        viewB?.translatesAutoresizingMaskIntoConstraints = false
        if let bind = bind {
            addConstraint(bind)
        }
        return bind
    }
    
    func constrainView(toLeft view: UIView?) -> NSLayoutConstraint? {
        return constrainView(toLeft: view, withInset: 0)
    }
    
    func constrainView(toLeft view: UIView?, withInset inset: CGFloat) -> NSLayoutConstraint? {
        return constrainView(view, to: UIEdgeInsets(top: CGFloat(NSNotFound), left: inset, bottom: CGFloat(NSNotFound), right: CGFloat(NSNotFound)))?[IPConstraintKeyLeft]
    }
    
    func constrainView(toRight view: UIView?) -> NSLayoutConstraint? {
        return constrainView(toRight: view, withInset: 0)
    }
    
    func constrainView(toRight view: UIView?, withInset inset: CGFloat) -> NSLayoutConstraint? {
        return constrainView(view, to: UIEdgeInsets(top: CGFloat(NSNotFound), left: CGFloat(NSNotFound), bottom: CGFloat(NSNotFound), right: -inset))?[IPConstraintKeyRight]
    }
    
    func constrainView(toTop view: UIView?) -> NSLayoutConstraint? {
        return constrainView(toTop: view, withInset: 0)
    }
    
    func constrainView(toTop view: UIView?, withInset inset: CGFloat) -> NSLayoutConstraint? {
        return constrainView(view, to: UIEdgeInsets(top: inset, left: CGFloat(NSNotFound), bottom: CGFloat(NSNotFound), right: CGFloat(NSNotFound)))?[IPConstraintKeyTop]
    }
    
    func constrainView(toBottom view: UIView?) -> NSLayoutConstraint? {
        return constrainView(toBottom: view, withInset: 0)
    }
    
    func constrainView(toBottom view: UIView?, withInset inset: CGFloat) -> NSLayoutConstraint? {
        return constrainView(view, to: UIEdgeInsets(top: CGFloat(NSNotFound), left: CGFloat(NSNotFound), bottom: -inset, right: CGFloat(NSNotFound)))?[IPConstraintKeyBottom]
    }
    
    
    func constrainView(toMiddleVertically view: UIView?) -> NSLayoutConstraint? {
        return constrainView(view, attribute: NSLayoutConstraint.Attribute.centerY, to: self, attribute: NSLayoutConstraint.Attribute.centerY)
    }
    
    func constrainView(toMiddleHorizontally view: UIView?) -> NSLayoutConstraint? {
        return constrainView(view, attribute: NSLayoutConstraint.Attribute.centerX, to: self, attribute: NSLayoutConstraint.Attribute.centerX)
    }
    
    func constrainTopOf(_ view: UIView?, toCenterYWithOffset offset: CGFloat) -> NSLayoutConstraint? {
        return constrainView(view, attribute: NSLayoutConstraint.Attribute.top, to: self, attribute: NSLayoutConstraint.Attribute.centerY, constant: offset, multiplier: 1)
    }
    
    func constrainBottomOf(_ view: UIView?, toCenterYWithOffset offset: CGFloat) -> NSLayoutConstraint? {
        return constrainView(view, attribute: NSLayoutConstraint.Attribute.bottom, to: self, attribute: NSLayoutConstraint.Attribute.centerY, constant: offset, multiplier: 1)
    }
    
    func constrainView(toAllEdges view: UIView?) -> ConstraintDictionary? {
        return constrainView(view, to: UIEdgeInsets.zero)
    }
    
    func constrainView(toHorizontalEdges view: UIView?) -> ConstraintDictionary? {
        return constrainView(view, to: UIEdgeInsets(top: CGFloat(NSNotFound), left: 0, bottom: CGFloat(NSNotFound), right: 0))
    }
    
}

