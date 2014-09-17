//
//  WindowButtonsView.swift
//  WindowButtonsView
//
//  Created by Jérémy Marchand on 16/09/2014.
//  Copyright (c) 2014 Jérémy Marchand. All rights reserved.
//

import Cocoa


let pluginBundle = NSBundle(forClass: WindowButtonsView.self);

@IBDesignable
public class WindowButtonsView: NSView {
    @IBInspectable public var firstButtonImage:NSImage = pluginBundle.imageForResource("close") {
       didSet {      updateImageForButtonAtIndex(0) }
    }
    @IBInspectable public var firstButtonBackgroundImage:NSImage = pluginBundle.imageForResource("closeBackground"){
        didSet {      updateImageForButtonAtIndex(0) }
    }
    
    @IBInspectable public var secondButtonImage:NSImage = pluginBundle.imageForResource("minimize"){
        didSet {      updateImageForButtonAtIndex(1) }
    }

    @IBInspectable public var secondButtonBackgroundImage:NSImage = pluginBundle.imageForResource("minimizeBackground"){
        didSet {      updateImageForButtonAtIndex(1) }
    }
    
    @IBInspectable public var thirdButtonImage:NSImage = pluginBundle.imageForResource("fullscreen") {
        didSet {      updateImageForButtonAtIndex(2) }
    }

    @IBInspectable public var thirdButtonBackgroundImage:NSImage = pluginBundle.imageForResource("fullscreenBackground") {
        didSet {      updateImageForButtonAtIndex(2) }
    }

    @IBInspectable public var unactiveBackgroundImage:NSImage = pluginBundle.imageForResource("unactiveBackground") {
        didSet {
            for button in buttons {
                button.unactiveBackgroundImage = unactiveBackgroundImage
            }
        
        }
    }
    
    
    
    private let buttons = [WindowButton(frame: NSRect(x: 0, y: 0, width: 12, height: 12)),WindowButton(frame: NSRect(x: 0, y: 0, width: 12, height: 12)),WindowButton(frame: NSRect(x: 0, y: 0, width: 12, height: 12))]
    
    private var buttonsImages:[NSImage]  {
        get {
            return [firstButtonImage,secondButtonImage,thirdButtonImage];
        }
        
    }
    private var buttonsBackgroundImages:[NSImage]  {
        get {
            return [firstButtonBackgroundImage,secondButtonBackgroundImage,thirdButtonBackgroundImage];
        }
        
    }
    private var trackingArea:NSTrackingArea?
    private var mouseInside:Bool = false { didSet {
        for button in buttons {
                button.displaySymbol = mouseInside
        }
        }
    }

    
    
    //MARK: -
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        for (index,button) in enumerate(buttons) {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.tag = index
            button.action = "performButtonAction:"
            button.target = self
            addSubview(button)
            let constraintV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[b(12)]", options: nil, metrics: nil, views: ["b":button])
            addConstraints(constraintV)
            updateImageForButtonAtIndex(index)
            button.unactiveBackgroundImage = unactiveBackgroundImage

        }
        
        let views = ["b1":buttons[0],"b2":buttons[1],"b3":buttons[2]];
        
        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("|-0-[b1(12)]-8-[b2(12)]-8-[b3(12)]", options: nil, metrics: nil, views: views)
        addConstraints(constraintsH)
        
        
        
    }
    
    
    //MARK: button state refresh
    public override func viewDidMoveToWindow() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateButton:", name: NSWindowDidBecomeMainNotification, object: window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateButton:", name: NSWindowDidResignMainNotification, object: window)


    }
    
    func updateButton(notification:NSNotification){
        for button in buttons {
            button.setNeedsDisplay()
        }
    }

    private func updateImageForButtonAtIndex(index:Int) {
        let button = buttons[index]
        button.backgroundImage = buttonsBackgroundImages[index]
        button.image = buttonsImages[index]
    }
    
    
    
    //MARK: button action
    
    func performButtonAction(sender:WindowButton!) {
        switch sender.tag  {
          case 0:
           window?.performClose(sender)
        case 1:
            window?.performMiniaturize(sender)
        case 2:
            window?.performZoom(sender)
         default:
            fatalError("")
    
         }
    }

    
    
    //MARK: - Mouse management
    public override func updateTrackingAreas() {
        if let area = trackingArea {
            removeTrackingArea(area)
        }
        
        trackingArea = NSTrackingArea(rect: bounds, options: NSTrackingAreaOptions.ActiveAlways|NSTrackingAreaOptions.MouseEnteredAndExited, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
        
    }
    
    public override func mouseEntered(theEvent: NSEvent!) {
        mouseInside = true
    }
     public override func mouseExited(theEvent: NSEvent!) {

        mouseInside = false
    }
    
}
