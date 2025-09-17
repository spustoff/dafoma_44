//
//  PomodoroView.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct PomodoroView: View {
    @StateObject private var pomodoroService = PomodoroService.shared
    @State private var selectedTask: Task?
    @State private var showingSettings = false
    @State private var showingTaskPicker = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#f1ccc6"), Color(hex: "#53bef4")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                headerView
                
                // Timer circle
                timerCircleView
                
                // Session info
                sessionInfoView
                
                // Control buttons
                controlButtonsView
                
                // Quick actions
                quickActionsView
                
                // Today's stats
                todaysStatsView
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showingSettings) {
            PomodoroSettingsView(service: pomodoroService)
        }
        .sheet(isPresented: $showingTaskPicker) {
            TaskPickerView(selectedTask: $selectedTask)
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Focus Timer")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                if let session = pomodoroService.currentSession {
                    Text(session.type.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                } else {
                    Text("Ready to focus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }
        }
        .padding(.top, 10)
    }
    
    private var timerCircleView: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(.white.opacity(0.2), lineWidth: 8)
                .frame(width: 250, height: 250)
            
            // Progress circle
            if let session = pomodoroService.currentSession {
                Circle()
                    .trim(from: 0, to: session.progress)
                    .stroke(session.type.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: session.progress)
            }
            
            // Timer content
            VStack(spacing: 8) {
                if let session = pomodoroService.currentSession {
                    Text(session.formattedRemainingTime)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                    
                    Text(session.type.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(session.type.color)
                } else {
                    Image(systemName: "timer")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Text("Ready to start")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }
    
    private var sessionInfoView: some View {
        VStack(spacing: 8) {
            if let session = pomodoroService.currentSession, let taskId = session.relatedTaskId {
                HStack {
                    Image(systemName: "link")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Text("Linked to task")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.1))
                )
            }
            
            // Completed cycles indicator
            if pomodoroService.stats.todaysCompletedSessions > 0 {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#54b702"))
                    
                    Text("\(pomodoroService.stats.todaysCompletedSessions) sessions completed today")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.1))
                )
            }
        }
    }
    
    private var controlButtonsView: some View {
        HStack(spacing: 20) {
            if let session = pomodoroService.currentSession {
                // Pause/Resume button
                Button {
                    if session.isPaused {
                        pomodoroService.resumeSession()
                    } else {
                        pomodoroService.pauseSession()
                    }
                } label: {
                    Image(systemName: session.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "#0278fc"))
                        .clipShape(Circle())
                }
                
                // Stop button
                Button {
                    pomodoroService.stopCurrentSession()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "#ee004a"))
                        .clipShape(Circle())
                }
            } else {
                // Start buttons
                Button {
                    pomodoroService.startSession(type: .work, relatedTaskId: selectedTask?.id)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 20, weight: .medium))
                        Text("Work")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(Color(hex: "#ee004a"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Button {
                    pomodoroService.startSession(type: .shortBreak)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 20, weight: .medium))
                        Text("Break")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(Color(hex: "#54b702"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
    
    private var quickActionsView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Quick Actions")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button {
                    showingTaskPicker = true
                } label: {
                    HStack {
                        Image(systemName: selectedTask != nil ? "link" : "plus")
                            .font(.system(size: 14))
                        Text(selectedTask?.title ?? "Link Task")
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white.opacity(0.2))
                    )
                }
                
                Button {
                    pomodoroService.startQuickWork(duration: 15)
                } label: {
                    Text("Quick 15min")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "#0278fc"))
                        )
                }
                
                Button {
                    pomodoroService.startQuickWork(duration: 45)
                } label: {
                    Text("Deep 45min")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "#d300ee"))
                        )
                }
            }
        }
    }
    
    private var todaysStatsView: some View {
        HStack(spacing: 15) {
            StatCard(
                title: "Sessions",
                value: "\(pomodoroService.stats.todaysCompletedSessions)",
                icon: "checkmark.circle.fill",
                color: Color(hex: "#54b702")
            )
            
            StatCard(
                title: "Focus Time",
                value: formatTime(pomodoroService.weeklyFocusTime),
                icon: "clock.fill",
                color: Color(hex: "#0278fc")
            )
            
            StatCard(
                title: "Goal",
                value: "\(Int(pomodoroService.stats.todaysProgress * 100))%",
                icon: "target",
                color: Color(hex: "#ee004a")
            )
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

struct PomodoroSettingsView: View {
    @ObservedObject var service: PomodoroService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Timer durations
                VStack(alignment: .leading, spacing: 16) {
                    Text("Timer Durations")
                        .font(.system(size: 18, weight: .semibold))
                    
                    VStack(spacing: 12) {
                        DurationSetting(
                            title: "Work Session",
                            value: $service.settings.workDurationMinutes,
                            range: 15...60,
                            color: Color(hex: "#ee004a")
                        )
                        
                        DurationSetting(
                            title: "Short Break",
                            value: $service.settings.shortBreakDurationMinutes,
                            range: 3...15,
                            color: Color(hex: "#54b702")
                        )
                        
                        DurationSetting(
                            title: "Long Break",
                            value: $service.settings.longBreakDurationMinutes,
                            range: 10...30,
                            color: Color(hex: "#0278fc")
                        )
                    }
                }
                
                // Auto-start settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("Auto-start")
                        .font(.system(size: 18, weight: .semibold))
                    
                    VStack(spacing: 8) {
                        Toggle("Auto-start breaks", isOn: $service.settings.autoStartBreaks)
                        Toggle("Auto-start work", isOn: $service.settings.autoStartWork)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#0278fc")))
                }
                
                // Notification settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("Notifications & Sounds")
                        .font(.system(size: 18, weight: .semibold))
                    
                    VStack(spacing: 8) {
                        Toggle("Sound alerts", isOn: $service.settings.soundEnabled)
                        Toggle("Vibration", isOn: $service.settings.vibrationEnabled)
                        Toggle("Push notifications", isOn: $service.settings.notificationEnabled)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#0278fc")))
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Pomodoro Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        service.saveSettings()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DurationSetting: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                
                Text("\(value) minutes")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Int($0) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
            .accentColor(color)
            .frame(width: 120)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct TaskPickerView: View {
    @Binding var selectedTask: Task?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var taskViewModel = TaskViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Current selection
                if let selectedTask = selectedTask {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected Task")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                            
                            Text(selectedTask.title)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        Spacer()
                        
                        Button("Remove") {
                            self.selectedTask = nil
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.red)
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Task list
                List {
                    ForEach(taskViewModel.todaysTasks) { task in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text(task.formattedDeadline)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedTask?.id == task.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color(hex: "#54b702"))
                            }
                        }
                        .onTapGesture {
                            selectedTask = task
                            dismiss()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .navigationTitle("Link Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            taskViewModel.loadTasks()
        }
    }
}

#Preview {
    PomodoroView()
}
