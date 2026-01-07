import Foundation

struct AppConfig {
    static let bundleIdentifier = "com.learnpartner.app"
    static let appName = "LearnPartner"
    static let version = "1.0"
    static let logFileName = "learnPartner.log"
    static let maxLogDays = 7
    
    static let defaultHotkeyModifierFlags: UInt = 1 << 17 | 1 << 16
    static let defaultHotkeyKeyCode: UInt16 = 8
    
    static let hotkeyModifierFlagsKey = "hotkeyModifierFlags"
    static let hotkeyKeyCodeKey = "hotkeyKeyCode"
}
