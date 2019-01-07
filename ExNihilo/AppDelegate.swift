//
//  AppDelegate.swift
//  ExNihilo
//
//  Created by Vayn on 2016/12/15.
//  Copyright © 2016年 Vayn. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var batteryInfoView: BatteryInfoView!
    @IBOutlet weak var autoLoginItem: NSMenuItem!

    let helperBundleIdentifier = "com.vayn.ex.nihilo.helper" as CFString

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var batteryInfoMenuItem: NSMenuItem!

    var currentTitle: NSMutableAttributedString = NSMutableAttributedString(string: "ExNihilo")
    var currentTitleColor: NSColor = NSColor.black
    var isMenuOpen: Bool = false

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        chooseInitialTitleColor()

        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 12.0
        paragraphStyle.alignment = NSTextAlignment.center

        let attributes: [String: Any] = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): NSFont(name: "Chalkduster", size: 14.0) ?? NSFont.systemFont(ofSize: 14),
                                         convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle): paragraphStyle]
        currentTitle.addAttributes(convertToNSAttributedStringKeyDictionary(attributes), range: NSMakeRange(0, currentTitle.length))

        statusItem.button?.attributedTitle = currentTitle
        statusItem.menu = statusMenu

        statusMenu.delegate = self

        batteryInfoMenuItem = statusMenu.item(withTitle: "Battery Info")
        batteryInfoMenuItem.view = batteryInfoView

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            let aboutItem = statusMenu.item(withTitle: "About Ex nihilo")
            aboutItem?.title = "About Ex nihilo (\(version))"
        }

        updateAutoLoginItem()
        updateBatteryInfo()

        let gpus = Utils.getGPUNames()
        var gpu = "Unknown"

        if gpus.count == 1 {
            gpu = gpus[0]
            batteryInfoView.gpuLabel.stringValue = "GPU (Integrated)"
        }
        else if gpus.count > 1 {
            gpu = gpus.first!
            batteryInfoView.gpuLabel.stringValue = "GPU (Discrete)"
        }

        batteryInfoView.gpuTextField.stringValue = gpu

        var notify_token: Int32 = 0
        notify_register_dispatch(kIOPSTimeRemainingNotificationKey,
                                 &notify_token,
                                 DispatchQueue.main) { (token: Int32) in
                                    self.updateBatteryInfo()
        }

        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: nil) {_ in 
                self.updateBatteryInfo()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        DistributedNotificationCenter.default().removeObserver(
            self,
            name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }

    // MARK: - Helper
    func updateBatteryInfo() -> Void {
        let uptime = Utils.uptime()
        let info: BatteryInfo = Utils.batteryInfo()

        if 0...CapacityLevel.empty.rawValue ~= info.currentCapacity {
            currentTitleColor = CapacityLevel.empty.color()
        }
        else if CapacityLevel.empty.rawValue...CapacityLevel.half.rawValue ~= info.currentCapacity {
            currentTitleColor = CapacityLevel.half.color()
        }
        else {
            chooseInitialTitleColor()
        }

        if !isMenuOpen {
            currentTitle.addAttribute(NSAttributedString.Key.foregroundColor,
                                      value: currentTitleColor,
                                      range: NSMakeRange(0, currentTitle.length))
        }

        currentTitle.mutableString.setString("\(info.currentCapacity)%")
        statusItem.button?.attributedTitle = currentTitle
        
        batteryInfoView.batteryIconView.batteryEnergy = CGFloat(info.currentCapacity)
        batteryInfoView.timeTextField.stringValue = info.timeRemaining
        batteryInfoView.statusTextField.stringValue = info.health
        batteryInfoView.cycleCountTextField.stringValue = "\(info.cycleCount)"
        batteryInfoView.healthTextField.stringValue = "\(info.maxCapacity)%"
        batteryInfoView.temperatureTextField.stringValue = String(format: "%.1f°C", info.temperature)
        batteryInfoView.uptimeTextField.stringValue = "\(uptime.days)d \(uptime.hrs)h \(uptime.mins)m"
    }

    func updateAutoLoginItem() -> Void {
        if SMJobCopyDictionary(kSMDomainUserLaunchd, helperBundleIdentifier) != nil {
            autoLoginItem.state = NSControl.StateValue.on
        }
    }

    func chooseInitialTitleColor() -> Void {
        if UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" {
            currentTitleColor = NSColor.white
        } else {
            currentTitleColor = NSColor.black
        }
    }

    // MARK: - IBAction
    @IBAction func autoLaunchClicked(_ sender: Any) {
        if autoLoginItem.state == NSControl.StateValue.on {
            autoLoginItem.state = NSControl.StateValue.off
        } else {
            autoLoginItem.state = NSControl.StateValue.on
        }

        let autoLaunch = (autoLoginItem.state == NSControl.StateValue.on)
        if SMLoginItemSetEnabled(helperBundleIdentifier, autoLaunch) {
            if autoLaunch {
                print("Successfully add login item.")
            } else {
                print("Successfully remove login item.")
            }

        } else {
            print("Failed to add login item.")
        }
    }

    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
}

extension AppDelegate: NSMenuDelegate {

    func menuWillOpen(_ menu: NSMenu) {
        isMenuOpen = true

        currentTitle.addAttribute(NSAttributedString.Key.foregroundColor,
                                  value: NSColor.white,
                                  range: NSMakeRange(0, currentTitle.length))
        statusItem.button?.attributedTitle = currentTitle
    }

    func menuDidClose(_ menu: NSMenu) {
        isMenuOpen = false

        currentTitle.addAttribute(NSAttributedString.Key.foregroundColor,
                                  value: currentTitleColor,
                                  range: NSMakeRange(0, currentTitle.length))
        statusItem.button?.attributedTitle = currentTitle
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
