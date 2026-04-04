import SwiftUI
import UserNotifications

@main
struct ClipboardMarkdownApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            ContentView()
        } label: {
            Image(systemName: "doc.on.clipboard")
        }
        .menuBarExtraStyle(.menu)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
    }

    // Called when user clicks the notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let path = response.notification.request.content.userInfo["filePath"] as? String {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }
        completionHandler()
    }

    // Show notification even when app is active
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
