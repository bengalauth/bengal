//
//  Mechanism.swift
//  bengal
//
//  Created by naomisphere on April 7th, 2026.
//  Copyright © 2026 naomisphere. All rights reserved.
//

// tag:stub - unfinished

import Foundation
import Security
import Security.AuthorizationPlugin
import AppKit

class Mechanism {
    var engine: AuthorizationEngineRef
    var mechanismId: String
    
    // make SURE to keep strong references alive
    static var activeMechanisms: [UnsafeMutableRawPointer: Mechanism] = [:]
    
    init(engine: AuthorizationEngineRef, mechanismId: String) {
        self.engine      = engine
        self.mechanismId = mechanismId
    }
    
    // C-compatible callbacks
    static func mechanismCreate(plugin: AuthorizationPluginRef,
                                engine: AuthorizationEngineRef,
                                mechanismId: AuthorizationMechanismId,
                                outMechanism: UnsafeMutablePointer<AuthorizationMechanismRef?>) -> OSStatus {
        let mechIdString = String(cString: mechanismId)
        let mech = Mechanism(engine: engine, mechanismId: mechIdString)
        outMechanism.pointee = UnsafeMutableRawPointer(Unmanaged.passRetained(mech).toOpaque())
        activeMechanisms[outMechanism.pointee!] = mech
        return errAuthorizationSuccess
    }
    
    static func mechanismInvoke(mechanism: AuthorizationMechanismRef) -> OSStatus {
        guard let mech = activeMechanisms[mechanism] else { return errAuthorizationInternal }
        
        switch mech.mechanismId {
        case _ where mech.mechanismId.contains("UI"):
            return mech.invokeUI()
        case _ where mech.mechanismId.contains("PowerControl"):
            return mech.invokePowerControl()
        case _ where mech.mechanismId.contains("CreateUser"):
            return mech.invokeCreateUser()
        default:
            // if we don't know what this is, just allow it through
            _ = BengalPlugin.shared.callbacks?.SetResult(mech.engine, .allow)
            return errAuthorizationSuccess
        }
    }
    
    static func mechanismDeactivate(mechanism: AuthorizationMechanismRef) -> OSStatus {
        // called by SecurityAgent when it wants the UI to go away (say, auth failed
        // at a later stage, or the whole transaction is being cancelled).
        // We don't have UU access to the UI object here, so just signal done.
        if let mech = activeMechanisms[mechanism] {
            DispatchQueue.main.async {
                NSApp.stop(nil)
                if let dummy = NSEvent.otherEvent(with: .applicationDefined, location: .zero,
                                                   modifierFlags: [], timestamp: 0, windowNumber: 0,
                                                   context: nil, subtype: 0, data1: 0, data2: 0) {
                    NSApp.postEvent(dummy, atStart: true)
                }
            }
            _ = BengalPlugin.shared.callbacks?.DidDeactivate(mech.engine)
        }
        return errAuthorizationSuccess
    }
    
    static func mechanismDestroy(mechanism: AuthorizationMechanismRef) -> OSStatus {
        if let mech = activeMechanisms[mechanism] {
            Unmanaged<Mechanism>.fromOpaque(mechanism).release()
            activeMechanisms.removeValue(forKey: mechanism)
        }
        return errAuthorizationSuccess
    }
    
