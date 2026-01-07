import Cocoa

func showNotification(_ title: String, _ message: String) {
    let notification = NSUserNotification()
    notification.title = title
    notification.informativeText = message
    notification.deliveryDate = Date()
    NSUserNotificationCenter.default.deliver(notification)
}
