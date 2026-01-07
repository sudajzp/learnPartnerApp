import Cocoa

struct AppState {
    static var isDarkMode: Bool {
        if #available(macOS 10.14, *) {
            return NSApp.effectiveAppearance.name == .darkAqua
        } else {
            let mode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
            return mode == "Dark"
        }
    }
}
