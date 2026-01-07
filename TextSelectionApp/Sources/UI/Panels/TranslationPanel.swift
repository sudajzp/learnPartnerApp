import Cocoa

class TranslationPanel {
    weak var delegate: TranslationPanelDelegate?
    var panel: NSPanel!
    private var textView: NSTextView?
    
    init(delegate: TranslationPanelDelegate?) {
        self.delegate = delegate
        createPanel()
    }
    
    private func createPanel() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 150),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.hasShadow = false
        panel.contentView?.wantsLayer = true
        panel.backgroundColor = NSColor.clear
        
        updateAppearance()
        
        let tv = NSTextView(frame: NSRect(x: 12, y: 10, width: 276, height: 130))
        tv.isEditable = false
        tv.isSelectable = true
        tv.backgroundColor = .clear
        tv.textColor = AppState.isDarkMode ? .white : .black
        tv.font = NSFont.systemFont(ofSize: 14)
        tv.alignment = .left
        tv.textContainer?.lineBreakMode = .byWordWrapping
        tv.textContainer?.widthTracksTextView = true
        tv.isHorizontallyResizable = false
        tv.isVerticallyResizable = true
        tv.autoresizingMask = [.width, .height]
        
        textView = tv
        panel.contentView?.addSubview(tv)
    }
    
    func updateAppearance() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            panel.backgroundColor = NSColor.clear
            
            if AppState.isDarkMode {
                panel.contentView?.layer?.borderColor = NSColor(white: 0.3, alpha: 1.0).cgColor
                panel.contentView?.layer?.backgroundColor = NSColor(white: 0.0, alpha: 0.5).cgColor
            } else {
                panel.contentView?.layer?.borderColor = NSColor(white: 0.85, alpha: 1.0).cgColor
                panel.contentView?.layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.5).cgColor
            }
        }
    }
    
    func show(text: String, at position: NSPoint) {
        guard textView != nil else { return }
        
        textView?.string = text
        
        let maxWidth: CGFloat = 300
        let textContainer = textView!.textContainer!
        let layoutManager = textContainer.layoutManager!
        
        textContainer.size = NSSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
        let textSize = layoutManager.usedRect(for: textContainer).size
        
        let windowWidth = max(300, textSize.width + 24)
        let windowHeight = max(100, textSize.height + 20)
        
        panel.setFrame(NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight), display: false)
        
        panel.contentView?.layer?.shadowPath = NSBezierPath(roundedRect: panel.contentView!.bounds, xRadius: 20, yRadius: 20).cgPath
        
        textView?.frame = NSRect(x: 12, y: 10, width: windowWidth - 24, height: windowHeight - 20)
        
        var windowPosition = position
        windowPosition.x -= windowWidth / 2
        windowPosition.y -= windowHeight + 10
        
        let screenFrame = NSScreen.main?.frame ?? NSMakeRect(0, 0, 1920, 1080)
        windowPosition.x = max(0, min(windowPosition.x, screenFrame.width - windowWidth))
        windowPosition.y = max(0, min(windowPosition.y, screenFrame.height - windowHeight))
        
        panel.setFrameOrigin(windowPosition)
        panel.orderFront(nil)
        
        showAnimation()
    }
    
    func hide() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0.0
            panel.contentView?.layer?.transform = CATransform3DMakeScale(0.95, 0.95, 1.0)
        } completionHandler: {
            self.panel.orderOut(nil)
        }
    }
    
    func close() {
        panel.orderOut(nil)
        panel = nil
        delegate = nil
    }
    
    private func showAnimation() {
        panel.alphaValue = 0.0
        panel.contentView?.layer?.transform = CATransform3DMakeScale(0.9, 0.9, 1.0)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1.0
            panel.contentView?.layer?.transform = CATransform3DIdentity
        }
    }
}

protocol TranslationPanelDelegate: AnyObject {}
