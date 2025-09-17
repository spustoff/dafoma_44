//
//  TaskTemplateModel.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import SwiftUI

struct TaskTemplate: Identifiable, Codable, Hashable {
    let id = UUID()
    var title: String
    var description: String
    var category: TaskCategory
    var priority: TaskPriority
    var estimatedDuration: TimeInterval
    var tags: [String]
    var defaultDeadlineOffset: TimeInterval // How many seconds from now for deadline
    var reminderEnabled: Bool
    var reminderOffset: TimeInterval // How many seconds before deadline
    var color: String
    var icon: String
    var usageCount: Int
    var createdAt: Date
    var lastUsed: Date?
    
    init(title: String, description: String = "", category: TaskCategory = .personal, priority: TaskPriority = .medium, estimatedDuration: TimeInterval = 3600, defaultDeadlineOffset: TimeInterval = 86400) {
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.estimatedDuration = estimatedDuration
        self.tags = []
        self.defaultDeadlineOffset = defaultDeadlineOffset
        self.reminderEnabled = true
        self.reminderOffset = 3600 // 1 hour before
        self.color = "#0278fc"
        self.icon = "doc.text"
        self.usageCount = 0
        self.createdAt = Date()
        self.lastUsed = nil
    }
    
    var formattedEstimatedDuration: String {
        let hours = Int(estimatedDuration) / 3600
        let minutes = Int(estimatedDuration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedDeadlineOffset: String {
        let days = Int(defaultDeadlineOffset) / 86400
        let hours = Int(defaultDeadlineOffset) % 86400 / 3600
        
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "Today"
        }
    }
    
    var categoryColor: Color {
        switch category {
        case .personal:
            return Color(hex: "#0278fc")
        case .work:
            return Color(hex: "#ee004a")
        case .health:
            return Color(hex: "#54b702")
        case .education:
            return Color(hex: "#d300ee")
        case .finance:
            return Color(hex: "#fff707")
        case .other:
            return Color.gray
        }
    }
    
    var templateColor: Color {
        Color(hex: color)
    }
    
    func createTask() -> Task {
        let deadline = Date().addingTimeInterval(defaultDeadlineOffset)
        let reminderTime = reminderEnabled ? deadline.addingTimeInterval(-reminderOffset) : nil
        
        var task = Task(
            title: title,
            description: description,
            deadline: deadline,
            priority: priority,
            category: category,
            estimatedDuration: estimatedDuration,
            reminderEnabled: reminderEnabled
        )
        
        task.reminderTime = reminderTime
        task.tags = tags
        
        return task
    }
    
    mutating func incrementUsage() {
        usageCount += 1
        lastUsed = Date()
    }
}

struct RecurringTask: Identifiable, Codable, Hashable {
    let id = UUID()
    var title: String
    var description: String
    var category: TaskCategory
    var priority: TaskPriority
    var estimatedDuration: TimeInterval
    var tags: [String]
    var recurrenceRule: RecurrenceRule
    var isActive: Bool
    var nextDueDate: Date
    var createdAt: Date
    var lastGenerated: Date?
    var generatedTaskIds: [UUID]
    var reminderEnabled: Bool
    var reminderOffset: TimeInterval
    var color: String
    var endDate: Date? // Optional end date for recurrence
    
    init(title: String, description: String = "", category: TaskCategory = .personal, priority: TaskPriority = .medium, estimatedDuration: TimeInterval = 3600, recurrenceRule: RecurrenceRule) {
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.estimatedDuration = estimatedDuration
        self.tags = []
        self.recurrenceRule = recurrenceRule
        self.isActive = true
        self.nextDueDate = recurrenceRule.calculateNextDate(from: Date())
        self.createdAt = Date()
        self.lastGenerated = nil
        self.generatedTaskIds = []
        self.reminderEnabled = true
        self.reminderOffset = 3600
        self.color = "#0278fc"
        self.endDate = nil
    }
    
    var isOverdue: Bool {
        nextDueDate < Date() && isActive
    }
    
    var shouldGenerateTask: Bool {
        guard isActive else { return false }
        
        // Check if we haven't generated for this occurrence yet
        if let lastGenerated = lastGenerated {
            return nextDueDate > lastGenerated
        }
        
        return nextDueDate <= Date().addingTimeInterval(86400) // Generate 1 day in advance
    }
    
