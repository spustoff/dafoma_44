//
//  NoteDetailView.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct NoteDetailView: View {
    let note: Note?
    @ObservedObject var viewModel: NoteViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var category = NoteCategory.general
    @State private var isPinned = false
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var selectedColor = "#0278fc"
    @State private var showingDeleteConfirmation = false
    // @FocusState private var isContentFocused: Bool // iOS 15.0+ feature
    
    private var isEditing: Bool { note != nil }
    
    private let availableColors = [
        "#0278fc", "#ee004a", "#54b702", "#fff707", "#d300ee",
        "#ff6b35", "#00d4aa", "#6c5ce7", "#fd79a8", "#00b894"
    ]
    
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
                
                VStack(spacing: 0) {
                    // Title section
                    VStack(spacing: 12) {
                        TextField("Note title", text: $title)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 20)
                        
                        // Note info
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 12))
                                Text(category.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(category.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(category.color.opacity(0.2))
                            .clipShape(Capsule())
                            
                            if isPinned {
                                HStack(spacing: 4) {
                                    Image(systemName: "pin.fill")
                                        .font(.system(size: 10))
                                    Text("Pinned")
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .foregroundStyle(Color(hex: "#fff707"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#fff707").opacity(0.2))
                                .clipShape(Capsule())
                            }
                            
                            Spacer()
                            
                            Text(isEditing ? "Modified \(note?.formattedModifiedDate ?? "")" : "New note")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.horizontal, 20)
                    
                    // Content section
                    VStack(alignment: .leading, spacing: 0) {
                        // Toolbar
                        HStack {
                            // Category picker
                            Menu {
                                ForEach(NoteCategory.allCases, id: \.self) { cat in
                                    Button {
                                        category = cat
                                    } label: {
                                        HStack {
                                            Image(systemName: cat.icon)
                                            Text(cat.rawValue)
                                            if category == cat {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: category.icon)
                                        .font(.system(size: 14))
                                    Text(category.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.white.opacity(0.2))
                                )
                            }
                            
                            // Pin toggle
                            Button {
                                isPinned.toggle()
                            } label: {
                                Image(systemName: isPinned ? "pin.fill" : "pin")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(isPinned ? Color(hex: "#fff707") : .white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            // Word count
                            if !content.isEmpty {
                                Text("\(content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count) words")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        
                        // Content editor
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                TextEditor(text: $content)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white)
                    .background(Color.clear)
                    .frame(minHeight: 200)
                                
                                Spacer(minLength: 100)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Tags and color section
                    VStack(spacing: 16) {
                        // Tags
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Tags")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                
                                Spacer()
                            }
                            
                            HStack {
                                TextField("Add tag", text: $newTag)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .onSubmit {
                                        addTag()
                                    }
                                
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
                                    .fill(.white.opacity(0.1))
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
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(hex: "#d300ee"))
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        
                        // Color picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Note Color")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                                ForEach(availableColors, id: \.self) { color in
                                    Button {
                                        selectedColor = color
                                    } label: {
                                        Circle()
                                            .fill(Color(hex: color))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Circle()
                                                    .stroke(.white, lineWidth: selectedColor == color ? 3 : 0)
                                            )
                                            .scaleEffect(selectedColor == color ? 1.2 : 1.0)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedColor)
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
                                    Text("Delete Note")
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
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    Spacer()
                }
                .padding(.bottom, 100)
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
                
                Text(isEditing ? "Edit Note" : "New Note")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button("Save") {
                    saveNote()
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
            loadNoteData()
        }
        // .onTapGesture {
        //     isContentFocused = false
        // }
        .confirmationDialog(
            "Delete Note",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let note = note {
                    viewModel.deleteNote(note)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
    }
    
    private func loadNoteData() {
        if let note = note {
            title = note.title
            content = note.content
            category = note.category
            isPinned = note.isPinned
            tags = note.tags
            selectedColor = note.color
        }
    }
    
    private func saveNote() {
        if let existingNote = note {
            var noteToSave = existingNote
            noteToSave.title = title
            noteToSave.content = content
            noteToSave.category = category
            noteToSave.isPinned = isPinned
            noteToSave.tags = tags
            noteToSave.color = selectedColor
            noteToSave.modifiedAt = Date()
            
            viewModel.updateNote(noteToSave)
        } else {
            let newNote = Note(
                title: title,
                content: content,
                category: category,
                color: selectedColor
            )
            var noteToSave = newNote
            noteToSave.isPinned = isPinned
            noteToSave.tags = tags
            
            viewModel.addNote(noteToSave)
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
    NoteDetailView(note: nil, viewModel: NoteViewModel())
}
