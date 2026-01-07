import Cocoa

class SettingsViewController: NSViewController {
    weak var delegate: SettingsWindowDelegate?
    
    var hotkeyModifierFlags: UInt = AppConfig.defaultHotkeyModifierFlags
    var hotkeyKeyCode: UInt16 = AppConfig.defaultHotkeyKeyCode
    var isRecordingHotkey = false
    
    // 视图属性
    var hotkeyDisplayField: NSTextField?
    var recordButton: NSButton?
    var apiKeyTextField: NSSecureTextField?
    
    // 初始化方法
    init(delegate: SettingsWindowDelegate?) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        loadHotkeySettings()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 加载快捷键设置
    private func loadHotkeySettings() {
        let defaults = UserDefaults.standard
        hotkeyModifierFlags = UInt(defaults.integer(forKey: AppConfig.hotkeyModifierFlagsKey))
        hotkeyKeyCode = UInt16(defaults.integer(forKey: AppConfig.hotkeyKeyCodeKey))
        
        if hotkeyModifierFlags == 0 {
            hotkeyModifierFlags = AppConfig.defaultHotkeyModifierFlags
        }
    }
    
    // 视图加载完成后调用
    override func viewDidLoad() {
        super.viewDidLoad()
        createSubviews()
    }
    
    // 创建所有子视图
    private func createSubviews() {
        // 创建一个自定义视图，允许成为第一响应者
        let customView = CustomSettingsView(frame: NSRect(x: 0, y: 0, width: 350, height: 420))
        customView.controller = self
        view = customView
        
        // API密钥标签
        let apiKeyLabel = NSTextField(frame: NSMakeRect(20, 340, 310, 20))
        apiKeyLabel.stringValue = "阿里云百炼API密钥"
        apiKeyLabel.isEditable = false
        apiKeyLabel.isBezeled = false
        apiKeyLabel.drawsBackground = false
        view.addSubview(apiKeyLabel)
        
        // API密钥状态标签
        let apiKeyStatusLabel = NSTextField(frame: NSMakeRect(20, 315, 310, 20))
        apiKeyStatusLabel.stringValue = UserDefaults.standard.string(forKey: "apiKey") != nil ? "已设置API密钥" : "未设置API密钥"
        apiKeyStatusLabel.isEditable = false
        apiKeyStatusLabel.isBezeled = false
        apiKeyStatusLabel.drawsBackground = false
        apiKeyStatusLabel.textColor = NSColor.secondaryLabelColor
        view.addSubview(apiKeyStatusLabel)
        
        // 修改API密钥按钮
        let modifyApiKeyButton = NSButton(frame: NSMakeRect(20, 280, 310, 30))
        modifyApiKeyButton.title = "修改API密钥"
        modifyApiKeyButton.bezelStyle = .rounded
        modifyApiKeyButton.action = #selector(showApiKeyDialog)
        modifyApiKeyButton.target = self
        view.addSubview(modifyApiKeyButton)
        
        // 分隔线
        let separatorLine = NSTextField(frame: NSMakeRect(20, 245, 310, 1))
        separatorLine.isEditable = false
        separatorLine.isBezeled = false
        separatorLine.drawsBackground = true
        separatorLine.backgroundColor = NSColor.separatorColor
        view.addSubview(separatorLine)
        
        // 快捷键标签
        let hotkeyLabel = NSTextField(frame: NSMakeRect(20, 210, 310, 20))
        hotkeyLabel.stringValue = "悬浮窗口快捷键"
        hotkeyLabel.isEditable = false
        hotkeyLabel.isBezeled = false
        hotkeyLabel.drawsBackground = false
        view.addSubview(hotkeyLabel)
        
        // 快捷键显示字段
        hotkeyDisplayField = NSTextField(frame: NSMakeRect(20, 175, 200, 35))
        hotkeyDisplayField?.stringValue = formatHotkey(modifierFlags: hotkeyModifierFlags, keyCode: hotkeyKeyCode)
        hotkeyDisplayField?.isEditable = false
        hotkeyDisplayField?.isBezeled = true
        hotkeyDisplayField?.bezelStyle = .roundedBezel
        hotkeyDisplayField?.alignment = .center
        if let displayField = hotkeyDisplayField {
            view.addSubview(displayField)
        }
        
        // 记录按钮
        recordButton = NSButton(frame: NSMakeRect(230, 175, 100, 35))
        recordButton?.title = "修改"
        recordButton?.bezelStyle = .rounded
        recordButton?.action = #selector(toggleHotkeyRecording)
        recordButton?.target = self
        if let button = recordButton {
            view.addSubview(button)
        }
        
        // 快捷键提示标签
        let hotkeyHintLabel = NSTextField(frame: NSMakeRect(20, 155, 310, 20))
        hotkeyHintLabel.stringValue = "按下任意键组合设置快捷键，按Esc取消"
        hotkeyHintLabel.font = NSFont.systemFont(ofSize: 10)
        hotkeyHintLabel.textColor = NSColor.secondaryLabelColor
        hotkeyHintLabel.isEditable = false
        hotkeyHintLabel.isBezeled = false
        hotkeyHintLabel.drawsBackground = false
        view.addSubview(hotkeyHintLabel)
        
        // 分隔线2
        let separatorLine2 = NSTextField(frame: NSMakeRect(20, 135, 310, 1))
        separatorLine2.isEditable = false
        separatorLine2.isBezeled = false
        separatorLine2.drawsBackground = true
        separatorLine2.backgroundColor = NSColor.separatorColor
        view.addSubview(separatorLine2)
        
        // 信息标签
        let infoLabel = NSTextField(frame: NSMakeRect(20, 90, 310, 40))
        infoLabel.stringValue = "LearnPartner v1.0\n基于Swift开发的macOS划词助手"
        infoLabel.isEditable = false
        infoLabel.isBezeled = false
        infoLabel.drawsBackground = false
        infoLabel.cell?.wraps = true
        infoLabel.cell?.isScrollable = false
        view.addSubview(infoLabel)
        
        // 清除日志按钮
        let clearLogButton = NSButton(frame: NSMakeRect(20, 50, 310, 30))
        clearLogButton.title = "清除日志文件"
        clearLogButton.bezelStyle = .rounded
        clearLogButton.action = #selector(delegate?.clearLogsAction)
        clearLogButton.target = delegate
        view.addSubview(clearLogButton)
        
        // 日志文件路径标签
        if let appSupportDirectory = LoggerService.shared.getLogDirectory() {
            let logFile = appSupportDirectory.appendingPathComponent(AppConfig.logFileName)
            let logPathLabel = NSTextField(frame: NSMakeRect(20, 10, 310, 30))
            logPathLabel.stringValue = "日志文件路径: \(logFile.path)"
            logPathLabel.isEditable = false
            logPathLabel.isBezeled = false
            logPathLabel.drawsBackground = false
            logPathLabel.cell?.wraps = true
            logPathLabel.cell?.isScrollable = false
            view.addSubview(logPathLabel)
        }
    }
    
