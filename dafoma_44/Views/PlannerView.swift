//
//  PlannerView.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct PlannerView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    let onTaskTapped: (Task) -> Void
    
    @State private var selectedDate = Date()
    @State private var showingAddTask = false
    @State private var viewMode: PlannerViewMode = .timeline
    
    enum PlannerViewMode: String, CaseIterable {
        case timeline = "Timeline"
        case calendar = "Calendar"
        case agenda = "Agenda"
        
        var icon: String {
            switch self {
            case .timeline:
                return "clock"
            case .calendar:
                return "calendar"
            case .agenda:
                return "list.bullet"
            }
        }
    }
    
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
                
                // Date picker and view mode selector
                controlsView
                
                // Content based on view mode
                Group {
                    switch viewMode {
                    case .timeline:
                        TimelineView(
                            tasks: tasksForSelectedDate,
                            selectedDate: selectedDate,
                            onTaskTapped: onTaskTapped
                        )
                    case .calendar:
                        CalendarView(
                            tasks: taskViewModel.tasks,
                            selectedDate: $selectedDate,
                            onTaskTapped: onTaskTapped
                        )
                    case .agenda:
                        AgendaView(
                            tasks: tasksForSelectedDate,
                            selectedDate: selectedDate,
                            onTaskTapped: onTaskTapped
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            TaskDetailView(task: nil, viewModel: taskViewModel)
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Planner")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(selectedDateString)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button {
                showingAddTask = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var controlsView: some View {
        VStack(spacing: 16) {
            // Date picker
            HStack {
                Button {
                    withAnimation {
                        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .accentColor(Color(hex: "#0278fc"))
                    .labelsHidden()
                
                Spacer()
                
                Button {
                    withAnimation {
                        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 20)
            
            // View mode selector
            HStack(spacing: 0) {
                ForEach(PlannerViewMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewMode = mode
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 14))
                            Text(mode.rawValue)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(viewMode == mode ? .white : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(viewMode == mode ? Color(hex: "#0278fc") : Color.clear)
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
        }
        .padding(.vertical, 12)
    }
    
    private var tasksForSelectedDate: [Task] {
        let calendar = Calendar.current
        return taskViewModel.tasks.filter { task in
            calendar.isDate(task.deadline, inSameDayAs: selectedDate) ||
            calendar.isDate(task.createdAt, inSameDayAs: selectedDate)
        }
        .sorted { $0.deadline < $1.deadline }
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        if Calendar.current.isDate(selectedDate, inSameDayAs: Date()) {
            return "Today"
        } else if Calendar.current.isDate(selectedDate, inSameDayAs: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()) {
            return "Tomorrow"
        } else {
            formatter.dateStyle = .full
            return formatter.string(from: selectedDate)
        }
    }
}

struct TimelineView: View {
    let tasks: [Task]
    let selectedDate: Date
    let onTaskTapped: (Task) -> Void
    
    private let hours = Array(0...23)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(hours, id: \.self) { hour in
                    HourSlot(
                        hour: hour,
                        tasks: tasksForHour(hour),
                        onTaskTapped: onTaskTapped
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .scrollTo(currentHour, anchor: .top)
    }
    
    private func tasksForHour(_ hour: Int) -> [Task] {
        let calendar = Calendar.current
        return tasks.filter { task in
            calendar.component(.hour, from: task.deadline) == hour
        }
    }
    
    private var currentHour: Int {
        Calendar.current.component(.hour, from: Date())
    }
}

struct HourSlot: View {
    let hour: Int
    let tasks: [Task]
    let onTaskTapped: (Task) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Time label
            VStack(spacing: 4) {
                Text(hourString)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(periodString)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(width: 60)
            
            // Timeline line
            VStack(spacing: 0) {
                Circle()
                    .fill(isCurrentHour ? Color(hex: "#0278fc") : .white.opacity(0.3))
                    .frame(width: 8, height: 8)
                
                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 1)
                    .frame(minHeight: 60)
            }
            
            // Tasks for this hour
            VStack(alignment: .leading, spacing: 8) {
                if tasks.isEmpty {
                    // Empty slot
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 60)
                } else {
                    ForEach(tasks) { task in
                        TimelineTaskCard(
                            task: task,
                            onTap: { onTaskTapped(task) }
                        )
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var hourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h"
        let date = Calendar.current.date(from: DateComponents(hour: hour)) ?? Date()
        return formatter.string(from: date)
    }
    
    private var periodString: String {
        hour < 12 ? "AM" : "PM"
    }
    
    private var isCurrentHour: Bool {
        Calendar.current.component(.hour, from: Date()) == hour
    }
}

struct TimelineTaskCard: View {
    let task: Task
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(task.priorityColor)
                .frame(width: 4)
                .clipShape(Capsule())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                }
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: task.category.icon)
                            .font(.system(size: 10))
                        Text(task.category.rawValue)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(task.categoryColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(task.categoryColor.opacity(0.2))
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    if task.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#54b702"))
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
        .onTapGesture {
            onTap()
        }
    }
}

struct CalendarView: View {
    let tasks: [Task]
    @Binding var selectedDate: Date
    let onTaskTapped: (Task) -> Void
    
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: currentMonth))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 20)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Weekday headers
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(height: 30)
                }
                
                // Calendar days
                ForEach(daysInMonth, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDate(date, inSameDayAs: Date()),
                        taskCount: tasksForDate(date).count,
                        onTap: {
                            selectedDate = date
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            
            // Tasks for selected date
            if !tasksForSelectedDate.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tasks for \(selectedDateString)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(tasksForSelectedDate) { task in
                                TimelineTaskCard(
                                    task: task,
                                    onTap: { onTaskTapped(task) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxHeight: 200)
                }
            }
            
            Spacer()
        }
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end - 1)
        else { return [] }
        
        var dates: [Date] = []
        var date = monthFirstWeek.start
        
        while date < monthLastWeek.end {
            dates.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return dates
    }
    
    private func tasksForDate(_ date: Date) -> [Task] {
        tasks.filter { calendar.isDate($0.deadline, inSameDayAs: date) }
    }
    
    private var tasksForSelectedDate: [Task] {
        tasksForDate(selectedDate).sorted { $0.deadline < $1.deadline }
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let taskCount: Int
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? .white : (isToday ? Color(hex: "#0278fc") : .white.opacity(0.8)))
                
                if taskCount > 0 {
                    Circle()
                        .fill(Color(hex: "#ee004a"))
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 40, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "#0278fc") : (isToday ? .white.opacity(0.1) : .clear))
            )
        }
    }
}

