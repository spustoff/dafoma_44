//
//  PomodoroService.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import SwiftUI
import AVFoundation
import UserNotifications

@MainActor
class PomodoroService: ObservableObject {
    static let shared = PomodoroService()
    
    @Published var currentSession: PomodoroSession?
    @Published var settings = PomodoroSettings()
    @Published var stats = PomodoroStats()
    @Published var isTimerRunning = false
    
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        loadSettings()
        loadStats()
        setupAudioSession()
    }
    
    // MARK: - Timer Control
    
    func startSession(type: SessionType, relatedTaskId: UUID? = nil) {
        stopCurrentSession()
        
        let duration: TimeInterval
        switch type {
        case .work:
            duration = settings.workDuration
        case .shortBreak:
            duration = settings.shortBreakDuration
        case .longBreak:
            duration = settings.longBreakDuration
        }
        
        currentSession = PomodoroSession(type: type, duration: duration)
        currentSession?.relatedTaskId = relatedTaskId
        currentSession?.start()
        
        startTimer()
        
        // Schedule completion notification
        scheduleCompletionNotification(for: duration, type: type)
        
        print("✅ Started \(type.rawValue) session: \(Int(duration/60)) minutes")
    }
    
    func pauseSession() {
        guard let session = currentSession, session.isActive && !session.isPaused else { return }
        
        currentSession?.pause()
        stopTimer()
        
        print("⏸️ Session paused")
    }
    
    func resumeSession() {
        guard let session = currentSession, session.isActive && session.isPaused else { return }
        
        currentSession?.resume()
        startTimer()
        
        print("▶️ Session resumed")
    }
    
    func stopCurrentSession() {
        currentSession?.stop()
        stopTimer()
        cancelNotifications()
        
        if let session = currentSession {
            recordSessionStats(session)
        }
        
        currentSession = nil
        print("⏹️ Session stopped")
    }
    
    func completeCurrentSession() {
        guard let session = currentSession else { return }
        
        currentSession?.complete()
        stopTimer()
        cancelNotifications()
        
        recordSessionStats(session)
        
        // Play completion sound
        playCompletionSound()
        
        // Trigger haptic feedback
        triggerHapticFeedback()
        
        // Auto-start next session if enabled
        handleAutoStart(after: session)
        
        currentSession = nil
        print("✅ Session completed: \(session.type.rawValue)")
    }
    
    private func startTimer() {
        stopTimer()
        isTimerRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
    }
    
    private func updateTimer() {
        guard let session = currentSession, session.isActive && !session.isPaused else {
            stopTimer()
            return
        }
        
        currentSession?.updateRemainingTime(session.remainingTime - 1)
        
        if session.remainingTime <= 0 {
            completeCurrentSession()
        }
    }
    
    // MARK: - Auto-start Logic
    
    private func handleAutoStart(after session: PomodoroSession) {
        switch session.type {
        case .work:
            let shouldStartLongBreak = (session.completedCycles % settings.cyclesBeforeLongBreak) == 0
            let nextType: SessionType = shouldStartLongBreak ? .longBreak : .shortBreak
            
            if settings.autoStartBreaks {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.startSession(type: nextType, relatedTaskId: session.relatedTaskId)
                }
            }
            
        case .shortBreak, .longBreak:
            if settings.autoStartWork {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.startSession(type: .work, relatedTaskId: session.relatedTaskId)
                }
            }
        }
    }
    
    // MARK: - Notifications
    
    private func scheduleCompletionNotification(for duration: TimeInterval, type: SessionType) {
        guard settings.notificationEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro Timer"
        content.body = "\(type.rawValue) session completed!"
        content.sound = settings.soundEnabled ? .default : nil
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
        let request = UNNotificationRequest(
            identifier: "pomodoro_completion",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling pomodoro notification: \(error)")
            }
        }
    }
    
    private func cancelNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["pomodoro_completion"])
    }
    
    // MARK: - Audio and Haptics
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Error setting up audio session: \(error)")
        }
    }
    
    private func playCompletionSound() {
        guard settings.soundEnabled else { return }
        
        // Use system sound for now
        AudioServicesPlaySystemSound(1016) // Sound ID for completion
    }
    
    private func triggerHapticFeedback() {
        guard settings.vibrationEnabled else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Statistics
    
    private func recordSessionStats(_ session: PomodoroSession) {
        stats.recordSession(session)
        saveStats()
        
        // Update focus time in related task
        if let taskId = session.relatedTaskId, session.type == .work && session.isCompleted {
            updateTaskFocusTime(taskId: taskId, focusTime: session.duration)
        }
    }
    
    private func updateTaskFocusTime(taskId: UUID, focusTime: TimeInterval) {
        // This would integrate with TaskViewModel to update actual time spent
        NotificationCenter.default.post(
            name: NSNotification.Name("PomodoroFocusTimeRecorded"),
            object: nil,
            userInfo: ["taskId": taskId, "focusTime": focusTime]
        )
    }
    
    // MARK: - Data Persistence
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "pomodoroSettings"),
           let loadedSettings = try? JSONDecoder().decode(PomodoroSettings.self, from: data) {
            settings = loadedSettings
        }
    }
    
    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "pomodoroSettings")
        }
    }
    
    private func loadStats() {
        if let data = UserDefaults.standard.data(forKey: "pomodoroStats"),
           let loadedStats = try? JSONDecoder().decode(PomodoroStats.self, from: data) {
            stats = loadedStats
        }
    }
    
    private func saveStats() {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: "pomodoroStats")
        }
    }
    
    // MARK: - Quick Actions
    
    func startQuickWork(duration: Int = 25) {
        let customSettings = settings
        let workSession = PomodoroSession(type: .work, duration: TimeInterval(duration * 60))
        currentSession = workSession
        currentSession?.start()
        startTimer()
        scheduleCompletionNotification(for: TimeInterval(duration * 60), type: .work)
    }
    
    func startQuickBreak(duration: Int = 5) {
        let breakSession = PomodoroSession(type: .shortBreak, duration: TimeInterval(duration * 60))
        currentSession = breakSession
        currentSession?.start()
        startTimer()
        scheduleCompletionNotification(for: TimeInterval(duration * 60), type: .shortBreak)
    }
    
    // MARK: - Session History
    
    var todaysSessions: [PomodoroSession] {
        let today = Calendar.current.startOfDay(for: Date())
        return stats.dailyStats
            .first { Calendar.current.isDate($0.date, inSameDayAs: today) }?
            .sessions ?? []
    }
    
    var weeklyFocusTime: TimeInterval {
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return stats.dailyStats
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + $1.focusTime }
    }
    
    var weeklySessionCount: Int {
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return stats.dailyStats
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + $1.completedSessions }
    }
    
    // MARK: - Recommendations
    
    func getProductivityRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if stats.completionRate < 0.7 {
            recommendations.append("Try shorter work sessions to improve completion rate")
        }
        
        if stats.todaysCompletedSessions < stats.weeklyGoal / 2 {
            recommendations.append("Consider breaking large tasks into smaller pomodoro sessions")
        }
        
        if weeklyFocusTime < TimeInterval(10 * 3600) { // Less than 10 hours per week
            recommendations.append("Aim for more consistent daily focus time")
        }
        
        return recommendations
    }
}

