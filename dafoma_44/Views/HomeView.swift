//
//  HomeView.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var noteViewModel = NoteViewModel()
    @StateObject private var analyticsViewModel = AnalyticsViewModel()
    @StateObject private var goalViewModel = GoalViewModel()
    @StateObject private var habitViewModel = HabitViewModel()
    @StateObject private var templateViewModel = TemplateViewModel()
    
    @State private var selectedTab = 0
    @State private var showingTaskDetail = false
    @State private var showingNoteDetail = false
    @State private var selectedTask: Task?
    @State private var selectedNote: Note?
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                backgroundGradient
                
                TabView(selection: $selectedTab) {
                    // Dashboard Tab
                    DashboardView(
                        taskViewModel: taskViewModel,
                        noteViewModel: noteViewModel,
                        analyticsViewModel: analyticsViewModel,
                        goalViewModel: goalViewModel,
                        habitViewModel: habitViewModel,
                        onTaskTapped: { task in
                            selectedTask = task
                            showingTaskDetail = true
                        },
                        onNoteTapped: { note in
                            selectedNote = note
                            showingNoteDetail = true
                        }
                    )
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)
                    
                    // Tasks Tab
                    TaskListView(
                        viewModel: taskViewModel,
                        onTaskTapped: { task in
                            selectedTask = task
                            showingTaskDetail = true
                        }
                    )
                    .tabItem {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Tasks")
                    }
                    .tag(1)
                    
                    // Goals & Habits Tab
                    GoalsHabitsTabView(
                        goalViewModel: goalViewModel,
                        habitViewModel: habitViewModel
                    )
                    .tabItem {
                        Image(systemName: "target")
                        Text("Goals")
                    }
                    .tag(2)
                    
                    // Focus Timer Tab
                    PomodoroView()
                        .tabItem {
                            Image(systemName: "timer")
                            Text("Focus")
                        }
                        .tag(3)
                    
                    // Templates Tab
                    TemplatesView()
                        .tabItem {
                            Image(systemName: "doc.text")
                            Text("Templates")
                        }
                        .tag(4)
                    
                    // More Tab (Notes, Planner, Analytics)
                    MoreTabView(
                        noteViewModel: noteViewModel,
                        taskViewModel: taskViewModel,
                        analyticsViewModel: analyticsViewModel,
                        onTaskTapped: { task in
                            selectedTask = task
                            showingTaskDetail = true
                        },
                        onNoteTapped: { note in
                            selectedNote = note
                            showingNoteDetail = true
                        }
                    )
                    .tabItem {
                        Image(systemName: "ellipsis")
                        Text("More")
                    }
                    .tag(5)
                }
                .accentColor(Color(hex: "#0278fc"))
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task, viewModel: taskViewModel)
        }
        .sheet(item: $selectedNote) { note in
            NoteDetailView(note: note, viewModel: noteViewModel)
        }
        .onAppear {
            setupNotificationCategories()
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(hex: "#f1ccc6"), Color(hex: "#53bef4")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private func setupNotificationCategories() {
        _Concurrency.Task {
            await NotificationService.shared.setupNotificationCategories()
        }
    }
}

