//
//  BrightnessManager.swift
//  BrightIntosh
//
//  Created by Niklas Rousset on 01.10.23.
//

import Foundation
import Cocoa

extension NSScreen {
    var displayId: CGDirectDisplayID? {
        return deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] as? CGDirectDisplayID
    }
}

class BrightnessManager : NSObject {
    
    @objc var settings: Settings
    
    var observationBrightIntoshActive: NSKeyValueObservation?
    var observationBrightness: NSKeyValueObservation?
    var observationOverlayTechnique: NSKeyValueObservation?
    
    var brightnessTechnique: BrightnessTechnique?
    
    override init() {
        settings = Settings.shared
        super.init()
        
        setBrightnessTechnique()
        
        if Settings.shared.brightintoshActive {
            self.brightnessTechnique?.enable()
        }
        
        // Observe displays
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenParameters(notification:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil)
        
        // Observe application state
        observationBrightIntoshActive = observe(\.settings.brightintoshActive, options: [.old, .new]) {
            object, change in
            print("Toggled increased brightness. Active: \(Settings.shared.brightintoshActive)")
            
            if Settings.shared.brightintoshActive {
                self.brightnessTechnique?.enable()
            } else {
                self.brightnessTechnique?.disable()
            }
        }
        
        observationBrightness = observe(\.settings.brightness, options: [.old, .new]) {
            object, change in
            print("Set brightness to \(Settings.shared.brightness)")
            if let brightnessTechnique = self.brightnessTechnique, brightnessTechnique.isEnabled {
                self.brightnessTechnique?.adjustBrightness()
            }
        }
        
        
        observationOverlayTechnique = observe(\.settings.overlayTechnique, options: [.old, .new]) {
            object, change in
            self.setBrightnessTechnique()
        }
    }
    
    func setBrightnessTechnique() {
        brightnessTechnique?.disable()
        if Settings.shared.overlayTechnique {
            brightnessTechnique = OverlayTechnique()
            print("Activated Overlay Technique")
        } else {
            brightnessTechnique = GammaTechnique()
            print("Activated Gamma Technique")
        }
    }
    
    @objc func handleScreenParameters(notification: Notification) {
        if let screen = getBuiltInScreen() {
            if let brightnessTechnique = brightnessTechnique, Settings.shared.brightintoshActive {
                if !brightnessTechnique.isEnabled {
                    brightnessTechnique.enable()
                } else {
                    brightnessTechnique.screenUpdate(screen: screen)
                }
            }
        } else {
            brightnessTechnique?.disable()
        }
    }
}


func getBuiltInScreen() -> NSScreen? {
    for screen in NSScreen.screens {
        let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
        let displayId: CGDirectDisplayID = screenNumber as! CGDirectDisplayID
        if (CGDisplayIsBuiltin(displayId) != 0) {
            return screen
        }
    }
    return nil
}
