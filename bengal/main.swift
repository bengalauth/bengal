//
//  main.swift
//  bengal
//
//  Copyright © 2026 naomisphere
//  Derived from authchanger 2.1.0 (Copyright © 2017 Joel Rennich).
//

import Foundation
import Security.AuthorizationDB

let preferences = Preferences()
let authdb = authorizationdb()

var err = OSStatus.init(0)

// New Hotness - Johan
// as always

// full arguments list as single string
let args = CommandLine.arguments
let argString = CommandLine.arguments.joined(separator: " ").uppercased()

// noarg / help / -help
let help_wanted = args.count == 1 || args.contains { $0.lowercased() == "help" } || args.contains { $0.lowercased() == "-help" }

if help_wanted {
    // check for "bengal help [cmd]"
    if args.count >= 3 && args[1].lowercased() == "help" {
        preferences.show_command_help(args[2])
    }
    // (and for "bengal [cmd] -help")
    else if args.count >= 3 && (args.contains("-help") || args.contains("help")) {
        preferences.show_command_help(args[1])
    }
    else {
        preferences.show_main_help()
    }
    exit(0)
}

// version / -version
if argString.contains("VERSION") {
    print("v" + preferences.version)
    exit(0)
}

extension Array where Element: Equatable {
    @discardableResult
    mutating func appendIfNotContains(_ element: Element) -> (appended: Bool, memberAfterAppend: Element) {
        if !contains(element) {
            append(element)
            return (true, element)
        }
        return (false, element)
    }
}

func getImpactedEntries(arguments: [String]) -> [String]{
    var impactedEntries: [String] = []
    for arg in arguments[1...] {
        
        switch(arg.uppercased()){
            
        // All of these parameters edit the same entry
        case "-BENGAL",
             "-PRELOGIN",
             "-PREAUTH",
             "-POSTAUTH":
            for domain in preferences.Bengal["impactedEntries"] as! [String]{
                impactedEntries.appendIfNotContains(domain)
            }
        case "-RESET",
             "-PRINT":
            for domain in preferences.Bengal["impactedEntries"] as! [String]{
                impactedEntries.appendIfNotContains(domain)
            }
        case "-CUSTOMRULE":
            let argArrayCap = (CommandLine.arguments).map{$0.uppercased()}
            let argIndex = argArrayCap.firstIndex(of: "-CUSTOMRULE")
            impactedEntries.appendIfNotContains((CommandLine.arguments)[argIndex! + 1])
        default:
            break
        }
    }
    return impactedEntries
}

// default mechanism addition function to avoid the code replication in the initial version

// default mechanism addition function to avoid the code replication in the initial version

func defaultMechanismAddition(editingConfiguration: [String: [String: AnyObject]], mechDict: [String: [String]], notify: Bool = false) -> [String: [String: AnyObject]] {
        
    var tmpEditingConfiguration = editingConfiguration
    
    for impactedMech in (mechDict["impactedEntries"]! as [String]) {
        
        var tmpEditingConfigurationMech = editingConfiguration[impactedMech]
        var editingMech = tmpEditingConfigurationMech?["mechanisms"] as! [String]
        
        var increment = 1
        if #available(macOS 10.16, *) {
            increment = 2
        }
        
        // Remove existing Bengal mechanisms and the default login window to ensure fresh placement and replacement
        let mechsToRemove = ["BengalLogin:UI", "BengalLogin:PowerControl,privileged", "BengalLogin:CreateUser,privileged", "loginwindow:login"]
        editingMech.removeAll { mech in mechsToRemove.contains(mech) }
        
        // adding the front mechanisms in the preferred order
        // preferred: UI -> PowerControl -> CreateUser
        let frontMechs = mechDict["frontMechs"]! as [String]
        for (index, addingMech) in frontMechs.enumerated() {
            editingMech.insert(addingMech, at: increment + index)
        }
        
        // adding the notify mechanism if specified
        if notify {
            if let additionIndex = editingMech.firstIndex(of: "builtin:login-begin") {
                for addingMech in (mechDict["notifyMech"]! as [String]).reversed() {
                    if !editingMech.contains(addingMech) {
                        editingMech.insert(addingMech, at: additionIndex)
                    }
                }
            }
        }
        
        // appending the rear mechanisms
        for addingMech in mechDict["endMechs"]! {
            if !editingMech.contains(addingMech) {
                editingMech.append(addingMech)
            }
        }
        
        // rebuilding the edited master authdb
        tmpEditingConfigurationMech?["mechanisms"] = editingMech as AnyObject
        tmpEditingConfiguration[impactedMech] = tmpEditingConfigurationMech
    }
    return tmpEditingConfiguration
}

