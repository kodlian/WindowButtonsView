//
//  WindowButtonsView.swift
//  WindowButtonsView
//
//  Created by Jérémy Marchand on 16/09/2014.
//  Copyright (c) 2014 Jérémy Marchand. All rights reserved.
//

import Cocoa


extension NSWindow {
    var canGoFullscreen:Bool {
        return (collectionBehavior & NSWindowCollectionBehavior.FullScreenPrimary ) != nil //|| (collectionBehavior & NSWindowCollectionBehavior.FullScreenAuxiliary) != nil
    }
    var canClose:Bool {
        return (styleMask & NSClosableWindowMask) == NSClosableWindowMask;
    }
    var canMiniaturize:Bool {
        return (styleMask & NSMiniaturizableWindowMask) == NSMiniaturizableWindowMask;
    }
    
    var inFullScreen:Bool {
         return (styleMask & NSFullScreenWindowMask) == NSFullScreenWindowMask;
        
    }
}



@IBDesignable
public class WindowButtonsView: NSView {
    
    public var delegate:WindowButtonsViewDelegate?
    
    let buttons = [WindowButton(type:.CloseButton),WindowButton(type:.MiniaturizeButton),WindowButton(type:.ZoomAndFullscreenButton(fullscreen:false))]
    
    var zoomAndFullscreenButton:WindowButton { return buttonForType(WindowButtonType.ZoomAndFullscreenButton(fullscreen:false)) }
    
    
    
    var flagMonitor:AnyObject?
    var localFlagMonitor:AnyObject?

