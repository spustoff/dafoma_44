//
//  TaskListView.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct TaskListView: View {
    @ObservedObject var viewModel: TaskViewModel
    let onTaskTapped: (Task) -> Void
    
    @State private var showingAddTask = false
    @State private var showingFilters = false
    @State private var showingSortOptions = false
    
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
                
                // Search and filters
                searchAndFiltersView
                
                // Task list
                taskListView
            }
        }
        .sheet(isPresented: $showingAddTask) {
            TaskDetailView(task: nil, viewModel: viewModel)
        }
        .sheet(isPresented: $showingFilters) {
            TaskFiltersView(viewModel: viewModel)
        }
        .refreshable {
            viewModel.loadTasks()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tasks")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("\(viewModel.filteredTasks.count) task\(viewModel.filteredTasks.count == 1 ? "" : "s")")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button {
                    showingFilters = true
                } label: {
                    Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                }
                
                Button {
                    showingAddTask = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var searchAndFiltersView: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.6))
                
                TextField("Search tasks...", text: $viewModel.searchText)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            
            // Sort and toggle options
            HStack {
                // Sort picker
                Menu {
                    ForEach(TaskViewModel.TaskSortOption.allCases, id: \.self) { option in
                        Button {
                            viewModel.sortOption = option
                        } label: {
                            HStack {
                                Image(systemName: option.systemImage)
                                Text(option.rawValue)
                                if viewModel.sortOption == option {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: viewModel.sortOption.systemImage)
                        Text(viewModel.sortOption.rawValue)
                        Image(systemName: "chevron.down")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                    )
                }
                
                Spacer()
                
                // Show completed toggle
                Toggle("Show Completed", isOn: $viewModel.showCompletedTasks)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#54b702")))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private var taskListView: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                    
                    Text("Loading tasks...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredTasks.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredTasks) { task in
                            TaskCard(
                                task: task,
                                onToggle: { viewModel.toggleTaskCompletion(task) },
                                onTap: { onTaskTapped(task) },
                                onDuplicate: { viewModel.duplicateTask(task) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease" : "checkmark.circle")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(.white.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(viewModel.hasActiveFilters ? "No tasks found" : "No tasks yet")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text(viewModel.hasActiveFilters ? "Try adjusting your filters" : "Add your first task to get started")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            if viewModel.hasActiveFilters {
                Button {
                    viewModel.clearFilters()
                } label: {
                    Text("Clear Filters")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#0278fc"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Button {
                    showingAddTask = true
                } label: {
                    Text("Add First Task")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#54b702"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

struct TaskCard: View {
    let task: Task
    let onToggle: () -> Void
    let onTap: () -> Void
    let onDuplicate: () -> Void
    
    @State private var showingContextMenu = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Completion button
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(task.isCompleted ? Color(hex: "#54b702") : .white.opacity(0.6))
                }
                
                // Task content
                VStack(alignment: .leading, spacing: 8) {
                    // Title and priority
                    HStack {
                Text(task.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(task.isCompleted ? .white.opacity(0.6) : .white)
                    .lineLimit(2)
                        
                        Spacer()
                        
                        Image(systemName: task.priority.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(task.priorityColor)
                    }
                    
                    // Description (if exists)
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(2)
                    }
                    
                    // Deadline and category
                    HStack {
                        Label(task.formattedDeadline, systemImage: "clock")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: task.category.icon)
                                .font(.system(size: 10))
                            Text(task.category.rawValue)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(task.categoryColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(task.categoryColor.opacity(0.2))
                        .clipShape(Capsule())
                    }
                    
                    // Tags (if any)
                    if !task.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(task.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(hex: "#d300ee"))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                    
                    // Status indicators
                    HStack(spacing: 8) {
                        if task.isOverdue && !task.isCompleted {
                            Label("OVERDUE", systemImage: "exclamationmark.triangle.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#ee004a"))
                                .clipShape(Capsule())
                        }
                        
                        if task.reminderEnabled {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: "#fff707"))
                        }
                        
                        Spacer()
                        
                        if task.estimatedDuration > 0 {
                            Text("\(Int(task.estimatedDuration / 60))min")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
                
                // Priority indicator
                Rectangle()
                    .fill(task.priorityColor)
                    .frame(width: 4)
                    .clipShape(Capsule())
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
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
                onDuplicate()
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Button {
                onToggle()
            } label: {
                Label(task.isCompleted ? "Mark Incomplete" : "Mark Complete", 
                      systemImage: task.isCompleted ? "circle" : "checkmark.circle")
            }
        }
    }
}

struct TaskFiltersView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    categorySection
                    prioritySection
                    clearFiltersSection
                }
                .padding(20)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(TaskCategory.allCases, id: \.self) { category in
                    categoryButton(for: category)
                }
            }
        }
    }
    
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Priority")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    priorityButton(for: priority)
                }
            }
        }
    }
    
    private var clearFiltersSection: some View {
        Group {
            if viewModel.hasActiveFilters {
                Button {
                    viewModel.clearFilters()
                    dismiss()
                } label: {
                    Text("Clear All Filters")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color(hex: "#ee004a"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private func categoryButton(for category: TaskCategory) -> some View {
        Button {
            if viewModel.selectedCategory == category {
                viewModel.selectedCategory = nil
            } else {
                viewModel.selectedCategory = category
            }
        } label: {
            HStack {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(viewModel.selectedCategory == category ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.selectedCategory == category ? categoryColor(for: category) : Color(.systemGray6))
            )
        }
    }
    
    private func priorityButton(for priority: TaskPriority) -> some View {
        Button {
            if viewModel.selectedPriority == priority {
                viewModel.selectedPriority = nil
            } else {
                viewModel.selectedPriority = priority
            }
        } label: {
            HStack {
                Image(systemName: priority.icon)
                    .font(.system(size: 14))
                Text(priority.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(viewModel.selectedPriority == priority ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.selectedPriority == priority ? Color(hex: "#0278fc") : Color(.systemGray6))
            )
        }
    }
    
    private func categoryColor(for category: TaskCategory) -> Color {
        switch category {
        case .personal:
            return Color(hex: "#0278fc") // Blue
        case .work:
            return Color(hex: "#ee004a") // Red
        case .health:
            return Color(hex: "#54b702") // Green
        case .education:
            return Color(hex: "#d300ee") // Purple
        case .finance:
            return Color(hex: "#fff707") // Yellow
        case .other:
            return Color.gray
        }
    }
}

#Preview {
    TaskListView(viewModel: TaskViewModel(), onTaskTapped: { _ in })
}