    var formattedNextDue: String {
        let formatter = DateFormatter()
        if Calendar.current.isDate(nextDueDate, inSameDayAs: Date()) {
            formatter.dateFormat = "HH:mm"
            return "Today at \(formatter.string(from: nextDueDate))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: nextDueDate)
        }
    }
    
    var categoryColor: Color {
        switch category {
        case .personal:
            return Color(hex: "#0278fc")
        case .work:
            return Color(hex: "#ee004a")
        case .health:
            return Color(hex: "#54b702")
        case .education:
            return Color(hex: "#d300ee")
        case .finance:
            return Color(hex: "#fff707")
        case .other:
            return Color.gray
        }
    }
    
    func generateTask() -> Task {
        let reminderTime = reminderEnabled ? nextDueDate.addingTimeInterval(-reminderOffset) : nil
        
        var task = Task(
            title: title,
            description: description,
            deadline: nextDueDate,
            priority: priority,
            category: category,
            estimatedDuration: estimatedDuration,
            reminderEnabled: reminderEnabled
        )
        
        task.reminderTime = reminderTime
        task.tags = tags + ["recurring"]
        
        return task
    }
    
    mutating func markGenerated(taskId: UUID) {
        generatedTaskIds.append(taskId)
        lastGenerated = Date()
        nextDueDate = recurrenceRule.calculateNextDate(from: nextDueDate)
    }
    
    mutating func updateNextDueDate() {
        nextDueDate = recurrenceRule.calculateNextDate(from: nextDueDate)
    }
}

struct RecurrenceRule: Codable, Hashable {
    var type: RecurrenceType
    var interval: Int // Every X days/weeks/months
    var daysOfWeek: [Int]? // For weekly recurrence (1=Sunday, 2=Monday, etc.)
    var dayOfMonth: Int? // For monthly recurrence
    var timeOfDay: Date // Time component only
    
    init(type: RecurrenceType, interval: Int = 1, timeOfDay: Date = Date()) {
        self.type = type
        self.interval = interval
        self.daysOfWeek = nil
        self.dayOfMonth = nil
        self.timeOfDay = timeOfDay
    }
    
    var description: String {
        switch type {
        case .daily:
            return interval == 1 ? "Daily" : "Every \(interval) days"
        case .weekly:
            if let days = daysOfWeek, !days.isEmpty {
                let dayNames = days.map { dayName(for: $0) }.joined(separator: ", ")
                return "Weekly on \(dayNames)"
            }
            return interval == 1 ? "Weekly" : "Every \(interval) weeks"
        case .monthly:
            if let day = dayOfMonth {
                return "Monthly on day \(day)"
            }
            return interval == 1 ? "Monthly" : "Every \(interval) months"
        case .yearly:
            return "Yearly"
        }
    }
    
    func calculateNextDate(from date: Date) -> Date {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeOfDay)
        
        switch type {
        case .daily:
            let nextDate = calendar.date(byAdding: .day, value: interval, to: date) ?? date
            return calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: nextDate) ?? nextDate
            
        case .weekly:
            if let daysOfWeek = daysOfWeek, !daysOfWeek.isEmpty {
                // Find next occurrence of specified weekdays
                let currentWeekday = calendar.component(.weekday, from: date)
                let nextWeekdays = daysOfWeek.filter { $0 > currentWeekday }
                
                if let nextWeekday = nextWeekdays.first {
                    let daysToAdd = nextWeekday - currentWeekday
                    let nextDate = calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
                    return calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: nextDate) ?? nextDate
                } else {
                    // Next week
                    let daysToAdd = 7 - currentWeekday + (daysOfWeek.first ?? 1)
                    let nextDate = calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
                    return calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: nextDate) ?? nextDate
                }
            } else {
                let nextDate = calendar.date(byAdding: .weekOfYear, value: interval, to: date) ?? date
                return calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: nextDate) ?? nextDate
            }
            
        case .monthly:
            let nextDate = calendar.date(byAdding: .month, value: interval, to: date) ?? date
            if let dayOfMonth = dayOfMonth {
                var components = calendar.dateComponents([.year, .month], from: nextDate)
                components.day = dayOfMonth
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute
                return calendar.date(from: components) ?? nextDate
            } else {
                return calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: nextDate) ?? nextDate
            }
            
        case .yearly:
            let nextDate = calendar.date(byAdding: .year, value: interval, to: date) ?? date
            return calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: nextDate) ?? nextDate
        }
    }
    
    private func dayName(for weekday: Int) -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[weekday - 1]
    }
}

