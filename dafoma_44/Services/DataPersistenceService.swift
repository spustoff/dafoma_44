//
//  DataPersistenceService.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import SwiftUI

@MainActor
class DataPersistenceService: ObservableObject {
    static let shared = DataPersistenceService()
    
    private let userDefaults = UserDefaults.standard
    private let documentsDirectory: URL
    
    // Keys for UserDefaults
    private enum Keys {
        static let tasks = "tasks"
        static let notes = "notes"
        static let analytics = "analytics"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let userPreferences = "userPreferences"
    }
    
    init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    // MARK: - Task Management
    
    func saveTasks(_ tasks: [Task]) {
        do {
            let data = try JSONEncoder().encode(tasks)
            userDefaults.set(data, forKey: Keys.tasks)
            print("✅ Tasks saved successfully: \(tasks.count) tasks")
        } catch {
            print("❌ Error saving tasks: \(error.localizedDescription)")
        }
    }
    
    func loadTasks() -> [Task] {
        guard let data = userDefaults.data(forKey: Keys.tasks) else {
            print("ℹ️ No tasks data found, returning sample tasks")
            return createSampleTasks()
        }
        
        do {
            let tasks = try JSONDecoder().decode([Task].self, from: data)
            print("✅ Tasks loaded successfully: \(tasks.count) tasks")
            return tasks
        } catch {
            print("❌ Error loading tasks: \(error.localizedDescription)")
            return createSampleTasks()
        }
    }
    
