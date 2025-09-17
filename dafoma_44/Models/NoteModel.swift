//
//  NoteModel.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import SwiftUI

struct Note: Identifiable, Codable, Hashable {
    let id = UUID()
    var title: String
    var content: String
    var createdAt: Date
    var modifiedAt: Date
    var tags: [String]
    var category: NoteCategory
    var isPinned: Bool
    var relatedTaskId: UUID?
    var attachments: [String] // File paths or references
    var color: String // Hex color for note styling
    
    init(title: String, content: String = "", category: NoteCategory = .general, color: String = "#0278fc") {
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.tags = []
        self.category = category
        self.isPinned = false
        self.relatedTaskId = nil
        self.attachments = []
        self.color = color
    }
    
    var wordCount: Int {
        content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
    
    var characterCount: Int {
        content.count
    }
    
    var readingTime: Int {
        // Assuming average reading speed of 200 words per minute
        max(1, wordCount / 200)
    }
    
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDate(createdAt, inSameDayAs: Date()) {
            formatter.dateFormat = "HH:mm"
            return "Today at \(formatter.string(from: createdAt))"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: createdAt)
        }
    }
    
    var formattedModifiedDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDate(modifiedAt, inSameDayAs: Date()) {
            formatter.dateFormat = "HH:mm"
            return "Modified today at \(formatter.string(from: modifiedAt))"
        } else {
            formatter.dateStyle = .medium
            return "Modified \(formatter.string(from: modifiedAt))"
        }
    }
    
    var categoryColor: Color {
        category.color
    }
    
    var noteColor: Color {
        Color(hex: color)
    }
    
    var preview: String {
        let maxLength = 100
        if content.count <= maxLength {
            return content
        }
        let index = content.index(content.startIndex, offsetBy: maxLength)
        return String(content[..<index]) + "..."
    }
    
    mutating func updateContent(_ newContent: String) {
        content = newContent
        modifiedAt = Date()
    }
    
    mutating func updateTitle(_ newTitle: String) {
        title = newTitle
        modifiedAt = Date()
    }
    
    mutating func addTag(_ tag: String) {
        if !tags.contains(tag) {
            tags.append(tag)
            modifiedAt = Date()
        }
    }
    
    mutating func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        modifiedAt = Date()
    }
    
    mutating func togglePin() {
        isPinned.toggle()
        modifiedAt = Date()
    }
    
    mutating func linkToTask(_ taskId: UUID) {
        relatedTaskId = taskId
        modifiedAt = Date()
    }
    
    mutating func unlinkFromTask() {
        relatedTaskId = nil
        modifiedAt = Date()
    }
}

enum NoteCategory: String, CaseIterable, Codable {
    case general = "General"
    case ideas = "Ideas"
    case meetings = "Meetings"
    case research = "Research"
    case personal = "Personal"
    case work = "Work"
    case study = "Study"
    case reminders = "Reminders"
    
    var icon: String {
        switch self {
        case .general:
            return "note.text"
        case .ideas:
            return "lightbulb"
        case .meetings:
            return "person.2"
        case .research:
            return "magnifyingglass"
        case .personal:
            return "person"
        case .work:
            return "briefcase"
        case .study:
            return "book"
        case .reminders:
            return "bell"
        }
    }
    
    var color: Color {
        switch self {
        case .general:
            return Color(hex: "#0278fc") // Blue
        case .ideas:
            return Color(hex: "#fff707") // Yellow
        case .meetings:
            return Color(hex: "#54b702") // Green
        case .research:
            return Color(hex: "#d300ee") // Purple
        case .personal:
            return Color(hex: "#ee004a") // Red
        case .work:
            return Color(hex: "#0278fc") // Blue
        case .study:
            return Color(hex: "#54b702") // Green
        case .reminders:
            return Color(hex: "#fff707") // Yellow
        }
    }
}

struct NoteListItem: Identifiable {
    let id = UUID()
    var text: String
    var isCompleted: Bool
    var createdAt: Date
    
    init(text: String) {
        self.text = text
        self.isCompleted = false
        self.createdAt = Date()
    }
    
    mutating func toggle() {
        isCompleted.toggle()
    }
}



