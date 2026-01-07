import Cocoa

class ToolbarPanel {
    weak var delegate: ToolbarPanelDelegate?
    var panel: NSPanel!
    
    init(delegate: ToolbarPanelDelegate?) {
        self.delegate = delegate
        createPanel()
    }
    
    private func createPanel() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 56),
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
        
        panel.contentView?.layer?.cornerRadius = 20
        panel.contentView?.layer?.masksToBounds = true
        
        let stackView = NSStackView(views: [
            createButton(title: "搜索", action: #selector(delegate?.searchAction)),
            createButton(title: "翻译", action: #selector(delegate?.translateAction))
        ])
        stackView.orientation = .horizontal
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView?.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: panel.contentView!.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: panel.contentView!.trailingAnchor, constant: -12),
            stackView.topAnchor.constraint(equalTo: panel.contentView!.topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: panel.contentView!.bottomAnchor, constant: -10)
        ])
    }
    
    private func createButton(title: String, action: Selector) -> AnimatedButton {
        let btn = AnimatedButton(title: title, target: delegate, action: action)
        btn.bezelStyle = .rounded
        btn.controlSize = .regular
        btn.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        
        if AppState.isDarkMode {
            btn.bezelColor = NSColor(white: 0.22, alpha: 1.0)
            btn.contentTintColor = NSColor.white
        } else {
            btn.bezelColor = NSColor(white: 0.9, alpha: 1.0)
            btn.contentTintColor = NSColor.black
        }
        
        btn.setButtonType(.momentaryPushIn)
        btn.isBordered = true
        btn.wantsLayer = true
        btn.layer?.cornerRadius = 10
        btn.layer?.masksToBounds = true
        btn.imagePosition = .noImage
        btn.title = "  \(title)  "
        btn.action = action
        btn.target = delegate
        
        return btn
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
    
    func show(at point: NSPoint) {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect.zero
        let panelSize = panel.frame.size
        
        var newX = point.x - panelSize.width / 2
        var newY = point.y + 15
        
        newX = max(screenFrame.minX + 10, min(newX, screenFrame.maxX - panelSize.width - 10))
        newY = max(screenFrame.minY + 10, min(newY, screenFrame.maxY - panelSize.height - 10))
        
        panel.setFrameOrigin(NSPoint(x: newX, y: newY))
        panel.makeKeyAndOrderFront(nil)
        
        showAnimation()
    }
    
    func hide() {
        panel.orderOut(nil)
    }
    
    func close() {
        hide()
        panel = nil
        delegate = nil
    }
    
    private func showAnimation() {
        if panel.contentView?.wantsLayer == true {
            panel.contentView?.layer?.transform = CATransform3DIdentity
            panel.contentView?.layer?.opacity = 0.0
            
            let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
            fadeInAnimation.fromValue = 0.0
            fadeInAnimation.toValue = 1.0
            fadeInAnimation.duration = 0.25
            fadeInAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = 0.92
            scaleAnimation.toValue = 1.0
            scaleAnimation.duration = 0.25
            scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            let translateYAnimation = CABasicAnimation(keyPath: "transform.translation.y")
            translateYAnimation.fromValue = 5
            translateYAnimation.toValue = 0
            translateYAnimation.duration = 0.25
            translateYAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            panel.contentView?.layer?.add(fadeInAnimation, forKey: "opacityAnimation")
            panel.contentView?.layer?.add(scaleAnimation, forKey: "scaleAnimation")
            panel.contentView?.layer?.add(translateYAnimation, forKey: "translateYAnimation")
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            panel.contentView?.layer?.opacity = 1.0
            panel.contentView?.layer?.transform = CATransform3DIdentity
            CATransaction.commit()
        }
    }
}

@objc protocol ToolbarPanelDelegate: AnyObject {
    @objc func searchAction()
    @objc func translateAction()
}
