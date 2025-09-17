//
//  AnalyticsView.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct AnalyticsView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    @State private var showingInsights = false
    
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
                
                // Time range selector
                timeRangeSelector
                
                // Analytics content
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Key metrics
                        keyMetricsView
                        
                        // Chart based on selected metric
                        chartView
                        
                        // Insights
                        insightsView
                        
                        // Category breakdown
                        categoryBreakdownView
                        
                        // Productivity trends
                        productivityTrendsView
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            viewModel.refreshAnalytics()
        }
        .sheet(isPresented: $showingInsights) {
            ProductivityInsightsView(viewModel: viewModel)
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Analytics")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Track your productivity")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button {
                showingInsights = true
            } label: {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var timeRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AnalyticsViewModel.TimeRange.allCases, id: \.self) { range in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.selectedTimeRange = range
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: range.systemImage)
                                .font(.system(size: 12))
                            Text(range.rawValue)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(viewModel.selectedTimeRange == range ? .white : .white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(viewModel.selectedTimeRange == range ? Color(hex: "#0278fc") : .white.opacity(0.1))
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
    }
    
    private var keyMetricsView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Key Metrics")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(
                    title: "Productivity Score",
                    value: String(format: "%.0f%%", viewModel.analytics.productivityScore * 100),
                    icon: "chart.line.uptrend.xyaxis",
                    color: Color(hex: "#54b702"),
                    trend: .up
                )
                
                MetricCard(
                    title: "Tasks Completed",
                    value: "\(viewModel.analytics.totalTasksCompleted)",
                    icon: "checkmark.circle.fill",
                    color: Color(hex: "#0278fc"),
                    trend: .stable
                )
                
                MetricCard(
                    title: "Current Streak",
                    value: "\(viewModel.analytics.streakCount) days",
                    icon: "flame.fill",
                    color: Color(hex: "#ee004a"),
                    trend: viewModel.analytics.streakCount > 0 ? .up : .down
                )
                
                MetricCard(
                    title: "Time Tracked",
                    value: formatTime(viewModel.analytics.totalTimeTracked),
                    icon: "clock.fill",
                    color: Color(hex: "#fff707"),
                    trend: .stable
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Trends")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                // Metric selector
                Menu {
                    ForEach(AnalyticsViewModel.AnalyticsMetric.allCases, id: \.self) { metric in
                        Button {
                            viewModel.selectedMetric = metric
                        } label: {
                            HStack {
                                Image(systemName: metric.systemImage)
                                Text(metric.rawValue)
                                if viewModel.selectedMetric == metric {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.selectedMetric.systemImage)
                        Text(viewModel.selectedMetric.rawValue)
                        Image(systemName: "chevron.down")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white.opacity(0.2))
                    )
                }
            }
            
            // Simple line chart representation
            SimpleLineChart(
                data: chartDataForSelectedMetric,
                color: colorForSelectedMetric
            )
            .frame(height: 200)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var insightsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Insights")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button {
                    showingInsights = true
                } label: {
                    Text("View All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#0278fc"))
                }
            }
            
            let insights = viewModel.generateInsights()
            
            if insights.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Text("Complete more tasks to see insights")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(insights.prefix(3)) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var categoryBreakdownView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Breakdown")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
            
            if viewModel.categoryChartData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Text("No category data available")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.categoryChartData) { dataPoint in
                        CategoryRow(
                            category: dataPoint.label,
                            value: Int(dataPoint.value),
                            percentage: dataPoint.value / viewModel.categoryChartData.reduce(0) { $0 + $1.value },
                            color: dataPoint.color
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
    
    private var productivityTrendsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Overview")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
            
            if viewModel.analytics.dailyStats.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Text("No data available yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.analytics.dailyStats.prefix(7).enumerated()), id: \.offset) { index, dailyStat in
                        DayOverviewRow(
                            dayName: dayName(for: dailyStat.date),
                            tasksCompleted: dailyStat.tasksCompleted,
                            productivityScore: dailyStat.productivityScore,
                            isToday: Calendar.current.isDate(dailyStat.date, inSameDayAs: Date())
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
    
    private var chartDataForSelectedMetric: [ChartDataPoint] {
        switch viewModel.selectedMetric {
        case .productivity:
            return viewModel.productivityChartData
        case .timeSpent:
            return viewModel.timeSpentChartData
        case .taskCompletion:
            return viewModel.taskCompletionChartData
        default:
            return viewModel.productivityChartData
        }
    }
    
    private var colorForSelectedMetric: Color {
        switch viewModel.selectedMetric {
        case .productivity:
            return Color(hex: "#54b702")
        case .timeSpent:
            return Color(hex: "#0278fc")
        case .taskCompletion:
            return Color(hex: "#ee004a")
        case .categories:
            return Color(hex: "#d300ee")
        case .priorities:
            return Color(hex: "#fff707")
        case .trends:
            return Color(hex: "#54b702")
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        if hours > 0 {
            return "\(hours)h"
        } else {
            let minutes = Int(seconds) / 60
            return "\(minutes)m"
        }
    }
    
    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDate(date, inSameDayAs: Date()) {
            return "Today"
        } else {
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: ProductivityInsight.TrendDirection
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(color)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(trend.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.1))
        )
    }
}

struct SimpleLineChart: View {
    let data: [ChartDataPoint]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            if data.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Text("No data available")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ZStack {
                    // Background grid
                    Path { path in
                        let stepY = geometry.size.height / 4
                        for i in 0...4 {
                            let y = CGFloat(i) * stepY
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                    }
                    .stroke(.white.opacity(0.1), lineWidth: 1)
                    
                    // Chart line
                    Path { path in
                        guard !data.isEmpty else { return }
                        
                        let maxValue = data.map { $0.value }.max() ?? 1
                        let minValue = data.map { $0.value }.min() ?? 0
                        let valueRange = maxValue - minValue
                        
                        let stepX = geometry.size.width / CGFloat(data.count - 1)
                        
                        for (index, point) in data.enumerated() {
                            let x = CGFloat(index) * stepX
                            let normalizedValue = valueRange > 0 ? (point.value - minValue) / valueRange : 0.5
                            let y = geometry.size.height - (normalizedValue * geometry.size.height)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    
                    // Data points
                    ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                        let maxValue = data.map { $0.value }.max() ?? 1
                        let minValue = data.map { $0.value }.min() ?? 0
                        let valueRange = maxValue - minValue
                        
                        let stepX = geometry.size.width / CGFloat(data.count - 1)
                        let x = CGFloat(index) * stepX
                        let normalizedValue = valueRange > 0 ? (point.value - minValue) / valueRange : 0.5
                        let y = geometry.size.height - (normalizedValue * geometry.size.height)
                        
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                    }
                }
            }
        }
    }
}

struct InsightCard: View {
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
                
                if let recommendation = insight.recommendation {
                    Text(recommendation)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: "#0278fc"))
                        .lineLimit(1)
                }
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

