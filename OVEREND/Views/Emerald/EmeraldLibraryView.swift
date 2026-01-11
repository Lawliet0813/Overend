//
//  EmeraldLibraryView.swift
//  OVEREND
//
//  Emerald Library - 文獻庫管理介面
//

import SwiftUI
import CoreData

// MARK: - 主視圖

struct EmeraldLibraryView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Library.name, ascending: true)],
        animation: .default
    )
    private var libraries: FetchedResults<Library>
    
    @State private var selectedLibrary: Library?
    @State private var selectedEntry: Entry?
    @State private var searchText = ""
    @State private var showAddReference = false
    
    var body: some View {
        HStack(spacing: 0) {
            // 左側邊欄
            LibrarySidebar(
                libraries: Array(libraries),
                selectedLibrary: $selectedLibrary,
                searchText: $searchText
            )
            .frame(width: 280)
            
            // 中間主內容
            LibraryMainContent(
                selectedLibrary: selectedLibrary,
                selectedEntry: $selectedEntry,
                searchText: searchText,
                onAddReference: { showAddReference = true }
            )
            
            // 右側 Inspector
            if let entry = selectedEntry {
                LibraryInspector(entry: entry)
                    .frame(width: 380)
            }
        }
        .background(EmeraldTheme.backgroundDark)
        .onAppear {
            if selectedLibrary == nil {
                selectedLibrary = libraries.first
            }
        }
    }
}

// MARK: - 側邊欄

struct LibrarySidebar: View {
    let libraries: [Library]
    @Binding var selectedLibrary: Library?
    @Binding var searchText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 搜尋框
            HStack {
                MaterialIcon(name: "search", size: 18, color: EmeraldTheme.textMuted)
                TextField("搜尋文獻庫...", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(EmeraldTheme.surfaceDark)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(EmeraldTheme.border, lineWidth: 1)
            )
            .padding()
            
            // Smart Groups
            VStack(alignment: .leading, spacing: 4) {
                Text("智慧群組")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(EmeraldTheme.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                
                SmartGroupButton(icon: "library_books", title: "所有文獻", count: totalEntryCount, isSelected: true)
                SmartGroupButton(icon: "schedule", title: "最近新增", count: 15, isSelected: false)
                SmartGroupButton(icon: "star", title: "收藏", count: 42, isSelected: false)
                SmartGroupButton(icon: "warning", title: "缺少 DOI", count: 3, isSelected: false)
            }
            .padding(.top, 8)
            
            // 文獻庫列表
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("我的文獻庫")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(EmeraldTheme.textMuted)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        MaterialIcon(name: "add", size: 14, color: EmeraldTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 8)
                
                ForEach(libraries) { library in
                    LibraryRowButton(
                        library: library,
                        isSelected: selectedLibrary?.id == library.id
                    ) {
                        selectedLibrary = library
                    }
                }
            }
            
            Spacer()
            
            // 同步狀態
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    MaterialIcon(name: "cloud_sync", size: 18, color: EmeraldTheme.primary)
                    Text("同步狀態")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(EmeraldTheme.primary)
                        .textCase(.uppercase)
                }
                
                Text("最後同步於 2 分鐘前。所有變更已儲存。")
                    .font(.system(size: 11))
                    .foregroundColor(EmeraldTheme.textSecondary)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [EmeraldTheme.elevated, EmeraldTheme.backgroundDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .cornerRadius(12)
            .padding()
        }
        .emeraldGlassBackground()
        .emeraldRightBorder()
    }
    
    private var totalEntryCount: Int {
        libraries.reduce(0) { $0 + ($1.entries?.count ?? 0) }
    }
}

// MARK: - Smart Group 按鈕

struct SmartGroupButton: View {
    let icon: String
    let title: String
    let count: Int
    let isSelected: Bool
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                MaterialIcon(
                    name: icon,
                    size: 18,
                    color: isSelected ? EmeraldTheme.primary : EmeraldTheme.textSecondary
                )
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : EmeraldTheme.textSecondary)
                
                Spacer()
                
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isSelected ? EmeraldTheme.primary : EmeraldTheme.textMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? EmeraldTheme.primary.opacity(0.1) : (isHovered ? Color.white.opacity(0.05) : .clear))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - 文獻庫行按鈕