struct DashboardView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var noteViewModel: NoteViewModel
    @ObservedObject var analyticsViewModel: AnalyticsViewModel
    @ObservedObject var goalViewModel: GoalViewModel
    @ObservedObject var habitViewModel: HabitViewModel
    
    let onTaskTapped: (Task) -> Void
    let onNoteTapped: (Note) -> Void
    
    @State private var showingAddTask = false
    @State private var showingAddNote = false
    @State private var showingSettings = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 20) {
                // Header
                headerView
                
                // Quick Stats
                quickStatsView
                
                // Today's Habits
                todaysHabitsView
                
                // Today's Tasks
                todaysTasksView
                
                // Active Goals Progress
                activeGoalsView
                
                // Recent Notes
                recentNotesView
                
                // Productivity Insights
                productivityInsightsView
                
                // Quick Actions
                quickActionsView
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .refreshable {
            await refreshData()
        }
        .sheet(isPresented: $showingAddTask) {
            TaskDetailView(task: nil, viewModel: taskViewModel)
        }
        .sheet(isPresented: $showingAddNote) {
            NoteDetailView(note: nil, viewModel: noteViewModel)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Let's make today productive!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }
        }
        .padding(.top, 10)
    }
    
    private var quickStatsView: some View {
        HStack(spacing: 15) {
            StatCard(
                title: "Today's Tasks",
                value: "\(taskViewModel.todaysTasks.count)",
                icon: "checkmark.circle.fill",
                color: Color(hex: "#54b702")
            )
            
            StatCard(
                title: "Habits Done",
                value: "\(habitViewModel.habitStatistics.completedToday)/\(habitViewModel.habitStatistics.activeHabits)",
                icon: "flame.fill",
                color: Color(hex: "#ee004a")
            )
            
            StatCard(
                title: "Goals Progress",
                value: String(format: "%.0f%%", goalViewModel.goalStatistics.averageProgress * 100),
                icon: "target",
                color: Color(hex: "#0278fc")
            )
        }
    }
    
    private var todaysHabitsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Habits")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text("\(habitViewModel.habitStatistics.completedTodayPercentage)%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            if habitViewModel.todaysHabits.isEmpty {
                Text("No habits for today")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(habitViewModel.todaysHabits.prefix(3)) { habit in
                        HabitRowView(
                            habit: habit,
                            onComplete: { value in
                                habitViewModel.recordHabitCompletion(habit.id, value: value)
                            }
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var activeGoalsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Goals")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text("\(goalViewModel.goalStatistics.activeGoals) active")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            let activeGoals = goalViewModel.goals.filter { !$0.isCompleted }.prefix(3)
            
            if activeGoals.isEmpty {
                Text("No active goals")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(activeGoals) { goal in
                        GoalRowView(goal: goal)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var todaysTasksView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Tasks")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button {
                    showingAddTask = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
            }
            
            if taskViewModel.todaysTasks.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "No tasks for today",
                    subtitle: "Add a task to get started",
                    buttonTitle: "Add Task",
                    action: { showingAddTask = true }
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(taskViewModel.todaysTasks.prefix(5)) { task in
                        TaskRowView(
                            task: task,
                            onToggle: { taskViewModel.toggleTaskCompletion(task) },
                            onTap: { onTaskTapped(task) }
                        )
                    }
                    
                    if taskViewModel.todaysTasks.count > 5 {
                        Button {
                            // Switch to tasks tab
                            // This would be handled by the parent view
                        } label: {
                            Text("View all \(taskViewModel.todaysTasks.count) tasks")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "#0278fc"))
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var recentNotesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Notes")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button {
                    showingAddNote = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
            }
            
            if noteViewModel.recentNotes.isEmpty {
                EmptyStateView(
                    icon: "note.text",
                    title: "No recent notes",
                    subtitle: "Capture your thoughts and ideas",
                    buttonTitle: "Add Note",
                    action: { showingAddNote = true }
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(noteViewModel.recentNotes.prefix(3)) { note in
                        NoteRowView(
                            note: note,
                            onTap: { onNoteTapped(note) }
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var productivityInsightsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Productivity Insights")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            let insights = analyticsViewModel.generateInsights()
            
            if insights.isEmpty {
                Text("Complete some tasks to see insights")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(insights.prefix(2)) { insight in
                        InsightRowView(insight: insight)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "Add Task",
                    icon: "plus.circle.fill",
                    color: Color(hex: "#54b702"),
                    action: { showingAddTask = true }
                )
                
                QuickActionButton(
                    title: "Add Note",
                    icon: "note.text.badge.plus",
                    color: Color(hex: "#fff707"),
                    action: { showingAddNote = true }
                )
                
                QuickActionButton(
                    title: "Start Focus",
                    icon: "timer",
                    color: Color(hex: "#ee004a"),
                    action: { /* Switch to focus tab */ }
                )
                
                QuickActionButton(
                    title: "Templates",
                    icon: "doc.text",
                    color: Color(hex: "#d300ee"),
                    action: { /* Switch to templates tab */ }
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<22:
            return "Good Evening"
        default:
            return "Good Night"
        }
    }
    
    @MainActor
    private func refreshData() async {
        taskViewModel.loadTasks()
        noteViewModel.loadNotes()
        analyticsViewModel.refreshAnalytics()
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

struct TaskRowView: View {
    let task: Task
    let onToggle: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(task.isCompleted ? Color(hex: "#54b702") : .white.opacity(0.6))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(task.isCompleted ? .white.opacity(0.6) : .white)
                
                HStack(spacing: 8) {
                    Label(task.formattedDeadline, systemImage: "clock")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    if task.isOverdue && !task.isCompleted {
                        Text("OVERDUE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#ee004a"))
                            .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
            
            Rectangle()
                .fill(task.priorityColor)
                .frame(width: 4, height: 40)
                .clipShape(Capsule())
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.1))
        )
        .onTapGesture {
            onTap()
        }
    }
}

struct NoteRowView: View {
    let note: Note
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Spacer()
                
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#fff707"))
                }
            }
            
            Text(note.preview)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(2)
            
            HStack {
                Label(note.formattedModifiedDate, systemImage: "clock")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: note.category.icon)
                        .font(.system(size: 10))
                    Text(note.category.rawValue)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(note.categoryColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(note.categoryColor.opacity(0.2))
                .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.1))
        )
        .onTapGesture {
            onTap()
        }
    }
}

