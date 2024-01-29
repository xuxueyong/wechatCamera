//
//  CameraAotoFocusView.swift
//  CameraDemo01
//
//  Created by 徐雪勇 on 2023/7/12.
//

import Foundation

import UIKit

class CameraAotoFocusView: UIView {
    private var borderPath: UIBezierPath!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        borderPath = UIBezierPath()
        isUserInteractionEnabled = true
        backgroundColor = .clear
    }
    
    override func draw(_ rect: CGRect) {
        borderPath = UIBezierPath(rect: bounds)
        borderPath.lineCapStyle = .butt
        borderPath.lineWidth = 2.0
//        let color = UIColor(red: 45/255.0, green: 175/255.0, blue: 45/255.0, alpha: 1)
        let color: UIColor = .white
        color.setStroke()
        
        borderPath.move(to: CGPoint(x: rect.size.width/2.0, y: 0))
        borderPath.addLine(to: CGPoint(x: rect.size.width/2.0, y: 0 + 8))
        borderPath.move(to: CGPoint(x: 0, y: rect.size.width/2.0))
        borderPath.addLine(to: CGPoint(x: 0 + 8, y: rect.size.width/2.0))
        borderPath.move(to: CGPoint(x: rect.size.width/2.0, y: rect.size.height))
        borderPath.addLine(to: CGPoint(x: rect.size.width/2.0, y: rect.size.height - 8))
        borderPath.move(to: CGPoint(x: rect.size.width, y: rect.size.height/2.0))
        borderPath.addLine(to: CGPoint(x: rect.size.width - 8, y: rect.size.height/2.0))
        
        borderPath.stroke()
    }
}
