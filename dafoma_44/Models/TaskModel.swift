//
//  TaskModel.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import SwiftUI

struct Task: Identifiable, Codable, Hashable {
    let id = UUID()
    var title: String
    var description: String
    var deadline: Date
    var isCompleted: Bool
    var priority: TaskPriority
    var category: TaskCategory
    var estimatedDuration: TimeInterval // in seconds
    var actualTimeSpent: TimeInterval // in seconds
    var createdAt: Date
    var completedAt: Date?
    var reminderEnabled: Bool
    var reminderTime: Date?
    var tags: [String]
    var notes: [String] // Related note IDs
    
    init(title: String, description: String = "", deadline: Date, priority: TaskPriority = .medium, category: TaskCategory = .personal, estimatedDuration: TimeInterval = 3600, reminderEnabled: Bool = true) {
        self.title = title
        self.description = description
        self.deadline = deadline
        self.isCompleted = false
        self.priority = priority
        self.category = category
        self.estimatedDuration = estimatedDuration
        self.actualTimeSpent = 0
        self.createdAt = Date()
        self.completedAt = nil
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderEnabled ? Calendar.current.date(byAdding: .hour, value: -1, to: deadline) : nil
        self.tags = []
        self.notes = []
    }
    
    var isOverdue: Bool {
        !isCompleted && deadline < Date()
    }
    
    var isDueToday: Bool {
        Calendar.current.isDate(deadline, inSameDayAs: Date())
    }
    
    var isDueTomorrow: Bool {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else { return false }
        return Calendar.current.isDate(deadline, inSameDayAs: tomorrow)
    }
    
    var timeUntilDeadline: TimeInterval {
        deadline.timeIntervalSinceNow
    }
    
    var formattedDeadline: String {
        let formatter = DateFormatter()
        if Calendar.current.isDate(deadline, inSameDayAs: Date()) {
            formatter.dateFormat = "HH:mm"
            return "Today at \(formatter.string(from: deadline))"
        } else if isDueTomorrow {
            formatter.dateFormat = "HH:mm"
            return "Tomorrow at \(formatter.string(from: deadline))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: deadline)
        }
    }
    
    var priorityColor: Color {
        switch priority {
        case .low:
            return Color(hex: "#54b702") // Green
        case .medium:
            return Color(hex: "#fff707") // Yellow
        case .high:
            return Color(hex: "#ee004a") // Red
        case .critical:
            return Color(hex: "#d300ee") // Purple
        }
    }
    
    var categoryColor: Color {
        switch category {
        case .personal:
            return Color(hex: "#0278fc") // Blue
        case .work:
            return Color(hex: "#ee004a") // Red
        case .health:
            return Color(hex: "#54b702") // Green
        case .education:
            return Color(hex: "#d300ee") // Purple
        case .finance:
            return Color(hex: "#fff707") // Yellow
        case .other:
            return Color.gray
        }
    }
    
    mutating func markCompleted() {
        isCompleted = true
        completedAt = Date()
    }
    
    mutating func markIncomplete() {
        isCompleted = false
        completedAt = nil
    }
    
    mutating func addTimeSpent(_ time: TimeInterval) {
        actualTimeSpent += time
    }
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var icon: String {
        switch self {
        case .low:
            return "arrow.down.circle"
        case .medium:
            return "minus.circle"
        case .high:
            return "arrow.up.circle"
        case .critical:
            return "exclamationmark.triangle"
        }
    }
}

enum TaskCategory: String, CaseIterable, Codable {
    case personal = "Personal"
    case work = "Work"
    case health = "Health"
    case education = "Education"
    case finance = "Finance"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .personal:
            return "person.fill"
        case .work:
            return "briefcase.fill"
        case .health:
            return "heart.fill"
        case .education:
            return "book.fill"
        case .finance:
            return "dollarsign.circle.fill"
        case .other:
            return "folder.fill"
        }
    }
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}



