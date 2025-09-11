//
//  NotificationService.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound, .provisional]
            )
            await MainActor.run {
                self.authorizationStatus = granted ? .authorized : .denied
            }
            print("✅ Notification authorization: \(granted ? "granted" : "denied")")
            return granted
        } catch {
            print("❌ Error requesting notification authorization: \(error.localizedDescription)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    // MARK: - Task Reminders
    
    func scheduleTaskReminder(for task: Task) async {
        guard task.reminderEnabled,
              let reminderTime = task.reminderTime,
              reminderTime > Date() else {
            print("⚠️ Task reminder not scheduled: reminder disabled or time in past")
            return
        }
        
        // Ensure we have permission
        if authorizationStatus != .authorized {
            let granted = await requestAuthorization()
            if !granted {
                print("❌ Cannot schedule reminder: authorization denied")
                return
            }
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.subtitle = "Due: \(task.formattedDeadline)"
        content.sound = .default
        content.badge = 1
        
        // Add custom data
        content.userInfo = [
            "taskId": task.id.uuidString,
            "type": "taskReminder",
            "priority": task.priority.rawValue
        ]
        
        // Set category for actions
        content.categoryIdentifier = "TASK_REMINDER"
        
        // Create trigger
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "task_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Task reminder scheduled for: \(reminderTime)")
        } catch {
            print("❌ Error scheduling task reminder: \(error.localizedDescription)")
        }
    }
    
    func cancelTaskReminder(for taskId: UUID) {
        let identifier = "task_\(taskId.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("✅ Task reminder cancelled for task: \(taskId)")
    }
    
    // MARK: - Daily Reminders
    
    func scheduleDailyPlanningReminder(at time: Date) async {
        guard authorizationStatus == .authorized else {
            print("❌ Cannot schedule daily reminder: authorization not granted")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Plan Your Day"
        content.body = "Take a few minutes to organize your tasks and set your priorities for today."
        content.sound = .default
        content.badge = 1
        
        content.userInfo = [
            "type": "dailyPlanning"
        ]
        
        content.categoryIdentifier = "DAILY_PLANNING"
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_planning",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Daily planning reminder scheduled for: \(time)")
        } catch {
            print("❌ Error scheduling daily planning reminder: \(error.localizedDescription)")
        }
    }
    
    func scheduleWeeklyReviewReminder() async {
        guard authorizationStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Weekly Review"
        content.body = "Review your progress and plan for the upcoming week."
        content.sound = .default
        
        content.userInfo = ["type": "weeklyReview"]
        content.categoryIdentifier = "WEEKLY_REVIEW"
        
        // Schedule for Sunday at 7 PM
        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 19
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "weekly_review",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Weekly review reminder scheduled")
        } catch {
            print("❌ Error scheduling weekly review reminder: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Overdue Task Notifications
    
    func checkAndNotifyOverdueTasks(_ tasks: [Task]) async {
        let overdueTasks = tasks.filter { $0.isOverdue && !$0.isCompleted }
        
        for task in overdueTasks.prefix(3) { // Limit to 3 to avoid spam
            await sendOverdueTaskNotification(task)
        }
    }
    
    private func sendOverdueTaskNotification(_ task: Task) async {
        guard authorizationStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Overdue Task"
        content.body = "\(task.title) was due \(formatTimeSince(task.deadline))"
        content.sound = .default
        content.badge = 1
        
        content.userInfo = [
            "taskId": task.id.uuidString,
            "type": "overdueTask"
        ]
        
        content.categoryIdentifier = "OVERDUE_TASK"
        
        let request = UNNotificationRequest(
            identifier: "overdue_\(task.id.uuidString)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Send immediately
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Overdue task notification sent for: \(task.title)")
        } catch {
            print("❌ Error sending overdue task notification: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Productivity Insights
    
    func sendProductivityInsight(_ insight: ProductivityInsight) async {
        guard authorizationStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Productivity Insight"
        content.body = insight.description
        content.sound = .default
        
        content.userInfo = [
            "type": "productivityInsight",
            "insightType": String(describing: insight.type)
        ]
        
        let request = UNNotificationRequest(
            identifier: "insight_\(insight.id.uuidString)",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Productivity insight notification sent")
        } catch {
            print("❌ Error sending productivity insight: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Notification Categories and Actions
    
    func setupNotificationCategories() async {
        // Task Reminder Actions
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_TASK",
            title: "Mark Complete",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_TASK",
            title: "Snooze 15min",
            options: []
        )
        
        let taskReminderCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Daily Planning Actions
        let openAppAction = UNNotificationAction(
            identifier: "OPEN_APP",
            title: "Open App",
            options: [.foreground]
        )
        
        let dailyPlanningCategory = UNNotificationCategory(
            identifier: "DAILY_PLANNING",
            actions: [openAppAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Overdue Task Actions
        let rescheduleAction = UNNotificationAction(
            identifier: "RESCHEDULE_TASK",
            title: "Reschedule",
            options: [.foreground]
        )
        
        let overdueTaskCategory = UNNotificationCategory(
            identifier: "OVERDUE_TASK",
            actions: [completeAction, rescheduleAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Weekly Review Category
        let weeklyReviewCategory = UNNotificationCategory(
            identifier: "WEEKLY_REVIEW",
            actions: [openAppAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            taskReminderCategory,
            dailyPlanningCategory,
            overdueTaskCategory,
            weeklyReviewCategory
        ])
        
        print("✅ Notification categories configured")
    }
    
    // MARK: - Utility Functions
    
    private func formatTimeSince(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else {
            return "just now"
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("✅ All notifications cancelled")
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
}