    // 切换快捷键录制状态
    @objc func toggleHotkeyRecording() {
        isRecordingHotkey = !isRecordingHotkey
        
        if isRecordingHotkey {
            // 让自定义视图成为第一响应者，以便接收键盘事件
            view.window?.makeFirstResponder(view)
            hotkeyDisplayField?.stringValue = "请按键..."
            recordButton?.title = "取消"
        } else {
            hotkeyDisplayField?.stringValue = formatHotkey(modifierFlags: hotkeyModifierFlags, keyCode: hotkeyKeyCode)
            recordButton?.title = "修改"
        }
    }
    
    // 处理按键事件
    func handleKeyEvent(_ event: NSEvent) -> Bool {
        if !isRecordingHotkey {
            return false
        }
        
        if event.keyCode == 53 {
            toggleHotkeyRecording()
            return true
        }
        
        hotkeyModifierFlags = event.modifierFlags.rawValue
        hotkeyKeyCode = event.keyCode
        
        saveHotkeySettings()
        hotkeyDisplayField?.stringValue = formatHotkey(modifierFlags: hotkeyModifierFlags, keyCode: hotkeyKeyCode)
        recordButton?.title = "修改"
        isRecordingHotkey = false
        
        logToFile("快捷键已设置为: \(formatHotkey(modifierFlags: hotkeyModifierFlags, keyCode: hotkeyKeyCode))")
        
        return true
    }
    
    // 直接处理键盘事件
    override func keyDown(with event: NSEvent) {
        handleKeyEvent(event)
    }
    
