//
//  WindowButtonsView.swift
//  WindowButtonsView
//
//  Created by Jérémy Marchand on 16/09/2014.
//  Copyright (c) 2014 Jérémy Marchand. All rights reserved.
//

import Cocoa

extension NSWindow {
    var canGoFullscreen: Bool {
        return collectionBehavior.contains(.fullScreenPrimary) //|| (collectionBehavior & NSWindowCollectionBehavior.FullScreenAuxiliary) != nil
    }
    var canClose: Bool {
        return styleMask.contains(NSClosableWindowMask)
    }
    var canMiniaturize: Bool {
        return styleMask.contains(NSMiniaturizableWindowMask)
    }
    var inFullScreen: Bool {
         return styleMask.contains(NSFullScreenWindowMask)
    }
}

@IBDesignable
open class WindowButtonsView: NSView {

    open var delegate: WindowButtonsViewDelegate?

    let buttons = [WindowButton(type:.closeButton), WindowButton(type:.miniaturizeButton), WindowButton(type:.zoomAndFullscreenButton(fullscreen:false))]

    var zoomAndFullscreenButton: WindowButton { return button(for: .zoomAndFullscreenButton(fullscreen:false)) }

    var flagMonitor: Any?
    var localFlagMonitor: Any?
    
    private var buttonConstrains: [NSLayoutConstraint] = []

    @IBInspectable open var closeImage: NSImage {
        get {
           return button(for: .closeButton).image!
        }
        set {
            button(for: .closeButton).image = newValue
        }
    }
    @IBInspectable open var miniaturizeImage: NSImage {
        get {
            return button(for: .miniaturizeButton).image!
        }
        set {
            button(for: .miniaturizeButton).image = newValue
        }
    }
    @IBInspectable open var zoomImage: NSImage? = pluginBundle.image(forResource: "zoom")! {
        didSet {
            updateZoomAndFullscreenButton()
        }
    }
    @IBInspectable open var fullscreenImage: NSImage? = pluginBundle.image(forResource: "fullscreen")! {
        didSet {
            updateZoomAndFullscreenButton()
        }
    }
    @IBInspectable open var fullscreenOffImage: NSImage? = pluginBundle.image(forResource: "fullscreenOff")! {
        didSet {
            updateZoomAndFullscreenButton()
        }
    }


    @IBInspectable open var closeBackgroundImage: NSImage {
        get {
            return button(for: .closeButton).backgroundImage
        }
        set {
            button(for: .closeButton).alternateImage = newValue
        }
    }
    @IBInspectable open var  miniaturizeBackgroundImage: NSImage {
        get {
            return button(for: .miniaturizeButton).alternateImage!
        }
        set {
            button(for: .miniaturizeButton).alternateImage = newValue
        }
    }
    @IBInspectable open var zoomAndFullscreenBackgroundImage: NSImage {
        get {
            return button(for: .zoomAndFullscreenButton(fullscreen:false)).alternateImage!
        }
        set {
            button(for: .zoomAndFullscreenButton(fullscreen:false)).alternateImage = newValue
        }
    }
    @IBInspectable open var unactiveBackgroundImage: NSImage = pluginBundle.image(forResource: "unactiveBackground")! {
        didSet {
            for button in buttons {
                button.unactiveBackgroundImage = unactiveBackgroundImage
            }
        }
    }
    
    @IBInspectable open var isVertical: Bool = false {
        didSet {
            initializeConstrains()
        }
    }
    
    // if true use close instead of performClose, miniaturize instead of perfromMiniaturize, ...
    @IBInspectable open var forceAction: Bool = false

