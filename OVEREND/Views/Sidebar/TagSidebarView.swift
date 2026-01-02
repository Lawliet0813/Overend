//
//  TagSidebarView.swift
//  OVEREND
//
//  標籤側邊欄視圖
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct TagSidebarView: View {
    @ObservedObject var library: Library
    @Binding var selectedTag: Tag?
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var isAddingTag = false
    @State private var newTagName = ""
    @State private var editingTag: Tag?
    @State private var editingName = ""
    
    var tags: [Tag] {
        let set = library.tags as? Set<Tag> ?? []
        return set.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("TAGS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    isAddingTag = true
                }) {
                    Image(systemName: "plus")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isAddingTag) {
                    VStack(spacing: 12) {
                        TextField("Tag Name", text: $newTagName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                        
                        HStack {
                            Button("Cancel") {
                                isAddingTag = false
                                newTagName = ""
                            }
                            
                            Button("Add") {
                                createTag()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(newTagName.isEmpty)
                        }
                    }
                    .padding()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            // Tag List
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(tags) { tag in
                        TagRow(tag: tag, isSelected: selectedTag == tag) {
                            selectedTag = (selectedTag == tag) ? nil : tag
                        }
                        .contextMenu {
                            Button("Rename") {
                                editingTag = tag
                                editingName = tag.name
                            }
                            
                            Divider()
                            
                            Button("Delete", role: .destructive) {
                                deleteTag(tag)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .sheet(item: $editingTag) { tag in
            VStack(spacing: 20) {
                Text("Rename Tag")
                    .font(.headline)
                
                TextField("Name", text: $editingName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
                
                HStack {
                    Button("Cancel") {
                        editingTag = nil
                    }
                    
                    Button("Save") {
                        tag.name = editingName
                        saveContext()
                        editingTag = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(editingName.isEmpty)
                }
            }
            .padding()
            .frame(width: 300, height: 150)
        }
    }
    
    private func createTag() {
        let tag = Tag(context: viewContext, name: newTagName, library: library)
        // Assign a random color from a preset palette
        let colors = ["#FF3B30", "#FF9500", "#FFCC00", "#4CD964", "#5AC8FA", "#007AFF", "#5856D6", "#FF2D55"]
        tag.colorHex = colors.randomElement() ?? "#007AFF"
        
        saveContext()
        newTagName = ""
        isAddingTag = false
    }
    
    private func deleteTag(_ tag: Tag) {
        viewContext.delete(tag)
        saveContext()
        if selectedTag == tag {
            selectedTag = nil
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

struct TagRow: View {
    @ObservedObject var tag: Tag
    var isSelected: Bool
    var action: () -> Void
    
    @State private var isTargeted = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(tag.color)
                    .frame(width: 8, height: 8)
                
                Text(tag.name)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                Text("\(tag.entryCount)")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor : (isTargeted ? Color.gray.opacity(0.1) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onDrop(of: [.text], isTargeted: $isTargeted) { providers in
            // Handle drop logic here (assigning entries to tag)
            // This requires passing the dropped entry IDs
            return true
        }
    }
}
