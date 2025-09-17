//
//  TemplateViewModel.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import SwiftUI

@MainActor
class TemplateViewModel: ObservableObject {
    @Published var taskTemplates: [TaskTemplate] = []
    @Published var recurringTasks: [RecurringTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory: TaskCategory?
    
    private let dataService = DataPersistenceService.shared
    private let smartTagService = SmartTagService.shared
    
    init() {
        loadTemplates()
        loadRecurringTasks()
        setupNotificationObserver()
    }
    
    // MARK: - Data Management
    
    func loadTemplates() {
        isLoading = true
        
        if let data = UserDefaults.standard.data(forKey: "taskTemplates"),
           let templates = try? JSONDecoder().decode([TaskTemplate].self, from: data) {
            taskTemplates = templates
        } else {
            taskTemplates = createSampleTemplates()
            saveTemplates()
        }
        
        isLoading = false
    }
    
    func saveTemplates() {
        if let data = try? JSONEncoder().encode(taskTemplates) {
            UserDefaults.standard.set(data, forKey: "taskTemplates")
        }
    }
    
    func loadRecurringTasks() {
        if let data = UserDefaults.standard.data(forKey: "recurringTasks"),
           let recurring = try? JSONDecoder().decode([RecurringTask].self, from: data) {
            recurringTasks = recurring
        } else {
            recurringTasks = createSampleRecurringTasks()
            saveRecurringTasks()
        }
    }
    
    func saveRecurringTasks() {
        if let data = try? JSONEncoder().encode(recurringTasks) {
            UserDefaults.standard.set(data, forKey: "recurringTasks")
        }
    }
    
    private func createSampleTemplates() -> [TaskTemplate] {
        return [
            TaskTemplate(
                title: "Weekly Team Meeting",
                description: "Regular sync with the development team",
                category: .work,
                priority: .medium,
                estimatedDuration: 3600,
                defaultDeadlineOffset: 604800 // 1 week
            ),
            TaskTemplate(
                title: "Grocery Shopping",
                description: "Buy weekly groceries and essentials",
                category: .personal,
                priority: .low,
                estimatedDuration: 2700,
                defaultDeadlineOffset: 86400 // 1 day
            ),
            TaskTemplate(
                title: "Monthly Budget Review",
                description: "Review and update monthly budget",
                category: .finance,
                priority: .high,
                estimatedDuration: 5400,
                defaultDeadlineOffset: 2592000 // 30 days
            ),
            TaskTemplate(
                title: "Morning Workout",
                description: "30-minute exercise session",
                category: .health,
                priority: .medium,
                estimatedDuration: 1800,
                defaultDeadlineOffset: 86400 // 1 day
            )
        ]
    }
    
    private func createSampleRecurringTasks() -> [RecurringTask] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            RecurringTask(
                title: "Daily Standup",
                description: "Morning team standup meeting",
                category: .work,
                priority: .medium,
                estimatedDuration: 900, // 15 minutes
                recurrenceRule: RecurrenceRule(
                    type: .daily,
                    interval: 1,
                    timeOfDay: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
                )
            ),
            RecurringTask(
                title: "Weekly Planning",
                description: "Plan tasks and priorities for the upcoming week",
                category: .personal,
                priority: .high,
                estimatedDuration: 3600, // 1 hour
                recurrenceRule: RecurrenceRule(
                    type: .weekly,
                    interval: 1,
                    timeOfDay: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now
                )
            )
        ]
    }
    
    // MARK: - Template Management
    
    func addTemplate(_ template: TaskTemplate) {
        taskTemplates.append(template)
        saveTemplates()
    }
    
    func updateTemplate(_ template: TaskTemplate) {
        if let index = taskTemplates.firstIndex(where: { $0.id == template.id }) {
            taskTemplates[index] = template
            saveTemplates()
        }
    }
    
    func deleteTemplate(_ template: TaskTemplate) {
        taskTemplates.removeAll { $0.id == template.id }
        saveTemplates()
    }
    
    func createTaskFromTemplate(_ template: TaskTemplate) -> Task {
        var updatedTemplate = template
        updatedTemplate.incrementUsage()
        updateTemplate(updatedTemplate)
        
        let task = template.createTask()
        
        // Auto-generate smart tags
        let autoTags = smartTagService.generateAutoTags(for: "\(task.title) \(task.description)")
        var taskWithTags = task
        taskWithTags.tags.append(contentsOf: autoTags)
        
        return taskWithTags
    }
    
    // MARK: - Recurring Tasks Management
    
    func addRecurringTask(_ recurringTask: RecurringTask) {
        recurringTasks.append(recurringTask)
        saveRecurringTasks()
    }
    
    func updateRecurringTask(_ recurringTask: RecurringTask) {
        if let index = recurringTasks.firstIndex(where: { $0.id == recurringTask.id }) {
            recurringTasks[index] = recurringTask
            saveRecurringTasks()
        }
    }
    
    func deleteRecurringTask(_ recurringTask: RecurringTask) {
        recurringTasks.removeAll { $0.id == recurringTask.id }
        saveRecurringTasks()
    }
    
    func toggleRecurringTaskActive(_ recurringTask: RecurringTask) {
        if let index = recurringTasks.firstIndex(where: { $0.id == recurringTask.id }) {
            recurringTasks[index].isActive.toggle()
            saveRecurringTasks()
        }
    }
    
    // MARK: - Task Generation
    
    func generatePendingTasks() -> [Task] {
        var generatedTasks: [Task] = []
        
        for index in recurringTasks.indices {
            if recurringTasks[index].shouldGenerateTask {
                let task = recurringTasks[index].generateTask()
                generatedTasks.append(task)
                
                recurringTasks[index].markGenerated(taskId: task.id)
            }
        }
        
        if !generatedTasks.isEmpty {
            saveRecurringTasks()
        }
        
        return generatedTasks
    }
    
    func checkAndGenerateRecurringTasks() {
        let newTasks = generatePendingTasks()
        
        if !newTasks.isEmpty {
            // Notify TaskViewModel about new tasks
            NotificationCenter.default.post(
                name: NSNotification.Name("RecurringTasksGenerated"),
                object: nil,
                userInfo: ["tasks": newTasks]
            )
            
            print("✅ Generated \(newTasks.count) recurring tasks")
        }
    }
    
    // MARK: - Filtering
    
    var filteredTemplates: [TaskTemplate] {
        var filtered = taskTemplates
        
        if !searchText.isEmpty {
            filtered = filtered.filter { template in
                template.title.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        return filtered.sorted { $0.usageCount > $1.usageCount }
    }
    
    var filteredRecurringTasks: [RecurringTask] {
        var filtered = recurringTasks
        
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        return filtered.sorted { $0.nextDueDate < $1.nextDueDate }
    }
    
    // MARK: - Popular Templates
    
    var popularTemplates: [TaskTemplate] {
        taskTemplates.filter { $0.usageCount > 0 }
            .sorted { $0.usageCount > $1.usageCount }
            .prefix(5)
            .map { $0 }
    }
    
    var recentlyUsedTemplates: [TaskTemplate] {
        taskTemplates.filter { $0.lastUsed != nil }
            .sorted { ($0.lastUsed ?? Date.distantPast) > ($1.lastUsed ?? Date.distantPast) }
            .prefix(3)
            .map { $0 }
    }
    
    // MARK: - Template Creation from Task
    
    func createTemplateFromTask(_ task: Task, name: String? = nil) -> TaskTemplate {
        let templateTitle = name ?? "\(task.title) Template"
        
        var template = TaskTemplate(
            title: templateTitle,
            description: task.description,
            category: task.category,
            priority: task.priority,
            estimatedDuration: task.estimatedDuration,
            defaultDeadlineOffset: 86400 // Default to 1 day
        )
        
        template.tags = task.tags
        template.reminderEnabled = task.reminderEnabled
        template.reminderOffset = 3600 // Default to 1 hour before
        
        addTemplate(template)
        return template
    }
    
    // MARK: - Statistics and Insights
    
    func getTemplateUsageInsights() -> [TemplateInsight] {
        var insights: [TemplateInsight] = []
        
        let totalUsage = taskTemplates.reduce(0) { $0 + $1.usageCount }
        let mostUsed = taskTemplates.max(by: { $0.usageCount < $1.usageCount })
        
        if let mostUsed = mostUsed, mostUsed.usageCount > 0 {
            insights.append(TemplateInsight(
                title: "Most Used Template",
                description: "\(mostUsed.title) has been used \(mostUsed.usageCount) times",
                type: .info
            ))
        }
        
        let unusedTemplates = taskTemplates.filter { $0.usageCount == 0 }
        if unusedTemplates.count > 3 {
            insights.append(TemplateInsight(
                title: "Unused Templates",
                description: "You have \(unusedTemplates.count) templates that haven't been used",
                type: .suggestion
            ))
        }
        
        return insights
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("DailyTaskGeneration"),
            object: nil,
            queue: .main
        ) { _ in
            self.checkAndGenerateRecurringTasks()
        }
    }
}

struct TemplateInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: InsightType
    
    enum InsightType {
        case info
        case suggestion
        case warning
        
        var color: Color {
            switch self {
            case .info:
                return Color(hex: "#0278fc")
            case .suggestion:
                return Color(hex: "#54b702")
            case .warning:
                return Color(hex: "#ee004a")
            }
        }
        
        var icon: String {
            switch self {
            case .info:
                return "info.circle.fill"
            case .suggestion:
                return "lightbulb.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            }
        }
    }
}
