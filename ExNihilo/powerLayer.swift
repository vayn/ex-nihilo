//
//  powerLayer.swift
//  ExNihilo
//
//  Created by Vayn on 2017/7/1.
//  Copyright © 2017年 Vayn. All rights reserved.
//

import Cocoa
import DynamicColor

class PowerLayer: CAShapeLayer {
    let animationDuration: CFTimeInterval = 0.28

    var pathWidth: CGFloat = 0
    var pathColor: DynamicColor?

    let startPoint = CGPoint(x: 5, y: 5)
    let endPoint = CGPoint(x: 5, y: 23)
    let yDelta: CGFloat = 11.0

    init(_ width: CGFloat, _ color: DynamicColor) {
        super.init()
        pathColor = color
        pathWidth = width

        fillColor = color.cgColor
        path = powerPathStarting
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var powerPathPre: CGPath {
        let powerPath = CGMutablePath()
        powerPath.move(to: startPoint)
        powerPath.addLine(to: CGPoint(x: pathWidth, y: startPoint.y))
        powerPath.addLine(to: CGPoint(x: pathWidth, y: endPoint.y))
        powerPath.addLine(to: endPoint)
        powerPath.addLine(to: startPoint)
        powerPath.closeSubpath()
        return powerPath
    }

    var powerPathStarting: CGPath {
        let powerPath = CGMutablePath()
        powerPath.move(to: startPoint)
        powerPath.addLine(to: CGPoint(x: pathWidth, y: startPoint.y))
        powerPath.addCurve(to: CGPoint(x: pathWidth, y: endPoint.y),
                           control1: CGPoint(x: pathWidth-1, y: yDelta),
                           control2: CGPoint(x: pathWidth+1, y: yDelta+6))
        powerPath.addLine(to: endPoint)
        powerPath.addLine(to: startPoint)
        powerPath.closeSubpath()
        return powerPath
    }

    var powerPathLow: CGPath {
        let powerPath = CGMutablePath()
        powerPath.move(to: startPoint)
        powerPath.addLine(to: CGPoint(x: pathWidth, y: startPoint.y))
        powerPath.addCurve(to: CGPoint(x: pathWidth, y: endPoint.y),
                         control1: CGPoint(x: pathWidth-2, y: yDelta),
                         control2: CGPoint(x: pathWidth+2, y: yDelta+6))
        powerPath.addLine(to: endPoint)
        powerPath.addLine(to: startPoint)
        powerPath.closeSubpath()
        return powerPath
    }

    var powerPathHigh: CGPath {
        let powerPath = CGMutablePath()
        powerPath.move(to: startPoint)
        powerPath.addLine(to: CGPoint(x: pathWidth, y: startPoint.y))
        powerPath.addCurve(to: CGPoint(x: pathWidth, y: endPoint.y),
                         control1: CGPoint(x: pathWidth+2, y: yDelta),
                         control2: CGPoint(x: pathWidth-2, y: yDelta+6))
        powerPath.addLine(to: endPoint)
        powerPath.addLine(to: startPoint)
        powerPath.closeSubpath()
        return powerPath
    }

    var powerPathComplete: CGPath {
        let powerPath = CGMutablePath()
        powerPath.move(to: startPoint)
        powerPath.addLine(to: CGPoint(x: pathWidth, y: startPoint.y))
        powerPath.addLine(to: CGPoint(x: pathWidth, y: endPoint.y))
        powerPath.addLine(to: endPoint)
        powerPath.addLine(to: startPoint)
        powerPath.closeSubpath()
        return powerPath
    }

    func animate() {
        let powerAnimationPre: CABasicAnimation = CABasicAnimation(keyPath: "path")
        powerAnimationPre.fromValue = powerPathPre
        powerAnimationPre.toValue = powerPathStarting
        powerAnimationPre.beginTime = 0.0
        powerAnimationPre.duration = animationDuration

        let powerAnimationLow: CABasicAnimation = CABasicAnimation(keyPath: "path")
        powerAnimationLow.fromValue = powerPathStarting
        powerAnimationLow.toValue = powerPathLow
        powerAnimationLow.beginTime = powerAnimationPre.beginTime + powerAnimationPre.duration
        powerAnimationLow.duration = animationDuration


        let powerAnimationHigh: CABasicAnimation = CABasicAnimation(keyPath: "path")
        powerAnimationHigh.fromValue = powerPathLow
        powerAnimationHigh.toValue = powerPathHigh
        powerAnimationHigh.beginTime = powerAnimationLow.beginTime + powerAnimationLow.duration
        powerAnimationHigh.duration = animationDuration

        let powerAnimationComplete: CABasicAnimation = CABasicAnimation(keyPath: "path")
        powerAnimationComplete.fromValue = powerPathHigh
        powerAnimationComplete.toValue = powerPathComplete
        powerAnimationComplete.beginTime = powerAnimationHigh.beginTime + powerAnimationHigh.duration
        powerAnimationComplete.duration = animationDuration

        let powerAnimationGroup: CAAnimationGroup = CAAnimationGroup()
        powerAnimationGroup.animations = [powerAnimationPre, powerAnimationLow, powerAnimationHigh, powerAnimationComplete]
        powerAnimationGroup.repeatCount = Float.greatestFiniteMagnitude
        powerAnimationGroup.duration = powerAnimationComplete.beginTime + powerAnimationComplete.duration
        powerAnimationGroup.fillMode = CAMediaTimingFillMode.forwards
        powerAnimationGroup.isRemovedOnCompletion = false
        add(powerAnimationGroup, forKey: "multiAnimation")

        let colorAnimation = CAKeyframeAnimation(keyPath: "fillColor")
        let colors: [CGColor] = [pathColor!.cgColor, pathColor!.lighter().cgColor]
        colorAnimation.values = colors
        colorAnimation.repeatCount = Float.greatestFiniteMagnitude
        colorAnimation.duration = 2.0
        colorAnimation.calculationMode = CAAnimationCalculationMode.paced
        colorAnimation.fillMode = CAMediaTimingFillMode.forwards
        colorAnimation.isRemovedOnCompletion = false
        colorAnimation.autoreverses = true
        add(colorAnimation, forKey: "fillColorAnimation")
    }
}
