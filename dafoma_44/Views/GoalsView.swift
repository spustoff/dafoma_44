//
//  GoalsView.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct GoalsView: View {
    @StateObject private var viewModel = GoalViewModel()
    @State private var showingAddGoal = false
    @State private var showingGoalDetail = false
    @State private var selectedGoal: Goal?
    
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
                
                // Goals list
                goalsListView
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            GoalDetailView(goal: nil, viewModel: viewModel)
        }
        .sheet(item: $selectedGoal) { goal in
            GoalDetailView(goal: goal, viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadGoals()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Goals")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("\(viewModel.filteredGoals.count) goal\(viewModel.filteredGoals.count == 1 ? "" : "s")")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button {
                showingAddGoal = true
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
        let stats = viewModel.goalStatistics
        
        return HStack(spacing: 15) {
            StatCard(
                title: "Active",
                value: "\(stats.activeGoals)",
                icon: "target",
                color: Color(hex: "#0278fc")
            )
            
            StatCard(
                title: "Completed",
                value: "\(stats.completedGoals)",
                icon: "checkmark.circle.fill",
                color: Color(hex: "#54b702")
            )
            
            StatCard(
                title: "Progress",
                value: String(format: "%.0f%%", stats.averageProgress * 100),
                icon: "chart.line.uptrend.xyaxis",
                color: Color(hex: "#ee004a")
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var goalsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.filteredGoals.isEmpty {
                    emptyStateView
                } else {
                    ForEach(viewModel.filteredGoals) { goal in
                        GoalCard(
                            goal: goal,
                            onTap: { selectedGoal = goal },
                            onProgressUpdate: { value in
                                viewModel.updateGoalProgress(goal.id, newValue: value)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(.white.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No goals yet")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text("Set your first goal to start tracking progress")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingAddGoal = true
            } label: {
                Text("Create First Goal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#54b702"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

struct GoalCard: View {
    let goal: Goal
    let onTap: () -> Void
    let onProgressUpdate: (Double) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    
                    if !goal.description.isEmpty {
                        Text(goal.description)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(goal.progressPercentage)%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(goal.formattedDeadline)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(Int(goal.currentValue)) / \(Int(goal.targetValue)) \(goal.unit)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Spacer()
                    
                    if goal.isOverdue && !goal.isCompleted {
                        Text("OVERDUE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#ee004a"))
                            .clipShape(Capsule())
                    }
                }
                
                ProgressView(value: goal.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: goal.categoryColor))
                    .scaleEffect(y: 2)
                
                // Next milestone
                if let nextMilestone = goal.nextMilestone {
                    HStack {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "#fff707"))
                        
                        Text("Next: \(nextMilestone.title)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text("\(Int(nextMilestone.targetValue - goal.currentValue)) \(goal.unit) to go")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            
            // Footer
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: goal.category.icon)
                        .font(.system(size: 10))
                    Text(goal.category.rawValue)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(goal.categoryColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(goal.categoryColor.opacity(0.2))
                .clipShape(Capsule())
                
                Spacer()
                
                Image(systemName: goal.priority.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(goal.priority == .high || goal.priority == .critical ? Color(hex: "#ee004a") : .white.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .onTapGesture {
            onTap()
        }
    }
}

struct GoalDetailView: View {
    let goal: Goal?
    @ObservedObject var viewModel: GoalViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var targetValue: Double = 10
    @State private var currentValue: Double = 0
    @State private var unit = "tasks"
    @State private var deadline = Date()
    @State private var category = GoalCategory.personal
    @State private var priority = TaskPriority.medium
    @State private var milestones: [Milestone] = []
    @State private var newMilestoneTitle = ""
    @State private var newMilestoneValue: Double = 5
    @State private var showingDeleteConfirmation = false
    
    private var isEditing: Bool { goal != nil }
    
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
                        // Title and description
                        VStack(alignment: .leading, spacing: 16) {
                            TextField("Goal title", text: $title)
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
                                .frame(minHeight: 80)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        
                        // Target and current values
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 16) {
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
                                            .frame(maxWidth: 80)
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.ultraThinMaterial)
                                    )
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Current")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                    
                                    TextField("Current", value: $currentValue, format: .number)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.white)
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(.ultraThinMaterial)
                                        )
                                }
                            }
                            
                            // Progress visualization
                            if targetValue > 0 {
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Progress: \(Int((currentValue / targetValue) * 100))%")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white)
                                        
                                        Spacer()
                                        
                                        Text("\(Int(max(0, targetValue - currentValue))) \(unit) remaining")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(.white.opacity(0.7))
                                    }
                                    
                                    ProgressView(value: currentValue / targetValue)
                                        .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "#54b702")))
                                        .scaleEffect(y: 2)
                                }
                            }
                        }
                        
                        // Category, Priority, Deadline
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Category")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                    
                                    Picker("Category", selection: $category) {
                                        ForEach(GoalCategory.allCases, id: \.self) { category in
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
                                    Text("Priority")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                    
                                    Picker("Priority", selection: $priority) {
                                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                                            HStack {
                                                Image(systemName: priority.icon)
                                                Text(priority.rawValue)
                                            }
                                            .tag(priority)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.ultraThinMaterial)
                                    )
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Deadline")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                
                                DatePicker("Deadline", selection: $deadline, displayedComponents: [.date])
                                    .datePickerStyle(.compact)
                                    .accentColor(Color(hex: "#0278fc"))
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                        }
                        
                        // Milestones
                        milestonesSection
                        
                        // Delete button (only when editing)
                        if isEditing {
                            Button {
                                showingDeleteConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Delete Goal")
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
                    
                    Text(isEditing ? "Edit Goal" : "New Goal")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button("Save") {
                        saveGoal()
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
            loadGoalData()
        }
        .confirmationDialog(
            "Delete Goal",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let goal = goal {
                    viewModel.deleteGoal(goal)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestones")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            
            // Add milestone
            HStack {
                TextField("Milestone title", text: $newMilestoneTitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                
                TextField("Value", value: $newMilestoneValue, format: .number)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .frame(width: 60)
                
                Button("Add") {
                    addMilestone()
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "#0278fc"))
                .clipShape(Capsule())
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
            )
            
            // Milestones list
            if !milestones.isEmpty {
                VStack(spacing: 8) {
                    ForEach(milestones.sorted { $0.targetValue < $1.targetValue }) { milestone in
                        MilestoneRow(
                            milestone: milestone,
                            currentValue: currentValue,
                            unit: unit,
                            onDelete: { removeMilestone(milestone) }
                        )
                    }
                }
            }
        }
    }
    
    private func loadGoalData() {
        if let goal = goal {
            title = goal.title
            description = goal.description
            targetValue = goal.targetValue
            currentValue = goal.currentValue
            unit = goal.unit
            deadline = goal.deadline
            category = goal.category
            priority = goal.priority
            milestones = goal.milestones
        }
    }
    
    private func saveGoal() {
        if let existingGoal = goal {
            var goalToSave = existingGoal
            goalToSave.title = title
            goalToSave.description = description
            goalToSave.targetValue = targetValue
            goalToSave.currentValue = currentValue
            goalToSave.unit = unit
            goalToSave.deadline = deadline
            goalToSave.category = category
            goalToSave.priority = priority
            goalToSave.milestones = milestones
            
            viewModel.updateGoal(goalToSave)
        } else {
            var newGoal = Goal(
                title: title,
                description: description,
                targetValue: targetValue,
                unit: unit,
                deadline: deadline,
                category: category,
                priority: priority
            )
            newGoal.currentValue = currentValue
            newGoal.milestones = milestones
            
            viewModel.addGoal(newGoal)
        }
        
        dismiss()
    }
    
    private func addMilestone() {
        guard !newMilestoneTitle.isEmpty && newMilestoneValue > 0 && newMilestoneValue <= targetValue else { return }
        
        let milestone = Milestone(
            title: newMilestoneTitle,
            targetValue: newMilestoneValue
        )
        
        milestones.append(milestone)
        newMilestoneTitle = ""
        newMilestoneValue = targetValue / 2
    }
    
    private func removeMilestone(_ milestone: Milestone) {
        milestones.removeAll { $0.id == milestone.id }
    }
}

struct MilestoneRow: View {
    let milestone: Milestone
    let currentValue: Double
    let unit: String
    let onDelete: () -> Void
    
    private var isCompleted: Bool {
        currentValue >= milestone.targetValue
    }
    
    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundStyle(isCompleted ? Color(hex: "#54b702") : .white.opacity(0.6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                
                Text("\(Int(milestone.targetValue)) \(unit)")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.white.opacity(0.1))
        )
    }
}

#Preview {
    GoalsView()
}
