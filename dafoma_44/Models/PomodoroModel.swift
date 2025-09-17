//
//  PomodoroModel.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import SwiftUI

struct PomodoroSession: Identifiable, Codable {
    let id = UUID()
    var type: SessionType
    var duration: TimeInterval
    var remainingTime: TimeInterval
    var isActive: Bool
    var isPaused: Bool
    var startTime: Date?
    var endTime: Date?
    var relatedTaskId: UUID?
    var completedCycles: Int
    var notes: String
    
    init(type: SessionType, duration: TimeInterval) {
        self.type = type
        self.duration = duration
        self.remainingTime = duration
        self.isActive = false
        self.isPaused = false
        self.startTime = nil
        self.endTime = nil
        self.relatedTaskId = nil
        self.completedCycles = 0
        self.notes = ""
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return (duration - remainingTime) / duration
    }
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    var formattedRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
    
    var isCompleted: Bool {
        remainingTime <= 0
    }
    
    mutating func start() {
        isActive = true
        isPaused = false
        startTime = Date()
    }
    
    mutating func pause() {
        isPaused = true
    }
    
    mutating func resume() {
        isPaused = false
    }
    
    mutating func stop() {
        isActive = false
        isPaused = false
        endTime = Date()
    }
    
    mutating func complete() {
        remainingTime = 0
        isActive = false
        endTime = Date()
        if type == .work {
            completedCycles += 1
        }
    }
    
    mutating func reset() {
        remainingTime = duration
        isActive = false
        isPaused = false
        startTime = nil
        endTime = nil
    }
    
    mutating func updateRemainingTime(_ time: TimeInterval) {
        remainingTime = max(0, time)
        if remainingTime <= 0 {
            complete()
        }
    }
}

enum SessionType: String, CaseIterable, Codable {
    case work = "Work"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    
    var color: Color {
        switch self {
        case .work:
            return Color(hex: "#ee004a") // Red
        case .shortBreak:
            return Color(hex: "#54b702") // Green
        case .longBreak:
            return Color(hex: "#0278fc") // Blue
        }
    }
    
    var icon: String {
        switch self {
        case .work:
            return "brain.head.profile"
        case .shortBreak:
            return "cup.and.saucer.fill"
        case .longBreak:
            return "bed.double.fill"
        }
    }
    
    var defaultDuration: TimeInterval {
        switch self {
        case .work:
            return 25 * 60 // 25 minutes
        case .shortBreak:
            return 5 * 60 // 5 minutes
        case .longBreak:
            return 15 * 60 // 15 minutes
        }
    }
}

struct PomodoroSettings: Codable {
    var workDuration: TimeInterval = 25 * 60 // 25 minutes
    var shortBreakDuration: TimeInterval = 5 * 60 // 5 minutes
    var longBreakDuration: TimeInterval = 15 * 60 // 15 minutes
    var cyclesBeforeLongBreak: Int = 4
    var autoStartBreaks: Bool = false
    var autoStartWork: Bool = false
    var soundEnabled: Bool = true
    var vibrationEnabled: Bool = true
    var notificationEnabled: Bool = true
    
    var workDurationMinutes: Int {
        get { Int(workDuration / 60) }
        set { workDuration = TimeInterval(newValue * 60) }
    }
    
    var shortBreakDurationMinutes: Int {
        get { Int(shortBreakDuration / 60) }
        set { shortBreakDuration = TimeInterval(newValue * 60) }
    }
    
    var longBreakDurationMinutes: Int {
        get { Int(longBreakDuration / 60) }
        set { longBreakDuration = TimeInterval(newValue * 60) }
    }
}

struct PomodoroStats: Codable {
    var totalSessions: Int = 0
    var completedSessions: Int = 0
    var totalFocusTime: TimeInterval = 0
    var totalBreakTime: TimeInterval = 0
    var averageSessionLength: TimeInterval = 0
    var dailyStats: [PomodoroDaily] = []
    var weeklyGoal: Int = 8 // Default: 8 pomodoros per day
    var bestDay: Date?
    var currentStreak: Int = 0
    
    var completionRate: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(completedSessions) / Double(totalSessions)
    }
    
    var todaysCompletedSessions: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return dailyStats.first { Calendar.current.isDate($0.date, inSameDayAs: today) }?.completedSessions ?? 0
    }
    
    var todaysProgress: Double {
        guard weeklyGoal > 0 else { return 0 }
        return Double(todaysCompletedSessions) / Double(weeklyGoal)
    }
    
}

struct PomodoroDaily: Identifiable, Codable {
    let id = UUID()
    let date: Date
    var totalSessions: Int = 0
    var completedSessions: Int = 0
    var focusTime: TimeInterval = 0
    
    var formattedDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDate(date, inSameDayAs: Date()) {
            return "Today"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    var formattedFocusTime: String {
        let hours = Int(focusTime) / 3600
        let minutes = Int(focusTime) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var completionRate: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(completedSessions) / Double(totalSessions)
    }
}
