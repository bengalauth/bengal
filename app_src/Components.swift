//
//  Components.swift
//  bengal
//
//  Created by naomisphere on April 7th, 2026.
//  Copyright © 2026 naomisphere. All rights reserved.
//

import Cocoa

// TAG:colors
enum BengalStyle {
    static let background = NSColor(calibratedWhite: 0.12, alpha: 1.0)
    static let surface    = NSColor(calibratedWhite: 0.18, alpha: 1.0)
    static let terminal   = NSColor(calibratedWhite: 0.08, alpha: 1.0)
    static let accent     = NSColor(calibratedRed: 0.32, green: 0.52, blue: 0.96, alpha: 1.0)
    static let text       = NSColor.white
    static let textMuted  = NSColor.white.withAlphaComponent(0.5)
}

// TAG:fontloader
enum BengalFont {
    static func registerAll() {
        let names = ["Comfortaa-Bold.ttf", "Comfortaa-Light.ttf", "Comfortaa-Regular.ttf"]
        let bundleURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Resources")
        for name in names {
            let url = bundleURL.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    static func light(size: CGFloat) -> NSFont {
        NSFont(name: "Comfortaa-Light", size: size) ?? NSFont.systemFont(ofSize: size, weight: .light)
    }
    static func regular(size: CGFloat) -> NSFont {
        NSFont(name: "Comfortaa-Regular", size: size) ?? NSFont.systemFont(ofSize: size, weight: .regular)
    }
    static func bold(size: CGFloat) -> NSFont {
        NSFont(name: "Comfortaa-Bold", size: size) ?? NSFont.systemFont(ofSize: size, weight: .bold)
    }
}

class RoundedView: NSView {
    var backgroundColor: NSColor = BengalStyle.surface { didSet { needsDisplay = true } }
    var cornerRadius: CGFloat = 12 { didSet { needsDisplay = true } }
    var isDraggable: Bool = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
        backgroundColor.setFill()
        path.fill()
    }
    
    override func mouseDown(with event: NSEvent) {
        if isDraggable {
            window?.performDrag(with: event)
        } else {
            super.mouseDown(with: event)
        }
    }
    
    override var mouseDownCanMoveWindow: Bool {
        return isDraggable
    }
}

class ModernSlider: NSView {
    var value: Double = 0.5 { didSet { needsDisplay = true } }
    var onChange: ((Double) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        let trackH: CGFloat = 4
        let trackY = (bounds.height - trackH) / 2
        let trackR = NSBezierPath(roundedRect: NSRect(x: 0, y: trackY, width: bounds.width, height: trackH), xRadius: 2, yRadius: 2)
        NSColor.white.withAlphaComponent(0.1).setFill()
        trackR.fill()
        
        let activeW = CGFloat(value) * bounds.width
        let activeR = NSBezierPath(roundedRect: NSRect(x: 0, y: trackY, width: activeW, height: trackH), xRadius: 2, yRadius: 2)
        BengalStyle.accent.setFill()
        activeR.fill()
        
        let knobSize: CGFloat = 14         // knob knob (bad joke)
        let knobX = activeW - (knobSize / 2)
        let knobY = (bounds.height - knobSize) / 2
        let knobR = NSBezierPath(ovalIn: NSRect(x: knobX, y: knobY, width: knobSize, height: knobSize))
        NSColor.white.setFill()
        knobR.fill()

        let glowR = NSBezierPath(ovalIn: NSRect(x: knobX - 2, y: knobY - 2, width: knobSize + 4, height: knobSize + 4))
        BengalStyle.accent.withAlphaComponent(0.3).setStroke()
        glowR.lineWidth = 1
        glowR.stroke()
    }
    
    private func updateValue(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        let val = max(0, min(1, loc.x / bounds.width))
        value = Double(val)
        onChange?(value)
    }
    
    override func mouseDown(with event: NSEvent) { updateValue(with: event) }
    override func mouseDragged(with event: NSEvent) { updateValue(with: event) }
    
    override var mouseDownCanMoveWindow: Bool { return false }
}

class ModernButton: NSView {
    var title: String = "" { didSet { needsDisplay = true } }
    var action: (() -> Void)?
    var isEnabled: Bool = true { didSet { alphaValue = isEnabled ? 1.0 : 0.4; needsDisplay = true } }
    var isToggled: Bool = false { didSet { needsDisplay = true } }

    private var isPressed = false
    private var isHovered = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        let ta = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(ta)
    }