    // ui; show UI and block until credentials are entered
    func invokeUI() -> OSStatus {
        bundle_log("invokeUI started for mechanism: \(mechanismId)")
        
        let runBlock = {
            bundle_log("Setting up NSApplication...")
            let app = NSApplication.shared
            app.setActivationPolicy(.accessory)
            
            // tag:userdetectionfix
            bundle_log("Detecting user...")
            var suggestedUser = self.getContextString(key: "username")
                                
            if suggestedUser == nil || suggestedUser == "_securityagent" {
                bundle_log("No context user, checking system defaults...")
                let task = Process()
                let pipe = Pipe()
                task.launchPath = "/usr/bin/defaults"
                task.arguments = ["read", "/Library/Preferences/com.apple.loginwindow", "lastUserName"]
                task.standardOutput = pipe
                try? task.run()
                task.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let last = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !last.isEmpty {
                    suggestedUser = last
                    bundle_log("Found last user: \(last)")
                }
            }
            
            bundle_log("Initializing LoginUI for user: \(suggestedUser ?? "unknown")")
            let ui = LoginUI(suggestedUser: suggestedUser ?? "_securityagent", onLogin: { [weak self] username, passwordData in
                guard let self = self else { return }
                bundle_log("Login callback triggered for: \(username)")
                self.setContextValue(key: "username", string: username)
                self.setContextValue(key: "password", data: passwordData)
                _ = BengalPlugin.shared.callbacks?.SetResult(self.engine, .allow)
                bundle_log("Auth allowed, stopping app.")
                NSApp.stop(nil)
            }, onAction: { [weak self] action in
                guard let self = self else { return }
                bundle_log("Action callback triggered: \(action)")
                self.setContextValue(key: "bengal:action", string: action)
                _ = BengalPlugin.shared.callbacks?.SetResult(self.engine, .allow)
                
                if action != "sleep" {
                    bundle_log("Stopping app for action: \(action)")
                    NSApp.stop(nil)
                }
            })
            
            bundle_log("Showing UI...")
            ui.show()
            bundle_log("Entering NSApplication.run...")
            app.run()
            bundle_log("NSApplication.run returned. Closing UI.")
            ui.close()
        }
        
        if Thread.isMainThread { 
            runBlock() 
        } else { 
            bundle_log("Switching to main thread for UI...")
            DispatchQueue.main.sync { runBlock() } 
        }
        
        bundle_log("invokeUI finishing.")
        return errAuthorizationSuccess
    }

    // -- PowerControl
    // handle privileged system actions
    func invokePowerControl() -> OSStatus {
        // read action from context
        if let action = getContextString(key: "bengal:action") {
            let task = Process()
            task.launchPath = "/sbin/shutdown"
            
            if action == "shutdown" {
                task.arguments = ["-h", "now"] // 'shutdown -h now'
                try? task.run()
            } else if action == "restart" {
                task.arguments = ["-r", "now"] // 'shutdown -r now'
                try? task.run()
            } else if action == "sleep" {
                task.launchPath = "/usr/bin/pmset" // 'pmset sleepnow'
                task.arguments = ["sleepnow"]
                try? task.run()
            }
        }
        
        _ = BengalPlugin.shared.callbacks?.SetResult(engine, .allow)
        return errAuthorizationSuccess
    }

    // tag:stub
    func invokeCreateUser() -> OSStatus {
        _ = BengalPlugin.shared.callbacks?.SetResult(engine, .allow)
        return errAuthorizationSuccess
    }
    
    // helpers
    private func setContextValue(key: String, string: String) {
        guard let callbacks = BengalPlugin.shared.callbacks else { return }
        let flags = AuthorizationContextFlags(rawValue: 1) // extractable
        string.withCString { cStr in
            var value = AuthorizationValue(length: string.utf8.count + 1,
                                           data: UnsafeMutableRawPointer(mutating: cStr))
            key.withCString { keyCStr in
                _ = callbacks.SetContextValue(engine, keyCStr, flags, &value)
            }
        }
    }

    private func setContextValue(key: String, data: Data) {
        guard let callbacks = BengalPlugin.shared.callbacks else { return }
        let flags = AuthorizationContextFlags(rawValue: 1)
        data.withUnsafeBytes { rawBuf in
            var value = AuthorizationValue(length: data.count,
                                           data: UnsafeMutableRawPointer(mutating: rawBuf.baseAddress))
            key.withCString { keyCStr in
                _ = callbacks.SetContextValue(engine, keyCStr, flags, &value)
            }
        }
    }

    private func getContextString(key: String) -> String? {
        guard let callbacks = BengalPlugin.shared.callbacks else { return nil }
        var value: UnsafePointer<AuthorizationValue>? = nil
        var flags = AuthorizationContextFlags()
        
        let status = key.withCString { keyCStr in
            return callbacks.GetContextValue(engine, keyCStr, &flags, &value)
        }
        
        if status == errAuthorizationSuccess, let val = value?.pointee {
            if let data = val.data {
                return String(cString: data.assumingMemoryBound(to: CChar.self))
            }
        }
        return nil
    }
}
