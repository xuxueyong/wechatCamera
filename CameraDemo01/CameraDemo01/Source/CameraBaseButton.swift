//
//  CameraBaseButton.swift
//  CameraDemo01
//
//  Created by 徐雪勇 on 2023/7/20.
//

import UIKit

class CameraBaseButton: UIButton {
    var width: CGFloat?
    var height: CGFloat?
    
    var hitSize: CGSize = .zero {
        didSet {
            width = hitSize.width
            height = hitSize.height
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let touchWidth = width ?? bounds.width
        let touchHeight = height ?? bounds.height
        let deltaX = max(0, touchWidth - bounds.width)
        let deltaY = max(0, touchHeight - bounds.height)
        let bounds = CGRectInset(bounds, -deltaX, -deltaY)
        return CGRectContainsPoint(bounds, point)
    }
}
