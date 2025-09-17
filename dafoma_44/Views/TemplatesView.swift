//
//  TemplatesView.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct TemplatesView: View {
    @StateObject private var viewModel = TemplateViewModel()
    @State private var selectedSegment = 0
    @State private var showingAddTemplate = false
    @State private var showingAddRecurring = false
    @State private var selectedTemplate: TaskTemplate?
    @State private var selectedRecurring: RecurringTask?
    
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
                
                // Segment control
                segmentControlView
                
                // Content based on selection
                if selectedSegment == 0 {
                    templatesContentView
                } else {
                    recurringTasksContentView
                }
            }
        }
        .sheet(isPresented: $showingAddTemplate) {
            TemplateDetailView(template: nil, viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddRecurring) {
            RecurringTaskDetailView(recurringTask: nil, viewModel: viewModel)
        }
        .sheet(item: $selectedTemplate) { template in
            TemplateDetailView(template: template, viewModel: viewModel)
        }
        .sheet(item: $selectedRecurring) { recurring in
            RecurringTaskDetailView(recurringTask: recurring, viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadTemplates()
            viewModel.loadRecurringTasks()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Templates")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Save time with reusable templates")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button {
                if selectedSegment == 0 {
                    showingAddTemplate = true
                } else {
                    showingAddRecurring = true
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var segmentControlView: some View {
        HStack(spacing: 0) {
            ForEach(["Templates", "Recurring"], id: \.self) { segment in
                let index = segment == "Templates" ? 0 : 1
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
        .padding(.vertical, 16)
    }
    
    private var templatesContentView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Popular templates
                if !viewModel.popularTemplates.isEmpty {
                    popularTemplatesSection
                }
                
                // All templates
                allTemplatesSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    private var popularTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Templates")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.popularTemplates) { template in
                        PopularTemplateCard(
                            template: template,
                            onTap: { selectedTemplate = template },
                            onUse: { useTemplate(template) }
                        )
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
    
    private var allTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Templates")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
            
            if viewModel.filteredTemplates.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: "No templates yet",
                    subtitle: "Create templates for frequently used tasks",
                    buttonTitle: "Create Template",
                    action: { showingAddTemplate = true }
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.filteredTemplates) { template in
                        TemplateRow(
                            template: template,
                            onTap: { selectedTemplate = template },
                            onUse: { useTemplate(template) }
                        )
                    }
                }
            }
        }
    }
    
    private var recurringTasksContentView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recurring Tasks")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    if viewModel.filteredRecurringTasks.isEmpty {
                        EmptyStateView(
                            icon: "arrow.clockwise",
                            title: "No recurring tasks",
                            subtitle: "Set up tasks that repeat automatically",
                            buttonTitle: "Create Recurring Task",
                            action: { showingAddRecurring = true }
                        )
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.filteredRecurringTasks) { recurring in
                                RecurringTaskCard(
                                    recurringTask: recurring,
                                    onTap: { selectedRecurring = recurring },
                                    onToggleActive: { viewModel.toggleRecurringTaskActive(recurring) }
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    private func useTemplate(_ template: TaskTemplate) {
        let task = viewModel.createTaskFromTemplate(template)
        
        // Notify TaskViewModel about new task
        NotificationCenter.default.post(
            name: NSNotification.Name("TaskCreatedFromTemplate"),
            object: nil,
            userInfo: ["task": task]
        )
        
        print("✅ Created task from template: \(template.title)")
    }
}

struct PopularTemplateCard: View {
    let template: TaskTemplate
    let onTap: () -> Void
    let onUse: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: template.category.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(template.categoryColor)
                
                Spacer()
                
                Text("\(template.usageCount)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Text(template.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(height: 36, alignment: .topLeading)
            
            Spacer()
            
            Button {
                onUse()
            } label: {
                Text("Use")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#0278fc"))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(12)
        .frame(width: 140, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .onTapGesture {
            onTap()
        }
    }
}

struct TemplateRow: View {
    let template: TaskTemplate
    let onTap: () -> Void
    let onUse: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: template.category.icon)
                .font(.system(size: 20))
                .foregroundStyle(template.categoryColor)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(template.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                HStack {
                    Text(template.category.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text("•")
                        .foregroundStyle(.white.opacity(0.4))
                    
                    Text(template.formattedEstimatedDuration)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    if template.usageCount > 0 {
                        Text("•")
                            .foregroundStyle(.white.opacity(0.4))
                        
                        Text("Used \(template.usageCount) times")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            Button {
                onUse()
            } label: {
                Text("Use")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#54b702"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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

struct RecurringTaskCard: View {
    let recurringTask: RecurringTask
    let onTap: () -> Void
    let onToggleActive: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Image(systemName: recurringTask.recurrenceRule.type.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(recurringTask.categoryColor)
                
                if recurringTask.isOverdue {
                    Text("OVERDUE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color(hex: "#ee004a"))
                        .clipShape(Capsule())
                }
            }
            .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recurringTask.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(recurringTask.isActive ? .white : .white.opacity(0.6))
                    .lineLimit(1)
                
                Text(recurringTask.recurrenceRule.description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                
                Text("Next: \(recurringTask.formattedNextDue)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Toggle("", isOn: Binding(
                    get: { recurringTask.isActive },
                    set: { _ in onToggleActive() }
                ))
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#54b702")))
                .labelsHidden()
                
                Text(recurringTask.isActive ? "Active" : "Inactive")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(recurringTask.isActive ? 0.1 : 0.05))
        )
        .onTapGesture {
            onTap()
        }
    }
}

struct TemplateDetailView: View {
    let template: TaskTemplate?
    @ObservedObject var viewModel: TemplateViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var category = TaskCategory.personal
    @State private var priority = TaskPriority.medium
    @State private var estimatedDuration: Double = 60 // minutes
    @State private var defaultDeadlineOffset: Double = 1 // days
    @State private var reminderEnabled = true
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var showingDeleteConfirmation = false
    
    private var isEditing: Bool { template != nil }
    
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
                            TextField("Template title", text: $title)
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
                        
                        // Category and priority
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category")
                                    .font(.system(size: 14, weight: .semibold))
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
                        
                        // Duration and deadline
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Estimated Duration: \(Int(estimatedDuration)) minutes")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                
                                Slider(value: $estimatedDuration, in: 15...480, step: 15)
                                    .accentColor(Color(hex: "#0278fc"))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Default Deadline: \(Int(defaultDeadlineOffset)) day\(Int(defaultDeadlineOffset) == 1 ? "" : "s") from now")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                
                                Slider(value: $defaultDeadlineOffset, in: 0.5...30, step: 0.5)
                                    .accentColor(Color(hex: "#54b702"))
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                        
                        // Tags
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tags")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            HStack {
                                TextField("Add tag", text: $newTag)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                                    .onSubmit { addTag() }
                                
                                Button("Add", action: addTag)
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
                            
                            if !tags.isEmpty {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                                    ForEach(tags, id: \.self) { tag in
                                        HStack {
                                            Text(tag)
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundStyle(.white)
                                            
                                            Button {
                                                removeTag(tag)
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(hex: "#d300ee"))
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        
                        // Delete button (only when editing)
                        if isEditing {
                            Button {
                                showingDeleteConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Delete Template")
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
            .overlay(alignment: .top) {
                // Custom navigation bar
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text(isEditing ? "Edit Template" : "New Template")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button("Save") {
                        saveTemplate()
                    }
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .semibold))
                    .disabled(title.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
            }
        }
        .onAppear {
            loadTemplateData()
        }
        .confirmationDialog(
            "Delete Template",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let template = template {
                    viewModel.deleteTemplate(template)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func loadTemplateData() {
        if let template = template {
            title = template.title
            description = template.description
            category = template.category
            priority = template.priority
            estimatedDuration = template.estimatedDuration / 60
            defaultDeadlineOffset = template.defaultDeadlineOffset / 86400
            reminderEnabled = template.reminderEnabled
            tags = template.tags
        }
    }
    
    private func saveTemplate() {
        if let existingTemplate = template {
            var templateToSave = existingTemplate
            templateToSave.title = title
            templateToSave.description = description
            templateToSave.category = category
            templateToSave.priority = priority
            templateToSave.estimatedDuration = estimatedDuration * 60
            templateToSave.defaultDeadlineOffset = defaultDeadlineOffset * 86400
            templateToSave.reminderEnabled = reminderEnabled
            templateToSave.tags = tags
            
            viewModel.updateTemplate(templateToSave)
        } else {
            var newTemplate = TaskTemplate(
                title: title,
                description: description,
                category: category,
                priority: priority,
                estimatedDuration: estimatedDuration * 60,
                defaultDeadlineOffset: defaultDeadlineOffset * 86400
            )
            newTemplate.reminderEnabled = reminderEnabled
            newTemplate.tags = tags
            
            viewModel.addTemplate(newTemplate)
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

struct RecurringTaskDetailView: View {
    let recurringTask: RecurringTask?
    @ObservedObject var viewModel: TemplateViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var category = TaskCategory.personal
    @State private var priority = TaskPriority.medium
    @State private var estimatedDuration: Double = 60
    @State private var recurrenceType = RecurrenceType.daily
    @State private var interval = 1
    @State private var timeOfDay = Date()
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var showingDeleteConfirmation = false
    
    private var isEditing: Bool { recurringTask != nil }
    
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
                            TextField("Recurring task title", text: $title)
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
                        
                        // Recurrence settings
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recurrence")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            VStack(spacing: 12) {
                                Picker("Type", selection: $recurrenceType) {
                                    ForEach(RecurrenceType.allCases, id: \.self) { type in
                                        HStack {
                                            Image(systemName: type.icon)
                                            Text(type.rawValue)
                                        }
                                        .tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                                
                                DatePicker("Time", selection: $timeOfDay, displayedComponents: [.hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .accentColor(Color(hex: "#0278fc"))
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                        }
                        
                        // Category and priority
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category")
                                    .font(.system(size: 14, weight: .semibold))
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
                        
                        // Duration
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Estimated Duration: \(Int(estimatedDuration)) minutes")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            Slider(value: $estimatedDuration, in: 15...480, step: 15)
                                .accentColor(Color(hex: "#0278fc"))
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                        
                        // Delete button (only when editing)
                        if isEditing {
                            Button {
                                showingDeleteConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Delete Recurring Task")
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
            .overlay(alignment: .top) {
                // Custom navigation bar
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text(isEditing ? "Edit Recurring Task" : "New Recurring Task")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button("Save") {
                        saveRecurringTask()
                    }
                    .foregroundStyle(.white)
                    .font(.system(size: 16, weight: .semibold))
                    .disabled(title.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
            }
        }
        .onAppear {
            loadRecurringTaskData()
        }
        .confirmationDialog(
            "Delete Recurring Task",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let recurringTask = recurringTask {
                    viewModel.deleteRecurringTask(recurringTask)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func loadRecurringTaskData() {
        if let recurringTask = recurringTask {
            title = recurringTask.title
            description = recurringTask.description
            category = recurringTask.category
            priority = recurringTask.priority
            estimatedDuration = recurringTask.estimatedDuration / 60
            recurrenceType = recurringTask.recurrenceRule.type
            interval = recurringTask.recurrenceRule.interval
            timeOfDay = recurringTask.recurrenceRule.timeOfDay
        }
    }
    
    private func saveRecurringTask() {
        let recurrenceRule = RecurrenceRule(
            type: recurrenceType,
            interval: interval,
            timeOfDay: timeOfDay
        )
        
        if let existingRecurring = recurringTask {
            var recurringToSave = existingRecurring
            recurringToSave.title = title
            recurringToSave.description = description
            recurringToSave.category = category
            recurringToSave.priority = priority
            recurringToSave.estimatedDuration = estimatedDuration * 60
            recurringToSave.recurrenceRule = recurrenceRule
            
            viewModel.updateRecurringTask(recurringToSave)
        } else {
            let newRecurring = RecurringTask(
                title: title,
                description: description,
                category: category,
                priority: priority,
                estimatedDuration: estimatedDuration * 60,
                recurrenceRule: recurrenceRule
            )
            
            viewModel.addRecurringTask(newRecurring)
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
    PomodoroView()
}
