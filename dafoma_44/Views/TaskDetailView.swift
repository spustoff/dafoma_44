//
//  TaskDetailView.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct TaskDetailView: View {
    let task: Task?
    @ObservedObject var viewModel: TaskViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var deadline = Date()
    @State private var priority = TaskPriority.medium
    @State private var category = TaskCategory.personal
    @State private var estimatedDuration: Double = 60 // minutes
    @State private var reminderEnabled = true
    @State private var reminderTime = Date()
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var showingDeleteConfirmation = false
    
    private var isEditing: Bool { task != nil }
    
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
                        // Title Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Task Title")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            TextField("Enter task title", text: $title)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        
                        // Description Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Description")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                            
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
                        
                        // Deadline Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Deadline")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            DatePicker("Select deadline", selection: $deadline, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .accentColor(Color(hex: "#0278fc"))
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        
                        // Priority and Category Section
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Priority")
                                    .font(.system(size: 16, weight: .semibold))
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
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Category")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                
                                Picker("Category", selection: $category) {
                                    ForEach(TaskCategory.allCases, id: \.self) { category in
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
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                            }
                        }
                        
                        // Estimated Duration Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Estimated Duration")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("\(Int(estimatedDuration)) minutes")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.white)
                                    Spacer()
                                }
                                
                                Slider(value: $estimatedDuration, in: 15...480, step: 15)
                                    .accentColor(Color(hex: "#0278fc"))
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        
                        // Reminder Section
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Enable Reminder", isOn: $reminderEnabled)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#54b702")))
                            
                            if reminderEnabled {
                                DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .accentColor(Color(hex: "#0278fc"))
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                        
                        // Tags Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tags")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            HStack {
                                TextField("Add tag", text: $newTag)
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white)
                                    .onSubmit {
                                        addTag()
                                    }
                                
                                Button("Add", action: addTag)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "#0278fc"))
                                    .clipShape(Capsule())
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                            
                            if !tags.isEmpty {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                    ForEach(tags, id: \.self) { tag in
                                        HStack {
                                            Text(tag)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundStyle(.white)
                                            
                                            Button {
                                                removeTag(tag)
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(hex: "#d300ee"))
                                        .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        // Delete Button (only when editing)
                        if isEditing {
                            Button {
                                showingDeleteConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Delete Task")
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
                
                Text(isEditing ? "Edit Task" : "New Task")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button("Save") {
                    saveTask()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .disabled(title.isEmpty)
                .opacity(title.isEmpty ? 0.5 : 1.0)
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
            loadTaskData()
        }
        .confirmationDialog(
            "Delete Task",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let task = task {
                    viewModel.deleteTask(task)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
    }
    
    private func loadTaskData() {
        if let task = task {
            title = task.title
            description = task.description
            deadline = task.deadline
            priority = task.priority
            category = task.category
            estimatedDuration = task.estimatedDuration / 60 // Convert to minutes
            reminderEnabled = task.reminderEnabled
            reminderTime = task.reminderTime ?? Calendar.current.date(byAdding: .hour, value: -1, to: task.deadline) ?? Date()
            tags = task.tags
        } else {
            // Set default reminder time to 1 hour before deadline
            reminderTime = Calendar.current.date(byAdding: .hour, value: -1, to: deadline) ?? Date()
        }
    }
    
    private func saveTask() {
        var taskToSave: Task
        
        if let existingTask = task {
            taskToSave = existingTask
            taskToSave.title = title
            taskToSave.description = description
            taskToSave.deadline = deadline
            taskToSave.priority = priority
            taskToSave.category = category
            taskToSave.estimatedDuration = estimatedDuration * 60 // Convert to seconds
            taskToSave.reminderEnabled = reminderEnabled
            taskToSave.reminderTime = reminderEnabled ? reminderTime : nil
            taskToSave.tags = tags
            
            viewModel.updateTask(taskToSave)
        } else {
            taskToSave = Task(
                title: title,
                description: description,
                deadline: deadline,
                priority: priority,
                category: category,
                estimatedDuration: estimatedDuration * 60, // Convert to seconds
                reminderEnabled: reminderEnabled
            )
            taskToSave.reminderTime = reminderEnabled ? reminderTime : nil
            taskToSave.tags = tags
            
            viewModel.addTask(taskToSave)
        }
        
        dismiss()
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

#Preview {
    TaskDetailView(task: nil, viewModel: TaskViewModel())
}


