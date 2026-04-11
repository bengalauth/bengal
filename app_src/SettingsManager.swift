//
//  SettingsManager.swift
//  bengal
//
//  Created by naomisphere on April 9th, 2026.
//  Copyright © 2026 naomisphere. All rights reserved.
//

import Foundation

import AppKit
import os.log

// logger
func bundle_log(_ message: String) {
    let logPath = "/tmp/bengal.log"
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    let timestamp = formatter.string(from: Date())
    let line = "[\(timestamp)] \(message)\n"
    
    if let data = line.data(using: .utf8) {
        if !FileManager.default.fileExists(atPath: logPath) {
            try? data.write(to: URL(fileURLWithPath: logPath))
            // make ww (666) so other processes/users can append if needed
            var attrs = [FileAttributeKey: Any]()
            attrs[.posixPermissions] = 0o666
            try? FileManager.default.setAttributes(attrs, ofItemAtPath: logPath)
        } else {
            if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        }
    }
    // os_log("Bengal: %{public}@", message)
}

class BengalSettings: Codable {
    var bgPath: String?
    var bgScaling: String = "fit" // fit, original, crop
    var bgType: String = "image" // image, gif, video
    var uiMode: String = "default" // default, minimalistic
    var cardTransparency: Double = 0.8
    var powerButtonsTransparency: Double = 0.6
    var clockSize: Int = 80
    var avatarPath: String? // Login Screen Avatar override
    
    var clockColor: String = "#FFFFFF"
    var clockAngle: Double = 270.0
    var loginButtonColor: String = "#5285F5|#3866D6"
    var loginButtonAngle: Double = 270.0
    
    var powerButtonBGColor: String = "#FFFFFF|#FFFFFF"
    var powerButtonBGAngle: Double = 270.0
    var powerButtonIconColor: String = "#FFFFFF"
    var powerButtonIconAngle: Double = 270.0
    
    static var shared: BengalSettings = BengalSettings.load()
    
    static func load() -> BengalSettings {
        let configDir = ("~/.config/bengal" as NSString).expandingTildeInPath
        let userPath = configDir + "/settings.json"
        
        // try user settings
        if let data = try? Data(contentsOf: URL(fileURLWithPath: userPath)),
           let settings = try? JSONDecoder().decode(BengalSettings.self, from: data) {
            return settings
        }
        
        // go for bundled settings 
        let bundle = Bundle(for: BengalSettings.self)
        if let bundlePath = bundle.path(forResource: "settings", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: bundlePath)),
           let settings = try? JSONDecoder().decode(BengalSettings.self, from: data) {
            bundle_log("Loaded settings from bundle.")
            return settings
        }

        return BengalSettings()
    }
    
    func save() {
        let configDir = ("~/.config/bengal" as NSString).expandingTildeInPath
        let path = configDir + "/settings.json"
        
        try? FileManager.default.createDirectory(atPath: configDir, withIntermediateDirectories: true)
        
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }
}
