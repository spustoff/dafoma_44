//
//  GoalModel.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import SwiftUI

struct Goal: Identifiable, Codable, Hashable {
    let id = UUID()
    var title: String
    var description: String
    var targetValue: Double
    var currentValue: Double
    var unit: String // "tasks", "hours", "days", "times", etc.
    var deadline: Date
    var category: GoalCategory
    var priority: TaskPriority
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var milestones: [Milestone]
    var relatedTaskIds: [UUID]
    var relatedHabitIds: [UUID]
    var color: String
    var icon: String
    
    init(title: String, description: String = "", targetValue: Double, unit: String, deadline: Date, category: GoalCategory = .personal, priority: TaskPriority = .medium) {
        self.title = title
        self.description = description
        self.targetValue = targetValue
        self.currentValue = 0
        self.unit = unit
        self.deadline = deadline
        self.category = category
        self.priority = priority
        self.isCompleted = false
        self.createdAt = Date()
        self.completedAt = nil
        self.milestones = []
        self.relatedTaskIds = []
        self.relatedHabitIds = []
        self.color = "#0278fc"
        self.icon = "target"
    }
    
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(1.0, currentValue / targetValue)
    }
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    var remainingValue: Double {
        max(0, targetValue - currentValue)
    }
    
    var isOverdue: Bool {
        !isCompleted && deadline < Date()
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: deadline)
        return max(0, components.day ?? 0)
    }
    
    var formattedDeadline: String {
        let formatter = DateFormatter()
        if Calendar.current.isDate(deadline, inSameDayAs: Date()) {
            return "Today"
        } else if daysRemaining == 1 {
            return "Tomorrow"
        } else if daysRemaining <= 7 {
            return "\(daysRemaining) days left"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: deadline)
        }
    }
    
    var categoryColor: Color {
        switch category {
        case .personal:
            return Color(hex: "#0278fc")
        case .career:
            return Color(hex: "#ee004a")
        case .health:
            return Color(hex: "#54b702")
        case .education:
            return Color(hex: "#d300ee")
        case .finance:
            return Color(hex: "#fff707")
        case .relationships:
            return Color(hex: "#ff6b35")
        case .creativity:
            return Color(hex: "#6c5ce7")
        }
    }
    
    mutating func updateProgress(_ value: Double) {
        currentValue = min(targetValue, max(0, value))
        if currentValue >= targetValue && !isCompleted {
            markCompleted()
        }
    }
    
    mutating func addProgress(_ value: Double) {
        updateProgress(currentValue + value)
    }
    
    mutating func markCompleted() {
        isCompleted = true
        currentValue = targetValue
        completedAt = Date()
    }
    
    mutating func addMilestone(_ milestone: Milestone) {
        milestones.append(milestone)
        milestones.sort { $0.targetValue < $1.targetValue }
    }
    
    var nextMilestone: Milestone? {
        milestones.first { !$0.isCompleted && $0.targetValue > currentValue }
    }
    
    var completedMilestones: [Milestone] {
        milestones.filter { $0.isCompleted || $0.targetValue <= currentValue }
    }
}

struct Milestone: Identifiable, Codable, Hashable {
    let id = UUID()
    var title: String
    var description: String
    var targetValue: Double
    var isCompleted: Bool
    var completedAt: Date?
    var reward: String?
    
    init(title: String, description: String = "", targetValue: Double, reward: String? = nil) {
        self.title = title
        self.description = description
        self.targetValue = targetValue
        self.isCompleted = false
        self.completedAt = nil
        self.reward = reward
    }
    
    mutating func markCompleted() {
        isCompleted = true
        completedAt = Date()
    }
}

enum GoalCategory: String, CaseIterable, Codable {
    case personal = "Personal"
    case career = "Career"
    case health = "Health"
    case education = "Education"
    case finance = "Finance"
    case relationships = "Relationships"
    case creativity = "Creativity"
    
    var icon: String {
        switch self {
        case .personal:
            return "person.fill"
        case .career:
            return "briefcase.fill"
        case .health:
            return "heart.fill"
        case .education:
            return "book.fill"
        case .finance:
            return "dollarsign.circle.fill"
        case .relationships:
            return "person.2.fill"
        case .creativity:
            return "paintbrush.fill"
        }
    }
}
