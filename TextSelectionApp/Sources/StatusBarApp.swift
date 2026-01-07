import SwiftUI
import Cocoa

@main
struct StatusBarApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate.shared ?? AppDelegate()
        AppDelegate.shared = delegate
        app.delegate = delegate
        app.run()
    }
}

extension AppDelegate {
    static var shared: AppDelegate?
}