struct LibraryRowButton: View {
    let library: Library
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                MaterialIcon(
                    name: "folder",
                    size: 18,
                    color: isSelected ? .white : EmeraldTheme.textSecondary
                )
                
                Text(library.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : EmeraldTheme.textSecondary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isHovered ? Color.white.opacity(0.05) : .clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - 主內容區

struct LibraryMainContent: View {
    let selectedLibrary: Library?
    @Binding var selectedEntry: Entry?
    let searchText: String
    let onAddReference: () -> Void
    
    private var entries: [Entry] {
        guard let library = selectedLibrary,
              let entrySet = library.entries as? Set<Entry> else { return [] }
        
        // 安全過濾：排除已刪除或無效的物件
        var result = entrySet.filter { entry in
            !entry.isDeleted && entry.managedObjectContext != nil
        }
        
        if !searchText.isEmpty {
            result = result.filter { entry in
                entry.title.localizedCaseInsensitiveContains(searchText) ||
                entry.author.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return Array(result).sorted { $0.title < $1.title }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具列
            HStack {
                HStack(spacing: 8) {
                    ToolbarButton(icon: "tune")
                    ToolbarButton(icon: "sort")
                    
                    Divider()
                        .frame(height: 20)
                        .background(Color.white.opacity(0.1))
                    
                    ToolbarButton(icon: "ios_share")
                }
                
                Spacer()
                
                Button(action: onAddReference) {
                    HStack(spacing: 8) {
                        MaterialIcon(name: "add", size: 18, color: EmeraldTheme.backgroundDark)
                        Text("新增文獻")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(EmeraldTheme.primary)
                    .foregroundColor(EmeraldTheme.backgroundDark)
                    .cornerRadius(8)
                    .shadow(color: EmeraldTheme.primary.opacity(0.3), radius: 10)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(EmeraldTheme.backgroundDark)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1),
                alignment: .bottom
            )
            
            // 表格
            ScrollView {
                LazyVStack(spacing: 0) {
                    // 表頭
                    HStack {
                        CheckboxView(isChecked: false)
                            .frame(width: 40)
                        
                        Text("標題")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("作者")
                            .frame(width: 150, alignment: .leading)
                        
                        Text("年份")
                            .frame(width: 80, alignment: .leading)
                        
                        Text("期刊")
                            .frame(width: 150, alignment: .leading)
                        
                        Spacer()
                            .frame(width: 40)
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(EmeraldTheme.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(EmeraldTheme.surfaceDark)
                    
                    // 資料行
                    ForEach(entries) { entry in
                        LibraryEntryTableRow(
                            entry: entry,
                            isSelected: selectedEntry?.id == entry.id
                        ) {
                            selectedEntry = entry
                        }
                    }
                }
                .background(EmeraldTheme.surfaceDark.opacity(0.5))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(24)
            }
        }
        .background(EmeraldTheme.backgroundDark)
    }
}

// MARK: - 工具列按鈕

struct ToolbarButton: View {
    let icon: String
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {}) {
            MaterialIcon(name: icon, size: 22, color: isHovered ? .white : EmeraldTheme.textSecondary)
                .frame(width: 40, height: 40)
                .background(isHovered ? EmeraldTheme.surfaceDark : .clear)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isHovered ? Color.white.opacity(0.1) : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Checkbox

struct CheckboxView: View {
    let isChecked: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(isChecked ? EmeraldTheme.primary : EmeraldTheme.backgroundDark)
            .frame(width: 16, height: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isChecked ? EmeraldTheme.primary : Color.white.opacity(0.2), lineWidth: 1)
            )
            .overlay(
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(EmeraldTheme.backgroundDark)
                    .opacity(isChecked ? 1 : 0)
            )
    }
}

// MARK: - 表格行

struct LibraryEntryTableRow: View {
    let entry: Entry
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    private var rowBackground: Color {
        if isSelected {
            return EmeraldTheme.primary.opacity(0.1)
        } else if isHovered {
            return EmeraldTheme.surfaceDark.opacity(0.8)
        }
        return .clear
    }
    
    private var pdfIconName: String {
        entry.hasPDF ? "picture_as_pdf" : "article"
    }
    
    private var pdfIconColor: Color {
        entry.hasPDF ? EmeraldTheme.primary : EmeraldTheme.textMuted
    }
    
    var body: some View {
        Button(action: action) {
            rowContent
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var rowContent: some View {
        HStack {
            CheckboxView(isChecked: isSelected)
                .frame(width: 40)
            
            Text(entry.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(entry.author)
                .font(.system(size: 13))
                .foregroundColor(EmeraldTheme.textSecondary)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
            
            Text(entry.year)
                .font(.system(size: 13))
                .foregroundColor(EmeraldTheme.textSecondary)
                .frame(width: 80, alignment: .leading)
            
            publicationBadge
            
            MaterialIcon(name: pdfIconName, size: 18, color: pdfIconColor)
                .frame(width: 40)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(rowBackground)
    }
    
    @ViewBuilder
    private var publicationBadge: some View {
        if !entry.publication.isEmpty {
            Text(entry.publication)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(EmeraldTheme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(EmeraldTheme.backgroundDark)
                .cornerRadius(4)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
        } else {
            Spacer()
                .frame(width: 150)
        }
    }
}

// MARK: - Inspector 面板

struct LibraryInspector: View {
    let entry: Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            inspectorHeader
            inspectorTabs
            inspectorContent
        }
        .background(EmeraldTheme.surfaceDark.opacity(0.3))
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 1),
            alignment: .leading
        )
    }
    
    private var inspectorHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(EmeraldTheme.primary.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    MaterialIcon(name: "article", size: 22, color: EmeraldTheme.primary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {}) {
                        MaterialIcon(name: "edit", size: 20, color: EmeraldTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {}) {
                        MaterialIcon(name: "delete", size: 20, color: EmeraldTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(3)
                
                Text("\(entry.author), \(entry.year) • \(entry.publication)")
                    .font(.system(size: 13))
                    .foregroundColor(EmeraldTheme.textSecondary)
            }
        }
        .padding(24)
    }
    
    private var inspectorTabs: some View {
        HStack(spacing: 24) {
            InspectorTab(title: "資訊", isSelected: true)
            InspectorTab(title: "筆記", isSelected: false)
            InspectorTab(title: "標籤", isSelected: false)
        }
        .padding(.horizontal, 24)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var inspectorContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                pdfAttachmentView
                abstractView
                doiView
            }
            .padding(24)
        }
    }
    
    @ViewBuilder
    private var pdfAttachmentView: some View {
        if entry.hasPDF {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    MaterialIcon(name: "picture_as_pdf", size: 20, color: .red)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.citationKey).pdf")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("PDF 文件")
                        .font(.system(size: 11))
                        .foregroundColor(EmeraldTheme.textSecondary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    MaterialIcon(name: "download", size: 18, color: EmeraldTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(EmeraldTheme.backgroundDark)
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var abstractView: some View {
        let abstractText = entry.fields["abstract"] ?? ""
        if !abstractText.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("摘要")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(EmeraldTheme.textMuted)
                    .textCase(.uppercase)
                
                Text(abstractText)
                    .font(.system(size: 13))
                    .foregroundColor(EmeraldTheme.textSecondary)
                    .lineSpacing(4)
            }
        }
    }
    
    @ViewBuilder
    private var doiView: some View {
        let doiText = entry.fields["doi"] ?? ""
        if !doiText.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("DOI")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(EmeraldTheme.textMuted)
                    .textCase(.uppercase)
                
                HStack {
                    Text(doiText)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        MaterialIcon(name: "link", size: 18, color: EmeraldTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(EmeraldTheme.surfaceDark)
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Inspector Tab

struct InspectorTab: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? EmeraldTheme.primary : EmeraldTheme.textSecondary)
                .padding(.bottom, 12)
            
            Rectangle()
                .fill(isSelected ? EmeraldTheme.primary : .clear)
                .frame(height: 2)
        }
    }
}

// MARK: - Preview

#Preview {
    EmeraldLibraryView()
        .environmentObject(AppTheme())
        .frame(width: 1400, height: 900)
}
