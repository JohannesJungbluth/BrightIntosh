//
//  AutomationManager.swift
//  BrightIntosh
//
//  Created by Niklas Rousset on 02.10.23.
//

import Foundation

class AutomationManager: NSObject {
    @objc var settings: Settings
    
    private let batteryLevelThreshold = 99
    private let batteryCheckInterval = 10.0
    private var batteryCheckTimer: Timer?
    
    var observationBatteryAutomation: NSKeyValueObservation?
    
    override init() {
        settings = Settings.shared
        super.init()
        
        if Settings.shared.batteryAutomation {
            startBatteryAutomation()
        }
            
        // Observe application state
        observationBatteryAutomation = observe(\.settings.batteryAutomation, options: [.old, .new]) {
            object, change in
            print("Toggled battery automation. Active: \(Settings.shared.batteryAutomation)")
            
            if Settings.shared.batteryAutomation {
                self.startBatteryAutomation()
            } else {
                self.stopBatteryAutomation()
            }
        }
    }
    
    func startBatteryAutomation() {
        if batteryCheckTimer != nil {
            return
        }
        let batteryCheckDate = Date()
        batteryCheckTimer = Timer(fire: batteryCheckDate, interval: batteryCheckInterval, repeats: true, block: {t in self.checkBatteryAutomation()})
        RunLoop.main.add(batteryCheckTimer!, forMode: RunLoop.Mode.default)
        print("Started automation")
    }
    
    func stopBatteryAutomation() {
        if batteryCheckTimer != nil {
            batteryCheckTimer?.invalidate()
            batteryCheckTimer = nil
        }
    }
    
    func checkBatteryAutomation() {
        if !Settings.shared.brightintoshActive {
            return
        }
        if let batteryCapacity = getBatteryCapacity() {
            let threshold = Settings.shared.batteryAutomationThreshold
            if batteryCapacity <= threshold {
                print("Battery level dropped below \(threshold)%. Deactivating increased brightness.")
                Settings.shared.brightintoshActive = false
            }
        }
    }
    
}
