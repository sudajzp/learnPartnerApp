import Cocoa

class AnimatedButton: NSButton {
    private var originalBezelColor: NSColor?
    private var isSelectedState: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupButton()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    private func setupButton() {
        originalBezelColor = bezelColor
        
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect, .assumeInside],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect, .assumeInside],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        if !isSelectedState {
            animateHover(true)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        if !isSelectedState {
            animateHover(false)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        animateClick(true)
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        animateClick(false)
        toggleSelectedState()
    }
    
    private func animateHover(_ isHovering: Bool) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            if isHovering {
                if let originalColor = originalBezelColor {
                    if originalColor.whiteComponent < 0.5 {
                        bezelColor = originalColor.blended(withFraction: 0.2, of: NSColor.white) ?? originalColor
                    } else {
                        bezelColor = originalColor.blended(withFraction: 0.1, of: NSColor.black) ?? originalColor
                    }
                }
            } else {
                bezelColor = originalBezelColor
            }
        }
    }
    
    private func animateClick(_ isClicked: Bool) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            if isClicked {
                layer?.transform = CATransform3DMakeScale(0.95, 0.95, 1.0)
            } else {
                layer?.transform = CATransform3DIdentity
            }
        }
    }
    
    func toggleSelectedState() {
        setSelectedState(!isSelectedState)
    }
    
    func setSelectedState(_ selected: Bool) {
        isSelectedState = selected
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            if selected {
                if let originalColor = originalBezelColor {
                    if originalColor.whiteComponent < 0.5 {
                        bezelColor = originalColor.blended(withFraction: 0.3, of: NSColor.white) ?? originalColor
                    } else {
                        bezelColor = originalColor.blended(withFraction: 0.2, of: NSColor.black) ?? originalColor
                    }
                }
                layer?.borderWidth = 1.0
                layer?.borderColor = NSColor.systemBlue.cgColor
            } else {
                bezelColor = originalBezelColor
                layer?.borderWidth = 0.0
            }
        }
    }
    
    func isSelected() -> Bool {
        return isSelectedState
    }
}
