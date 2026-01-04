//
//  BatchTagInputView.swift
//  OVEREND
//
//  批次標籤輸入視圖
//

import SwiftUI
import CoreData

struct BatchTagInputView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    // 參數
    let library: Library
    let onApply: ([Tag]) -> Void
    let onCancel: () -> Void
    
    // 狀態
    @State private var searchText = ""
    @State private var selectedTags: Set<Tag> = []
    @State private var availableTags: [Tag] = []
    
    var body: some View {
        VStack(spacing: 16) {
            Text("批次新增標籤")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(theme.textPrimary)
            
            // 搜尋/新增欄位
            TextField("搜尋或建立新標籤...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    createNewTag()
                }
            
            // 已選標籤
            if !selectedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(selectedTags).sorted(by: { $0.name < $1.name })) { tag in
                            TagChip(tag: tag) {
                                selectedTags.remove(tag)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(height: 32)
            }
            
            Divider()
            
            // 可用標籤列表
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("現有標籤")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textMuted)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        ForEach(filteredTags) { tag in
                            Button(action: {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                }
                            }) {
                                Text(tag.name)
                                    .font(.system(size: 12))
                                    .foregroundColor(selectedTags.contains(tag) ? .white : theme.textPrimary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(selectedTags.contains(tag) ? tag.color : theme.itemHover)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(height: 200)
            
            // 按鈕
            HStack {
                Button("取消") {
                    onCancel()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("套用") {
                    onApply(Array(selectedTags))
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
                .disabled(selectedTags.isEmpty && searchText.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400)
        .background(theme.card)
        .onAppear {
            loadTags()
        }
    }
    
    // MARK: - 邏輯
    
    private var filteredTags: [Tag] {
        if searchText.isEmpty {
            return availableTags
        } else {
            return availableTags.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private func loadTags() {
        availableTags = Tag.fetchAll(in: library, context: viewContext)
    }
    
    private func createNewTag() {
        let trimmedName = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // 檢查是否已存在
        if let existingTag = availableTags.first(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            selectedTags.insert(existingTag)
            searchText = ""
            return
        }
        
        // 建立新標籤
        let newTag = Tag(context: viewContext, name: trimmedName, library: library)
        // 隨機顏色
        let colors = ["#FF3B30", "#FF9500", "#FFCC00", "#4CD964", "#5AC8FA", "#007AFF", "#5856D6", "#FF2D55"]
        newTag.colorHex = colors.randomElement() ?? "#007AFF"
        
        do {
            try viewContext.save()
            availableTags.append(newTag)
            selectedTags.insert(newTag)
            searchText = ""
        } catch {
            print("Failed to create tag: \(error)")
        }
    }
}

// 標籤晶片視圖
struct TagChip: View {
    let tag: Tag
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag.name)
                .font(.system(size: 12))
                .foregroundColor(.white)
            
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tag.color)
        .cornerRadius(4)
    }
}
