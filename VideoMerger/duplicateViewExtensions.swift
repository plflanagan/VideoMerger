//
//  duplicateViewExtensions.swift
//  VideoMerger
//
//  Created by Patrick Flanagan on 4/30/19.
//  Copyright © 2019 ORG_NAME. All rights reserved.
//

import UIKit

extension UIImage {
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = image?.cgImage else {
            return nil
        }
        self.init(cgImage: cgImage)
    }

    func imageByMakingWhiteBackgroundTransparent() -> UIImage? {

        let image = UIImage(data: self.jpegData(compressionQuality: 1.0)!)!
        let rawImageRef: CGImage = image.cgImage!

        let colorMasking: [CGFloat] = [222, 255, 222, 255, 222, 255]
        UIGraphicsBeginImageContextWithOptions(image.size, false, 1.0)

        let maskedImageRef = rawImageRef.copy(maskingColorComponents: colorMasking)
        UIGraphicsGetCurrentContext()?.translateBy(x: 0.0,y: image.size.height)
        UIGraphicsGetCurrentContext()?.scaleBy(x: 1.0, y: -1.0)
        UIGraphicsGetCurrentContext()?.draw(maskedImageRef!, in: CGRect.init(x: 0, y: 0, width: image.size.width, height: image.size.height))
        let result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return result

    }
}

extension UIView {
    func asImage() -> UIImage? {
        let fitRect = UIScreen.main.bounds

        let horizontalRatio = fitRect.size.width / self.bounds.size.width
        let verticalRatio = fitRect.size.height / self.bounds.size.height
        let ratio = min(horizontalRatio, verticalRatio)

        let convertedRect = CGRect(
            x: fitRect.origin.x,
            y: fitRect.origin.y,
            width: (self.bounds.size.width * ratio).rounded(),
            height: (self.bounds.size.height * ratio).rounded()
        )
        UIGraphicsBeginImageContextWithOptions(convertedRect.size, false, 1.0)
//        UIGraphicsBeginImageContextWithOptions(convertedRect.size, self.isOpaque, 0.0)

        self.drawHierarchy(in: convertedRect, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgImage = image?.cgImage else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    func sketchShadow(opacity: Float, x: CGFloat, y: CGFloat, blur: CGFloat, spread: CGFloat) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowRadius = blur / 2
        self.layer.shadowOffset = CGSize(width: x, height: y)
        self.layer.shadowOpacity = opacity
        if spread == 0 { self.layer.shadowPath = nil } else {
            let dx = -spread
            let rect = self.bounds.insetBy(dx: dx, dy: dx)
            self.layer.shadowPath = UIBezierPath(rect: rect).cgPath
        }
    }

}