    override func draw(_ dirtyRect: NSRect) {
        let r = bounds.insetBy(dx: 0.5, dy: 0.5)
        let path = NSBezierPath(roundedRect: r, xRadius: 8, yRadius: 8)

        var color: NSColor
        if isPressed {
            color = BengalStyle.accent.withAlphaComponent(0.8)
        } else if isToggled {
            color = NSColor(calibratedRed: 0.3, green: 0.8, blue: 0.4, alpha: 0.25)
        } else if isHovered {
            color = BengalStyle.accent.withAlphaComponent(0.15)
        } else {
            color = BengalStyle.accent.withAlphaComponent(0.1)
        }
        color.setFill()
        path.fill()

        let strokeColor: NSColor
        if isToggled {
            strokeColor = NSColor(calibratedRed: 0.3, green: 0.8, blue: 0.4, alpha: 0.6)
        } else if isHovered {
            strokeColor = BengalStyle.accent.withAlphaComponent(0.5)
        } else {
            strokeColor = BengalStyle.accent.withAlphaComponent(0.2)
        }
        strokeColor.setStroke()
        path.lineWidth = 1
        path.stroke()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: BengalFont.bold(size: 13),
            .foregroundColor: isPressed ? NSColor.white : (isHovered || isToggled ? NSColor.white : BengalStyle.textMuted)
        ]
        let str = title as NSString
        let size = str.size(withAttributes: attrs)
        str.draw(at: NSPoint(x: (bounds.width - size.width)/2, y: (bounds.height - size.height)/2), withAttributes: attrs)
    }

    override func mouseDown(with event: NSEvent) { if isEnabled { isPressed = true; needsDisplay = true } }
    override func mouseUp(with event: NSEvent) {
        if isEnabled && isPressed {
            isPressed = false; needsDisplay = true
            let loc = convert(event.locationInWindow, from: nil)
            if bounds.contains(loc) { action?() }
        }
    }
    override func mouseEntered(with event: NSEvent) { isHovered = true; needsDisplay = true }
    override func mouseExited(with event: NSEvent) { isHovered = false; needsDisplay = true }
    
    override var mouseDownCanMoveWindow: Bool { return false }
}

// tag:buggy
class ModernCheckbox: NSView {
    var title: String = "" { didSet { label.stringValue = title } }
    var isOn: Bool = false { didSet { checkView.backgroundColor = isOn ? BengalStyle.accent : NSColor.clear; needsDisplay = true } }
    var action: ((Bool) -> Void)?
    
    private let checkView = RoundedView()
    private let label = NSTextField(labelWithString: "")
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        
        checkView.cornerRadius = 4
        checkView.backgroundColor = .clear
        checkView.layer?.borderWidth = 1
        checkView.layer?.borderColor = BengalStyle.textMuted.cgColor
        checkView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(checkView)
        
        label.font = BengalFont.regular(size: 13)
        label.textColor = BengalStyle.text
        label.drawsBackground = false
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = false
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        NSLayoutConstraint.activate([
            checkView.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkView.leadingAnchor.constraint(equalTo: leadingAnchor),
            checkView.widthAnchor.constraint(equalToConstant: 18),
            checkView.heightAnchor.constraint(equalToConstant: 18),
            
            label.centerYAnchor.constraint(equalTo: checkView.centerYAnchor, constant: 0),
            label.leadingAnchor.constraint(equalTo: checkView.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    override func mouseDown(with event: NSEvent) {
        isOn.toggle()
        action?(isOn)
    }
    
    override var mouseDownCanMoveWindow: Bool { return false }
}

class ModernTextField: NSTextField {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        isBezeled = false
        drawsBackground = false
        focusRingType = .none
        font = BengalFont.regular(size: 13)
        textColor = BengalStyle.text
        
        let bgView = RoundedView(frame: bounds)
        bgView.backgroundColor = NSColor.black.withAlphaComponent(0.25)
        bgView.cornerRadius = 6
        bgView.autoresizingMask = [.width, .height]
        addSubview(bgView, positioned: .below, relativeTo: nil)
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "v": if NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self) { return true }
            case "c": if NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self) { return true }
            case "x": if NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self) { return true }
            case "a": if NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: self) { return true }
            default: break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
    
    override var mouseDownCanMoveWindow: Bool { return false }
}

class ParameterRow: NSView {
    let popup = NSPopUpButton(frame: NSRect.zero, pullsDown: false)
    let textField = ModernTextField(frame: NSRect.zero)
    let removeButton = ModernButton(frame: NSRect.zero)
    
    var onRemove: (() -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: NSRect(x: 0, y: 0, width: 320, height: 40))
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        
        popup.addItems(withTitles: ["-preLogin", "-preAuth", "-postAuth", "-customrule"])
        popup.frame = NSRect(x: 0, y: 8, width: 120, height: 24)
        addSubview(popup)
        
        textField.frame = NSRect(x: 125, y: 7, width: 150, height: 26)
        textField.placeholderString = "Mechanism/Rule..."
        addSubview(textField)
        
        removeButton.frame = NSRect(x: 285, y: 7, width: 26, height: 26)
        removeButton.title = "–"
        removeButton.action = { [weak self] in self?.onRemove?() }
        addSubview(removeButton)
        heightAnchor.constraint(equalToConstant: 40).isActive = true
        translatesAutoresizingMaskIntoConstraints = false
    }
}