func authorizationDBPrettyPrint(authDBConfiguration: [String: [String: AnyObject]]){
    for authDBEntryKey in authDBConfiguration.keys {
        print("Entry: " + authDBEntryKey)
        let entryProperty = authDBConfiguration[authDBEntryKey]
        
        for EntryPropertyKey in (authDBConfiguration[authDBEntryKey]?.keys)! {
            
            if EntryPropertyKey == "mechanisms" || EntryPropertyKey == "rule"{
                let entryMechs = entryProperty?[EntryPropertyKey]
                print("   \(EntryPropertyKey):")
                for mechName in entryMechs as! [String]{
                    print("      \(mechName)")
                }
            } else {
                print("   " + EntryPropertyKey + " : \(entryProperty![EntryPropertyKey]!)")
            }
        }
        print()
    }
}

// Getting the current configuration of the machine for the preferences necessary
let currentConfiguration = authdb.getBatch(getArray: getImpactedEntries(arguments: CommandLine.arguments))

// Making a copy of the configuraiton to edit
var editingConfiguration = currentConfiguration as [String: [String: AnyObject]]

    if argString.contains("-RESET") {
        var tmpEditingConfigurationMech = editingConfiguration[((preferences.Reset)["impactedEntries"]! as [String])[0]]
        if #available(macOS 10.16, *) {
            tmpEditingConfigurationMech?["mechanisms"] = (preferences.Reset)[Preferences.kDefaultsMech] as AnyObject
        } else {
            tmpEditingConfigurationMech?["mechanisms"] = (preferences.Reset)[Preferences.kDefaultMechs1014And15] as AnyObject
        }
        
        editingConfiguration[((preferences.Reset)["impactedEntries"]! as [String])[0]] = tmpEditingConfigurationMech
    }

if argString.contains("-BENGAL") {
    editingConfiguration = defaultMechanismAddition(editingConfiguration: editingConfiguration, mechDict: preferences.Bengal, notify: false)
}

// getting all mechanisms from the parameters given in
// this code is dirty..... -Johan
var preLoginMechs:[String] = [], preAuthMechs:[String] = [], postAuthMechs:[String] = [], customRuleMechs:[String] = []
if argString.contains("-PRELOGIN") || argString.contains("-PREAUTH") || argString.contains("-POSTAUTH") || argString.contains("-CUSTOMRULE"){
    let argArrayCap = (CommandLine.arguments).map{$0.uppercased()}
    var i = 1
    while i < argArrayCap.count {
        if argArrayCap[i] == "-PRELOGIN" {
            i += 1
            if i >= argArrayCap.count{break}
            while !(argArrayCap[i]).hasPrefix("-"){
                preLoginMechs.append((CommandLine.arguments)[i])
                i += 1
                if i >= argArrayCap.count{break}
            }
            i -= 1
        }
        if argArrayCap[i] == "-PREAUTH" {
            i += 1
            if i >= argArrayCap.count{break}
            while !(argArrayCap[i]).hasPrefix("-"){
                preAuthMechs.append((CommandLine.arguments)[i])
                i += 1
                if i >= argArrayCap.count{break}
            }
            i -= 1
        }
        if argArrayCap[i] == "-POSTAUTH" {
            i += 1
            if i >= argArrayCap.count{break}
            while !(argArrayCap[i]).hasPrefix("-"){
                postAuthMechs.append((CommandLine.arguments)[i])
                i += 1
                if i >= argArrayCap.count{break}
            }
            i -= 1
        }
        if argArrayCap[i] == "-CUSTOMRULE" {
            i += 1
            if i >= argArrayCap.count{break}
            while !(argArrayCap[i]).hasPrefix("-"){
                customRuleMechs.append((CommandLine.arguments)[i])
                i += 1
                if i >= argArrayCap.count{break}
            }
            i -= 1
        }
        i += 1
    }
}