    @IBInspectable public var closeImage:NSImage {
        get {
           return buttonForType(.CloseButton).image!
        }
        set {
            buttonForType(.CloseButton).image = newValue
        }
    }
    @IBInspectable public var  miniaturizeImage:NSImage {
        get {
            return buttonForType(.MiniaturizeButton).image!
        }
        set {
            buttonForType(.MiniaturizeButton).image = newValue
        }
    }
    @IBInspectable public var zoomImage:NSImage? = pluginBundle.imageForResource("zoom")!{
        didSet {
            updateZoomAndFullscreenButton()
        }
    }
    @IBInspectable public var fullscreenImage:NSImage? = pluginBundle.imageForResource("fullscreen")! {
        didSet {
            updateZoomAndFullscreenButton()
        }
    }
    @IBInspectable public var fullscreenOffImage:NSImage? = pluginBundle.imageForResource("fullscreenOff")!{
        didSet {
            updateZoomAndFullscreenButton()
        }
    }
    
    
    @IBInspectable public var closeBackgroundImage:NSImage {
        get {
            return buttonForType(.CloseButton).backgroundImage
        }
        set {
            buttonForType(.CloseButton).alternateImage = newValue
        }
    }
    @IBInspectable public var  miniaturizeBackgroundImage:NSImage {
        get {
            return buttonForType(.MiniaturizeButton).alternateImage!
        }
        set {
            buttonForType(.MiniaturizeButton).alternateImage = newValue
        }
    }
    @IBInspectable public var zoomAndFullscreenBackgroundImage:NSImage {
        get {
            return buttonForType(.ZoomAndFullscreenButton(fullscreen:false)).alternateImage!
        }
        set {
            buttonForType(.ZoomAndFullscreenButton(fullscreen:false)).alternateImage = newValue
        }
    }
    
    
    @IBInspectable public var unactiveBackgroundImage:NSImage = pluginBundle.imageForResource("unactiveBackground")! {
        didSet {
            for button in buttons {
                button.unactiveBackgroundImage = unactiveBackgroundImage
            }
        }
    }
    
   



    
    //MARK: - life cycle
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        for (index,button) in enumerate(buttons) {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.tag = index
            button.action = "performButtonAction:"
            button.target = self
            addSubview(button)
            let constraintV = NSLayoutConstraint.constraintsWithVisualFormat("V:[b(12)]", options: nil, metrics: nil, views: ["b":button])
            addConstraints(constraintV)
            addConstraint(NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0))
        }
        
        let views = ["b1":buttons[0],"b2":buttons[1],"b3":buttons[2]];
        
        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("[b1(12)]-8-[b2(12)]-8-[b3(12)]", options: nil, metrics: nil, views: views)
        addConstraints(constraintsH)
        addConstraint(NSLayoutConstraint(item: buttons[1], attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0))

        
        // Alt
        flagMonitor = NSEvent.addGlobalMonitorForEventsMatchingMask(NSEventMask.FlagsChangedMask, handler: { (event:NSEvent!) -> Void in
           self.alternateKeyPressed = (event.modifierFlags & NSEventModifierFlags.AlternateKeyMask) == NSEventModifierFlags.AlternateKeyMask
        })
        localFlagMonitor = NSEvent.addLocalMonitorForEventsMatchingMask(NSEventMask.FlagsChangedMask, handler: { (event:NSEvent!) -> NSEvent! in
            
            self.alternateKeyPressed = (event.modifierFlags & NSEventModifierFlags.AlternateKeyMask) == NSEventModifierFlags.AlternateKeyMask

            
            return event
         })
       
    }
    
    deinit {
        if let monitor: AnyObject = flagMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor: AnyObject = localFlagMonitor {
            NSEvent.removeMonitor(monitor)
        }
         NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public override func viewDidMoveToWindow() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateButton:", name: NSWindowDidBecomeMainNotification, object: window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateButton:", name: NSWindowDidResignMainNotification, object: window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateButton:", name: NSWindowDidDeminiaturizeNotification, object: window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateButton:", name: NSWindowDidMiniaturizeNotification, object: window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateButton:", name: NSWindowWillMiniaturizeNotification, object: window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateButton:", name: NSWindowDidResizeNotification, object: window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "windowDidToggleFullscreen:", name: NSWindowDidEnterFullScreenNotification, object: window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "windowDidToggleFullscreen:", name: NSWindowDidExitFullScreenNotification, object: window)

        
     
         updateButtonsState()
         updateZoomAndFullscreenButton()
    }
    
    //MARK: button
    private func buttonForType(type:WindowButtonType) -> WindowButton {
        return buttons[type.index()]
    }
    func updateButton(notification:NSNotification){
        mouseInside = false
        for button in buttons {
            button.setNeedsDisplay()
        }
    }
    public func rectForButtonType(type:WindowButtonType) -> NSRect {
        return buttonForType(type).frame
    }
    
    private func updateButtonsState(){
        let notFullscreen = window?.inFullScreen == false
        buttonForType(.CloseButton).enabled = window?.canClose == true && notFullscreen
        buttonForType(.MiniaturizeButton).enabled = window?.canMiniaturize == true && notFullscreen

    }
    
    
    //MARK: button action
    func performButtonAction(sender:WindowButton!) {
        if delegate?.windowButtonsView(self, willPerformActionforButton: sender.type) ?? true {
            
            switch sender.type  {
            case .CloseButton:
                window?.performClose(sender)
            case .MiniaturizeButton:
                window?.performMiniaturize(sender)
            case .ZoomAndFullscreenButton(fullscreen:false):
                window?.performZoom(sender)
            case .ZoomAndFullscreenButton(fullscreen:true):
                window?.toggleFullScreen(sender)

            default:
                fatalError("")
                
                
            }
            
            delegate?.windowButtonsView(self, didPerformActionforButton: sender.type)
        }
    }

    //MARK: - Mouse management
    private var trackingArea:NSTrackingArea?
    private var mouseInside:Bool = false { didSet {
        for button in buttons {
            button.displaySymbol = mouseInside
        }
        }
    }
    public override func updateTrackingAreas() {
        if let area = trackingArea {
            removeTrackingArea(area)
        }
        
        trackingArea = NSTrackingArea(rect: bounds, options: NSTrackingAreaOptions.ActiveAlways|NSTrackingAreaOptions.MouseEnteredAndExited, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
        
    }
    public override func mouseEntered(theEvent: NSEvent) {
        mouseInside = true
    }
     public override func mouseExited(theEvent: NSEvent) {
        mouseInside = false
    }
    
    
    //MARK - ZoomAndFullscreenButton
    private var alternateKeyPressed:Bool = false {
        didSet {
            updateZoomAndFullscreenButton()
       
        }
    }
    
    func windowDidToggleFullscreen(notification:NSNotification) {
        updateZoomAndFullscreenButton()

    }
    
    private func updateZoomAndFullscreenButton() {
        
        zoomAndFullscreenButton.type = .ZoomAndFullscreenButton(fullscreen:(window?.canGoFullscreen == true && !alternateKeyPressed) || window?.inFullScreen == true)
        
        if window?.inFullScreen == true {
            zoomAndFullscreenButton.image = fullscreenOffImage
        }
        else {
            switch zoomAndFullscreenButton.type {
            case .ZoomAndFullscreenButton(fullscreen:true):
                zoomAndFullscreenButton.image = fullscreenImage
            case .ZoomAndFullscreenButton(fullscreen:false):
                zoomAndFullscreenButton.image = zoomImage

            default:
                fatalError("")
            }
        }
        
        
    }
   
}


public protocol WindowButtonsViewDelegate {
     func  windowButtonsView(windowButtonsView:WindowButtonsView,  willPerformActionforButton:WindowButtonType) -> Bool
     func  windowButtonsView(windowButtonsView:WindowButtonsView,  didPerformActionforButton:WindowButtonType)
}
