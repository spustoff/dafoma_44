//
//  GoalViewModel.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import SwiftUI

@MainActor
class GoalViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory: GoalCategory?
    @Published var sortOption: GoalSortOption = .deadline
    @Published var showCompletedGoals = false
    
    private let dataService = DataPersistenceService.shared
    
    enum GoalSortOption: String, CaseIterable {
        case deadline = "Deadline"
        case progress = "Progress"
        case created = "Created"
        case alphabetical = "Alphabetical"
        case category = "Category"
        
        var systemImage: String {
            switch self {
            case .deadline:
                return "clock"
            case .progress:
                return "chart.line.uptrend.xyaxis"
            case .created:
                return "calendar.badge.plus"
            case .alphabetical:
                return "textformat.abc"
            case .category:
                return "folder"
            }
        }
    }
    
    init() {
        loadGoals()
    }
    
    // MARK: - Data Management
    
    func loadGoals() {
        isLoading = true
        errorMessage = nil
        
        if let data = UserDefaults.standard.data(forKey: "goals"),
           let loadedGoals = try? JSONDecoder().decode([Goal].self, from: data) {
            goals = loadedGoals
        } else {
            goals = createSampleGoals()
            saveGoals()
        }
        
        isLoading = false
    }
    
    func saveGoals() {
        if let data = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(data, forKey: "goals")
        }
    }
    
    private func createSampleGoals() -> [Goal] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            Goal(
                title: "Complete 50 Tasks This Month",
                description: "Increase productivity by completing 50 tasks before month end",
                targetValue: 50,
                unit: "tasks",
                deadline: calendar.date(byAdding: .month, value: 1, to: now) ?? now,
                category: .personal,
                priority: .high
            ),
            Goal(
                title: "Read 12 Books This Year",
                description: "Expand knowledge by reading one book per month",
                targetValue: 12,
                unit: "books",
                deadline: calendar.date(byAdding: .year, value: 1, to: now) ?? now,
                category: .education,
                priority: .medium
            ),
            Goal(
                title: "Exercise 100 Hours",
                description: "Maintain fitness with regular exercise sessions",
                targetValue: 100,
                unit: "hours",
                deadline: calendar.date(byAdding: .month, value: 6, to: now) ?? now,
                category: .health,
                priority: .high
            )
        ]
    }
    
    // MARK: - Goal Management
    
    func addGoal(_ goal: Goal) {
        goals.append(goal)
        saveGoals()
    }
    
    func updateGoal(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
            saveGoals()
        }
    }
    
    func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        saveGoals()
    }
    
    func updateGoalProgress(_ goalId: UUID, newValue: Double) {
        if let index = goals.firstIndex(where: { $0.id == goalId }) {
            goals[index].updateProgress(newValue)
            saveGoals()
        }
    }
    
    func addGoalProgress(_ goalId: UUID, value: Double) {
        if let index = goals.firstIndex(where: { $0.id == goalId }) {
            goals[index].addProgress(value)
            saveGoals()
        }
    }
    
    func markGoalCompleted(_ goalId: UUID) {
        if let index = goals.firstIndex(where: { $0.id == goalId }) {
            goals[index].markCompleted()
            saveGoals()
        }
    }
    
    func addMilestone(to goalId: UUID, milestone: Milestone) {
        if let index = goals.firstIndex(where: { $0.id == goalId }) {
            goals[index].addMilestone(milestone)
            saveGoals()
        }
    }
    
    // MARK: - Filtering and Sorting
    
    var filteredGoals: [Goal] {
        var filtered = goals
        
        // Filter by completion status
        if !showCompletedGoals {
            filtered = filtered.filter { !$0.isCompleted }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { goal in
                goal.title.localizedCaseInsensitiveContains(searchText) ||
                goal.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        return sortGoals(filtered)
    }
    
    private func sortGoals(_ goals: [Goal]) -> [Goal] {
        switch sortOption {
        case .deadline:
            return goals.sorted { $0.deadline < $1.deadline }
        case .progress:
            return goals.sorted { $0.progress > $1.progress }
        case .created:
            return goals.sorted { $0.createdAt > $1.createdAt }
        case .alphabetical:
            return goals.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .category:
            return goals.sorted { $0.category.rawValue.localizedCaseInsensitiveCompare($1.category.rawValue) == .orderedAscending }
        }
    }
    
    // MARK: - Statistics
    
    var goalStatistics: GoalStatistics {
        let total = goals.count
        let completed = goals.filter { $0.isCompleted }.count
        let active = goals.filter { !$0.isCompleted }.count
        let overdue = goals.filter { $0.isOverdue }.count
        let onTrack = goals.filter { !$0.isCompleted && !$0.isOverdue && $0.progress >= 0.25 }.count
        
        let averageProgress = active > 0 ? goals.filter { !$0.isCompleted }.reduce(0) { $0 + $1.progress } / Double(active) : 0
        
        return GoalStatistics(
            totalGoals: total,
            completedGoals: completed,
            activeGoals: active,
            overdueGoals: overdue,
            onTrackGoals: onTrack,
            averageProgress: averageProgress
        )
    }
    
    var goalsNearDeadline: [Goal] {
        let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return goals.filter { !$0.isCompleted && $0.deadline <= sevenDaysFromNow }
            .sorted { $0.deadline < $1.deadline }
    }
    
    var goalsAtRisk: [Goal] {
        return goals.filter { goal in
            !goal.isCompleted && 
            goal.daysRemaining > 0 && 
            goal.progress < 0.5 && 
            goal.daysRemaining <= 30
        }
    }
    
    // MARK: - Auto-updates from Tasks
    
    func updateGoalProgressFromTask(_ task: Task) {
        // Update goals that might be related to task completion
        for index in goals.indices {
            var goal = goals[index]
            
            if goal.category.rawValue.lowercased() == task.category.rawValue.lowercased() &&
               goal.unit == "tasks" && !goal.isCompleted {
                goal.addProgress(1.0)
                goals[index] = goal
            }
        }
        saveGoals()
    }
    
    func updateGoalProgressFromHabit(_ habit: Habit, value: Double) {
        // Update goals that might be related to habit completion
        for index in goals.indices {
            var goal = goals[index]
            
            if goal.title.localizedCaseInsensitiveContains(habit.title) ||
               goal.description.localizedCaseInsensitiveContains(habit.title) {
                goal.addProgress(value)
                goals[index] = goal
            }
        }
        saveGoals()
    }
    
    // MARK: - Insights and Recommendations
    
    func getGoalInsights() -> [GoalInsight] {
        var insights: [GoalInsight] = []
        
        // Progress insights
        let lowProgressGoals = goals.filter { !$0.isCompleted && $0.progress < 0.3 && $0.daysRemaining <= 30 }
        if !lowProgressGoals.isEmpty {
            insights.append(GoalInsight(
                title: "Goals Need Attention",
                description: "\(lowProgressGoals.count) goal\(lowProgressGoals.count == 1 ? "" : "s") behind schedule",
                type: .warning,
                actionable: true,
                recommendation: "Consider breaking down large goals into smaller milestones"
            ))
        }
        
        // Success insights
        let recentlyCompleted = goals.filter { 
            $0.isCompleted && 
            Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.contains($0.completedAt ?? Date()) == true
        }
        if !recentlyCompleted.isEmpty {
            insights.append(GoalInsight(
                title: "Great Progress!",
                description: "You completed \(recentlyCompleted.count) goal\(recentlyCompleted.count == 1 ? "" : "s") this week",
                type: .success,
                actionable: false,
                recommendation: nil
            ))
        }
        
        return insights
    }
}

struct GoalStatistics {
    let totalGoals: Int
    let completedGoals: Int
    let activeGoals: Int
    let overdueGoals: Int
    let onTrackGoals: Int
    let averageProgress: Double
    
    var completionRate: Double {
        guard totalGoals > 0 else { return 0 }
        return Double(completedGoals) / Double(totalGoals)
    }
    
    var onTrackRate: Double {
        guard activeGoals > 0 else { return 0 }
        return Double(onTrackGoals) / Double(activeGoals)
    }
}

struct GoalInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: InsightType
    let actionable: Bool
    let recommendation: String?
    
    enum InsightType {
        case success
        case warning
        case info
        
        var color: Color {
            switch self {
            case .success:
                return Color(hex: "#54b702")
            case .warning:
                return Color(hex: "#ee004a")
            case .info:
                return Color(hex: "#0278fc")
            }
        }
        
        var icon: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            case .info:
                return "info.circle.fill"
            }
        }
    }
}