// reversing the pre and post mech lists for addition
preLoginMechs.reverse()
preAuthMechs.reverse()
postAuthMechs.reverse()


if argString.contains("-PRELOGIN") {
    var tmpEditingConfigurationMech = editingConfiguration["system.login.console"]
    var editingMech = tmpEditingConfigurationMech?["mechanisms"] as! [String]
    for mech in preLoginMechs {
        editingMech.insert(mech, at: 1)
    }
    tmpEditingConfigurationMech?["mechanisms"] = editingMech as AnyObject
    editingConfiguration["system.login.console"] = tmpEditingConfigurationMech
}

if argString.contains("-PREAUTH") {
    var tmpEditingConfigurationMech = editingConfiguration["system.login.console"]
    var editingMech = tmpEditingConfigurationMech?["mechanisms"] as! [String]
    let additionIndex = editingMech.firstIndex(of: "builtin:login-begin")!
    for mech in preAuthMechs {
        editingMech.insert(mech, at: additionIndex)
    }
    tmpEditingConfigurationMech?["mechanisms"] = editingMech as AnyObject
    editingConfiguration["system.login.console"] = tmpEditingConfigurationMech
}

if argString.contains("-POSTAUTH") {
    var tmpEditingConfigurationMech = editingConfiguration["system.login.console"]
    var editingMech = tmpEditingConfigurationMech?["mechanisms"] as! [String]
    let additionIndex = editingMech.count
    for mech in postAuthMechs {
        editingMech.insert(mech, at: additionIndex)
    }
    tmpEditingConfigurationMech?["mechanisms"] = editingMech as AnyObject
    editingConfiguration["system.login.console"] = tmpEditingConfigurationMech
}

if argString.contains("-CUSTOMRULE") {
    
    let customRuleName = customRuleMechs.remove(at: 0)
    var tmpEditingConfigurationMech = editingConfiguration[customRuleName]
    
    if argString.contains("-PRINT"){
        authorizationDBPrettyPrint(authDBConfiguration: [customRuleName: (currentConfiguration[customRuleName] ?? nil)!])
        exit(0)
    } else if !argString.contains("-DEBUG"){
        print("Previous Rule for reference:\n")
        authorizationDBPrettyPrint(authDBConfiguration: currentConfiguration)
    }
    if !(customRuleMechs.count >= 1) {
        print("More parameters necessary, please see -help documentation")
        exit(1)
    }
    let customKeyName = customRuleMechs.remove(at: 0)
    switch customKeyName {
    case "mechanisms":
        tmpEditingConfigurationMech?["mechanisms"] = customRuleMechs as AnyObject
        tmpEditingConfigurationMech?["class"] = "evaluate-mechanisms" as AnyObject
        tmpEditingConfigurationMech?["rule"] = nil
    case "rules":
        tmpEditingConfigurationMech?["rule"] = customRuleMechs as AnyObject
        tmpEditingConfigurationMech?["class"] = "rule" as AnyObject
        tmpEditingConfigurationMech?["mechanisms"] = nil
    default:
        break
    }
    
    editingConfiguration[customRuleName] = tmpEditingConfigurationMech
}


// print version and quit if asked
if argString.contains("-PRINT") {
    authorizationDBPrettyPrint(authDBConfiguration: currentConfiguration)
    exit(0)
}

if argString.contains("-DEBUG") {
    authorizationDBPrettyPrint(authDBConfiguration: editingConfiguration)
    exit(0)
} else {
    // writing everything back
    authdb.setBatch(setArray: editingConfiguration)
}
