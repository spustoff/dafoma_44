//
//  HabitViewModel.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import SwiftUI

@MainActor
class HabitViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory: HabitCategory?
    @Published var sortOption: HabitSortOption = .streak
    @Published var showInactiveHabits = false
    
    private let dataService = DataPersistenceService.shared
    private let notificationService = NotificationService.shared
    
    enum HabitSortOption: String, CaseIterable {
        case streak = "Streak"
        case progress = "Progress"
        case created = "Created"
        case alphabetical = "Alphabetical"
        case category = "Category"
        
        var systemImage: String {
            switch self {
            case .streak:
                return "flame"
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
        loadHabits()
        setupNotificationObserver()
    }
    
    // MARK: - Data Management
    
    func loadHabits() {
        isLoading = true
        errorMessage = nil
        
        if let data = UserDefaults.standard.data(forKey: "habits"),
           let loadedHabits = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = loadedHabits
        } else {
            habits = createSampleHabits()
            saveHabits()
        }
        
        isLoading = false
    }
    
    func saveHabits() {
        if let data = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(data, forKey: "habits")
        }
    }
    
    private func createSampleHabits() -> [Habit] {
        return [
            Habit(
                title: "Drink 8 Glasses of Water",
                description: "Stay hydrated throughout the day",
                category: .health,
                frequency: .daily,
                targetValue: 8,
                unit: "glasses"
            ),
            Habit(
                title: "Read for 30 Minutes",
                description: "Daily reading to expand knowledge",
                category: .learning,
                frequency: .daily,
                targetValue: 30,
                unit: "minutes"
            ),
            Habit(
                title: "Morning Meditation",
                description: "Start the day with mindfulness",
                category: .mindfulness,
                frequency: .daily,
                targetValue: 1,
                unit: "session"
            ),
            Habit(
                title: "Weekly Exercise",
                description: "Maintain fitness with regular workouts",
                category: .health,
                frequency: .custom(days: 2),
                targetValue: 3,
                unit: "workouts"
            )
        ]
    }
    
    // MARK: - Habit Management
    
    func addHabit(_ habit: Habit) {
        habits.append(habit)
        saveHabits()
        
        if habit.reminderEnabled {
            scheduleHabitReminder(for: habit)
        }
    }
    
    func updateHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
            saveHabits()
            
            // Update notification if needed
            scheduleHabitReminder(for: habit)
        }
    }
    
    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        saveHabits()
        cancelHabitReminder(for: habit.id)
    }
    
    func toggleHabitActive(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index].isActive.toggle()
            saveHabits()
            
            if !habits[index].isActive {
                cancelHabitReminder(for: habit.id)
            } else if habits[index].reminderEnabled {
                scheduleHabitReminder(for: habits[index])
            }
        }
    }
    
    func recordHabitCompletion(_ habitId: UUID, value: Double = 1.0, date: Date = Date()) {
        if let index = habits.firstIndex(where: { $0.id == habitId }) {
            habits[index].recordCompletion(value: value, date: date)
            saveHabits()
            
            // Update related goals
            updateRelatedGoals(for: habits[index], value: value)
        }
    }
    
    func removeHabitCompletion(_ habitId: UUID, date: Date) {
        if let index = habits.firstIndex(where: { $0.id == habitId }) {
            habits[index].removeCompletion(for: date)
            saveHabits()
        }
    }
    
    // MARK: - Filtering and Sorting
    
    var filteredHabits: [Habit] {
        var filtered = habits
        
        // Filter by active status
        if !showInactiveHabits {
            filtered = filtered.filter { $0.isActive }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { habit in
                habit.title.localizedCaseInsensitiveContains(searchText) ||
                habit.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        return sortHabits(filtered)
    }
    
    private func sortHabits(_ habits: [Habit]) -> [Habit] {
        switch sortOption {
        case .streak:
            return habits.sorted { $0.streakCount > $1.streakCount }
        case .progress:
            return habits.sorted { $0.todaysProgress > $1.todaysProgress }
        case .created:
            return habits.sorted { $0.createdAt > $1.createdAt }
        case .alphabetical:
            return habits.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .category:
            return habits.sorted { $0.category.rawValue.localizedCaseInsensitiveCompare($1.category.rawValue) == .orderedAscending }
        }
    }
    
    // MARK: - Statistics
    
    var habitStatistics: HabitStats {
        let total = habits.count
        let active = habits.filter { $0.isActive }.count
        let completedToday = habits.filter { $0.isCompletedToday }.count
        let averageStreak = active > 0 ? habits.filter { $0.isActive }.reduce(0) { $0 + Double($1.streakCount) } / Double(active) : 0
        let longestStreak = habits.map { $0.bestStreak }.max() ?? 0
        
        let totalPossibleCompletions = active
        let completionRate = totalPossibleCompletions > 0 ? Double(completedToday) / Double(totalPossibleCompletions) : 0
        
        let categoryBreakdown = Dictionary(grouping: habits.filter { $0.isActive }, by: { $0.category })
            .mapValues { $0.count }
        
        return HabitStats(
            totalHabits: total,
            activeHabits: active,
            completedToday: completedToday,
            averageStreak: averageStreak,
            longestStreak: longestStreak,
            completionRate: completionRate,
            categoryBreakdown: categoryBreakdown
        )
    }
    
    var todaysHabits: [Habit] {
        habits.filter { $0.isActive }
            .sorted { habit1, habit2 in
                if habit1.isCompletedToday != habit2.isCompletedToday {
                    return !habit1.isCompletedToday
                }
                return habit1.todaysProgress > habit2.todaysProgress
            }
    }
    
    var streakHabits: [Habit] {
        habits.filter { $0.isActive && $0.streakCount > 0 }
            .sorted { $0.streakCount > $1.streakCount }
    }
    
    // MARK: - Notifications
    
    private func scheduleHabitReminder(for habit: Habit) {
        guard habit.reminderEnabled, let reminderTime = habit.reminderTime else { return }
        
        _Concurrency.Task {
            await scheduleHabitReminderAsync(for: habit, at: reminderTime)
        }
    }
    
    private func scheduleHabitReminderAsync(for habit: Habit, at time: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder"
        content.body = habit.title
        content.sound = .default
        content.badge = 1
        
        content.userInfo = [
            "habitId": habit.id.uuidString,
            "type": "habitReminder"
        ]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "habit_\(habit.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Habit reminder scheduled for: \(habit.title)")
        } catch {
            print("❌ Error scheduling habit reminder: \(error)")
        }
    }
    
    private func cancelHabitReminder(for habitId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["habit_\(habitId.uuidString)"])
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TaskCompleted"),
            object: nil,
            queue: .main
        ) { notification in
            if let taskInfo = notification.userInfo,
               let task = taskInfo["task"] as? Task {
                self.updateHabitsFromTask(task)
            }
        }
    }
    
    private func updateHabitsFromTask(_ task: Task) {
        // Update habits that might be related to task completion
        for index in habits.indices {
            if habits[index].isActive &&
               (habits[index].title.localizedCaseInsensitiveContains(task.title) ||
                task.tags.contains { habits[index].title.localizedCaseInsensitiveContains($0) }) {
                habits[index].recordCompletion()
                saveHabits()
            }
        }
    }
    
    private func updateRelatedGoals(for habit: Habit, value: Double) {
        NotificationCenter.default.post(
            name: NSNotification.Name("HabitCompleted"),
            object: nil,
            userInfo: ["habit": habit, "value": value]
        )
    }
    
    // MARK: - Bulk Operations
    
    func markAllHabitsCompleted() {
        for index in habits.indices {
            if habits[index].isActive && !habits[index].isCompletedToday {
                habits[index].recordCompletion()
            }
        }
        saveHabits()
    }
    
    func resetAllHabits() {
        for index in habits.indices {
            habits[index].completions.removeAll()
            habits[index].streakCount = 0
        }
        saveHabits()
    }
    
    func archiveCompletedHabits() {
        // Move long-completed habits to inactive
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        for index in habits.indices {
            let recentCompletions = habits[index].completions.filter { $0.date >= thirtyDaysAgo }
            if recentCompletions.isEmpty && habits[index].isActive {
                habits[index].isActive = false
            }
        }
        saveHabits()
    }
}
