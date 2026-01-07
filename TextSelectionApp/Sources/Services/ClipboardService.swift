import Foundation
import Cocoa

class ClipboardService {
    static let shared = ClipboardService()
    
    private init() {}
    
    func getSelectedText() -> String? {
        logToFile("开始使用剪贴板方式获取选中文本")
        
        let pasteboard = NSPasteboard.general
        let originalClipboardContent = pasteboard.string(forType: .string) ?? "空"
        pasteboard.clearContents()
        logToFile("原始剪贴板内容: \(originalClipboardContent)")
        
        let source = CGEventSource(stateID: .combinedSessionState)
        guard source != nil else {
            logToFile("无法创建事件源")
            return nil
        }
        
        source?.setLocalEventsFilterDuringSuppressionState([.permitLocalMouseEvents, .permitLocalKeyboardEvents], state: .eventSuppressionStateSuppressionInterval)
        
        let cmdDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        cmdDownEvent?.flags = .maskCommand
        cmdDownEvent?.post(tap: .cghidEventTap)
        
        let cKeyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        cKeyDownEvent?.flags = .maskCommand
        cKeyDownEvent?.post(tap: .cghidEventTap)
        
        usleep(5000)
        
        let cKeyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        cKeyUpEvent?.flags = .maskCommand
        cKeyUpEvent?.post(tap: .cghidEventTap)
        
        let cmdUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        cmdUpEvent?.post(tap: .cghidEventTap)
        
        usleep(25000)
        
        let clipboardString = pasteboard.string(forType: .string)
        logToFile("剪贴板当前内容: \(clipboardString ?? "空")")
        
        guard let clipboardString = clipboardString else {
            if originalClipboardContent != "空" {
                do {
                    pasteboard.clearContents()
                    try pasteboard.setString(originalClipboardContent, forType: .string)
                    logToFile("已恢复原始剪贴板字符串内容")
                } catch {
                    logToFile("恢复剪贴板内容时出错: \(error)")
                }
            }
            return nil
        }
        
        let trimmedText = clipboardString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            pasteboard.clearContents()
            
            if originalClipboardContent != "空" {
                do {
                    try pasteboard.setString(originalClipboardContent, forType: .string)
                    logToFile("已恢复原始剪贴板字符串内容")
                } catch {
                    logToFile("恢复剪贴板字符串内容时出错: \(error)")
                }
            }
        } catch {
            logToFile("恢复剪贴板内容时发生异常: \(error)")
            do {
                try pasteboard.clearContents()
            } catch {
                logToFile("清空剪贴板时出错: \(error)")
            }
        }
        
        logToFile("通过剪贴板方式获取到选中文本: \(trimmedText)")
        return trimmedText
    }
    
    func clearClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
    }
}