struct CategoryRow: View {
    let category: String
    let value: Int
    let percentage: Double
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(category)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
            
            Spacer()
            
            Text("\(value)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
            
            Text("(\(String(format: "%.0f", percentage * 100))%)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

struct DayOverviewRow: View {
    let dayName: String
    let tasksCompleted: Int
    let productivityScore: Double
    let isToday: Bool
    
    var body: some View {
        HStack {
            Text(dayName)
                .font(.system(size: 14, weight: isToday ? .bold : .medium))
                .foregroundStyle(isToday ? Color(hex: "#0278fc") : .white)
                .frame(width: 60, alignment: .leading)
            
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index < tasksCompleted ? Color(hex: "#54b702") : .white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            Spacer()
            
            Text(String(format: "%.0f%%", productivityScore * 100))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

struct ProductivityInsightsView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    let insights = viewModel.generateInsights()
                    
                    if insights.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "lightbulb")
                                .font(.system(size: 60, weight: .light))
                                .foregroundStyle(.secondary)
                            
                            VStack(spacing: 8) {
                                Text("No insights available")
                                    .font(.system(size: 20, weight: .semibold))
                                
                                Text("Complete more tasks to generate insights")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(40)
                    } else {
                        ForEach(insights) { insight in
                            InsightCard(insight: insight)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Productivity Insights")
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
}

#Preview {
    AnalyticsView(viewModel: AnalyticsViewModel())
}



