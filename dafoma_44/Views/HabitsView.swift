//
//  HabitsView.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct HabitsView: View {
    @StateObject private var viewModel = HabitViewModel()
    @State private var showingAddHabit = false
    @State private var showingHabitDetail = false
    @State private var selectedHabit: Habit?
    
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
                headerView
                
                // Quick stats
                quickStatsView
                
                // Today's habits
                todaysHabitsView
                
                // All habits
                allHabitsView
            }
        }
        .sheet(isPresented: $showingAddHabit) {
            HabitDetailView(habit: nil, viewModel: viewModel)
        }
        .sheet(item: $selectedHabit) { habit in
            HabitDetailView(habit: habit, viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadHabits()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Habits")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Build better routines")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button {
                showingAddHabit = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var quickStatsView: some View {
        let stats = viewModel.habitStatistics
        
        return HStack(spacing: 15) {
            StatCard(
                title: "Completed Today",
                value: "\(stats.completedToday)/\(stats.activeHabits)",
                icon: "checkmark.circle.fill",
                color: Color(hex: "#54b702")
            )
            
            StatCard(
                title: "Avg Streak",
                value: String(format: "%.0f", stats.averageStreak),
                icon: "flame.fill",
                color: Color(hex: "#ee004a")
            )
            
            StatCard(
                title: "Best Streak",
                value: "\(stats.longestStreak)",
                icon: "trophy.fill",
                color: Color(hex: "#fff707")
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var todaysHabitsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Habits")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text("\(viewModel.habitStatistics.completedTodayPercentage)% Complete")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            if viewModel.todaysHabits.isEmpty {
                Text("No active habits")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.todaysHabits) { habit in
                        TodayHabitCard(
                            habit: habit,
                            onTap: { selectedHabit = habit },
                            onComplete: { value in
                                viewModel.recordHabitCompletion(habit.id, value: value)
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
        .padding(.horizontal, 20)
    }
    
    private var allHabitsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("All Habits")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Toggle("Show Inactive", isOn: $viewModel.showInactiveHabits)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#0278fc")))
            }
            
            if viewModel.filteredHabits.isEmpty {
                Text("No habits found")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredHabits) { habit in
                        HabitCard(
                            habit: habit,
                            onTap: { selectedHabit = habit },
                            onToggleActive: { viewModel.toggleHabitActive(habit) }
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
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

struct TodayHabitCard: View {
    let habit: Habit
    let onTap: () -> Void
    let onComplete: (Double) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                onComplete(1.0)
            } label: {
                Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(habit.isCompletedToday ? Color(hex: "#54b702") : .white.opacity(0.6))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                HStack {
                    if habit.targetValue > 1 {
                        Text("\(Int(habit.todaysProgress))/\(Int(habit.targetValue)) \(habit.unit)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    if habit.streakCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: "#ee004a"))
                            Text("\(habit.streakCount)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(hex: "#ee004a"))
                        }
                    }
                }
            }
            
            Spacer()
            
            if habit.targetValue > 1 && !habit.isCompletedToday {
                CircularProgressView(
                    progress: habit.todaysProgress / habit.targetValue,
                    color: habit.categoryColor,
                    size: 32
                )
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

struct HabitCard: View {
    let habit: Habit
    let onTap: () -> Void
    let onToggleActive: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Image(systemName: habit.category.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(habit.categoryColor)
                
                if habit.streakCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(Color(hex: "#ee004a"))
                        Text("\(habit.streakCount)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color(hex: "#ee004a"))
                    }
                }
            }
            .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(habit.isActive ? .white : .white.opacity(0.6))
                    .lineLimit(1)
                
                Text(habit.frequency.description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                
                HStack {
                    Text("\(Int(habit.targetValue)) \(habit.unit)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Text("Best: \(habit.bestStreak)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                CircularProgressView(
                    progress: habit.weeklyProgress,
                    color: habit.categoryColor,
                    size: 32
                )
                
                Text("\(Int(habit.weeklyProgress * 100))%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(habit.isActive ? 0.1 : 0.05))
        )
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button {
                onTap()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button {
                onToggleActive()
            } label: {
                Label(habit.isActive ? "Deactivate" : "Activate", 
                      systemImage: habit.isActive ? "pause.circle" : "play.circle")
            }
        }
    }
}

struct HabitDetailView: View {
    let habit: Habit?
    @ObservedObject var viewModel: HabitViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var category = HabitCategory.health
    @State private var frequency = HabitFrequency.daily
    @State private var targetValue: Double = 1
    @State private var unit = "times"
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    @State private var showingDeleteConfirmation = false
    
    private var isEditing: Bool { habit != nil }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "#f1ccc6"), Color(hex: "#53bef4")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Basic info
                        VStack(spacing: 16) {
                            TextField("Habit title", text: $title)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                            
                            TextEditor(text: $description)
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                                .background(Color.clear)
                                .frame(minHeight: 60)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        
                        // Category and frequency
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                
                                Picker("Category", selection: $category) {
                                    ForEach(HabitCategory.allCases, id: \.self) { category in
                                        HStack {
                                            Image(systemName: category.icon)
                                            Text(category.rawValue)
                                        }
                                        .tag(category)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.ultraThinMaterial)
                                )
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Frequency")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                
                                Menu {
                                    Button("Daily") { frequency = .daily }
                                    Button("Weekly") { frequency = .weekly }
                                    Button("Every 2 days") { frequency = .custom(days: 2) }
                                    Button("Every 3 days") { frequency = .custom(days: 3) }
                                } label: {
                                    HStack {
                                        Image(systemName: frequency.icon)
                                        Text(frequency.description)
                                        Image(systemName: "chevron.down")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.ultraThinMaterial)
                                    )
                                }
                            }
                        }
                        
                        // Target value and unit
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            HStack {
                                TextField("Target", value: $targetValue, format: .number)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                
                                TextField("Unit", text: $unit)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: 100)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        
                        // Reminder settings
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Daily Reminder", isOn: $reminderEnabled)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#54b702")))
                            
                            if reminderEnabled {
                                DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: [.hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .accentColor(Color(hex: "#0278fc"))
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                        
                        // Statistics (if editing)
                        if isEditing, let habit = habit {
                            habitStatsSection(for: habit)
                        }
                        
                        // Delete button (only when editing)
                        if isEditing {
                            Button {
                                showingDeleteConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Delete Habit")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(Color(hex: "#ee004a"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .safeAreaInset(edge: .top) {
                // Custom navigation bar
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text(isEditing ? "Edit Habit" : "New Habit")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button("Save") {
                        saveHabit()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .disabled(title.isEmpty || targetValue <= 0)
                    .opacity((title.isEmpty || targetValue <= 0) ? 0.5 : 1.0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .top)
                )
            }
        }
        .onAppear {
            loadHabitData()
        }
        .confirmationDialog(
            "Delete Habit",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let habit = habit {
                    viewModel.deleteHabit(habit)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func habitStatsSection(for habit: Habit) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Current Streak")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#ee004a"))
                        Text("\(habit.streakCount) days")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                
                HStack {
                    Text("Best Streak")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(habit.bestStreak) days")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                HStack {
                    Text("Weekly Progress")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(Int(habit.weeklyProgress * 100))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func loadHabitData() {
        if let habit = habit {
            title = habit.title
            description = habit.description
            category = habit.category
            frequency = habit.frequency
            targetValue = habit.targetValue
            unit = habit.unit
            reminderEnabled = habit.reminderEnabled
            reminderTime = habit.reminderTime ?? Date()
        }
    }
    
    private func saveHabit() {
        if let existingHabit = habit {
            var habitToSave = existingHabit
            habitToSave.title = title
            habitToSave.description = description
            habitToSave.category = category
            habitToSave.frequency = frequency
            habitToSave.targetValue = targetValue
            habitToSave.unit = unit
            habitToSave.reminderEnabled = reminderEnabled
            habitToSave.reminderTime = reminderEnabled ? reminderTime : nil
            
            viewModel.updateHabit(habitToSave)
        } else {
            var newHabit = Habit(
                title: title,
                description: description,
                category: category,
                frequency: frequency,
                targetValue: targetValue,
                unit: unit
            )
            newHabit.reminderEnabled = reminderEnabled
            newHabit.reminderTime = reminderEnabled ? reminderTime : nil
            
            viewModel.addHabit(newHabit)
        }
        
        dismiss()
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 3)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}

#Preview {
    HabitsView()
}
