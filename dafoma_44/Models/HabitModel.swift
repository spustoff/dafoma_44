//
//  HabitModel.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import SwiftUI

struct Habit: Identifiable, Codable, Hashable {
    let id = UUID()
    var title: String
    var description: String
    var category: HabitCategory
    var frequency: HabitFrequency
    var targetValue: Double // For measurable habits (e.g., 8 glasses of water)
    var unit: String // "times", "minutes", "glasses", etc.
    var reminderTime: Date?
    var reminderEnabled: Bool
    var isActive: Bool
    var createdAt: Date
    var color: String
    var icon: String
    var streakCount: Int
    var bestStreak: Int
    var completions: [HabitCompletion]
    var notes: String
    
    init(title: String, description: String = "", category: HabitCategory = .health, frequency: HabitFrequency = .daily, targetValue: Double = 1, unit: String = "times") {
        self.title = title
        self.description = description
        self.category = category
        self.frequency = frequency
        self.targetValue = targetValue
        self.unit = unit
        self.reminderTime = nil
        self.reminderEnabled = false
        self.isActive = true
        self.createdAt = Date()
        self.color = "#54b702"
        self.icon = "checkmark.circle"
        self.streakCount = 0
        self.bestStreak = 0
        self.completions = []
        self.notes = ""
    }
    
    var todaysCompletion: HabitCompletion? {
        let today = Calendar.current.startOfDay(for: Date())
        return completions.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    var todaysProgress: Double {
        todaysCompletion?.value ?? 0
    }
    
    var todaysProgressPercentage: Int {
        guard targetValue > 0 else { return 0 }
        return Int((todaysProgress / targetValue) * 100)
    }
    
    var isCompletedToday: Bool {
        todaysProgress >= targetValue
    }
    
    var categoryColor: Color {
        category.color
    }
    
    var habitColor: Color {
        Color(hex: color)
    }
    
    var currentStreak: Int {
        calculateCurrentStreak()
    }
    
    var weeklyProgress: Double {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let weekCompletions = completions.filter { $0.date >= weekStart }
        
        switch frequency {
        case .daily:
            return Double(weekCompletions.filter { $0.value >= targetValue }.count) / 7.0
        case .weekly:
            return weekCompletions.reduce(0) { $0 + $1.value } / targetValue
        case .custom(let days):
            return Double(weekCompletions.filter { $0.value >= targetValue }.count) / Double(days)
        }
    }
    
    var monthlyProgress: Double {
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        let monthCompletions = completions.filter { $0.date >= monthStart }
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: Date())?.count ?? 30
        
        switch frequency {
        case .daily:
            return Double(monthCompletions.filter { $0.value >= targetValue }.count) / Double(daysInMonth)
        case .weekly:
            return Double(monthCompletions.filter { $0.value >= targetValue }.count) / 4.0 // 4 weeks
        case .custom(let days):
            let expectedCompletions = daysInMonth / days
            return Double(monthCompletions.filter { $0.value >= targetValue }.count) / Double(expectedCompletions)
        }
    }
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        while true {
            if let completion = completions.first(where: { calendar.isDate($0.date, inSameDayAs: currentDate) }),
               completion.value >= targetValue {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    mutating func recordCompletion(value: Double = 1.0, date: Date = Date()) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        if let existingIndex = completions.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: dayStart) }) {
            completions[existingIndex].value += value
            completions[existingIndex].value = min(targetValue, completions[existingIndex].value)
        } else {
            let completion = HabitCompletion(date: dayStart, value: min(targetValue, value))
            completions.append(completion)
        }
        
        // Update streaks
        streakCount = calculateCurrentStreak()
        bestStreak = max(bestStreak, streakCount)
        
        // Sort completions by date
        completions.sort { $0.date > $1.date }
    }
    
    mutating func removeCompletion(for date: Date) {
        let calendar = Calendar.current
        completions.removeAll { calendar.isDate($0.date, inSameDayAs: date) }
        streakCount = calculateCurrentStreak()
    }
    
    func shouldShowReminderToday() -> Bool {
        guard isActive && reminderEnabled else { return false }
        return !isCompletedToday
    }
}

struct HabitCompletion: Identifiable, Codable, Hashable {
    let id = UUID()
    let date: Date
    var value: Double
    var notes: String?
    
    init(date: Date, value: Double, notes: String? = nil) {
        self.date = date
        self.value = value
        self.notes = notes
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

enum HabitFrequency: Codable, Hashable {
    case daily
    case weekly
    case custom(days: Int) // Every X days
    
    var description: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .custom(let days):
            return "Every \(days) days"
        }
    }
    
    var icon: String {
        switch self {
        case .daily:
            return "calendar"
        case .weekly:
            return "calendar.badge.clock"
        case .custom:
            return "calendar.badge.plus"
        }
    }
}

enum HabitCategory: String, CaseIterable, Codable {
    case health = "Health"
    case productivity = "Productivity"
    case learning = "Learning"
    case mindfulness = "Mindfulness"
    case social = "Social"
    case creativity = "Creativity"
    case finance = "Finance"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .health:
            return "heart.fill"
        case .productivity:
            return "bolt.fill"
        case .learning:
            return "book.fill"
        case .mindfulness:
            return "leaf.fill"
        case .social:
            return "person.2.fill"
        case .creativity:
            return "paintbrush.fill"
        case .finance:
            return "dollarsign.circle.fill"
        case .other:
            return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .health:
            return Color(hex: "#54b702") // Green
        case .productivity:
            return Color(hex: "#0278fc") // Blue
        case .learning:
            return Color(hex: "#d300ee") // Purple
        case .mindfulness:
            return Color(hex: "#00d4aa") // Teal
        case .social:
            return Color(hex: "#fd79a8") // Pink
        case .creativity:
            return Color(hex: "#6c5ce7") // Violet
        case .finance:
            return Color(hex: "#fff707") // Yellow
        case .other:
            return Color.gray
        }
    }
}

struct HabitStats {
    let totalHabits: Int
    let activeHabits: Int
    let completedToday: Int
    let averageStreak: Double
    let longestStreak: Int
    let completionRate: Double
    let categoryBreakdown: [HabitCategory: Int]
    
    var completedTodayPercentage: Int {
        guard activeHabits > 0 else { return 0 }
        return Int((Double(completedToday) / Double(activeHabits)) * 100)
    }
}