    private func createSampleTasks() -> [Task] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            Task(
                title: "Complete project proposal",
                description: "Finish the quarterly project proposal for the new client",
                deadline: calendar.date(byAdding: .hour, value: 4, to: now) ?? now,
                priority: .high,
                category: .work,
                estimatedDuration: 7200
            ),
            Task(
                title: "Morning workout",
                description: "30-minute cardio session",
                deadline: calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now).addingTimeInterval(7*3600)) ?? now,
                priority: .medium,
                category: .health,
                estimatedDuration: 1800
            ),
            Task(
                title: "Read chapter 5",
                description: "Continue reading 'Atomic Habits'",
                deadline: calendar.date(byAdding: .day, value: 2, to: now) ?? now,
                priority: .low,
                category: .education,
                estimatedDuration: 3600
            ),
            Task(
                title: "Team meeting",
                description: "Weekly sync with development team",
                deadline: calendar.date(byAdding: .day, value: 3, to: calendar.startOfDay(for: now).addingTimeInterval(14*3600)) ?? now,
                priority: .high,
                category: .work,
                estimatedDuration: 3600
            ),
            Task(
                title: "Grocery shopping",
                description: "Buy ingredients for weekend cooking",
                deadline: calendar.date(byAdding: .day, value: 1, to: now) ?? now,
                priority: .medium,
                category: .personal,
                estimatedDuration: 2700
            )
        ]
    }
    
    // MARK: - Note Management
    
    func saveNotes(_ notes: [Note]) {
        do {
            let data = try JSONEncoder().encode(notes)
            userDefaults.set(data, forKey: Keys.notes)
            print("✅ Notes saved successfully: \(notes.count) notes")
        } catch {
            print("❌ Error saving notes: \(error.localizedDescription)")
        }
    }
    
    func loadNotes() -> [Note] {
        guard let data = userDefaults.data(forKey: Keys.notes) else {
            print("ℹ️ No notes data found, returning sample notes")
            return createSampleNotes()
        }
        
        do {
            let notes = try JSONDecoder().decode([Note].self, from: data)
            print("✅ Notes loaded successfully: \(notes.count) notes")
            return notes
        } catch {
            print("❌ Error loading notes: \(error.localizedDescription)")
            return createSampleNotes()
        }
    }
    
    private func createSampleNotes() -> [Note] {
        return [
            Note(
                title: "Meeting Notes - Project Kickoff",
                content: """
                Key points from today's project kickoff meeting:
                
                • Project timeline: 8 weeks
                • Team size: 5 developers, 2 designers
                • Main deliverables: MVP by week 6, testing by week 8
                • Weekly check-ins every Monday at 10 AM
                • Budget approved: $50K
                
                Action items:
                - Set up project repository
                - Create initial wireframes
                - Schedule first sprint planning
                """,
                category: .meetings,
                color: "#54b702"
            ),
            Note(
                title: "Book Ideas",
                content: """
                Ideas for my productivity book:
                
                1. The Power of Micro-Habits
                2. Digital Minimalism in the Workplace
                3. Time-Blocking for Creative Professionals
                4. The Science of Deep Work
                5. Building Systems, Not Goals
                
                Research needed:
                - Latest studies on attention spans
                - Case studies from successful entrepreneurs
                - Neuroscience of habit formation
                """,
                category: .ideas,
                color: "#fff707"
            ),
            Note(
                title: "Weekend Recipe Collection",
                content: """
                Recipes to try this weekend:
                
                Saturday Dinner:
                • Honey Garlic Salmon with roasted vegetables
                • Ingredients: salmon fillets, honey, garlic, broccoli, carrots
                
                Sunday Brunch:
                • Avocado toast with poached eggs
                • Fresh fruit smoothie bowl
                
                Meal prep for the week:
                • Chicken and quinoa bowls
                • Overnight oats with berries
                """,
                category: .personal,
                color: "#ee004a"
            ),
            Note(
                title: "Learning Goals - Q4",
                content: """
                Skills to develop this quarter:
                
                Technical:
                - Master SwiftUI animations
                - Learn Core Data optimization
                - Explore Combine framework
                
                Soft Skills:
                - Improve presentation skills
                - Practice active listening
                - Develop mentoring abilities
                
                Resources:
                - Apple Developer Documentation
                - Ray Wenderlich courses
                - Local iOS meetups
                """,
                category: .study,
                color: "#d300ee"
            )
        ]
    }
    
    // MARK: - Analytics Management
    
    func saveAnalytics(_ analytics: AnalyticsData) {
        do {
            let data = try JSONEncoder().encode(analytics)
            userDefaults.set(data, forKey: Keys.analytics)
            print("✅ Analytics saved successfully")
        } catch {
            print("❌ Error saving analytics: \(error.localizedDescription)")
        }
    }
    
    func loadAnalytics() -> AnalyticsData {
        guard let data = userDefaults.data(forKey: Keys.analytics) else {
            print("ℹ️ No analytics data found, creating new analytics")
            return createInitialAnalytics()
        }
        
        do {
            let analytics = try JSONDecoder().decode(AnalyticsData.self, from: data)
            print("✅ Analytics loaded successfully")
            return analytics
        } catch {
            print("❌ Error loading analytics: \(error.localizedDescription)")
            return createInitialAnalytics()
        }
    }
    
    private func createInitialAnalytics() -> AnalyticsData {
        var analytics = AnalyticsData()
        
        // Create sample data for the past 7 days
        let calendar = Calendar.current
        let now = Date()
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                var dailyStat = DailyStats(date: date)
                dailyStat.tasksCompleted = Int.random(in: 2...8)
                dailyStat.tasksCreated = dailyStat.tasksCompleted + Int.random(in: 0...3)
                dailyStat.timeSpent = TimeInterval(Int.random(in: 3600...28800)) // 1-8 hours
                dailyStat.productivityScore = Double.random(in: 0.6...0.95)
                dailyStat.notesCreated = Int.random(in: 0...3)
                analytics.dailyStats.append(dailyStat)
            }
        }
        
        // Calculate totals
        analytics.totalTasksCompleted = analytics.dailyStats.reduce(0) { $0 + $1.tasksCompleted }
        analytics.totalTimeTracked = analytics.dailyStats.reduce(0) { $0 + $1.timeSpent }
        analytics.productivityScore = analytics.dailyStats.reduce(0) { $0 + $1.productivityScore } / Double(analytics.dailyStats.count)
        
        return analytics
    }
    
    // MARK: - User Preferences
    
    var hasCompletedOnboarding: Bool {
        get {
            userDefaults.bool(forKey: Keys.hasCompletedOnboarding)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.hasCompletedOnboarding)
            print("✅ Onboarding status updated: \(newValue)")
        }
    }
    
    func resetAllData() {
        userDefaults.removeObject(forKey: Keys.tasks)
        userDefaults.removeObject(forKey: Keys.notes)
        userDefaults.removeObject(forKey: Keys.analytics)
        userDefaults.removeObject(forKey: Keys.hasCompletedOnboarding)
        userDefaults.removeObject(forKey: Keys.userPreferences)
        print("✅ All user data has been reset")
    }
    
    // MARK: - Export/Import Functions
    
    func exportData() -> [String: Any] {
        var exportData: [String: Any] = [:]
        
        let tasks = loadTasks()
        let notes = loadNotes()
        let analytics = loadAnalytics()
        
        do {
            let tasksData = try JSONEncoder().encode(tasks)
            let notesData = try JSONEncoder().encode(notes)
            let analyticsData = try JSONEncoder().encode(analytics)
            
            exportData["tasks"] = tasksData
            exportData["notes"] = notesData
            exportData["analytics"] = analyticsData
            exportData["exportDate"] = Date()
            
            print("✅ Data exported successfully")
        } catch {
            print("❌ Error exporting data: \(error.localizedDescription)")
        }
        
        return exportData
    }
    
    func importData(_ data: [String: Any]) -> Bool {
        do {
            if let tasksData = data["tasks"] as? Data {
                let tasks = try JSONDecoder().decode([Task].self, from: tasksData)
                saveTasks(tasks)
            }
            
            if let notesData = data["notes"] as? Data {
                let notes = try JSONDecoder().decode([Note].self, from: notesData)
                saveNotes(notes)
            }
            
            if let analyticsData = data["analytics"] as? Data {
                let analytics = try JSONDecoder().decode(AnalyticsData.self, from: analyticsData)
                saveAnalytics(analytics)
            }
            
            print("✅ Data imported successfully")
            return true
        } catch {
            print("❌ Error importing data: \(error.localizedDescription)")
            return false
        }
    }
}