    //MARK: - life cycle
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        initialize()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }

    func initialize() {
        initializeConstrains()

        // Alt
        flagMonitor = NSEvent.addGlobalMonitorForEvents(matching: NSEventMask.flagsChanged) { event in
            self.alternateKeyPressed = event.modifierFlags.contains(.option)
        }
        localFlagMonitor = NSEvent.addLocalMonitorForEvents(matching: NSEventMask.flagsChanged) { event in
            self.alternateKeyPressed = event.modifierFlags.contains(.option)
            return event
        }
    }

    func initializeConstrains() {
        if !buttonConstrains.isEmpty {
            self.removeConstraints(buttonConstrains)
        }
        buttonConstrains = []
        let size = 12
        for (index, button) in buttons.enumerated() {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.tag = index
            button.action = #selector(WindowButtonsView.performButtonAction(_:))
            button.target = self
            addSubview(button)
            
            let orientation = isVertical ? "": "V:"
            let center: NSLayoutAttribute = isVertical ? .centerX : .centerY
            
            buttonConstrains += NSLayoutConstraint.constraints(withVisualFormat: "\(orientation)[b(\(size))]", options: [], metrics: nil, views: ["b": button])
            buttonConstrains += [NSLayoutConstraint(item: button, attribute: center, relatedBy: .equal, toItem: self, attribute: center, multiplier: 1.0, constant: 0.0)]
        }
        
        let views = ["b1":buttons[0], "b2":buttons[1], "b3":buttons[2]]
        
        let orientation = isVertical ? "V:": ""
        let center: NSLayoutAttribute = isVertical ? .centerY : .centerX
        buttonConstrains += NSLayoutConstraint.constraints(withVisualFormat: "\(orientation)[b1(\(size))]-8-[b2(\(size))]-8-[b3(\(size))]", options: [], metrics: nil, views: views)
        buttonConstrains += [NSLayoutConstraint(item: buttons[1], attribute: center, relatedBy: .equal, toItem: self, attribute: center, multiplier: 1.0, constant: 0.0)]
        
        self.addConstraints(buttonConstrains)
    }

    deinit {
        if let monitor = flagMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localFlagMonitor {
            NSEvent.removeMonitor(monitor)
        }
        NotificationCenter.default.removeObserver(self)
    }

    open override func viewDidMoveToWindow() {
        var names: [NSNotification.Name] = [
            .NSWindowDidBecomeMain, .NSWindowDidResignMain, .NSWindowDidDeminiaturize,
            .NSWindowDidMiniaturize, .NSWindowWillMiniaturize, .NSWindowDidResize
        ]
        for name in names {
            NotificationCenter.default.addObserver(self, selector: #selector(WindowButtonsView.updateButton(_:)), name: name, object: window)
        }
        names = [.NSWindowDidEnterFullScreen, .NSWindowDidExitFullScreen]
        for name in names {
            NotificationCenter.default.addObserver(self, selector: #selector(WindowButtonsView.windowDidToggleFullscreen(_:)), name: name, object: window)
        }

        updateButtonsState()
        updateZoomAndFullscreenButton()
    }

    //MARK: button
    fileprivate func button(for type: WindowButtonType) -> WindowButton {
        return buttons[type.index()]
    }
    func updateButton(_ notification: Notification) {
        mouseInside = false
        for button in buttons {
            button.setNeedsDisplay()
        }
    }
    open func rect(for type: WindowButtonType) -> NSRect {
        return button(for: type).frame
    }

    fileprivate func updateButtonsState() {
        let notFullscreen = window?.inFullScreen == false
        button(for: .closeButton).isEnabled = window?.canClose == true
        button(for: .miniaturizeButton).isEnabled = window?.canMiniaturize == true && notFullscreen
    }


    //MARK: button action
    func performButtonAction(_ sender: WindowButton!) {
        if delegate?.windowButtonsView(self, willPerformActionforButton: sender.type) ?? true {

            if let window = window {
                sender.type.action(sender, on: window, perform: !forceAction)
            }

            delegate?.windowButtonsView(self, didPerformActionforButton: sender.type)
        }
    }

    //MARK: - Mouse management
    fileprivate var trackingArea: NSTrackingArea?
    fileprivate var mouseInside: Bool = false {
        didSet {
            for button in buttons {
                button.displaySymbol = mouseInside
            }
        }
    }
    open override func updateTrackingAreas() {
        if let area = trackingArea {
            removeTrackingArea(area)
        }

        trackingArea = NSTrackingArea(rect: bounds, options: [.activeAlways, .mouseEnteredAndExited], owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)

    }
    open override func mouseEntered(with theEvent: NSEvent) {
        mouseInside = true
    }
    open override func mouseExited(with theEvent: NSEvent) {
        mouseInside = false
    }


    //MARK - ZoomAndFullscreenButton
    fileprivate var alternateKeyPressed: Bool = false {
        didSet {
            updateZoomAndFullscreenButton()
        }
    }

    func windowDidToggleFullscreen(_ notification: Notification) {
        updateButtonsState()
        updateZoomAndFullscreenButton()
    }
    
    fileprivate func updateZoomAndFullscreenButton() {
        zoomAndFullscreenButton.type = .zoomAndFullscreenButton(fullscreen:(window?.canGoFullscreen == true && !alternateKeyPressed) || window?.inFullScreen == true)

        if window?.inFullScreen == true {
            zoomAndFullscreenButton.image = fullscreenOffImage
        } else {
            switch zoomAndFullscreenButton.type {
            case .zoomAndFullscreenButton(fullscreen:true):
                zoomAndFullscreenButton.image = fullscreenImage
            case .zoomAndFullscreenButton(fullscreen:false):
                zoomAndFullscreenButton.image = zoomImage
            default:
                fatalError("")
            }
        }

    }

}

public protocol WindowButtonsViewDelegate {
     func windowButtonsView(_ windowButtonsView: WindowButtonsView, willPerformActionforButton: WindowButtonType) -> Bool
     func windowButtonsView(_ windowButtonsView: WindowButtonsView, didPerformActionforButton: WindowButtonType)
}