enum RecurrenceType: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var icon: String {
        switch self {
        case .daily:
            return "calendar"
        case .weekly:
            return "calendar.badge.clock"
        case .monthly:
            return "calendar.badge.plus"
        case .yearly:
            return "calendar.badge.exclamationmark"
        }
    }
}

struct SmartTag: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var color: String
    var isAutoGenerated: Bool
    var keywords: [String] // For auto-tagging
    var usageCount: Int
    var createdAt: Date
    var category: TagCategory
    
    init(name: String, color: String = "#0278fc", isAutoGenerated: Bool = false, keywords: [String] = [], category: TagCategory = .custom) {
        self.name = name
        self.color = color
        self.isAutoGenerated = isAutoGenerated
        self.keywords = keywords
        self.usageCount = 0
        self.createdAt = Date()
        self.category = category
    }
    
    var tagColor: Color {
        Color(hex: color)
    }
    
    mutating func incrementUsage() {
        usageCount += 1
    }
    
    func matches(text: String) -> Bool {
        let lowercaseText = text.lowercased()
        return keywords.contains { lowercaseText.contains($0.lowercased()) }
    }
}

enum TagCategory: String, CaseIterable, Codable {
    case custom = "Custom"
    case auto = "Auto-generated"
    case system = "System"
    case project = "Project"
    case context = "Context"
    
    var color: Color {
        switch self {
        case .custom:
            return Color(hex: "#0278fc")
        case .auto:
            return Color(hex: "#54b702")
        case .system:
            return Color(hex: "#ee004a")
        case .project:
            return Color(hex: "#d300ee")
        case .context:
            return Color(hex: "#fff707")
        }
    }
}

struct SavedFilter: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var description: String
    var searchText: String?
    var selectedCategory: TaskCategory?
    var selectedPriority: TaskPriority?
    var tags: [String]
    var dateRange: DateRange?
    var completionStatus: CompletionStatus
    var createdAt: Date
    var usageCount: Int
    var icon: String
    var color: String
    
    init(name: String, description: String = "") {
        self.name = name
        self.description = description
        self.searchText = nil
        self.selectedCategory = nil
        self.selectedPriority = nil
        self.tags = []
        self.dateRange = nil
        self.completionStatus = .all
        self.createdAt = Date()
        self.usageCount = 0
        self.icon = "line.3.horizontal.decrease"
        self.color = "#0278fc"
    }
    
    mutating func incrementUsage() {
        usageCount += 1
    }
}

enum CompletionStatus: String, CaseIterable, Codable {
    case all = "All"
    case completed = "Completed"
    case pending = "Pending"
    case overdue = "Overdue"
    
    var icon: String {
        switch self {
        case .all:
            return "list.bullet"
        case .completed:
            return "checkmark.circle"
        case .pending:
            return "clock"
        case .overdue:
            return "exclamationmark.triangle"
        }
    }
}

enum DateRange: String, CaseIterable, Codable {
    case today = "Today"
    case tomorrow = "Tomorrow"
    case thisWeek = "This Week"
    case nextWeek = "Next Week"
    case thisMonth = "This Month"
    case custom = "Custom"
    
    var icon: String {
        switch self {
        case .today:
            return "calendar"
        case .tomorrow:
            return "calendar.badge.plus"
        case .thisWeek:
            return "calendar.badge.clock"
        case .nextWeek:
            return "calendar.badge.exclamationmark"
        case .thisMonth:
            return "calendar.circle"
        case .custom:
            return "calendar.badge.minus"
        }
    }
    
    func dateInterval() -> DateInterval? {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            return calendar.dateInterval(of: .day, for: now)
        case .tomorrow:
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return nil }
            return calendar.dateInterval(of: .day, for: tomorrow)
        case .thisWeek:
            return calendar.dateInterval(of: .weekOfYear, for: now)
        case .nextWeek:
            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: now) else { return nil }
            return calendar.dateInterval(of: .weekOfYear, for: nextWeek)
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: now)
        case .custom:
            return nil
        }
    }
}
