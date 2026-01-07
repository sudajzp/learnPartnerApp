import Foundation
import Cocoa
import ObjectiveC

extension NSApplication {
    static let swizzleSendEvent: Void = {
        let originalSelector = #selector(NSApplication.sendEvent(_:))
        let swizzledSelector = #selector(NSApplication.customSendEvent(_:))
        
        let originalMethod = class_getInstanceMethod(NSApplication.self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(NSApplication.self, swizzledSelector)
        
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
            logToFile("NSApplication.sendEvent方法已成功交换")
        } else {
            logToFile("NSApplication.sendEvent方法交换失败")
        }
    }()
    
    @objc func customSendEvent(_ event: NSEvent) {
        self.customSendEvent(event)
    }
}
