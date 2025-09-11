//
//  NoteListView.swift
//  TimeMaster Sweet
//
//  Created by Вячеслав on 9/9/25.
//

import SwiftUI

struct NoteListView: View {
    @ObservedObject var viewModel: NoteViewModel
    let onNoteTapped: (Note) -> Void
    
    @State private var showingAddNote = false
    @State private var showingFilters = false
    @State private var selectedViewMode: ViewMode = .grid
    
    enum ViewMode: String, CaseIterable {
        case grid = "Grid"
        case list = "List"
        
        var icon: String {
            switch self {
            case .grid:
                return "square.grid.2x2"
            case .list:
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
                
                // Search and filters
                searchAndFiltersView
                
                // Notes content
                notesContentView
            }
        }
        .sheet(isPresented: $showingAddNote) {
            NoteDetailView(note: nil, viewModel: viewModel)
        }
        .sheet(isPresented: $showingFilters) {
            NoteFiltersView(viewModel: viewModel)
        }
        .refreshable {
            viewModel.loadNotes()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("\(viewModel.filteredNotes.count) note\(viewModel.filteredNotes.count == 1 ? "" : "s")")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                // View mode toggle
                Button {
                    selectedViewMode = selectedViewMode == .grid ? .list : .grid
                } label: {
                    Image(systemName: selectedViewMode.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
                
                // Filters
                Button {
                    showingFilters = true
                } label: {
                    Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
                
                // Add note
                Button {
                    showingAddNote = true
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
                
                TextField("Search notes...", text: $viewModel.searchText)
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
                    ForEach(NoteViewModel.NoteSortOption.allCases, id: \.self) { option in
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
                
                // Show pinned only toggle
                Toggle("Pinned Only", isOn: $viewModel.showPinnedOnly)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#fff707")))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private var notesContentView: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                    
                    Text("Loading notes...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredNotes.isEmpty {
                emptyStateView
            } else {
                if selectedViewMode == .grid {
                    gridView
                } else {
                    listView
                }
            }
        }
    }
    
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(viewModel.filteredNotes) { note in
                    NoteGridCard(
                        note: note,
                        onTap: { onNoteTapped(note) },
                        onPin: { viewModel.toggleNotePinned(note) }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredNotes) { note in
                    NoteListCard(
                        note: note,
                        onTap: { onNoteTapped(note) },
                        onPin: { viewModel.toggleNotePinned(note) },
                        onDuplicate: { viewModel.duplicateNote(note) }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease" : "note.text")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(.white.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(viewModel.hasActiveFilters ? "No notes found" : "No notes yet")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text(viewModel.hasActiveFilters ? "Try adjusting your filters" : "Capture your thoughts and ideas")
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
                    showingAddNote = true
                } label: {
                    Text("Create First Note")
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

struct NoteGridCard: View {
    let note: Note
    let onTap: () -> Void
    let onPin: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(note.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                Spacer()
                
                Button(action: onPin) {
                    Image(systemName: note.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 12))
                        .foregroundStyle(note.isPinned ? Color(hex: "#fff707") : .white.opacity(0.6))
                }
            }
            
            // Content preview
            Text(note.preview)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Footer
            VStack(alignment: .leading, spacing: 8) {
                // Tags
                if !note.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(note.tags.prefix(2), id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: "#d300ee"))
                                    .clipShape(Capsule())
                            }
                            
                            if note.tags.count > 2 {
                                Text("+\(note.tags.count - 2)")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                    }
                }
                
                // Category and date
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: note.category.icon)
                            .font(.system(size: 8))
                        Text(note.category.rawValue)
                            .font(.system(size: 8, weight: .medium))
                    }
                    .foregroundStyle(note.categoryColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(note.categoryColor.opacity(0.2))
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    Text(note.formattedModifiedDate)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .padding(16)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: note.color).opacity(0.3), lineWidth: 1)
                )
        )
        .onTapGesture {
            onTap()
        }
    }
}

struct NoteListCard: View {
    let note: Note
    let onTap: () -> Void
    let onPin: () -> Void
    let onDuplicate: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Color indicator
            Rectangle()
                .fill(Color(hex: note.color))
                .frame(width: 4)
                .clipShape(Capsule())
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title and pin
                HStack {
                    Text(note.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#fff707"))
                    }
                }
                
                // Content preview
                Text(note.preview)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
                
                // Tags
                if !note.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(note.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: "#d300ee"))
                                    .clipShape(Capsule())
                            }
                            
                            if note.tags.count > 3 {
                                Text("+\(note.tags.count - 3)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
                
                // Footer
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: note.category.icon)
                            .font(.system(size: 10))
                        Text(note.category.rawValue)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(note.categoryColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(note.categoryColor.opacity(0.2))
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    Text(note.formattedModifiedDate)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                    
                    Text("\(note.wordCount) words")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
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
                onPin()
            } label: {
                Label(note.isPinned ? "Unpin" : "Pin", 
                      systemImage: note.isPinned ? "pin.slash" : "pin")
            }
        }
    }
}

struct NoteFiltersView: View {
    @ObservedObject var viewModel: NoteViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Category filter
                VStack(alignment: .leading, spacing: 12) {
                    Text("Category")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(NoteCategory.allCases, id: \.self) { category in
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
                                        .fill(viewModel.selectedCategory == category ? category.color : Color(.systemGray6))
                                )
                            }
                        }
                    }
                }
                
                // Tags filter
                if !viewModel.allTags.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tags")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(viewModel.allTags.prefix(12), id: \.self) { tag in
                                Button {
                                    // Toggle tag filter (would need to be implemented in ViewModel)
                                } label: {
                                    Text(tag)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.primary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.systemGray6))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Clear filters button
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
            .padding(20)
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
}

#Preview {
    NoteListView(viewModel: NoteViewModel(), onNoteTapped: { _ in })
}