struct AgendaView: View {
    let tasks: [Task]
    let selectedDate: Date
    let onTaskTapped: (Task) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if tasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 60, weight: .light))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("No tasks scheduled")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            Text("Enjoy your free time!")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(40)
                } else {
                    ForEach(groupedTasks.keys.sorted(), id: \.self) { timeSlot in
                        AgendaSection(
                            title: timeSlot,
                            tasks: groupedTasks[timeSlot] ?? [],
                            onTaskTapped: onTaskTapped
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    private var groupedTasks: [String: [Task]] {
        let calendar = Calendar.current
        var groups: [String: [Task]] = [:]
        
        for task in tasks {
            let hour = calendar.component(.hour, from: task.deadline)
            let timeSlot = timeSlotString(for: hour)
            
            if groups[timeSlot] == nil {
                groups[timeSlot] = []
            }
            groups[timeSlot]?.append(task)
        }
        
        return groups
    }
    
    private func timeSlotString(for hour: Int) -> String {
        switch hour {
        case 0..<6:
            return "Early Morning (12AM - 6AM)"
        case 6..<12:
            return "Morning (6AM - 12PM)"
        case 12..<17:
            return "Afternoon (12PM - 5PM)"
        case 17..<21:
            return "Evening (5PM - 9PM)"
        default:
            return "Night (9PM - 12AM)"
        }
    }
}

struct AgendaSection: View {
    let title: String
    let tasks: [Task]
    let onTaskTapped: (Task) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
            
            ForEach(tasks) { task in
                TimelineTaskCard(
                    task: task,
                    onTap: { onTaskTapped(task) }
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

extension ScrollView {
    func scrollTo<ID: Hashable>(_ id: ID, anchor: UnitPoint = .center) -> some View {
        self.onAppear {
            // This would require a ScrollViewReader wrapper
            // For now, we'll keep it simple
        }
    }
}

#Preview {
    PlannerView(taskViewModel: TaskViewModel(), onTaskTapped: { _ in })
}



