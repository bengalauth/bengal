//
//  AuthorizationPlugin.swift
//  bengal
//
//  Created by naomisphere on April 7th, 2026.
//  Copyright © 2026 naomisphere. All rights reserved.
//

// this is the main authorization plugin that allows the login screen
// to interact with macOS security mechanisms. without this,
// you're never logging in.

import Foundation
import Security
import Security.AuthorizationPlugin

@_cdecl("AuthorizationPluginCreate")
public func AuthorizationPluginCreate(_ callbacks: UnsafePointer<AuthorizationCallbacks>,
                                      _ plugin: UnsafeMutablePointer<Optional<UnsafeMutableRawPointer>>,
                                      _ pluginInterface: UnsafeMutablePointer<UnsafePointer<AuthorizationPluginInterface>?>) -> OSStatus {
    
    // need to store callbacks so mechs can use them
    BengalPlugin.shared.callbacks = callbacks.pointee
    
    // return interface mapping
    pluginInterface.pointee = UnsafePointer(BengalPlugin.shared.pluginInterface)
    
    // plugin pointer (can be self or anything to identify the plugin instance)
    plugin.pointee = Unmanaged.passUnretained(BengalPlugin.shared).toOpaque()
    
    return errAuthorizationSuccess
}

class BengalPlugin {
    static var shared = BengalPlugin()
    
    var callbacks: AuthorizationCallbacks?
    
    var pluginInterface: UnsafeMutablePointer<AuthorizationPluginInterface>
    
    init() {
        pluginInterface = UnsafeMutablePointer<AuthorizationPluginInterface>.allocate(capacity: 1)
        pluginInterface.pointee.version = UInt32(kAuthorizationPluginInterfaceVersion)
        
        pluginInterface.pointee.MechanismCreate = { (plugin: AuthorizationPluginRef, engine: AuthorizationEngineRef, mechanismId: AuthorizationMechanismId, outMechanism: UnsafeMutablePointer<AuthorizationMechanismRef?>) -> OSStatus in
            return Mechanism.mechanismCreate(plugin: plugin, engine: engine, mechanismId: mechanismId, outMechanism: outMechanism)
        }
        
        pluginInterface.pointee.MechanismInvoke = { (mechanism: AuthorizationMechanismRef) -> OSStatus in
            return Mechanism.mechanismInvoke(mechanism: mechanism)
        }
        
        pluginInterface.pointee.MechanismDeactivate = { (mechanism: AuthorizationMechanismRef) -> OSStatus in
            return Mechanism.mechanismDeactivate(mechanism: mechanism)
        }
        
        pluginInterface.pointee.MechanismDestroy = { (mechanism: AuthorizationMechanismRef) -> OSStatus in
            return Mechanism.mechanismDestroy(mechanism: mechanism)
        }
        
        pluginInterface.pointee.PluginDestroy = { (plugin: AuthorizationPluginRef) -> OSStatus in
            return errAuthorizationSuccess
        }
    }
}
