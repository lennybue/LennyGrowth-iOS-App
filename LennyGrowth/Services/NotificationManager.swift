import Foundation
import UserNotifications
import UIKit

@MainActor
final class NotificationManager: ObservableObject {

    @Published var isAuthorized = false

    static let shared = NotificationManager()

    private init() {
        Task { await checkAuthorizationStatus() }
    }

    // ─── Authorization ────────────────────────────────────────────────────────

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            if granted {
                registerForRemoteNotifications()
            }
        } catch {
            print("Notification authorization error: \(error)")
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    // ─── Device token ─────────────────────────────────────────────────────────

    func handleDeviceToken(_ tokenData: Data) -> String {
        tokenData.map { String(format: "%02.2hhx", $0) }.joined()
    }

    // ─── Local notifications ──────────────────────────────────────────────────

    /// Schedule a local notification (e.g. reminder before optimal post time)
    func scheduleLocalNotification(title: String, body: String, scheduledAt: Date, identifier: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let id = identifier ?? UUID().uuidString
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Notification schedule error: \(error)") }
        }
    }

    /// Cancel pending notification by post ID
    func cancelNotification(for postId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [postId])
    }

    /// Cancel all pending notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // ─── Convenience ──────────────────────────────────────────────────────────

    func schedulePostReminder(postId: String, scheduledAt: Date, platform: String) {
        let reminderTime = scheduledAt.addingTimeInterval(-15 * 60) // 15 min before
        guard reminderTime > Date() else { return }
        scheduleLocalNotification(
            title: "Post in 15 Minuten",
            body: "Dein \(platform)-Post wird bald veröffentlicht.",
            scheduledAt: reminderTime,
            identifier: "reminder_\(postId)"
        )
    }
}
