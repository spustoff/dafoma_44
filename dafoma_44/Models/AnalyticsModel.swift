//
//  AnalyticsModel.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import SwiftUI

struct AnalyticsData: Codable {
    var dailyStats: [DailyStats]
    var weeklyStats: [WeeklyStats]
    var monthlyStats: [MonthlyStats]
    var productivityScore: Double
    var streakCount: Int
    var totalTasksCompleted: Int
    var totalTimeTracked: TimeInterval
    var averageTaskCompletionTime: TimeInterval
    var mostProductiveHour: Int
    var mostProductiveDay: Int // 0 = Sunday, 1 = Monday, etc.
    var categoryBreakdown: [TaskCategory: CategoryStats]
    var priorityBreakdown: [TaskPriority: PriorityStats]
    
    init() {
        self.dailyStats = []
        self.weeklyStats = []
        self.monthlyStats = []
        self.productivityScore = 0.0
        self.streakCount = 0
        self.totalTasksCompleted = 0
        self.totalTimeTracked = 0
        self.averageTaskCompletionTime = 0
        self.mostProductiveHour = 9
        self.mostProductiveDay = 2 // Tuesday
        self.categoryBreakdown = [:]
        self.priorityBreakdown = [:]
    }
}

struct DailyStats: Identifiable, Codable {
    let id = UUID()
    let date: Date
    var tasksCompleted: Int
    var tasksCreated: Int
    var timeSpent: TimeInterval
    var productivityScore: Double
    var focusTime: TimeInterval
    var breakTime: TimeInterval
    var notesCreated: Int
    var goalsAchieved: Int
    
    init(date: Date) {
        self.date = date
        self.tasksCompleted = 0
        self.tasksCreated = 0
        self.timeSpent = 0
        self.productivityScore = 0.0
        self.focusTime = 0
        self.breakTime = 0
        self.notesCreated = 0
        self.goalsAchieved = 0
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    var completionRate: Double {
        guard tasksCreated > 0 else { return 0 }
        return Double(tasksCompleted) / Double(tasksCreated)
    }
    
    var formattedTimeSpent: String {
        let hours = Int(timeSpent) / 3600
        let minutes = Int(timeSpent) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
}

struct WeeklyStats: Identifiable, Codable {
    let id = UUID()
    let weekStartDate: Date
    var totalTasksCompleted: Int
    var totalTasksCreated: Int
    var totalTimeSpent: TimeInterval
    var averageProductivityScore: Double
    var dailyAverageTasksCompleted: Double
    var bestDay: Date?
    var worstDay: Date?
    var weeklyGoalsAchieved: Int
    var weeklyGoalsSet: Int
    
    init(weekStartDate: Date) {
        self.weekStartDate = weekStartDate
        self.totalTasksCompleted = 0
        self.totalTasksCreated = 0
        self.totalTimeSpent = 0
        self.averageProductivityScore = 0.0
        self.dailyAverageTasksCompleted = 0.0
        self.bestDay = nil
        self.worstDay = nil
        self.weeklyGoalsAchieved = 0
        self.weeklyGoalsSet = 0
    }
    
    var weekRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate
        return "\(formatter.string(from: weekStartDate)) - \(formatter.string(from: endDate))"
    }
    
    var completionRate: Double {
        guard totalTasksCreated > 0 else { return 0 }
        return Double(totalTasksCompleted) / Double(totalTasksCreated)
    }
}

struct MonthlyStats: Identifiable, Codable {
    let id = UUID()
    let month: Int
    let year: Int
    var totalTasksCompleted: Int
    var totalTasksCreated: Int
    var totalTimeSpent: TimeInterval
    var averageProductivityScore: Double
    var bestWeek: Date?
    var worstWeek: Date?
    var monthlyGoalsAchieved: Int
    var monthlyGoalsSet: Int
    var streakDays: Int
    
    init(month: Int, year: Int) {
        self.month = month
        self.year = year
        self.totalTasksCompleted = 0
        self.totalTasksCreated = 0
        self.totalTimeSpent = 0
        self.averageProductivityScore = 0.0
        self.bestWeek = nil
        self.worstWeek = nil
        self.monthlyGoalsAchieved = 0
        self.monthlyGoalsSet = 0
        self.streakDays = 0
    }
    
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let date = Calendar.current.date(from: DateComponents(year: year, month: month)) ?? Date()
        return formatter.string(from: date)
    }
    
    var completionRate: Double {
        guard totalTasksCreated > 0 else { return 0 }
        return Double(totalTasksCompleted) / Double(totalTasksCreated)
    }
}

struct CategoryStats: Codable {
    var tasksCompleted: Int
    var tasksCreated: Int
    var timeSpent: TimeInterval
    var averageCompletionTime: TimeInterval
    
    init() {
        self.tasksCompleted = 0
        self.tasksCreated = 0
        self.timeSpent = 0
        self.averageCompletionTime = 0
    }
    
    var completionRate: Double {
        guard tasksCreated > 0 else { return 0 }
        return Double(tasksCompleted) / Double(tasksCreated)
    }
    
    var percentage: Double {
        // This will be calculated relative to total stats
        return 0.0
    }
}

struct PriorityStats: Codable {
    var tasksCompleted: Int
    var tasksCreated: Int
    var averageCompletionTime: TimeInterval
    var onTimeCompletionRate: Double
    
    init() {
        self.tasksCompleted = 0
        self.tasksCreated = 0
        self.averageCompletionTime = 0
        self.onTimeCompletionRate = 0.0
    }
    
    var completionRate: Double {
        guard tasksCreated > 0 else { return 0 }
        return Double(tasksCompleted) / Double(tasksCreated)
    }
}

struct ProductivityInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: InsightType
    let value: Double
    let trend: TrendDirection
    let actionable: Bool
    let recommendation: String?
    
    enum InsightType {
        case productivity
        case timeManagement
        case taskCompletion
        case focus
        case balance
    }
    
    enum TrendDirection {
        case up
        case down
        case stable
        
        var icon: String {
            switch self {
            case .up:
                return "arrow.up.right"
            case .down:
                return "arrow.down.right"
            case .stable:
                return "arrow.right"
            }
        }
        
        var color: Color {
            switch self {
            case .up:
                return Color(hex: "#54b702") // Green
            case .down:
                return Color(hex: "#ee004a") // Red
            case .stable:
                return Color(hex: "#0278fc") // Blue
            }
        }
    }
}

struct TimeSlot: Identifiable, Codable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    var taskId: UUID?
    var title: String
    var isCompleted: Bool
    var category: TaskCategory
    
    init(startTime: Date, endTime: Date, title: String = "", category: TaskCategory = .personal) {
        self.startTime = startTime
        self.endTime = endTime
        self.title = title
        self.isCompleted = false
        self.category = category
        self.taskId = nil
    }
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    var isActive: Bool {
        let now = Date()
        return now >= startTime && now <= endTime
    }
    
    var isPast: Bool {
        Date() > endTime
    }
    
    var isFuture: Bool {
        Date() < startTime
    }
}



