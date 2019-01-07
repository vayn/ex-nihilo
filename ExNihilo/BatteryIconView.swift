//
//  BatteryIconView.swift
//  ExNihilo
//
//  Created by Vayn on 2016/12/27.
//  Copyright © 2016年 Vayn. All rights reserved.
//

import Cocoa
import DynamicColor

class BatteryIconView: NSView {

    private let ENERGY_UNIT: CGFloat = 1.95

    private let iconViewWidth: CGFloat = 195.0
    private let iconViewHeight: CGFloat = 28.0

    private let startPoint: NSPoint = NSMakePoint(0, 0)
    private let endPoint: NSPoint = NSMakePoint(0, 28)

    private var powerLayer: PowerLayer? = nil

    var batteryEnergy: CGFloat = 0 {
        didSet {
            batteryEnergy = batteryEnergy * ENERGY_UNIT - 10
            if batteryEnergy < 0 { batteryEnergy = 0 }

            needsDisplay = true
            powerLayer?.setNeedsDisplay()
        }
    }

    var batteryColor = DynamicColor(red: 46.0/255.0, green: 117.0/255.0, blue: 146.0/255.0, alpha: 1.0)

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        createBatteryIcon()
    }

    func createBatteryIcon() -> Void {
        // Colors
        let batteryFrameColor = DynamicColor(red: 0.515, green: 0.507, blue: 0.507, alpha: 1.0)
        let batteryHeaderColor = DynamicColor(red: 0.615, green: 0.615, blue: 0.615, alpha: 1.0)

        // Positions
        let headerX: CGFloat = iconViewWidth - 3
        let frameX: CGFloat = iconViewWidth - 5

        // Header drawing
        let batteryHeaderPath = NSBezierPath()
        batteryHeaderPath.move(to: NSMakePoint(headerX, iconViewHeight/2-4))
        batteryHeaderPath.line(to: NSMakePoint(iconViewWidth, iconViewHeight/2-4))
        batteryHeaderPath.line(to: NSMakePoint(iconViewWidth, iconViewHeight/2+4))
        batteryHeaderPath.line(to: NSMakePoint(headerX, iconViewHeight/2+4))
        batteryHeaderPath.line(to: NSMakePoint(headerX, iconViewHeight/2-4))
        batteryHeaderPath.close()
        batteryHeaderColor.setFill()
        batteryHeaderPath.fill()

        // Frame drawing
        let batteryFramePath = NSBezierPath()
        batteryFramePath.lineWidth = 1.0
        batteryFramePath.move(to: startPoint)
        batteryFramePath.line(to: NSMakePoint(frameX, startPoint.y))
        batteryFramePath.line(to: NSMakePoint(frameX, endPoint.y))
        batteryFramePath.line(to: endPoint)
        batteryFramePath.line(to: startPoint)
        batteryFramePath.close()
        batteryFrameColor.setStroke()
        batteryFramePath.stroke()

        drawArc()
    }

    func drawArc() {
        if batteryEnergy <= (ENERGY_UNIT * CGFloat(CapacityLevel.half.rawValue)) {
            batteryColor = CapacityLevel.half.color()
        }

        if batteryEnergy <= (ENERGY_UNIT * CGFloat(CapacityLevel.empty.rawValue)) {
            batteryColor = CapacityLevel.empty.color()
        }

        powerLayer = PowerLayer(batteryEnergy, batteryColor)

        self.layer?.addSublayer(powerLayer!)
        self.wantsLayer = true
        powerLayer!.animate()
    }
}
