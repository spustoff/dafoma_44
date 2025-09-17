//
//  AdvancedAnalyticsModel.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import SwiftUI

struct AdvancedAnalytics: Codable {
    var heatMapData: [HeatMapPoint] = []
    var timeDistribution: [CategoryTimeData] = []
    var productivityPredictions: [ProductivityPrediction] = []
    var workloadForecasts: [WorkloadForecast] = []
    var comparisonData: [PeriodComparison] = []
    var focusTimeAnalysis: FocusTimeAnalysis = FocusTimeAnalysis()
    var habitAnalytics: HabitAnalytics = HabitAnalytics()
    var goalAnalytics: GoalAnalytics = GoalAnalytics()
    
    init() {}
}

struct HeatMapPoint: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let hour: Int
    var intensity: Double // 0.0 to 1.0
    var taskCount: Int
    var completedTasks: Int
    var focusTime: TimeInterval
    var productivityScore: Double
    
    init(date: Date, hour: Int) {
        self.date = date
        self.hour = hour
        self.intensity = 0.0
        self.taskCount = 0
        self.completedTasks = 0
        self.focusTime = 0
        self.productivityScore = 0.0
    }
    
    var heatColor: Color {
        let baseColor = Color(hex: "#0278fc")
        return baseColor.opacity(intensity)
    }
    
    var formattedHour: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let hourDate = Calendar.current.date(from: DateComponents(hour: hour)) ?? Date()
        return formatter.string(from: hourDate)
    }
}

struct CategoryTimeData: Identifiable, Codable {
    let id = UUID()
    let category: TaskCategory
    var totalTime: TimeInterval
    var averageTaskTime: TimeInterval
    var taskCount: Int
    var completionRate: Double
    var trendDirection: TrendDirection
    
    var percentage: Double = 0.0 // Will be calculated relative to total
    
    var formattedTotalTime: String {
        let hours = Int(totalTime) / 3600
        let minutes = Int(totalTime) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
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
}

enum TrendDirection: String, Codable {
    case increasing = "Increasing"
    case decreasing = "Decreasing"
    case stable = "Stable"
    
    var icon: String {
        switch self {
        case .increasing:
            return "arrow.up.right"
        case .decreasing:
            return "arrow.down.right"
        case .stable:
            return "arrow.right"
        }
    }
    
    var color: Color {
        switch self {
        case .increasing:
            return Color(hex: "#54b702")
        case .decreasing:
            return Color(hex: "#ee004a")
        case .stable:
            return Color(hex: "#0278fc")
        }
    }
}

struct ProductivityPrediction: Identifiable, Codable {
    let id = UUID()
    let date: Date
    var predictedProductivity: Double
    var predictedTaskCount: Int
    var predictedFocusTime: TimeInterval
    var confidence: Double // 0.0 to 1.0
    var factors: [PredictionFactor]
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var confidenceLevel: String {
        switch confidence {
        case 0.8...1.0:
            return "High"
        case 0.6..<0.8:
            return "Medium"
        default:
            return "Low"
        }
    }
}

struct PredictionFactor: Identifiable, Codable {
    let id = UUID()
    let name: String
    let impact: Double // -1.0 to 1.0
    let description: String
    
    var impactColor: Color {
        if impact > 0.3 {
            return Color(hex: "#54b702") // Positive
        } else if impact < -0.3 {
            return Color(hex: "#ee004a") // Negative
        } else {
            return Color(hex: "#fff707") // Neutral
        }
    }
}

struct WorkloadForecast: Identifiable, Codable {
    let id = UUID()
    let date: Date
    var scheduledTasks: Int
    var estimatedWorkload: TimeInterval
    var availableTime: TimeInterval
    var overloadRisk: Double // 0.0 to 1.0
    var recommendations: [String]
    
    var workloadLevel: WorkloadLevel {
        let ratio = estimatedWorkload / max(availableTime, 1)
        
        if ratio <= 0.7 {
            return .light
        } else if ratio <= 1.0 {
            return .optimal
        } else if ratio <= 1.3 {
            return .heavy
        } else {
            return .overloaded
        }
    }
    
    var formattedWorkload: String {
        let hours = Int(estimatedWorkload) / 3600
        let minutes = Int(estimatedWorkload) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
}

enum WorkloadLevel: String, CaseIterable {
    case light = "Light"
    case optimal = "Optimal"
    case heavy = "Heavy"
    case overloaded = "Overloaded"
    
    var color: Color {
        switch self {
        case .light:
            return Color(hex: "#54b702") // Green
        case .optimal:
            return Color(hex: "#0278fc") // Blue
        case .heavy:
            return Color(hex: "#fff707") // Yellow
        case .overloaded:
            return Color(hex: "#ee004a") // Red
        }
    }
    
