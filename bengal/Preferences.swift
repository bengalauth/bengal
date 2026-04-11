//
//  main.swift
//  bengal
//
//  Copyright © 2026 naomisphere
//  Derived from authchanger 2.1.0 (Copyright © 2017 Joel Rennich).
//

import Foundation

class Preferences {
    
    // New Hotness -Johan
    // very awesome thanks
    
    let version = "1.0.0"
    static let kDefaultsMech = "defaultMechs"
    static let kDefaultMechs1014And15 = "defaultMechs10-14And10-15"
    static let kDefaultMechs1013 = "defaultMechs10-13"
    let Bengal = [
        "impactedEntries": ["system.login.console"],
        "frontMechs": [
            "BengalLogin:UI",
            "BengalLogin:PowerControl,privileged",
            "BengalLogin:CreateUser,privileged"
        ],
        "endMechs": [],
        "notifyMech": []
    ]
    
    let Reset = [
        "impactedEntries": ["system.login.console"],
        kDefaultsMech : ["builtin:policy-banner", "builtin:prelogin", "loginwindow:login", "builtin:login-begin", "builtin:reset-password,privileged", "loginwindow:FDESupport,privileged", "builtin:forward-login,privileged", "builtin:auto-login,privileged", "builtin:authenticate,privileged", "PKINITMechanism:auth,privileged", "builtin:login-success", "loginwindow:success", "HomeDirMechanism:login,privileged", "HomeDirMechanism:status", "MCXMechanism:login", "CryptoTokenKit:login", "loginwindow:done"],
        kDefaultMechs1014And15 : ["builtin:policy-banner", "loginwindow:login", "builtin:login-begin", "builtin:reset-password,privileged", "loginwindow:FDESupport,privileged", "builtin:forward-login,privileged", "builtin:auto-login,privileged", "builtin:authenticate,privileged", "PKINITMechanism:auth,privileged", "builtin:login-success", "loginwindow:success", "HomeDirMechanism:login,privileged", "HomeDirMechanism:status", "MCXMechanism:login", "CryptoTokenKit:login", "loginwindow:done"],
        kDefaultMechs1013 : ["builtin:policy-banner", "loginwindow:login", "builtin:login-begin", "builtin:reset-password,privileged", "builtin:forward-login,privileged", "builtin:auto-login,privileged", "builtin:authenticate,privileged", "PKINITMechanism:auth,privileged", "builtin:login-success", "loginwindow:success", "loginwindow:FDESupport,privileged", "HomeDirMechanism:login,privileged", "HomeDirMechanism:status", "MCXMechanism:login", "CryptoTokenKit:login", "loginwindow:done"]
    ]
    
    func show_main_help() {
        let help = """
        bengal v\(self.version)
        based on authchanger v2.1.0

        bengal is a utility to help you manage the authorization database used by macOS to determine how the login process progresses.
        Some commands must be run as root.
        
        Usage:
            bengal <command> [options]
            bengal help <command>
            bengal <command> -help
        
        Commands:
            version               print version
            help                  show this help message
            -reset                reset login screen to default
            -bengal               apply bengal login UI
            -print                print current authorization mechanisms
            -debug                dry run of changes showing what would've happened
            -customrule           manage custom authorization rules
            -prelogin             set pre-login mechanisms
            -preauth              set pre-authentication mechanisms
            -postauth             set post-authentication mechanisms
        
        """
        print(help)
    }
    
    func show_command_help(_ command: String) {
        let cmd = command.lowercased().replacingOccurrences(of: "-", with: "")
        
        switch cmd {
        case "reset":
            print("""
            bengal -reset
            
            Usage: bengal -reset [-debug]
            
            Resets the login screen to factory settings.
            
            Options:
                -debug    Dry run without making changes
            
            Examples:
                bengal -reset
                bengal -reset -debug
            """)
            
        case "bengal":
            print("""
            bengal -bengal
            
            Usage: bengal -bengal [-debug] [-preLogin <mechs>] [-preAuth <mechs>] [-postAuth <mechs>]
            
            Apply Bengal login UI.
            
            Options:
                -debug              Dry run without making changes
                -preLogin <mechs>   Mechanisms before UI is shown
                -preAuth <mechs>    Mechanisms between UI and authentication
                -postAuth <mechs>   Mechanisms after authentication
            
            Examples:
                bengal -bengal
                bengal -bengal -preLogin CustomMechanism:Something
            """)
            
        case "print":
            print("""
            bengal -print
            
            Usage: bengal -print
            
            Prints the current authorization mechanisms for system.login.console
            
            Example:
                bengal -print
            """)
            
        case "debug":
            print("""
            bengal -debug
            
            Usage: bengal -debug <command>
            
            Performs a dry run of the specified command without making changes.
            
            Examples:
                bengal -debug -reset
                bengal -debug -bengal -preLogin CustomMechanism:Something
            """)
            
        case "customrule":
            print("""
            bengal customrule
            
            Usage:
                bengal -customrule <rule> print
                bengal -customrule <rule> mechanisms <mechs...> [-debug]
                bengal -customrule <rule> rules <rule-name> [-debug]
            
            Manages custom authorization rules.
            """)
            
        case "prelogin":
            print("""
            bengal -prelogin
            
            Usage: bengal -prelogin <mechanisms...> [-debug]
            
            Sets mechanisms to be used before the UI is shown.
            
            Examples:
                bengal -prelogin CustomMechanism:Something
                bengal -prelogin "CustomAuth:Check" -debug
            """)
            
        case "preauth":
            print("""
            bengal -preauth
            
            Usage: bengal -preauth <mechanisms...> [-debug]
            
            Sets mechanisms to be used between login UI and authentication.
            
            Examples:
                bengal -preauth CustomAuth:Check
                bengal -preauth "CustomAuth:Check" -debug
            """)
            
        case "postauth":
            print("""
            bengal -postauth
            
            Usage: bengal -postauth <mechanisms...> [-debug]
            
            Sets mechanisms to be used after authentication.
            
            Examples:
                bengal -postauth PostLogin:Setup
                bengal -postauth "PostLogin:Setup" -debug
            """)
            
        default:
            print("Unknown command: \(command)\n")
            print("Run 'bengal help' for help")
        }
    }
}