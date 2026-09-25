import SwiftUI
import UserNotifications

enum ReminderError: LocalizedError {
    case notificationsDenied

    var errorDescription: String? {
        String(localized: "Notifications are turned off for CopyHistory. Enable them in System Settings to get reminders.")
    }
}

enum ReminderService {
    private static var center: UNUserNotificationCenter { .current() }

    static func schedule(id: String, body: String, at date: Date) async throws {
        guard try await center.requestAuthorization(options: [.alert, .sound]) else {
            throw ReminderError.notificationsDenied
        }
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Reminder")
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    static func cancel(ids: [String]) {
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}

struct ReminderPopoverView: View {
    @State private var date: Date
    let hasReminder: Bool
    let onSet: (Date) -> Void
    let onClear: () -> Void

    init(current: Date?, onSet: @escaping (Date) -> Void, onClear: @escaping () -> Void) {
        _date = State(initialValue: current ?? Date().addingTimeInterval(3600))
        hasReminder = current != nil
        self.onSet = onSet
        self.onClear = onClear
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminder").font(.headline)
            DatePicker("", selection: $date, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .labelsHidden()
            HStack {
                if hasReminder {
                    Button("Clear", action: onClear)
                }
                Spacer()
                Button("Set") { onSet(date) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
    }
}