    var icon: String {
        switch self {
        case .light:
            return "leaf"
        case .optimal:
            return "checkmark.circle"
        case .heavy:
            return "exclamationmark.triangle"
        case .overloaded:
            return "xmark.octagon"
        }
    }
}

struct PeriodComparison: Identifiable, Codable {
    let id = UUID()
    let currentPeriod: AnalyticsPeriod
    let previousPeriod: AnalyticsPeriod
    let comparisonType: ComparisonType
    
    var productivityChange: Double {
        guard previousPeriod.averageProductivity > 0 else { return 0 }
        return (currentPeriod.averageProductivity - previousPeriod.averageProductivity) / previousPeriod.averageProductivity
    }
    
    var taskCompletionChange: Double {
        guard previousPeriod.completedTasks > 0 else { return 0 }
        return (Double(currentPeriod.completedTasks - previousPeriod.completedTasks) / Double(previousPeriod.completedTasks))
    }
    
    var timeSpentChange: Double {
        guard previousPeriod.totalTimeSpent > 0 else { return 0 }
        return (currentPeriod.totalTimeSpent - previousPeriod.totalTimeSpent) / previousPeriod.totalTimeSpent
    }
}

struct AnalyticsPeriod: Codable {
    let startDate: Date
    let endDate: Date
    var completedTasks: Int
    var totalTasks: Int
    var totalTimeSpent: TimeInterval
    var averageProductivity: Double
    var focusTime: TimeInterval
    var pomodoroSessions: Int
    
    var completionRate: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    var formattedPeriod: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

enum ComparisonType: String, CaseIterable, Codable {
    case weekToWeek = "Week to Week"
    case monthToMonth = "Month to Month"
    case quarterToQuarter = "Quarter to Quarter"
    case yearToYear = "Year to Year"
    
    var icon: String {
        switch self {
        case .weekToWeek:
            return "calendar.badge.clock"
        case .monthToMonth:
            return "calendar.circle"
        case .quarterToQuarter:
            return "calendar.badge.plus"
        case .yearToYear:
            return "calendar.badge.exclamationmark"
        }
    }
}

struct FocusTimeAnalysis: Codable {
    var totalFocusTime: TimeInterval = 0
    var averageFocusSession: TimeInterval = 0
    var longestFocusSession: TimeInterval = 0
    var focusStreakDays: Int = 0
    var bestFocusDay: Date?
    var focusTimeByHour: [Int: TimeInterval] = [:] // Hour -> Total focus time
    var focusTimeByDay: [Int: TimeInterval] = [:] // Weekday -> Total focus time
    var distractionCount: Int = 0
    var averageSessionsPerDay: Double = 0
    
    var formattedTotalFocusTime: String {
        let hours = Int(totalFocusTime) / 3600
        let minutes = Int(totalFocusTime) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
    
    var mostProductiveHour: Int {
        focusTimeByHour.max(by: { $0.value < $1.value })?.key ?? 9
    }
    
    var mostProductiveDay: Int {
        focusTimeByDay.max(by: { $0.value < $1.value })?.key ?? 2 // Tuesday
    }
}

struct HabitAnalytics: Codable {
    var totalHabits: Int = 0
    var activeHabits: Int = 0
    var averageCompletionRate: Double = 0
    var longestStreak: Int = 0
    var currentActiveStreaks: Int = 0
    var habitsByCategory: [HabitCategory: Int] = [:]
    var weeklyProgress: Double = 0
    var monthlyProgress: Double = 0
    var bestHabitDay: Date?
    var habitCompletionTrends: [HabitTrendData] = []
    
    var activeHabitsPercentage: Int {
        guard totalHabits > 0 else { return 0 }
        return Int((Double(activeHabits) / Double(totalHabits)) * 100)
    }
}

struct HabitTrendData: Identifiable, Codable {
    let id = UUID()
    let date: Date
    var completedHabits: Int
    var totalActiveHabits: Int
    var completionRate: Double
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct GoalAnalytics: Codable {
    var totalGoals: Int = 0
    var activeGoals: Int = 0
    var completedGoals: Int = 0
    var averageProgress: Double = 0
    var goalsOnTrack: Int = 0
    var goalsAtRisk: Int = 0
    var goalsByCategory: [GoalCategory: Int] = [:]
    var averageCompletionTime: TimeInterval = 0
    var goalCompletionTrends: [GoalTrendData] = []
    
    var completionRate: Double {
        guard totalGoals > 0 else { return 0 }
        return Double(completedGoals) / Double(totalGoals)
    }
    
    var onTrackPercentage: Int {
        guard activeGoals > 0 else { return 0 }
        return Int((Double(goalsOnTrack) / Double(activeGoals)) * 100)
    }
}

struct GoalTrendData: Identifiable, Codable {
    let id = UUID()
    let date: Date
    var averageProgress: Double
    var completedGoals: Int
    var newGoals: Int
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
