//
//  WindowButton.swift
//  WindowButtonsView
//
//  Created by Jérémy Marchand on 16/09/2014.
//  Copyright (c) 2014 Jérémy Marchand. All rights reserved.
//

import Cocoa


let pluginBundle = Bundle(for: WindowButtonsView.self)

// MARK: - WindowButtonType
public enum WindowButtonType {

    case closeButton
    case miniaturizeButton
    case zoomAndFullscreenButton(fullscreen:Bool)

    public func defaultBackgroundImage() -> NSImage {
        switch self {
        case .closeButton:
            return pluginBundle.image(forResource: "closeBackground")!
        case .miniaturizeButton:
            return pluginBundle.image(forResource: "miniaturizeBackground")!
        case .zoomAndFullscreenButton:
            return pluginBundle.image(forResource: "fullscreenBackground")!
        }
    }
    public func defaultUnactiveBackgroundImage() -> NSImage {
        return pluginBundle.image(forResource: "unactiveBackground")!

    }
    public func defaultImage() -> NSImage {
        switch self {
        case .closeButton:
            return pluginBundle.image(forResource: "close")!
        case .miniaturizeButton:
            return pluginBundle.image(forResource: "miniaturize")!
        case .zoomAndFullscreenButton:
            return pluginBundle.image(forResource: "zoom")!
        }
    }

    func index() -> Int {
        switch self {
        case .closeButton:
            return 0
        case .miniaturizeButton:
            return 1
        case .zoomAndFullscreenButton:
            return 2
        }
    }

    func action(_ sender: WindowButton, on window: NSWindow, perform: Bool = true) {
        switch self{
        case .closeButton:
            if perform {
                window.performClose(sender)
            }
            else {
                window.close()
            }
        case .miniaturizeButton:
            if perform {
                window.performMiniaturize(sender)
            }
            else {
                window.miniaturize(sender)
            }
        case .zoomAndFullscreenButton(fullscreen:false):
             if perform {
                window.performZoom(sender)
             }
             else {
                window.zoom(sender)
            }
        case .zoomAndFullscreenButton(fullscreen:true):
            window.toggleFullScreen(sender)
        }
    }

}

// MARK: - WindowButton
class WindowButton: NSButton {
    init(type aType: WindowButtonType) {
        super.init(frame: NSRect(x: 0, y: 0, width: 12, height: 12))
        type = aType

        image = type.defaultImage()
        backgroundImage = type.defaultBackgroundImage()
        unactiveBackgroundImage = type.defaultUnactiveBackgroundImage()

        isBordered = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override class func cellClass() -> AnyClass? {
        return WindowButtonCell.self
    }
    
    var buttonCell: WindowButtonCell {
        return (cell as? WindowButtonCell)!
    }

    var type: WindowButtonType {
        set {
            buttonCell.windowButtonType = newValue
            setNeedsDisplay()
        }
        get {
            return buttonCell.windowButtonType
        }
    }

    var displaySymbol: Bool {
        set {
            buttonCell.displaySymbol = newValue
            setNeedsDisplay()
        }
        get {
            return buttonCell.displaySymbol
        }
    }

    var backgroundImage: NSImage {
        set {
           buttonCell.backgroundImage = newValue
           setNeedsDisplay()
        }
        get {
            return buttonCell.backgroundImage
        }
    }

    var unactiveBackgroundImage: NSImage {
        set {
            buttonCell.unactiveBackgroundImage = newValue
            setNeedsDisplay()
        }
        get {
            return buttonCell.unactiveBackgroundImage
        }
    }
}

extension NSGraphicsContext {
    
    class func `do`(_ block: (_ context: NSGraphicsContext) -> Void) {
        NSGraphicsContext.saveGraphicsState()
        if let currentContext = NSGraphicsContext.current() {
            block(currentContext)
        }
        NSGraphicsContext.restoreGraphicsState()
    }

}

// MARK: - WindowButtonCell
class WindowButtonCell: NSButtonCell {
    var displaySymbol: Bool = false

    var backgroundImage: NSImage = pluginBundle.image(forResource: "closeBackground")!
    var unactiveBackgroundImage: NSImage = pluginBundle.image(forResource: "unactiveBackground")!
    var windowButtonType: WindowButtonType = .closeButton

    override func drawBezel(withFrame frame: NSRect, in controlView: NSView) {

    }
    
    override func prepareForInterfaceBuilder() {
        displaySymbol = true
    }

    override func awakeFromNib() {
        #if TARGET_INTERFACE_BUILDER
            displaySymbol = true
        #endif
    }
    
    override func drawImage(_ anImage: NSImage, withFrame frame: NSRect, in controlView: NSView) {

        #if TARGET_INTERFACE_BUILDER
          let currentBackground = enabled ? backgroundImage : unactiveBackgroundImage
        #else
          let currentBackground =  (controlView.window?.isMainWindow == true || displaySymbol) && isEnabled ? backgroundImage : unactiveBackgroundImage
        #endif


        var rect = frame
        rect = rect.insetBy(dx:(frame.width-currentBackground.size.width)/2, dy: (frame.height-currentBackground.size.height)/2)
        rect = rect.integral
        currentBackground.draw(in: rect)

        if isHighlighted {
            NSGraphicsContext.do { currentContext in
                let ctx = currentContext.cgContext
                if let cgImage = currentBackground.cgImage(forProposedRect: &rect, context: currentContext, hints: nil) {
                    //Create the mask
                    let width = cgImage.width
                    let height = cgImage.height
                    let colorSpace = CGColorSpaceCreateDeviceGray()
                    let bitmapInfo = CGImageAlphaInfo.alphaOnly.rawValue
                    
                    if let bitmapCtx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo) {
                        
                        let scale = controlView.window?.screen?.backingScaleFactor ?? 1
                        bitmapCtx.draw(cgImage, in: CGRect(x: 0, y: 0, width: currentBackground.size.width * scale, height: currentBackground.size.height * scale))
                        if let maskRef = bitmapCtx.makeImage() {
                            
                            // draw black onverlay
                            ctx.clip(to: NSRectToCGRect(rect), mask: maskRef)
                        }
                    }
                    ctx.setFillColor(NSColor.black.cgColor)
                    ctx.setAlpha(0.2)
                    ctx.fill(rect)
                }
            }
        }
        
        if displaySymbol && isEnabled {
            if let img = self.image {
                super.drawImage(img, withFrame: frame, in: controlView)
            }
        }
    }

}
