//
//  TaskViewModel.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import SwiftUI

@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory: TaskCategory?
    @Published var selectedPriority: TaskPriority?
    @Published var sortOption: TaskSortOption = .deadline
    @Published var showCompletedTasks = false
    
    private let dataService = DataPersistenceService.shared
    private let notificationService = NotificationService.shared
    
    enum TaskSortOption: String, CaseIterable {
        case deadline = "Deadline"
        case priority = "Priority"
        case created = "Created"
        case alphabetical = "Alphabetical"
        case category = "Category"
        
        var systemImage: String {
            switch self {
            case .deadline:
                return "clock"
            case .priority:
                return "exclamationmark.triangle"
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
        loadTasks()
    }
    
    // MARK: - Data Loading
    
    func loadTasks() {
        isLoading = true
        errorMessage = nil
        
        tasks = dataService.loadTasks()
        print("✅ Tasks loaded: \(tasks.count)")
        
        isLoading = false
    }
    
    func saveTasks() {
        dataService.saveTasks(tasks)
        print("✅ Tasks saved: \(tasks.count)")
    }
    
    // MARK: - Task Management
    
    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
        
        // Schedule notification if enabled
        if task.reminderEnabled {
            _Concurrency.Task {
                await notificationService.scheduleTaskReminder(for: task)
            }
        }
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            let oldTask = tasks[index]
            tasks[index] = task
            saveTasks()
            
            // Update notification if needed
            if task.reminderEnabled && task.reminderTime != oldTask.reminderTime {
                _Concurrency.Task {
                    await notificationService.cancelTaskReminder(for: task.id)
                    await notificationService.scheduleTaskReminder(for: task)
                }
            } else if !task.reminderEnabled && oldTask.reminderEnabled {
                _Concurrency.Task {
                    await notificationService.cancelTaskReminder(for: task.id)
                }
            }
        }
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
        
        // Cancel notification
        _Concurrency.Task {
            await notificationService.cancelTaskReminder(for: task.id)
        }
    }
    
    func deleteTask(at indexSet: IndexSet) {
        let tasksToDelete = indexSet.map { filteredTasks[$0] }
        for task in tasksToDelete {
            deleteTask(task)
        }
    }
    
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            
            if tasks[index].isCompleted {
                tasks[index].completedAt = Date()
                // Cancel reminder since task is completed
                _Concurrency.Task {
                    await notificationService.cancelTaskReminder(for: task.id)
                }
            } else {
                tasks[index].completedAt = nil
                // Reschedule reminder if enabled and time is in future
                if tasks[index].reminderEnabled, let reminderTime = tasks[index].reminderTime, reminderTime > Date() {
                    _Concurrency.Task {
                        await notificationService.scheduleTaskReminder(for: tasks[index])
                    }
                }
            }
            
            saveTasks()
        }
    }
    
    func duplicateTask(_ task: Task) {
        var newTask = task
        newTask.title = "\(task.title) (Copy)"
        newTask.isCompleted = false
        newTask.completedAt = nil
        newTask.createdAt = Date()
        
        // Set new deadline (1 day from now)
        newTask.deadline = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        
        // Update reminder time if enabled
        if newTask.reminderEnabled {
            newTask.reminderTime = Calendar.current.date(byAdding: .hour, value: -1, to: newTask.deadline)
        }
        
        addTask(newTask)
    }
    
    // MARK: - Filtering and Sorting
    
    var filteredTasks: [Task] {
        var filtered = tasks
        
        // Filter by completion status
        if !showCompletedTasks {
            filtered = filtered.filter { !$0.isCompleted }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.description.localizedCaseInsensitiveContains(searchText) ||
                task.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filter by priority
        if let selectedPriority = selectedPriority {
            filtered = filtered.filter { $0.priority == selectedPriority }
        }
        
        // Sort
        return sortTasks(filtered)
    }
    
    private func sortTasks(_ tasks: [Task]) -> [Task] {
        switch sortOption {
        case .deadline:
            return tasks.sorted { task1, task2 in
                if task1.isCompleted != task2.isCompleted {
                    return !task1.isCompleted
                }
                return task1.deadline < task2.deadline
            }
        case .priority:
            return tasks.sorted { task1, task2 in
                if task1.isCompleted != task2.isCompleted {
                    return !task1.isCompleted
                }
                return priorityValue(task1.priority) > priorityValue(task2.priority)
            }
        case .created:
            return tasks.sorted { task1, task2 in
                if task1.isCompleted != task2.isCompleted {
                    return !task1.isCompleted
                }
                return task1.createdAt > task2.createdAt
            }
        case .alphabetical:
            return tasks.sorted { task1, task2 in
                if task1.isCompleted != task2.isCompleted {
                    return !task1.isCompleted
                }
                return task1.title.localizedCaseInsensitiveCompare(task2.title) == .orderedAscending
            }
        case .category:
            return tasks.sorted { task1, task2 in
                if task1.isCompleted != task2.isCompleted {
                    return !task1.isCompleted
                }
                return task1.category.rawValue.localizedCaseInsensitiveCompare(task2.category.rawValue) == .orderedAscending
            }
        }
    }
    
    private func priorityValue(_ priority: TaskPriority) -> Int {
        switch priority {
        case .critical:
            return 4
        case .high:
            return 3
        case .medium:
            return 2
        case .low:
            return 1
        }
    }
    
    // MARK: - Statistics
    
    var taskStatistics: TaskStatistics {
        let total = tasks.count
        let completed = tasks.filter { $0.isCompleted }.count
        let overdue = tasks.filter { $0.isOverdue && !$0.isCompleted }.count
        let dueToday = tasks.filter { $0.isDueToday && !$0.isCompleted }.count
        let dueTomorrow = tasks.filter { $0.isDueTomorrow && !$0.isCompleted }.count
        
        let completionRate = total > 0 ? Double(completed) / Double(total) : 0.0
        
        return TaskStatistics(
            totalTasks: total,
            completedTasks: completed,
            overdueTasks: overdue,
            dueTodayTasks: dueToday,
            dueTomorrowTasks: dueTomorrow,
            completionRate: completionRate
        )
    }
    
    var todaysTasks: [Task] {
        tasks.filter { $0.isDueToday && !$0.isCompleted }
    }
    
    var upcomingTasks: [Task] {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        
        return tasks.filter { task in
            !task.isCompleted && task.deadline > tomorrow && task.deadline <= nextWeek
        }.sorted { $0.deadline < $1.deadline }
    }
    
    var overdueTasks: [Task] {
        tasks.filter { $0.isOverdue && !$0.isCompleted }
            .sorted { $0.deadline < $1.deadline }
    }
    
    var highPriorityTasks: [Task] {
        tasks.filter { ($0.priority == .high || $0.priority == .critical) && !$0.isCompleted }
            .sorted { $0.deadline < $1.deadline }
    }
    
    // MARK: - Bulk Operations
    
    func markAllCompleted(in category: TaskCategory) {
        for index in tasks.indices {
            if tasks[index].category == category && !tasks[index].isCompleted {
                tasks[index].isCompleted = true
                tasks[index].completedAt = Date()
            }
        }
        saveTasks()
    }
    
    func deleteCompleted() {
        let completedTasks = tasks.filter { $0.isCompleted }
        for task in completedTasks {
            deleteTask(task)
        }
    }
    
    func rescheduleOverdue(to newDate: Date) {
        for index in tasks.indices {
            if tasks[index].isOverdue && !tasks[index].isCompleted {
                tasks[index].deadline = newDate
                if tasks[index].reminderEnabled {
                    tasks[index].reminderTime = Calendar.current.date(byAdding: .hour, value: -1, to: newDate)
                }
            }
        }
        saveTasks()
    }
    
    // MARK: - Search and Filters
    
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedPriority = nil
        sortOption = .deadline
    }
    
    var hasActiveFilters: Bool {
        !searchText.isEmpty || selectedCategory != nil || selectedPriority != nil
    }
}

struct TaskStatistics {
    let totalTasks: Int
    let completedTasks: Int
    let overdueTasks: Int
    let dueTodayTasks: Int
    let dueTomorrowTasks: Int
    let completionRate: Double
    
    var pendingTasks: Int {
        totalTasks - completedTasks
    }
    
    var formattedCompletionRate: String {
        String(format: "%.1f%%", completionRate * 100)
    }
}
