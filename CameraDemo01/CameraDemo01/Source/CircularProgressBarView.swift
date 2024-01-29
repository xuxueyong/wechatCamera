//
//  CircularProgressBarView.swift
//  CameraDemo01
//
//  Created by 徐雪勇 on 2023/7/12.
//

import Foundation
import UIKit

class CircularProgressBarView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var progress: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
        
    override func draw(_ rect: CGRect) {
        let lineWidth: CGFloat = 7.0
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2 - lineWidth
        
        // 绘制背景圆环
        let backgroundPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        UIColor.lightGray.setStroke()
        backgroundPath.lineWidth = lineWidth
        backgroundPath.stroke()
        
        // 绘制进度圆环
        let progressPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: -CGFloat.pi / 2, endAngle: -CGFloat.pi / 2 + CGFloat.pi * 2 * progress, clockwise: true)
        UIColor.green.setStroke()
        progressPath.lineWidth = lineWidth
        progressPath.lineCapStyle = .round
        progressPath.stroke()
    }
}