// MARK: - Extensions

extension PomodoroStats {
    mutating func recordSession(_ session: PomodoroSession) {
        totalSessions += 1
        
        if session.isCompleted {
            completedSessions += 1
            
            if session.type == .work {
                totalFocusTime += session.duration
            } else {
                totalBreakTime += session.duration
            }
        }
        
        averageSessionLength = totalFocusTime / Double(max(1, completedSessions))
        
        // Update daily stats
        updateDailyStats(for: session)
    }
    
    private mutating func updateDailyStats(for session: PomodoroSession) {
        let calendar = Calendar.current
        let sessionDate = session.startTime ?? Date()
        let dayStart = calendar.startOfDay(for: sessionDate)
        
        if let index = dailyStats.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: dayStart) }) {
            dailyStats[index].totalSessions += 1
            if session.isCompleted {
                dailyStats[index].completedSessions += 1
                if session.type == .work {
                    dailyStats[index].focusTime += session.duration
                }
            }
        } else {
            var newDaily = PomodoroDaily(date: dayStart)
            newDaily.totalSessions = 1
            if session.isCompleted {
                newDaily.completedSessions = 1
                if session.type == .work {
                    newDaily.focusTime = session.duration
                }
            }
            dailyStats.append(newDaily)
        }
        
        // Keep only last 30 days
        dailyStats = Array(dailyStats.sorted { $0.date > $1.date }.prefix(30))
    }
}

extension PomodoroDaily {
    var sessions: [PomodoroSession] {
        // This would be populated from actual session records
        // For now, return empty array
        return []
    }
}
