//
//  BatteryInfoView.swift
//  ExNihilo
//
//  Created by Vayn on 2016/12/16.
//  Copyright © 2016年 Vayn. All rights reserved.
//

import Cocoa

class BatteryInfoView: NSView {

    @IBOutlet weak var timeTextField: NSTextField!
    @IBOutlet weak var statusTextField: NSTextField!
    @IBOutlet weak var cycleCountTextField: NSTextField!
    @IBOutlet weak var healthTextField: NSTextField!
    @IBOutlet weak var temperatureTextField: NSTextField!
    @IBOutlet weak var uptimeTextField: NSTextField!

    @IBOutlet weak var gpuLabel: NSTextField!
    @IBOutlet weak var gpuTextField: NSTextField!

    @IBOutlet weak var batteryIconView: BatteryIconView!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }

    @IBAction func aboutClicked(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://github.com/Vayn/ex-nihilo")!)
    }
}