    // 允许视图控制器成为第一响应者
    override var acceptsFirstResponder: Bool {
        return isRecordingHotkey
    }
    
    // 保存快捷键设置
    private func saveHotkeySettings() {
        let defaults = UserDefaults.standard
        defaults.set(Int(hotkeyModifierFlags), forKey: AppConfig.hotkeyModifierFlagsKey)
        defaults.set(Int(hotkeyKeyCode), forKey: AppConfig.hotkeyKeyCodeKey)
        defaults.synchronize()
        
        // 通知代理快捷键设置已更改
        delegate?.hotkeySettingsDidChange?(modifierFlags: hotkeyModifierFlags, keyCode: hotkeyKeyCode)
    }
    
    // 格式化快捷键显示
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
            modifiers.append("⌃")
        }
        
        let keyName = keyCodeToName(keyCode)
        
        return modifiers.joined() + keyName
    }
    
    // 键码转键名
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
    
    // 显示API密钥输入弹窗
    @objc func showApiKeyDialog() {
        // 创建弹窗
        let alert = NSAlert()
        alert.messageText = "修改阿里云百炼API密钥"
        alert.informativeText = "请输入新的API密钥："
        alert.alertStyle = .informational
        
        // 创建安全输入框
        let secureTextField = NSSecureTextField(frame: NSMakeRect(0, 0, 300, 25))
        secureTextField.placeholderString = "请输入API密钥"
        alert.accessoryView = secureTextField
        
        // 添加按钮
        alert.addButton(withTitle: "确认")
        alert.addButton(withTitle: "取消")
        
        // 显示弹窗并处理结果
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // 触发保存API密钥操作
            apiKeyTextField = secureTextField
            delegate?.saveApiKey(nil)
        }
    }
    
    // 获取API密钥
    func getApiKey() -> String? {
        return apiKeyTextField?.stringValue
    }
}

class SettingsWindow: NSWindowController {
    weak var delegate: SettingsWindowDelegate?
    var settingsViewController: SettingsViewController?
    
    init(delegate: SettingsWindowDelegate?) {
        self.delegate = delegate
        self.settingsViewController = SettingsViewController(delegate: delegate)
        
        // 创建窗口并设置内容视图控制器
        let window = NSWindow(contentRect: NSMakeRect(0, 0, 350, 420),
                             styleMask: [.titled, .closable, .resizable],
                             backing: .buffered,
                             defer: false)
        window.title = "LearnPartner 设置"
        window.center()
        window.contentViewController = settingsViewController
        
        super.init(window: window)
        
        // 在调用super.init之后才能使用self
        window.delegate = self
        
        logToFile("SettingsWindow 初始化完成")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        logToFile("显示设置窗口")
    }
    
    func getApiKey() -> String? {
        return settingsViewController?.getApiKey()
    }
    
    func handleKeyEvent(_ event: NSEvent) -> Bool {
        return settingsViewController?.handleKeyEvent(event) ?? false
    }
    
    func getHotkeyModifierFlags() -> UInt {
        return settingsViewController?.hotkeyModifierFlags ?? AppConfig.defaultHotkeyModifierFlags
    }
    
    func getHotkeyKeyCode() -> UInt16 {
        return settingsViewController?.hotkeyKeyCode ?? AppConfig.defaultHotkeyKeyCode
    }
    
    func closeWindow() {
        window?.orderOut(nil)
    }
}

extension SettingsWindow: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        logToFile("windowWillClose 触发")
        delegate?.settingsWindowDidClose()
        
        // 清理资源
        settingsViewController = nil
        window?.delegate = nil
    }
}

@objc protocol SettingsWindowDelegate: AnyObject {
    @objc func saveApiKey(_ sender: NSButton?)
    @objc func clearLogsAction()
    @objc func viewLogs()
    @objc func settingsWindowDidClose()
    @objc optional func hotkeySettingsDidChange(modifierFlags: UInt, keyCode: UInt16)
}

// 自定义视图，允许成为第一响应者并处理键盘事件
class CustomSettingsView: NSView {
    weak var controller: SettingsViewController?
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        if let controller = controller {
            if controller.handleKeyEvent(event) {
                return
            }
        }
        super.keyDown(with: event)
    }
}
