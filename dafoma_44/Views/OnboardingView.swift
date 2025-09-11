//
//  OnboardingView.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var animateElements = false
    @State private var showWelcome = true
    
    private let onboardingPages = OnboardingPage.allPages
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#f1ccc6"), Color(hex: "#53bef4")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if showWelcome {
                welcomeView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8)),
                        removal: .opacity.combined(with: .scale(scale: 1.1))
                    ))
            } else {
                onboardingPagesView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.5)) {
                animateElements = true
            }
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App icon and name
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#ee004a"), Color(hex: "#d300ee")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateElements ? 1 : 0.5)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateElements)
                    
                    Image(systemName: "clock.badge.checkmark.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundStyle(.white)
                        .scaleEffect(animateElements ? 1 : 0.3)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4), value: animateElements)
                }
                
                VStack(spacing: 8) {
                    Text("TimeMaster Sweet")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.6), value: animateElements)
                    
                    Text("Your productivity companion")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.8), value: animateElements)
                }
            }
            
            Spacer()
            
            // Get started button
            Button {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showWelcome = false
                }
            } label: {
                HStack(spacing: 12) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#0278fc"), Color(hex: "#54b702")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .padding(.horizontal, 40)
            .scaleEffect(animateElements ? 1 : 0.8)
            .opacity(animateElements ? 1 : 0)
            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(1.0), value: animateElements)
            
            Spacer()
        }
    }
    
    private var onboardingPagesView: some View {
        VStack(spacing: 0) {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<onboardingPages.count, id: \.self) { index in
                    OnboardingPageView(page: onboardingPages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Bottom controls
            VStack(spacing: 30) {
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
                    }
                }
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentPage -= 1
                            }
                        } label: {
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white.opacity(0.8))
                                .frame(width: 80, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.white.opacity(0.1))
                                )
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    Button {
                        if currentPage < onboardingPages.count - 1 {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(currentPage == onboardingPages.count - 1 ? "Start Using App" : "Next")
                                .font(.system(size: 16, weight: .semibold))
                            
                            if currentPage < onboardingPages.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(height: 44)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#0278fc"), Color(hex: "#54b702")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(.bottom, 50)
        }
    }
    
    private func completeOnboarding() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            hasCompletedOnboarding = true
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var animateContent = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [page.primaryColor.opacity(0.3), page.secondaryColor.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(animateContent ? 1 : 0.8)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateContent)
                
                Image(systemName: page.iconName)
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.primaryColor, page.secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateContent ? 1 : 0.5)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4), value: animateContent)
            }
            
            // Content
            VStack(spacing: 20) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: animateContent)
                
                Text(page.description)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: animateContent)
            }
            .padding(.horizontal, 40)
            
            // Features list
            VStack(spacing: 16) {
                ForEach(Array(page.features.enumerated()), id: \.offset) { index, feature in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(page.primaryColor)
                        
                        Text(feature)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Spacer()
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(x: animateContent ? 0 : -20)
                    .animation(.easeOut(duration: 0.6).delay(1.0 + Double(index) * 0.1), value: animateContent)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .onAppear {
            withAnimation {
                animateContent = true
            }
        }
        .onDisappear {
            animateContent = false
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let iconName: String
    let features: [String]
    let primaryColor: Color
    let secondaryColor: Color
    
    static let allPages: [OnboardingPage] = [
        OnboardingPage(
            title: "Organize Your Tasks",
            description: "Create, manage, and track your tasks with deadlines, priorities, and categories. Never miss an important deadline again.",
            iconName: "list.bullet.clipboard",
            features: [
                "Set deadlines and reminders",
                "Organize by priority and category",
                "Track time spent on tasks"
            ],
            primaryColor: Color(hex: "#ee004a"),
            secondaryColor: Color(hex: "#0278fc")
        ),
        OnboardingPage(
            title: "Take Smart Notes",
            description: "Capture ideas, meeting notes, and important information. Link notes to tasks and organize them by categories.",
            iconName: "note.text",
            features: [
                "Rich text formatting",
                "Link notes to tasks",
                "Organize with tags and categories"
            ],
            primaryColor: Color(hex: "#fff707"),
            secondaryColor: Color(hex: "#54b702")
        ),
        OnboardingPage(
            title: "Plan Your Day",
            description: "Visualize your schedule with an interactive timeline. See your tasks, deadlines, and free time at a glance.",
            iconName: "calendar.badge.clock",
            features: [
                "Interactive timeline view",
                "Drag and drop scheduling",
                "See conflicts and free time"
            ],
            primaryColor: Color(hex: "#0278fc"),
            secondaryColor: Color(hex: "#d300ee")
        ),
        OnboardingPage(
            title: "Track Your Progress",
            description: "Get insights into your productivity patterns with beautiful charts and analytics. Understand how you spend your time.",
            iconName: "chart.xyaxis.line",
            features: [
                "Productivity analytics",
                "Time tracking insights",
                "Weekly and monthly reports"
            ],
            primaryColor: Color(hex: "#54b702"),
            secondaryColor: Color(hex: "#ee004a")
        )
    ]
}

#Preview {
    OnboardingView()
}


