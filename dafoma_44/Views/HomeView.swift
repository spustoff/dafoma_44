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
                    
                    // Notes Tab
                    NoteListView(
                        viewModel: noteViewModel,
                        onNoteTapped: { note in
                            selectedNote = note
                            showingNoteDetail = true
                        }
                    )
                    .tabItem {
                        Image(systemName: "note.text")
                        Text("Notes")
                    }
                    .tag(2)
                    
                    // Planner Tab
                    PlannerView(
                        taskViewModel: taskViewModel,
                        onTaskTapped: { task in
                            selectedTask = task
                            showingTaskDetail = true
                        }
                    )
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Planner")
                    }
                    .tag(3)
                    
                    // Analytics Tab
                    AnalyticsView(viewModel: analyticsViewModel)
                        .tabItem {
                            Image(systemName: "chart.xyaxis.line")
                            Text("Analytics")
                        }
                        .tag(4)
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
                
                // Today's Tasks
                todaysTasksView
                
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
                title: "Completed",
                value: "\(taskViewModel.taskStatistics.completedTasks)",
                icon: "checkmark.circle.fill",
                color: Color(hex: "#0278fc")
            )
            
            StatCard(
                title: "Productivity",
                value: String(format: "%.0f%%", analyticsViewModel.analytics.productivityScore * 100),
                icon: "chart.line.uptrend.xyaxis",
                color: Color(hex: "#ee004a")
            )
        }
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
                    title: "View Planner",
                    icon: "calendar.badge.clock",
                    color: Color(hex: "#0278fc"),
                    action: { /* Switch to planner tab */ }
                )
                
                QuickActionButton(
                    title: "Analytics",
                    icon: "chart.xyaxis.line",
                    color: Color(hex: "#ee004a"),
                    action: { /* Switch to analytics tab */ }
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

#Preview {
    HomeView()
}
