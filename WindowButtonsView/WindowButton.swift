//
//  WindowButton.swift
//  WindowButtonsView
//
//  Created by Jérémy Marchand on 16/09/2014.
//  Copyright (c) 2014 Jérémy Marchand. All rights reserved.
//

import Cocoa


let pluginBundle = NSBundle(forClass: WindowButtonsView.self);

public enum WindowButtonType {
    
    case CloseButton
    case MiniaturizeButton
    case ZoomAndFullscreenButton(fullscreen:Bool)
    
    
    public func defaultBackgroundImage() -> NSImage {
        switch self {
        case CloseButton:
            return pluginBundle.imageForResource("closeBackground")!
        case MiniaturizeButton:
            return pluginBundle.imageForResource("miniaturizeBackground")!
        case ZoomAndFullscreenButton:
            return pluginBundle.imageForResource("fullscreenBackground")!
        }
    }
    public func defaultUnactiveBackgroundImage() -> NSImage {
        return pluginBundle.imageForResource("unactiveBackground")!

    }
    public func defaultImage() -> NSImage {
        switch self {
        case CloseButton:
            return pluginBundle.imageForResource("close")!
        case MiniaturizeButton:
            return pluginBundle.imageForResource("miniaturize")!
        case ZoomAndFullscreenButton:
            return pluginBundle.imageForResource("zoom")!
        }
    }

    
     func index() -> Int {
        switch self {
        case CloseButton:
            return 0
        case MiniaturizeButton:
            return 1
        case ZoomAndFullscreenButton:
            return 2
        }
    }
  
    
}


class WindowButton: NSButton {
    init!(type aType:WindowButtonType) {
        
   
        
        super.init(frame: NSRect(x: 0,y: 0,width: 12,height: 12))
        type = aType

        
        image = type.defaultImage()
        backgroundImage = type.defaultBackgroundImage()
        unactiveBackgroundImage = type.defaultUnactiveBackgroundImage()

        
        
        bordered = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

    }
    
    
   override class func cellClass() -> AnyClass? {
        return WindowButtonCell.self
    }
    var buttonCell:WindowButtonCell {
        return (cell() as? WindowButtonCell)!
    }
    
    var type:WindowButtonType {
        set {
            buttonCell.windowButtonType = newValue
            setNeedsDisplay()
            
        }
        get {
            return buttonCell.windowButtonType
            
        }
        
    }

    
    
    var displaySymbol:Bool {
        set {
            buttonCell.displaySymbol = newValue
            setNeedsDisplay()
            
        }
        get {
            return buttonCell.displaySymbol
            
        }
    }
   
    var backgroundImage:NSImage {
        set {
           buttonCell.backgroundImage = newValue
           setNeedsDisplay()

        }
        get {
            return buttonCell.backgroundImage
            
        }
    }
    
    var unactiveBackgroundImage:NSImage {
        set {
            buttonCell.unactiveBackgroundImage = newValue
            setNeedsDisplay()
            
        }
        get {
            return buttonCell.unactiveBackgroundImage
            
        }
    }
    
    
}





class WindowButtonCell: NSButtonCell {
    var displaySymbol:Bool = false

    var backgroundImage:NSImage = pluginBundle.imageForResource("closeBackground")!
    var unactiveBackgroundImage:NSImage = pluginBundle.imageForResource("unactiveBackground")!
    var windowButtonType:WindowButtonType = .CloseButton

    
    override func drawBezelWithFrame(frame: NSRect, inView controlView: NSView) {
  
    }
    override func prepareForInterfaceBuilder() {
        displaySymbol = true
    }

    override func awakeFromNib() {
        #if TARGET_INTERFACE_BUILDER
            displaySymbol = true

        #endif

    }
    override func drawImage(anImage: NSImage, withFrame frame: NSRect, inView controlView: NSView) {
        
        #if TARGET_INTERFACE_BUILDER
          let currentBackground = enabled ? backgroundImage : unactiveBackgroundImage
            
        #else
          let currentBackground =  (controlView.window?.mainWindow == true || displaySymbol) && enabled ? backgroundImage : unactiveBackgroundImage
        #endif
   

        var rect = frame
        rect.inset(dx:(frame.width-currentBackground.size.width)/2, dy: (frame.height-currentBackground.size.height)/2)
        rect.integerize()
        
        currentBackground.drawInRect(rect)
        
        if highlighted {
            NSGraphicsContext.saveGraphicsState()
            let ctx = NSGraphicsContext.currentContext()?.CGContext
            if let cgImage = currentBackground.CGImageForProposedRect(&rect, context: NSGraphicsContext.currentContext(), hints: nil)?.takeUnretainedValue() {
                //Create the mask
                let scale = controlView.window?.screen?.backingScaleFactor ?? 1
                let info = CGBitmapInfo(rawValue:CGImageAlphaInfo.Only.rawValue)
                let bitmapCtx = CGBitmapContextCreate(nil, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage), 8, 0, nil, info)
                CGContextDrawImage(bitmapCtx, CGRectMake(0, 0, currentBackground.size.width * scale, currentBackground.size.height * scale), cgImage)
                let maskRef: CGImageRef = CGBitmapContextCreateImage(bitmapCtx)
                
                // draw black onverlay
                CGContextClipToMask(ctx, NSRectToCGRect(rect), maskRef);
                CGContextSetFillColorWithColor(ctx, CGColorGetConstantColor(kCGColorBlack))
                CGContextSetAlpha(ctx, 0.2)
                CGContextFillRect(ctx, rect)
                
                
            }
            
            NSGraphicsContext.restoreGraphicsState()
            
            
        }
        if displaySymbol && enabled {
            if let img = self.image {
                super.drawImage(img, withFrame: frame, inView: controlView)

            }
        }
     

    }

}