struct InsightRowView: View {
    let insight: ProductivityInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.trend.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(insight.trend.color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text(insight.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.1))
        )
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.1))
            )
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.white.opacity(0.6))
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "#0278fc"))
                    )
            }
        }
        .padding(.vertical, 20)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color(hex: "#0278fc"))
                        
                        VStack(alignment: .leading) {
                            Text("TimeMaster User")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Free Plan")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Notifications") {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(Color(hex: "#fff707"))
                        Text("Task Reminders")
                    }
                    
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundStyle(Color(hex: "#54b702"))
                        Text("Daily Planning")
                    }
                }
                
                Section("Data") {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color(hex: "#0278fc"))
                        Text("Export Data")
                    }
                    
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundStyle(Color(hex: "#d300ee"))
                        Text("Import Data")
                    }
                }
                
                Section("Danger Zone") {
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundStyle(Color(hex: "#ee004a"))
                            Text("Delete All Data")
                                .foregroundStyle(Color(hex: "#ee004a"))
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete All Data",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All Data", role: .destructive) {
                DataPersistenceService.shared.resetAllData()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all your tasks, notes, and analytics data. This action cannot be undone.")
        }
    }
}

struct HabitRowView: View {
    let habit: Habit
    let onComplete: (Double) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                onComplete(1.0)
            } label: {
                Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(habit.isCompletedToday ? Color(hex: "#54b702") : .white.opacity(0.6))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                HStack {
                    if habit.targetValue > 1 {
                        Text("\(Int(habit.todaysProgress))/\(Int(habit.targetValue)) \(habit.unit)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    if habit.streakCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Color(hex: "#ee004a"))
                            Text("\(habit.streakCount)")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(Color(hex: "#ee004a"))
                        }
                    }
                }
            }
            
            Spacer()
            
            if habit.targetValue > 1 {
                CircularProgressView(
                    progress: habit.todaysProgress / habit.targetValue,
                    color: habit.categoryColor,
                    size: 24
                )
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.white.opacity(0.1))
        )
    }
}

struct GoalRowView: View {
    let goal: Goal
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text("\(Int(goal.currentValue))/\(Int(goal.targetValue)) \(goal.unit)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(goal.progressPercentage)%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                
                Text(goal.formattedDeadline)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            CircularProgressView(
                progress: goal.progress,
                color: goal.categoryColor,
                size: 24
            )
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.white.opacity(0.1))
        )
    }
}

struct GoalsHabitsTabView: View {
    @ObservedObject var goalViewModel: GoalViewModel
    @ObservedObject var habitViewModel: HabitViewModel
    @State private var selectedSegment = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#f1ccc6"), Color(hex: "#53bef4")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Segment control
                HStack(spacing: 0) {
                    ForEach(["Goals", "Habits"], id: \.self) { segment in
                        let index = segment == "Goals" ? 0 : 1
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedSegment = index
                            }
                        } label: {
                            Text(segment)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(selectedSegment == index ? .white : .white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedSegment == index ? Color(hex: "#0278fc") : Color.clear)
                                )
                        }
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Content
                if selectedSegment == 0 {
                    GoalsView()
                } else {
                    HabitsView()
                }
            }
        }
    }
}

struct MoreTabView: View {
    @ObservedObject var noteViewModel: NoteViewModel
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var analyticsViewModel: AnalyticsViewModel
    
    let onTaskTapped: (Task) -> Void
    let onNoteTapped: (Note) -> Void
    
    @State private var selectedMoreOption = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#f1ccc6"), Color(hex: "#53bef4")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("More")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Options grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    MoreOptionCard(
                        title: "Notes",
                        subtitle: "\(noteViewModel.notes.count) notes",
                        icon: "note.text",
                        color: Color(hex: "#fff707"),
                        action: { selectedMoreOption = 1 }
                    )
                    
                    MoreOptionCard(
                        title: "Planner",
                        subtitle: "Daily schedule",
                        icon: "calendar",
                        color: Color(hex: "#0278fc"),
                        action: { selectedMoreOption = 2 }
                    )
                    
                    MoreOptionCard(
                        title: "Analytics",
                        subtitle: "Productivity insights",
                        icon: "chart.xyaxis.line",
                        color: Color(hex: "#d300ee"),
                        action: { selectedMoreOption = 3 }
                    )
                    
                    MoreOptionCard(
                        title: "Settings",
                        subtitle: "App preferences",
                        icon: "gear",
                        color: Color(hex: "#54b702"),
                        action: { selectedMoreOption = 4 }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Content based on selection
                Group {
                    switch selectedMoreOption {
                    case 1:
                        NoteListView(viewModel: noteViewModel, onNoteTapped: onNoteTapped)
                    case 2:
                        PlannerView(taskViewModel: taskViewModel, onTaskTapped: onTaskTapped)
                    case 3:
                        AnalyticsView(viewModel: analyticsViewModel)
                    case 4:
                        SettingsView()
                    default:
                        EmptyView()
                    }
                }
            }
        }
    }
}

struct MoreOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

#Preview {
    HomeView()
}
