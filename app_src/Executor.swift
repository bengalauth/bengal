//
//  Executor.swift
//  bengal
//
//  Created by naomisphere on April 7th, 2026.
//  Copyright © 2026 naomisphere. All rights reserved.
//

import Foundation
import Darwin

class Executor {
    static let shared = Executor()
    
    private var masterFd: Int32 = -1
    private var childPid: pid_t = -1
    
    var onOutput: ((String) -> Void)?
    var onStateChange: ((Bool) -> Void)?
    var onCompletion: ((Int32) -> Void)?
    
    private let queue = DispatchQueue(label: "com.bengal.app.executor", qos: .userInitiated)
    
    func run(command: String, arguments: [String], asRoot: Bool = false) {
        guard masterFd == -1 else { 
            onOutput?("\n[!] A command is already running.\n")
            return 
        }
        
        var master: Int32 = 0
        let pid = forkpty(&master, nil, nil, nil)
        
        if pid < 0 {
            onOutput?("\n[!] Failed to fork PTY.\n")
            return
        }
        
        if pid == 0 {
            // child proc.
            let binaryPath = Bundle.main.resourcePath! + "/bengal"
            
            var args: [String] = []
            var execPath = binaryPath
            
            if asRoot {
                execPath = "/usr/bin/sudo"
                args = ["sudo", binaryPath] + arguments
            } else {
                args = [binaryPath] + arguments
            }
            
            let cArgs = args.map { strdup($0) } + [nil]
            execv(execPath, cArgs.compactMap { $0 })
            exit(1)
        } else {
            // parent proc.
            self.masterFd = master
            self.childPid = pid
            self.onStateChange?(true)
            
            queue.async {
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
                defer { buffer.deallocate() }
                
                while true {
                    let count = read(self.masterFd, buffer, 1024)
                    if count <= 0 { break }
                    
                    if let output = String(bytes: UnsafeBufferPointer(start: buffer, count: count), encoding: .utf8) {
                        DispatchQueue.main.async {
                            self.onOutput?(output)
                        }
                    }
                }
                
                self.cleanup()
            }
        }
    }
    
    func writeInput(_ input: String) {
        guard masterFd != -1 else { return }
        input.withCString { ptr in
            _ = write(masterFd, ptr, strlen(ptr))
        }
    }
    
    private func cleanup() {
        var status: Int32 = 0
        if childPid != -1 {
            waitpid(childPid, &status, 0)
        }
        
        let exitCode = WIFEXITED(status) ? WEXITSTATUS(status) : -1
        
        if masterFd != -1 {
            close(masterFd)
            masterFd = -1
        }
        childPid = -1
        DispatchQueue.main.async {
            self.onStateChange?(false)
            self.onCompletion?(exitCode)
        }
    }
}

// helpers for waitpid status
func WIFEXITED(_ status: Int32) -> Bool {
    return (status & 0x7f) == 0
}

func WEXITSTATUS(_ status: Int32) -> Int32 {
    return (status >> 8) & 0xff
}
