import Cocoa
import ObjectiveC
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate,
                    ToolbarPanelDelegate, TranslationPanelDelegate,
                    SettingsWindowDelegate {
    var statusItem: NSStatusItem!
    var settingsWindow: SettingsWindow?
    var toolbarPanel: ToolbarPanel?
    var translationPanel: TranslationPanel?
    var isMouseDragging = false
    var lastSelectedText: String = ""
    
    var mouseDownMonitor: Any?
    var mouseDragMonitor: Any?
    var mouseUpMonitor: Any?
    var keyDownMonitor: Any?
    
    var appearanceObserver: NSKeyValueObservation?
    
    var isShowingToolbar = false
    var hotkeyModifierFlags: UInt = 0
    var hotkeyKeyCode: UInt16 = 0
    
    // 热键相关属性
    var hotKeyRef: EventHotKeyRef? = nil
    var hotKeyID: EventHotKeyID = {
        var signature: OSType = 0
        "LPTK".withCString { ptr in
            signature = OSType(strtoul(ptr, nil, 16))
        }
        return EventHotKeyID(signature: signature, id: 1)
    }()
    
    func setupGlobalExceptionHandling() {
        logToFile("设置全局未捕获异常处理")
        
        NSSetUncaughtExceptionHandler { exception in
            let name = exception.name.rawValue
            let reason = exception.reason ?? "无详细原因"
            let stackTrace = exception.callStackSymbols.joined(separator: "\n")
            
            let errorMessage = "\n=== 未捕获的Objective-C异常 ===\n" +
                              "异常名称: \(name)\n" +
                              "异常原因: \(reason)\n" +
                              "调用堆栈:\n\(stackTrace)\n"
            
            logToFile(errorMessage)
            
            showNotification("LearnPartner错误", "应用程序遇到了一个严重错误，已记录详细日志供调试")
        }
    }
    
    // 热键事件处理回调函数
    private func hotKeyHandler(_ nextHandler: EventHandlerCallRef?, eventRef: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus {
        logToFile("热键事件处理回调被调用")
        
        // 处理热键事件，先检查选中文本，再打开悬浮窗口
        DispatchQueue.main.async {
            self.checkSelectedText()
        }
        
        return noErr
    }
    
    // 注册热键事件处理程序
    func registerHotKeyHandler() {
        // 创建事件类型列表
        let eventTypes = [kEventHotKeyPressed]
        
        // 创建事件处理程序引用
        var eventHandlerRef: EventHandlerRef? = nil
        
        // 注册事件处理程序
        let status = InstallEventHandler(GetEventDispatcherTarget(), 
                                        { (nextHandler, eventRef, userData) -> OSStatus in
                                            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
                                            return appDelegate.hotKeyHandler(nextHandler, eventRef: eventRef, userData: userData)
                                        },
                                        eventTypes.count,
                                        eventTypes.map { EventTypeSpec(eventClass: UInt32(kEventClassKeyboard), eventKind: UInt32($0)) },
                                        Unmanaged.passRetained(self).toOpaque(),
                                        &eventHandlerRef)
        
        if status != noErr {
            logToFile("注册热键事件处理程序失败，错误代码: \(status)")
        } else {
            logToFile("热键事件处理程序注册成功")
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApplication.shared.delegate = self
        NSApp.setActivationPolicy(.accessory)
        
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        let runningApplications = NSWorkspace.shared.runningApplications
        let count = runningApplications.filter { app in
            guard let id = app.bundleIdentifier else { return false }
            return id == bundleIdentifier && app.processIdentifier != ProcessInfo.processInfo.processIdentifier
        }.count
        
        if count > 0 {
            showNotification("LearnPartner", "应用程序已经在运行")
            NSApplication.shared.terminate(self)
            return
        }
        
        NSApplication.swizzleSendEvent
        
        showNotification("LearnPartner", "应用程序已启动")
        
        LoggerService.shared.deleteOldLogs()
        
        if !AccessibilityService.shared.checkPermission() {
            logToFile("警告：应用程序没有辅助功能权限，可能无法正常显示划词菜单")
            AccessibilityService.shared.showPermissionAlert()
        } else {
            logToFile("辅助功能权限已启用")
        }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusIcon()
        
        if #available(macOS 10.14, *) {
            appearanceObserver = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in
                self?.updateStatusIcon()
                self?.toolbarPanel?.updateAppearance()
                self?.translationPanel?.updateAppearance()
            }
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "设置", action: #selector(showSettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "查看日志", action: #selector(viewLogs), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "清除日志", action: #selector(clearLogsAction), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "关于", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: ""))
        statusItem.menu = menu
        
        setupMouseListeners()
        setupKeyboardListeners() // 保持这个调用，用于处理设置窗口中的快捷键录制
        loadHotkeySettings()
        registerHotKeyHandler() // 注册热键事件处理程序
        registerHotKey()
        
        toolbarPanel = ToolbarPanel(delegate: self)
        translationPanel = TranslationPanel(delegate: self)
        
        setupGlobalExceptionHandling()
        
        logToFile("应用程序已启动并完成初始化")
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        logToFile("应用程序即将变为活跃状态")
        setupMouseListeners()
        setupKeyboardListeners()
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        logToFile("应用程序已变为活跃状态")
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        logToFile("应用程序即将变为非活跃状态")
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        logToFile("应用程序已变为非活跃状态")
    }
    
    func updateStatusIcon() {
        guard let button = statusItem.button else { return }
        
        let iconName = AppState.isDarkMode ? "StatusIconDark" : "StatusIcon"
        if let icon = NSImage(named: NSImage.Name(iconName)) {
            icon.size = NSSize(width: 20, height: 20)
            button.image = icon
            button.imagePosition = .imageOnly
        } else {
            button.title = "LP"
        }
    }
    
    func setupMouseListeners() {
        if let monitor = mouseDownMonitor {
            NSEvent.removeMonitor(monitor)
            mouseDownMonitor = nil
        }
        if let monitor = mouseDragMonitor {
            NSEvent.removeMonitor(monitor)
            mouseDragMonitor = nil
        }
        if let monitor = mouseUpMonitor {
            NSEvent.removeMonitor(monitor)
            mouseUpMonitor = nil
        }
        
        mouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            self?.isMouseDragging = false
            
            if event.clickCount == 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.checkSelectedText()
                }
            } else if event.clickCount == 2 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.checkSelectedText()
                }
            } else if event.clickCount == 1 {
                DispatchQueue.main.async {
                    self?.toolbarPanel?.hide()
                    self?.translationPanel?.hide()
                }
            }
        }
        
        mouseDragMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .rightMouseDragged]) { [weak self] _ in
            self?.isMouseDragging = true
        }
        
        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp]) { [weak self] event in
            if let isDragging = self?.isMouseDragging, isDragging {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.checkSelectedText()
                }
            }
            self?.isMouseDragging = false
        }
    }
    
    func setupKeyboardListeners() {
        if let monitor = keyDownMonitor {
            NSEvent.removeMonitor(monitor)
            keyDownMonitor = nil
        }
        
        keyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.handleKeyEvent(event)
        }
    }
    
    func handleKeyEvent(_ event: NSEvent) {
        logToFile("检测到键盘事件，keyCode: \(event.keyCode), modifiers: \(event.modifierFlags.rawValue)")
        
        // 检查是否正在录制快捷键，如果是则优先传递给SettingsWindow
        if let settingsWindow = settingsWindow {
            if settingsWindow.handleKeyEvent(event) {
                return
            }
        }
        
        // 不再通过全局键盘监听器处理热键事件，由Carbon框架的热键事件处理程序处理
        // 只有当没有按下热键时，才隐藏悬浮窗口
        DispatchQueue.main.async {
            self.toolbarPanel?.hide()
            self.translationPanel?.hide()
        }
    }
    
    func loadHotkeySettings() {
        let defaults = UserDefaults.standard
        hotkeyModifierFlags = UInt(defaults.integer(forKey: AppConfig.hotkeyModifierFlagsKey))
        hotkeyKeyCode = UInt16(defaults.integer(forKey: AppConfig.hotkeyKeyCodeKey))
        
        if hotkeyModifierFlags == 0 {
            hotkeyModifierFlags = AppConfig.defaultHotkeyModifierFlags
            hotkeyKeyCode = AppConfig.defaultHotkeyKeyCode
        }
        
        logToFile("快捷键设置已加载: \(formatHotkey(modifierFlags: hotkeyModifierFlags, keyCode: hotkeyKeyCode))")
    }
    
    // 注册全局热键
    func registerHotKey() {
        // 先注销已有的热键
        unregisterHotKey()
        
        logToFile("开始注册全局热键: keyCode=\(hotkeyKeyCode), modifiers=\(hotkeyModifierFlags)")
        
        // 转换修饰符
        var carbonModifiers: UInt32 = 0
        let cocoaModifiers = NSEvent.ModifierFlags(rawValue: hotkeyModifierFlags)
        
        if cocoaModifiers.contains(.shift) {
            carbonModifiers |= UInt32(shiftKey)
        }
        if cocoaModifiers.contains(.option) {
            carbonModifiers |= UInt32(optionKey)
        }
        if cocoaModifiers.contains(.control) {
            carbonModifiers |= UInt32(controlKey)
        }
        if cocoaModifiers.contains(.command) {
            carbonModifiers |= UInt32(cmdKey)
        }
        
        // 注册热键
        let status = RegisterEventHotKey(UInt32(hotkeyKeyCode), carbonModifiers, hotKeyID, nil, 0, &hotKeyRef)
        
        if status != noErr {
            logToFile("热键注册失败，错误代码: \(status)")
        } else {
            logToFile("热键注册成功: \(formatHotkey(modifierFlags: hotkeyModifierFlags, keyCode: hotkeyKeyCode))")
        }
    }
    
    // 注销全局热键
    func unregisterHotKey() {
        if hotKeyRef != nil {
            UnregisterEventHotKey(hotKeyRef!)
            hotKeyRef = nil
            logToFile("已注销全局热键")
        }
    }
    
    private func formatHotkey(modifierFlags: UInt, keyCode: UInt16) -> String {
        var modifiers: [String] = []
        
        if modifierFlags & NSEvent.ModifierFlags.command.rawValue != 0 {
            modifiers.append("⌘")
        }
        if modifierFlags & NSEvent.ModifierFlags.shift.rawValue != 0 {
            modifiers.append("⇧")
        }
        if modifierFlags & NSEvent.ModifierFlags.option.rawValue != 0 {
            modifiers.append("⌥")
        }
        if modifierFlags & NSEvent.ModifierFlags.control.rawValue != 0 {
            modifiers.append("^")
        }
        
        let keyName = keyCodeToName(keyCode)
        
        return modifiers.joined() + keyName
    }
    
    private func keyCodeToName(_ keyCode: UInt16) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 36: return "↵"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 48: return "⇥"
        case 49: return " "
        case 50: return "`"
        case 51: return "⌫"
        case 53: return "⎋"
        case 55: return "⌘"
        case 56: return "⇧"
        case 57: return "⌥"
        case 58: return "⌃"
        case 59: return "F1"
        case 60: return "F2"
        case 61: return "F3"
        case 62: return "F4"
        case 63: return "F5"
        case 64: return "F6"
        case 65: return "F7"
        case 66: return "F8"
        case 67: return "F9"
        case 68: return "F10"
        case 69: return "F11"
        case 70: return "F12"
        case 71: return "F13"
        case 72: return "F14"
        case 73: return "F15"
        case 74: return "F16"
        case 75: return "F17"
        case 76: return "↵"
        case 82: return "0"
        case 83: return "1"
        case 84: return "2"
        case 85: return "3"
        case 86: return "4"
        case 87: return "5"
        case 88: return "6"
        case 89: return "7"
        case 90: return "8"
        case 91: return "9"
        case 92: return "."
        case 93: return "/"
        case 95: return "*"
        case 96: return "+"
        default: return "Key\(keyCode)"
        }
    }
    
    func showToolbarAtMouseLocation() {
        let mouseLocation = NSEvent.mouseLocation
        if !lastSelectedText.isEmpty {
            self.toolbarPanel?.show(at: mouseLocation)
            logToFile("使用快捷键显示悬浮窗口")
        } else {
            self.toolbarPanel?.show(at: mouseLocation)
            logToFile("使用快捷键显示悬浮窗口（无选中文本）")
        }
    }
    
    func checkSelectedText() {
        logToFile("开始检查选中文本")
        
        guard let selectedText = getSelectedText(), !selectedText.isEmpty, selectedText.count > 2 else {
            logToFile("未检测到有效选中文本或选中文本长度不足3个字符")
            return
        }
        
        lastSelectedText = selectedText
        logToFile("检测到选中文本: \(selectedText)")
        
        showContextMenu(for: selectedText)
        logToFile("选中文本检查流程完成")
    }
    
    func getSelectedText() -> String? {
        // 直接使用AccessibilityService的getSelectedText方法，它已经包含了完整的逻辑
        return AccessibilityService.shared.getSelectedText()
    }
    
    func showContextMenu(for text: String) {
        logToFile("开始显示划词菜单，文本: \(text)")
        
        DispatchQueue.main.async { [weak self] in
            self?.lastSelectedText = text
            
            let mouseLocation = NSEvent.mouseLocation
            logToFile("鼠标位置: \(mouseLocation)")
            
            self?.toolbarPanel?.show(at: mouseLocation)
            logToFile("已请求显示浮动工具栏")
        }
    }
    
    @objc func showSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if settingsWindow == nil {
            settingsWindow = SettingsWindow(delegate: self)
        }
        settingsWindow?.show()
    }
    
    @objc func viewLogs() {
        guard let appSupportDirectory = LoggerService.shared.getLogDirectory() else {
            return
        }
        
        let logFile = appSupportDirectory.appendingPathComponent(AppConfig.logFileName)
        if FileManager.default.fileExists(atPath: logFile.path) {
            NSWorkspace.shared.open(logFile)
            logToFile("打开日志文件")
        } else {
            let alert = NSAlert()
            alert.messageText = "日志文件不存在"
            alert.informativeText = "日志文件尚未创建，应用将在运行过程中自动生成日志"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }
    
    @objc func clearLogsAction() {
        let alert = NSAlert()
        alert.messageText = "确认清除日志"
        alert.informativeText = "确定要清除所有日志文件吗？此操作无法撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            LoggerService.shared.clearLogs()
            showNotification("LearnPartner", "日志文件已清除")
            logToFile("日志文件已手动清除")
        }
    }
    
    @objc func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApplication.shared.orderFrontStandardAboutPanel()
    }
    
    @objc func quitApp() {
        logToFile("应用程序已退出")
        NSApplication.shared.terminate(self)
    }
    
    func searchAction() {
        if !lastSelectedText.isEmpty {
            let query = lastSelectedText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "https://cn.bing.com/search?q=\(query)") {
                NSWorkspace.shared.open(url)
                logToFile("使用Bing搜索: \(lastSelectedText)")
            }
        }
        
        toolbarPanel?.hide()
    }
    
    func translateAction() {
        if !lastSelectedText.isEmpty {
            TranslationService.shared.translate(lastSelectedText) { [weak self] result in
                if let result = result {
                    let mouseLocation = NSEvent.mouseLocation
                    self?.translationPanel?.show(text: result, at: mouseLocation)
                } else {
                    let alert = NSAlert()
                    alert.messageText = "翻译错误"
                    alert.informativeText = "翻译失败，请稍后重试"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "确定")
                    alert.runModal()
                }
            }
        }
        
        toolbarPanel?.hide()
    }
    
    @objc func saveApiKey(_ sender: NSButton?) {
        let apiKey = settingsWindow?.getApiKey() ?? ""
        
        if apiKey.isEmpty {
            let alert = NSAlert()
            alert.messageText = "API密钥不能为空"
            alert.informativeText = "请输入有效的阿里云百炼API密钥"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "确定")
            alert.runModal()
            return
        }
        
        TranslationService.shared.saveApiKey(apiKey) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    let alert = NSAlert()
                    alert.messageText = "保存成功"
                    alert.informativeText = "API密钥已保存"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "确定")
                    alert.runModal()
                    logToFile("API密钥已保存")
                } else {
                    let alert = NSAlert()
                    alert.messageText = "保存失败"
                    alert.informativeText = error ?? "未知错误"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "确定")
                    alert.runModal()
                    logToFile("API密钥保存失败: \(error ?? "未知错误")")
                }
            }
        }
    }
    
    func settingsWindowDidClose() {
        logToFile("settingsWindowDidClose 被调用")
        // 重新加载快捷键设置，确保新设置生效
        loadHotkeySettings()
        settingsWindow = nil
    }
    
    // 处理快捷键设置变更
    func hotkeySettingsDidChange(modifierFlags: UInt, keyCode: UInt16) {
        logToFile("hotkeySettingsDidChange 被调用: modifierFlags=\(modifierFlags), keyCode=\(keyCode)")
        hotkeyModifierFlags = modifierFlags
        hotkeyKeyCode = keyCode
        registerHotKey() // 重新注册热键
        logToFile("快捷键已更新: \(formatHotkey(modifierFlags: hotkeyModifierFlags, keyCode: hotkeyKeyCode))")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 返回false，确保即使最后一个窗口关闭，应用程序也不会退出
        return false
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        logToFile("applicationWillTerminate 被调用 - 应用即将退出")
        
        statusItem.menu = nil
        toolbarPanel?.close()
        translationPanel?.close()
        settingsWindow?.closeWindow()
        
        if let monitor = mouseDownMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = mouseDragMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = mouseUpMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = keyDownMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        // 注销热键
        unregisterHotKey()
        
        appearanceObserver?.invalidate()
        
        toolbarPanel = nil
        translationPanel = nil
        settingsWindow = nil
        statusItem = nil
    }
}
