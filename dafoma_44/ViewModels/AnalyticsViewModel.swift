//
//  AnalyticsViewModel.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import SwiftUI

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var analytics: AnalyticsData = AnalyticsData()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTimeRange: TimeRange = .week
    @Published var selectedMetric: AnalyticsMetric = .productivity
    
    private let dataService = DataPersistenceService.shared
    private var tasks: [Task] = []
    private var notes: [Note] = []
    
    enum TimeRange: String, CaseIterable {
        case day = "Today"
        case week = "This Week"
        case month = "This Month"
        case year = "This Year"
        case all = "All Time"
        
        var systemImage: String {
            switch self {
            case .day:
                return "calendar"
            case .week:
                return "calendar.badge.clock"
            case .month:
                return "calendar.badge.plus"
            case .year:
                return "calendar.badge.exclamationmark"
            case .all:
                return "infinity"
            }
        }
    }
    
    enum AnalyticsMetric: String, CaseIterable {
        case productivity = "Productivity"
        case timeSpent = "Time Spent"
        case taskCompletion = "Task Completion"
        case categories = "Categories"
        case priorities = "Priorities"
        case trends = "Trends"
        
        var systemImage: String {
            switch self {
            case .productivity:
                return "chart.line.uptrend.xyaxis"
            case .timeSpent:
                return "clock.fill"
            case .taskCompletion:
                return "checkmark.circle.fill"
            case .categories:
                return "folder.fill"
            case .priorities:
                return "exclamationmark.triangle.fill"
            case .trends:
                return "chart.xyaxis.line"
            }
        }
    }
    
    init() {
        loadAnalytics()
        loadTasksAndNotes()
        calculateAnalytics()
    }
    
    // MARK: - Data Loading
    
    func loadAnalytics() {
        isLoading = true
        errorMessage = nil
        
        analytics = dataService.loadAnalytics()
        print("✅ Analytics loaded")
        
        isLoading = false
    }
    
    func saveAnalytics() {
        dataService.saveAnalytics(analytics)
        print("✅ Analytics saved")
    }
    
    private func loadTasksAndNotes() {
        tasks = dataService.loadTasks()
        notes = dataService.loadNotes()
    }
    
    // MARK: - Analytics Calculation
    
    func calculateAnalytics() {
        updateDailyStats()
        updateWeeklyStats()
        updateMonthlyStats()
        updateCategoryBreakdown()
        updatePriorityBreakdown()
        calculateProductivityScore()
        calculateStreaks()
        updateTotals()
    }
    
    private func updateDailyStats() {
        let calendar = Calendar.current
        let today = Date()
        
        // Update or create today's stats
        if let todayIndex = analytics.dailyStats.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            updateDailyStats(at: todayIndex, for: today)
        } else {
            var todayStats = DailyStats(date: today)
            updateDailyStatsData(&todayStats, for: today)
            analytics.dailyStats.insert(todayStats, at: 0)
        }
        
        // Keep only last 30 days
        analytics.dailyStats = Array(analytics.dailyStats.prefix(30))
    }
    
    private func updateDailyStats(at index: Int, for date: Date) {
        updateDailyStatsData(&analytics.dailyStats[index], for: date)
    }
    
    private func updateDailyStatsData(_ stats: inout DailyStats, for date: Date) {
        let calendar = Calendar.current
        let dayTasks = tasks.filter { calendar.isDate($0.createdAt, inSameDayAs: date) || calendar.isDate($0.deadline, inSameDayAs: date) }
        
        stats.tasksCompleted = dayTasks.filter { $0.isCompleted && calendar.isDate($0.completedAt ?? date, inSameDayAs: date) }.count
        stats.tasksCreated = dayTasks.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }.count
        stats.timeSpent = dayTasks.reduce(0) { $0 + $1.actualTimeSpent }
        stats.notesCreated = notes.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }.count
        
        // Calculate productivity score based on completion rate and time efficiency
        let completionRate = stats.tasksCreated > 0 ? Double(stats.tasksCompleted) / Double(stats.tasksCreated) : 0
        let timeEfficiency = calculateTimeEfficiency(for: dayTasks)
        stats.productivityScore = (completionRate * 0.7) + (timeEfficiency * 0.3)
    }
    
    private func updateWeeklyStats() {
        let calendar = Calendar.current
        let now = Date()
        
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return }
        
        if let weekIndex = analytics.weeklyStats.firstIndex(where: { calendar.isDate($0.weekStartDate, inSameDayAs: weekStart) }) {
            updateWeeklyStats(at: weekIndex, for: weekStart)
        } else {
            var weekStats = WeeklyStats(weekStartDate: weekStart)
            updateWeeklyStatsData(&weekStats, for: weekStart)
            analytics.weeklyStats.insert(weekStats, at: 0)
        }
        
        // Keep only last 12 weeks
        analytics.weeklyStats = Array(analytics.weeklyStats.prefix(12))
    }
    
    private func updateWeeklyStats(at index: Int, for weekStart: Date) {
        updateWeeklyStatsData(&analytics.weeklyStats[index], for: weekStart)
    }
    
    private func updateWeeklyStatsData(_ stats: inout WeeklyStats, for weekStart: Date) {
        let calendar = Calendar.current
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else { return }
        
        let weekTasks = tasks.filter { task in
            task.createdAt >= weekStart && task.createdAt <= weekEnd ||
            task.deadline >= weekStart && task.deadline <= weekEnd
        }
        
        stats.totalTasksCompleted = weekTasks.filter { $0.isCompleted }.count
        stats.totalTasksCreated = weekTasks.filter { $0.createdAt >= weekStart && $0.createdAt <= weekEnd }.count
        stats.totalTimeSpent = weekTasks.reduce(0) { $0 + $1.actualTimeSpent }
        
        let dailyProductivityScores = analytics.dailyStats
            .filter { $0.date >= weekStart && $0.date <= weekEnd }
            .map { $0.productivityScore }
        
        stats.averageProductivityScore = dailyProductivityScores.isEmpty ? 0 : dailyProductivityScores.reduce(0, +) / Double(dailyProductivityScores.count)
        stats.dailyAverageTasksCompleted = Double(stats.totalTasksCompleted) / 7.0
    }
    
    private func updateMonthlyStats() {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        if let monthIndex = analytics.monthlyStats.firstIndex(where: { $0.month == currentMonth && $0.year == currentYear }) {
            updateMonthlyStats(at: monthIndex, for: currentMonth, year: currentYear)
        } else {
            var monthStats = MonthlyStats(month: currentMonth, year: currentYear)
            updateMonthlyStatsData(&monthStats, for: currentMonth, year: currentYear)
            analytics.monthlyStats.insert(monthStats, at: 0)
        }
        
        // Keep only last 12 months
        analytics.monthlyStats = Array(analytics.monthlyStats.prefix(12))
    }
    
    private func updateMonthlyStats(at index: Int, for month: Int, year: Int) {
        updateMonthlyStatsData(&analytics.monthlyStats[index], for: month, year: year)
    }
    
    private func updateMonthlyStatsData(_ stats: inout MonthlyStats, for month: Int, year: Int) {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else { return }
        
        let monthTasks = tasks.filter { task in
            task.createdAt >= monthStart && task.createdAt <= monthEnd ||
            task.deadline >= monthStart && task.deadline <= monthEnd
        }
        
        stats.totalTasksCompleted = monthTasks.filter { $0.isCompleted }.count
        stats.totalTasksCreated = monthTasks.filter { $0.createdAt >= monthStart && $0.createdAt <= monthEnd }.count
        stats.totalTimeSpent = monthTasks.reduce(0) { $0 + $1.actualTimeSpent }
        
        let monthlyProductivityScores = analytics.dailyStats
            .filter { $0.date >= monthStart && $0.date <= monthEnd }
            .map { $0.productivityScore }
        
        stats.averageProductivityScore = monthlyProductivityScores.isEmpty ? 0 : monthlyProductivityScores.reduce(0, +) / Double(monthlyProductivityScores.count)
    }
    
    private func updateCategoryBreakdown() {
        analytics.categoryBreakdown = [:]
        
        for category in TaskCategory.allCases {
            let categoryTasks = tasks.filter { $0.category == category }
            var categoryStats = CategoryStats()
            categoryStats.tasksCompleted = categoryTasks.filter { $0.isCompleted }.count
            categoryStats.tasksCreated = categoryTasks.count
            categoryStats.timeSpent = categoryTasks.reduce(0) { $0 + $1.actualTimeSpent }
            categoryStats.averageCompletionTime = categoryStats.tasksCompleted > 0 ? 
                categoryTasks.filter { $0.isCompleted }.reduce(0) { total, task in
                    if let completedAt = task.completedAt {
                        return total + completedAt.timeIntervalSince(task.createdAt)
                    }
                    return total
                } / Double(categoryStats.tasksCompleted) : 0
            
            analytics.categoryBreakdown[category] = categoryStats
        }
    }
    
    private func updatePriorityBreakdown() {
        analytics.priorityBreakdown = [:]
        
        for priority in TaskPriority.allCases {
            let priorityTasks = tasks.filter { $0.priority == priority }
            var priorityStats = PriorityStats()
            priorityStats.tasksCompleted = priorityTasks.filter { $0.isCompleted }.count
            priorityStats.tasksCreated = priorityTasks.count
            priorityStats.averageCompletionTime = priorityStats.tasksCompleted > 0 ?
                priorityTasks.filter { $0.isCompleted }.reduce(0) { total, task in
                    if let completedAt = task.completedAt {
                        return total + completedAt.timeIntervalSince(task.createdAt)
                    }
                    return total
                } / Double(priorityStats.tasksCompleted) : 0
            
            let onTimeTasks = priorityTasks.filter { task in
                task.isCompleted && (task.completedAt ?? Date()) <= task.deadline
            }
            priorityStats.onTimeCompletionRate = priorityStats.tasksCompleted > 0 ? 
                Double(onTimeTasks.count) / Double(priorityStats.tasksCompleted) : 0
            
            analytics.priorityBreakdown[priority] = priorityStats
        }
    }
    
    private func calculateProductivityScore() {
        let recentDays = Array(analytics.dailyStats.prefix(7))
        let totalScore = recentDays.reduce(0) { $0 + $1.productivityScore }
        analytics.productivityScore = recentDays.isEmpty ? 0 : totalScore / Double(recentDays.count)
    }
    
    private func calculateStreaks() {
        let sortedDays = analytics.dailyStats.sorted { $0.date > $1.date }
        var currentStreak = 0
        let calendar = Calendar.current
        
        for (index, day) in sortedDays.enumerated() {
            if day.tasksCompleted > 0 && day.productivityScore > 0.5 {
                if index == 0 || calendar.dateInterval(of: .day, for: sortedDays[index-1].date)?.end == calendar.dateInterval(of: .day, for: day.date)?.start {
                    currentStreak += 1
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        analytics.streakCount = currentStreak
    }
    
    private func updateTotals() {
        analytics.totalTasksCompleted = tasks.filter { $0.isCompleted }.count
        analytics.totalTimeTracked = tasks.reduce(0) { $0 + $1.actualTimeSpent }
        
        let completedTasks = tasks.filter { $0.isCompleted }
        analytics.averageTaskCompletionTime = completedTasks.isEmpty ? 0 : 
            completedTasks.reduce(0) { total, task in
                if let completedAt = task.completedAt {
                    return total + completedAt.timeIntervalSince(task.createdAt)
                }
                return total
            } / Double(completedTasks.count)
        
        // Find most productive hour and day
        updateMostProductiveTime()
    }
    
    private func updateMostProductiveTime() {
        let calendar = Calendar.current
        var hourCounts: [Int: Int] = [:]
        var dayCounts: [Int: Int] = [:]
        
        for task in tasks.filter({ $0.isCompleted }) {
            if let completedAt = task.completedAt {
                let hour = calendar.component(.hour, from: completedAt)
                let weekday = calendar.component(.weekday, from: completedAt)
                
                hourCounts[hour, default: 0] += 1
                dayCounts[weekday, default: 0] += 1
            }
        }
        
        analytics.mostProductiveHour = hourCounts.max(by: { $0.value < $1.value })?.key ?? 9
        analytics.mostProductiveDay = dayCounts.max(by: { $0.value < $1.value })?.key ?? 2
    }
    
    private func calculateTimeEfficiency(for tasks: [Task]) -> Double {
        let completedTasks = tasks.filter { $0.isCompleted && $0.actualTimeSpent > 0 }
        guard !completedTasks.isEmpty else { return 0.5 }
        
        let efficiencyScores = completedTasks.map { task -> Double in
            let efficiency = task.estimatedDuration / task.actualTimeSpent
            return min(1.0, max(0.0, efficiency))
        }
        
        return efficiencyScores.reduce(0, +) / Double(efficiencyScores.count)
    }
    
    // MARK: - Insights Generation
    
    func generateInsights() -> [ProductivityInsight] {
        var insights: [ProductivityInsight] = []
        
        // Productivity trend insight
        if analytics.dailyStats.count >= 7 {
            let recentWeek = Array(analytics.dailyStats.prefix(7))
            let previousWeek = Array(analytics.dailyStats.dropFirst(7).prefix(7))
            
            if !previousWeek.isEmpty {
                let recentAvg = recentWeek.reduce(0) { $0 + $1.productivityScore } / Double(recentWeek.count)
                let previousAvg = previousWeek.reduce(0) { $0 + $1.productivityScore } / Double(previousWeek.count)
                let change = recentAvg - previousAvg
                
                let trend: ProductivityInsight.TrendDirection = change > 0.05 ? .up : (change < -0.05 ? .down : .stable)
                let changePercent = abs(change * 100)
                
                insights.append(ProductivityInsight(
                    title: "Productivity Trend",
                    description: trend == .up ? "Your productivity increased by \(String(format: "%.1f", changePercent))% this week!" :
                                trend == .down ? "Your productivity decreased by \(String(format: "%.1f", changePercent))% this week." :
                                "Your productivity remained stable this week.",
                    type: .productivity,
                    value: recentAvg,
                    trend: trend,
                    actionable: trend == .down,
                    recommendation: trend == .down ? "Consider reviewing your task priorities and time management strategies." : nil
                ))
            }
        }
        
        // Task completion insight
        let completionRate = analytics.totalTasksCompleted > 0 ? 
            Double(analytics.totalTasksCompleted) / Double(tasks.count) : 0
        
        insights.append(ProductivityInsight(
            title: "Task Completion Rate",
            description: "You complete \(String(format: "%.0f", completionRate * 100))% of your tasks on average.",
            type: .taskCompletion,
            value: completionRate,
            trend: completionRate >= 0.8 ? .up : (completionRate >= 0.6 ? .stable : .down),
            actionable: completionRate < 0.7,
            recommendation: completionRate < 0.7 ? "Try breaking large tasks into smaller, manageable chunks." : nil
        ))
        
        // Time management insight
        let overdueTasks = tasks.filter { $0.isOverdue && !$0.isCompleted }
        if !overdueTasks.isEmpty {
            insights.append(ProductivityInsight(
                title: "Overdue Tasks",
                description: "You have \(overdueTasks.count) overdue task\(overdueTasks.count == 1 ? "" : "s").",
                type: .timeManagement,
                value: Double(overdueTasks.count),
                trend: .down,
                actionable: true,
                recommendation: "Consider rescheduling or breaking down overdue tasks to make them more manageable."
            ))
        }
        
        // Most productive time insight
        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "h a"
        let productiveHour = Calendar.current.date(from: DateComponents(hour: analytics.mostProductiveHour)) ?? Date()
        
        insights.append(ProductivityInsight(
            title: "Peak Productivity",
            description: "You're most productive around \(hourFormatter.string(from: productiveHour)).",
            type: .focus,
            value: Double(analytics.mostProductiveHour),
            trend: .stable,
            actionable: true,
            recommendation: "Schedule your most important tasks during your peak productivity hours."
        ))
        
        return insights
    }
    
    // MARK: - Data for Charts
    
    var productivityChartData: [ChartDataPoint] {
        let filteredStats = getFilteredDailyStats()
        return filteredStats.map { stats in
            ChartDataPoint(
                date: stats.date,
                value: stats.productivityScore,
                label: String(format: "%.1f%%", stats.productivityScore * 100)
            )
        }
    }
    
    var taskCompletionChartData: [ChartDataPoint] {
        let filteredStats = getFilteredDailyStats()
        return filteredStats.map { stats in
            ChartDataPoint(
                date: stats.date,
                value: Double(stats.tasksCompleted),
                label: "\(stats.tasksCompleted)"
            )
        }
    }
    
    var timeSpentChartData: [ChartDataPoint] {
        let filteredStats = getFilteredDailyStats()
        return filteredStats.map { stats in
            ChartDataPoint(
                date: stats.date,
                value: stats.timeSpent / 3600, // Convert to hours
                label: String(format: "%.1fh", stats.timeSpent / 3600)
            )
        }
    }
    
    var categoryChartData: [PieChartDataPoint] {
        return analytics.categoryBreakdown.compactMap { category, stats -> PieChartDataPoint? in
            guard stats.tasksCompleted > 0 else { return nil }
            return PieChartDataPoint(
                label: category.rawValue,
                value: Double(stats.tasksCompleted),
                color: categoryColor(for: category)
            )
        }
    }
    
    private func getFilteredDailyStats() -> [DailyStats] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .day:
            return analytics.dailyStats.filter { calendar.isDate($0.date, inSameDayAs: now) }
        case .week:
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
            return analytics.dailyStats.filter { $0.date >= weekStart }
        case .month:
            guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start else { return [] }
            return analytics.dailyStats.filter { $0.date >= monthStart }
        case .year:
            guard let yearStart = calendar.dateInterval(of: .year, for: now)?.start else { return [] }
            return analytics.dailyStats.filter { $0.date >= yearStart }
        case .all:
            return analytics.dailyStats
        }
    }
    
    // MARK: - Refresh Data
    
    func refreshAnalytics() {
        loadTasksAndNotes()
        calculateAnalytics()
        saveAnalytics()
    }
    
    // MARK: - Helper Functions
    
    private func categoryColor(for category: TaskCategory) -> Color {
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
}

// MARK: - Chart Data Models

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
}

struct PieChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}
