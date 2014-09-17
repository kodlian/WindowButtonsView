//
//  WindowButton.swift
//  WindowButtonsView
//
//  Created by Jérémy Marchand on 16/09/2014.
//  Copyright (c) 2014 Jérémy Marchand. All rights reserved.
//

import Cocoa


class WindowButton: NSButton {
    
    override init!(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        bordered = false
    }

    required init!(coder: NSCoder!) {
        super.init(coder: coder)

    }
    
    
   override class func cellClass() -> AnyClass! {
        return WindowButtonCell.self
    }
    var buttonCell:WindowButtonCell {
        return (cell() as? WindowButtonCell)!
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
    var backgroundImage:NSImage = pluginBundle.imageForResource("unactiveBackground")
    var unactiveBackgroundImage:NSImage = pluginBundle.imageForResource("unactiveBackground")

    
    override func drawBezelWithFrame(frame: NSRect, inView controlView: NSView!) {
  
    }
    
    override func drawImage(image: NSImage!, withFrame frame: NSRect, inView controlView: NSView!) {
        let currentBackground = ((controlView.window?.mainWindow == true && enabled) || displaySymbol) ? backgroundImage : unactiveBackgroundImage
        
        var rect = frame
        rect.inset(dx:(frame.width-currentBackground.size.width)/2, dy: (frame.height-currentBackground.size.height)/2)
        rect.integerize()
        
        currentBackground.drawInRect(rect)
        
        if highlighted {
            NSGraphicsContext.saveGraphicsState()
            let ctx = NSGraphicsContext.currentContext().CGContext
            let cgImage = currentBackground.CGImageForProposedRect(&rect, context: NSGraphicsContext.currentContext(), hints: nil).takeUnretainedValue()
            
            
            //Create the mask
            let scale = controlView.window?.screen.backingScaleFactor ?? 1
            let info = CGBitmapInfo(rawValue:CGImageAlphaInfo.Only.rawValue)
            let bitmapCtx = CGBitmapContextCreate(nil, CGImageGetWidth(cgImage), CGImageGetHeight(cgImage), 8, 0, nil, info)
            CGContextDrawImage(bitmapCtx, CGRectMake(0, 0, currentBackground.size.width * scale, currentBackground.size.height * scale), cgImage)
            let maskRef: CGImageRef = CGBitmapContextCreateImage(bitmapCtx)
            
            // draw black onverlay
            CGContextClipToMask(ctx, NSRectToCGRect(rect), maskRef);
            CGContextSetFillColorWithColor(ctx, CGColorGetConstantColor(kCGColorBlack))
            CGContextSetAlpha(ctx, 0.2)
            CGContextFillRect(ctx, rect)
            
            NSGraphicsContext.restoreGraphicsState()
            
            
        }


      
        if displaySymbol && enabled {
            super.drawImage(image, withFrame: frame, inView: controlView)
        }
    }
    
}
