import Foundation
import Cocoa
import ObjectiveC

class AccessibilityService {
    static let shared = AccessibilityService()
    
    private init() {}
    
    func checkPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: false]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    func getSelectedText() -> String? {
        logToFile("开始获取选中文本")
        
        guard AccessibilityService.shared.checkPermission() else {
            logToFile("没有辅助功能权限，无法获取选中文本")
            return nil
        }
        
        // 获取前端应用
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication, 
              let bundleID = frontmostApp.bundleIdentifier else {
            logToFile("无法获取前端应用信息")
            return nil
        }
        
        // 忽略自己
        if bundleID == Bundle.main.bundleIdentifier {
            logToFile("当前前端应用是自己，忽略获取选中文本")
            return nil
        }
        
        logToFile("当前前端应用: \(bundleID)")
        
        // 获取当前应用的选中文字
        var selectedText = ""
        let source = AXUIElementCreateApplication(frontmostApp.processIdentifier)
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(source, kAXSelectedTextAttribute as CFString, &value)
        if result == .success, let text = value as? String {
            selectedText = text
        } else {
            logToFile("直接从应用获取选中文本失败，错误代码: \(result.rawValue)")
        }
        
        // 如果获取到的文本不为空，返回trim后的结果
        if !selectedText.isEmpty {
            let trimmedText = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedText.isEmpty {
                logToFile("Accessibility API获取到文本: \(trimmedText)")
                return trimmedText
            }
        }
        
        // 如果直接获取失败或文本为空，尝试通过焦点元素获取
        logToFile("尝试通过焦点元素获取选中文本")
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        let error = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        if error == .success && focusedElement != nil {
            var value: AnyObject?
            let textError = AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, kAXSelectedTextAttribute as CFString, &value)
            
            if textError == .success, let text = value as? String {
                let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedText.isEmpty {
                    logToFile("通过焦点元素获取到文本: \(trimmedText)")
                    return trimmedText
                }
            } else {
                logToFile("通过焦点元素获取选中文本失败，错误代码: \(textError.rawValue)")
            }
        } else {
            logToFile("获取焦点UI元素失败，错误代码: \(error.rawValue)")
        }
        
        logToFile("所有获取选中文本的方式均失败")
        return nil
    }
    
    func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = "请在系统偏好设置 > 安全性与隐私 > 辅助功能中启用LearnPartner应用程序，以便正常显示划词菜单"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打开系统偏好设置")
        alert.addButton(withTitle: "稍后再说")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }
}
