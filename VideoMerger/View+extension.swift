//
//  UIView+ConstraintAccessors.swift
//  UNUMCanvas
//
//  Created by Patrick Flanagan on 11/20/18.
//

import UIKit

public extension UIView {

    private func getConstraint(from constraintView: UIView?, type: NSLayoutConstraint.Attribute) -> NSLayoutConstraint? {

        var returnConstraint: NSLayoutConstraint? = nil

        // Keep in mind that this will return the last of the constraints fulfilling the type.
        for constraint in constraintView?.constraints ?? [] {
            guard
                let view = constraint.firstItem as? UIView,
                view == self
                else {
                    continue
            }
            if constraint.firstAttribute == type {
                returnConstraint = constraint
            }
        }
        return returnConstraint
    }

    private func getInternalConstraint(type: NSLayoutConstraint.Attribute) -> NSLayoutConstraint? {
        return getConstraint(from: self, type: type)
    }

    var widthConstraint: NSLayoutConstraint? {
        return getInternalConstraint(type: .width)
    }

    var heightConstraint: NSLayoutConstraint? {
        return getInternalConstraint(type: .height)
    }

    var heightIsBoundToWidth: Bool {
        for constraint in constraints {
            if
                let view = constraint.firstItem as? UIView,
                view == self,
                constraint.firstAttribute == .height,
                constraint.secondAttribute == .width
            {
                return true
            }
        }
        return false
    }

    var widthIsBoundToHeight: Bool {

        for constraint in constraints {
            if
                let view = constraint.firstItem as? UIView,
                view == self,
                constraint.firstAttribute == .width,
                constraint.secondAttribute == .height
            {
                return true
            }
        }
        return false
    }
}

public extension UIView {
    private func getSuperviewConstraint(type: NSLayoutConstraint.Attribute) -> NSLayoutConstraint? {
        return getConstraint(from: self.superview, type: type)
    }

    var leadingConstraint: NSLayoutConstraint? {
        return getSuperviewConstraint(type: .leading)
    }

    var topConstraint: NSLayoutConstraint? {
        return getSuperviewConstraint(type: .top)
    }
}
