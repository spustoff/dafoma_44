//
//  NoteViewModel.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import SwiftUI

@MainActor
class NoteViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory: NoteCategory?
    @Published var sortOption: NoteSortOption = .modified
    @Published var showPinnedOnly = false
    
    private let dataService = DataPersistenceService.shared
    
    enum NoteSortOption: String, CaseIterable {
        case modified = "Last Modified"
        case created = "Created"
        case alphabetical = "Alphabetical"
        case category = "Category"
        case wordCount = "Word Count"
        
        var systemImage: String {
            switch self {
            case .modified:
                return "clock.arrow.circlepath"
            case .created:
                return "calendar.badge.plus"
            case .alphabetical:
                return "textformat.abc"
            case .category:
                return "folder"
            case .wordCount:
                return "textformat.size"
            }
        }
    }
    
    init() {
        loadNotes()
    }
    
    // MARK: - Data Loading
    
    func loadNotes() {
        isLoading = true
        errorMessage = nil
        
        notes = dataService.loadNotes()
        print("✅ Notes loaded: \(notes.count)")
        
        isLoading = false
    }
    
    func saveNotes() {
        dataService.saveNotes(notes)
        print("✅ Notes saved: \(notes.count)")
    }
    
    // MARK: - Note Management
    
    func addNote(_ note: Note) {
        notes.insert(note, at: 0) // Insert at beginning for newest first
        saveNotes()
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            saveNotes()
        }
    }
    
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }
    
    func deleteNote(at indexSet: IndexSet) {
        let notesToDelete = indexSet.map { filteredNotes[$0] }
        for note in notesToDelete {
            deleteNote(note)
        }
    }
    
    func duplicateNote(_ note: Note) {
        var newNote = note
        newNote.title = "\(note.title) (Copy)"
        newNote.createdAt = Date()
        newNote.modifiedAt = Date()
        newNote.isPinned = false
        
        addNote(newNote)
    }
    
    func toggleNotePinned(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].isPinned.toggle()
            notes[index].modifiedAt = Date()
            saveNotes()
        }
    }
    
    func updateNoteContent(_ noteId: UUID, title: String, content: String) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].title = title
            notes[index].content = content
            notes[index].modifiedAt = Date()
            saveNotes()
        }
    }
    
    func addTagToNote(_ noteId: UUID, tag: String) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].addTag(tag)
            saveNotes()
        }
    }
    
    func removeTagFromNote(_ noteId: UUID, tag: String) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].removeTag(tag)
            saveNotes()
        }
    }
    
    func linkNoteToTask(_ noteId: UUID, taskId: UUID) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].linkToTask(taskId)
            saveNotes()
        }
    }
    
    func unlinkNoteFromTask(_ noteId: UUID) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].unlinkFromTask()
            saveNotes()
        }
    }
    
    // MARK: - Filtering and Sorting
    
    var filteredNotes: [Note] {
        var filtered = notes
        
        // Filter by pinned status
        if showPinnedOnly {
            filtered = filtered.filter { $0.isPinned }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText) ||
                note.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Sort
        return sortNotes(filtered)
    }
    
    private func sortNotes(_ notes: [Note]) -> [Note] {
        let pinned = notes.filter { $0.isPinned }
        let unpinned = notes.filter { !$0.isPinned }
        
        func sortByOption(_ notes: [Note]) -> [Note] {
            switch sortOption {
            case .modified:
                return notes.sorted { $0.modifiedAt > $1.modifiedAt }
            case .created:
                return notes.sorted { $0.createdAt > $1.createdAt }
            case .alphabetical:
                return notes.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            case .category:
                return notes.sorted { $0.category.rawValue.localizedCaseInsensitiveCompare($1.category.rawValue) == .orderedAscending }
            case .wordCount:
                return notes.sorted { $0.wordCount > $1.wordCount }
            }
        }
        
        // Always show pinned notes first
        return sortByOption(pinned) + sortByOption(unpinned)
    }
    
    // MARK: - Statistics
    
    var noteStatistics: NoteStatistics {
        let total = notes.count
        let pinned = notes.filter { $0.isPinned }.count
        let totalWords = notes.reduce(0) { $0 + $1.wordCount }
        let totalCharacters = notes.reduce(0) { $0 + $1.characterCount }
        let averageWordsPerNote = total > 0 ? totalWords / total : 0
        
        let categoryBreakdown = Dictionary(grouping: notes, by: { $0.category })
            .mapValues { $0.count }
        
        let recentNotes = notes.filter { 
            Calendar.current.isDate($0.createdAt, inSameDayAs: Date()) ||
            Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.contains($0.createdAt) == true
        }.count
        
        return NoteStatistics(
            totalNotes: total,
            pinnedNotes: pinned,
            totalWords: totalWords,
            totalCharacters: totalCharacters,
            averageWordsPerNote: averageWordsPerNote,
            categoryBreakdown: categoryBreakdown,
            recentNotes: recentNotes
        )
    }
    
    var pinnedNotes: [Note] {
        notes.filter { $0.isPinned }
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }
    
    var recentNotes: [Note] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return notes.filter { $0.modifiedAt >= sevenDaysAgo }
            .sorted { $0.modifiedAt > $1.modifiedAt }
            .prefix(10)
            .map { $0 }
    }
    
    var categorizedNotes: [NoteCategory: [Note]] {
        Dictionary(grouping: notes, by: { $0.category })
    }
    
    // MARK: - Search and Filters
    
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        sortOption = .modified
        showPinnedOnly = false
    }
    
    var hasActiveFilters: Bool {
        !searchText.isEmpty || selectedCategory != nil || showPinnedOnly
    }
    
    func searchNotes(by query: String) -> [Note] {
        guard !query.isEmpty else { return notes }
        
        return notes.filter { note in
            note.title.localizedCaseInsensitiveContains(query) ||
            note.content.localizedCaseInsensitiveContains(query) ||
            note.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    // MARK: - Bulk Operations
    
    func deleteAllNotes(in category: NoteCategory) {
        notes.removeAll { $0.category == category }
        saveNotes()
    }
    
    func unpinAllNotes() {
        for index in notes.indices {
            if notes[index].isPinned {
                notes[index].isPinned = false
                notes[index].modifiedAt = Date()
            }
        }
        saveNotes()
    }
    
    func exportNotes() -> String {
        let exportText = notes.map { note in
            """
            # \(note.title)
            
            **Category:** \(note.category.rawValue)
            **Created:** \(note.formattedCreatedDate)
            **Modified:** \(note.formattedModifiedDate)
            **Tags:** \(note.tags.joined(separator: ", "))
            
            \(note.content)
            
            ---
            
            """
        }.joined(separator: "\n")
        
        return exportText
    }
    
    // MARK: - Tag Management
    
    var allTags: [String] {
        let allTags = notes.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }
    
    func notesWithTag(_ tag: String) -> [Note] {
        notes.filter { $0.tags.contains(tag) }
    }
    
    func removeTag(_ tag: String) {
        for index in notes.indices {
            notes[index].tags.removeAll { $0 == tag }
            if !notes[index].tags.isEmpty {
                notes[index].modifiedAt = Date()
            }
        }
        saveNotes()
    }
    
    func renameTag(from oldTag: String, to newTag: String) {
        for index in notes.indices {
            if let tagIndex = notes[index].tags.firstIndex(of: oldTag) {
                notes[index].tags[tagIndex] = newTag
                notes[index].modifiedAt = Date()
            }
        }
        saveNotes()
    }
}

struct NoteStatistics {
    let totalNotes: Int
    let pinnedNotes: Int
    let totalWords: Int
    let totalCharacters: Int
    let averageWordsPerNote: Int
    let categoryBreakdown: [NoteCategory: Int]
    let recentNotes: Int
    
    var formattedTotalWords: String {
        if totalWords >= 1000 {
            return String(format: "%.1fK", Double(totalWords) / 1000.0)
        }
        return "\(totalWords)"
    }
    
    var formattedTotalCharacters: String {
        if totalCharacters >= 1000 {
            return String(format: "%.1fK", Double(totalCharacters) / 1000.0)
        }
        return "\(totalCharacters)"
    }
}
