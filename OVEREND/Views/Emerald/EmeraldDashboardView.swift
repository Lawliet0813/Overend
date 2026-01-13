//
//  EmeraldDashboardView.swift
//  OVEREND
//
//  Emerald Dashboard - 寫作模式
//

import SwiftUI
import CoreData

// MARK: - 主視圖

struct EmeraldDashboardView: View {
    @ObservedObject var document: Document
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var attributedText: NSAttributedString
    @State private var textViewRef: NSTextView?
    @State private var showCitationPanel = false
    @State private var selectedMode = "academic"
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Library.name, ascending: true)],
        animation: .default
    )
    private var libraries: FetchedResults<Library>
    
    init(document: Document) {
        self.document = document
        _attributedText = State(initialValue: document.attributedString)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 左側文件導航
            DocumentSidebar(document: document)
                .frame(width: 280)
            
            // 中央編輯器
            EditorPane(
                document: document,
                attributedText: $attributedText,
                textViewRef: $textViewRef,
                selectedMode: $selectedMode,
                showCitationPanel: $showCitationPanel
            )
            
            // 右側文獻引用面板
            ReferenceLibraryPane(
                libraries: Array(libraries),
                onInsertCitation: { entry in
                    insertCitation(entry)
                }
            )
            .frame(width: 320)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "#102a20"),
                    Color(hex: "#050a08"),
                    Color(hex: "#050a08")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private func insertCitation(_ entry: Entry) {
        guard let textView = textViewRef else { return }
        
        let insertionPoint = textView.selectedRange().location
        guard let textStorage = textView.textStorage else { return }
        
        let citationText = "(\(entry.author), \(entry.year.isEmpty ? "n.d." : entry.year))"
        let citationAttributed = NSAttributedString(
            string: citationText,
            attributes: [
                .foregroundColor: NSColor.black,
                .font: NSFont.systemFont(ofSize: 12)
            ]
        )
        
        textStorage.insert(citationAttributed, at: insertionPoint)
        attributedText = textView.attributedString()
        
        document.attributedString = attributedText
        document.updatedAt = Date()
        try? viewContext.save()
    }
}

// MARK: - 文件導航側邊欄

struct DocumentSidebar: View {
    let document: Document
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 標題
            VStack(alignment: .leading, spacing: 8) {
                Text("結構")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(EmeraldTheme.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)
            }
            .padding(16)
            
            // 文件樹
            VStack(spacing: 4) {
                DocumentTreeItem(icon: "folder_open", title: "緒論", isActive: false)
                DocumentTreeItem(icon: "folder", title: "文獻回顧", isActive: false)
                DocumentTreeItem(icon: "article", title: "研究方法", isActive: true)
                
                // 子項目
                VStack(spacing: 4) {
                    Text("1.1 量子基礎")
                        .font(.system(size: 11))
                        .foregroundColor(EmeraldTheme.textMuted)
                        .padding(.leading, 36)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("1.2 相干模型")
                        .font(.system(size: 11))
                        .foregroundColor(EmeraldTheme.textMuted)
                        .padding(.leading, 36)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
                
                DocumentTreeItem(icon: "folder", title: "結果與討論", isActive: false)
            }
            .padding(.horizontal, 8)
            
            Spacer()
            
            // 統計
            VStack(alignment: .leading, spacing: 8) {
                Text("快速統計")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(EmeraldTheme.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)
                
                HStack(spacing: 8) {
                    EmeraldStatCard(value: "4.2k", label: "字數")
                    EmeraldStatCard(value: "18m", label: "閱讀時間")
                }
            }
            .padding(16)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1),
                alignment: .top
            )
        }
        .background(EmeraldTheme.glassBackground)
        .background(.ultraThinMaterial)
        .emeraldRightBorder()
    }
}

// MARK: - 文件樹項目

struct DocumentTreeItem: View {
    let icon: String
    let title: String
    let isActive: Bool
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            MaterialIcon(
                name: icon,
                size: 18,
                color: isActive ? EmeraldTheme.primary : EmeraldTheme.textMuted
            )
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isActive ? .white : EmeraldTheme.textMuted)
            
            Spacer()
            
            if isActive {
                Circle()
                    .fill(EmeraldTheme.primary)
                    .frame(width: 6, height: 6)
                    .emeraldGlow(radius: 5)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            isActive ?
            EmeraldTheme.primary.opacity(0.1) :
            (isHovered ? Color.white.opacity(0.05) : .clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? EmeraldTheme.borderAccent : .clear, lineWidth: 1)
        )
        .cornerRadius(8)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - 統計卡片

struct EmeraldStatCard: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(EmeraldTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - 編輯器面板

struct EditorPane: View {
    let document: Document
    @Binding var attributedText: NSAttributedString
    @Binding var textViewRef: NSTextView?
    @Binding var selectedMode: String
    @Binding var showCitationPanel: Bool
    
    var body: some View {
        ZStack {
            // 背景
            Color(hex: "#0b1410")
            
            VStack(spacing: 0) {
                // 編輯器內容
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 標題
                        Text(document.title)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(-0.5)
                        
                        // 內容
                        RichTextEditorView(
                            attributedText: $attributedText,
                            textViewRef: $textViewRef,
                            onTextChange: {}
                        )
                        .frame(minHeight: 400)
                    }
                    .padding(.horizontal, 80)
                    .padding(.vertical, 80)
                    .frame(maxWidth: 800)
                }
                .frame(maxWidth: .infinity)
            }
            
            // 模式切換 (頂部)
            VStack {
                ModeSelector(selectedMode: $selectedMode)
                    .padding(.top, 24)
                
                Spacer()
            }
            
            // 格式工具列 (右側浮動)
            HStack {
                Spacer()
                
                VStack(spacing: 8) {
                    FormatToolButton(icon: "format_bold", tooltip: "粗體")
                    FormatToolButton(icon: "format_italic", tooltip: "斜體")
                    FormatToolButton(icon: "link", tooltip: "連結")
                    FormatToolButton(icon: "format_quote", tooltip: "引用")
                    
                    Divider()
                        .frame(width: 24)
                        .background(Color.white.opacity(0.1))
                    
                    Button(action: { showCitationPanel.toggle() }) {
                        MaterialIcon(name: "school", size: 20, color: EmeraldTheme.primary)
                            .frame(width: 36, height: 36)
                            .background(EmeraldTheme.primary.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .emeraldGlow(radius: 8)
                }
                .padding(8)
                .glassPanel(isActive: true)
                .padding(.trailing, 32)
                .padding(.top, 24)
            }
            
            // 底部漸層
            VStack {
                Spacer()
                
                LinearGradient(
                    colors: [.clear, Color(hex: "#0b1410")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - 模式選擇器

struct ModeSelector: View {
    @Binding var selectedMode: String
    
    var body: some View {
        HStack(spacing: 4) {
            ModeButton(title: "Markdown", mode: "markdown", selectedMode: $selectedMode)
            ModeButton(title: "學術", mode: "academic", selectedMode: $selectedMode)
            ModeButton(title: "所見即所得", mode: "wysiwyg", selectedMode: $selectedMode)
        }
        .padding(4)
        .background(Color(hex: "#1a2e26").opacity(0.9))
        .background(.ultraThinMaterial)
        .cornerRadius(999)
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ModeButton: View {
    let title: String
    let mode: String
    @Binding var selectedMode: String
    
    var isSelected: Bool { selectedMode == mode }
    
    var body: some View {
        Button(action: { selectedMode = mode }) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? EmeraldTheme.backgroundDark : EmeraldTheme.textMuted)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? EmeraldTheme.primary : .clear)
                .cornerRadius(999)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 格式工具按鈕

struct FormatToolButton: View {
    let icon: String
    let tooltip: String
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {}) {
            MaterialIcon(
                name: icon,
                size: 20,
                color: isHovered ? EmeraldTheme.primary : EmeraldTheme.textMuted
            )
            .frame(width: 36, height: 36)
            .background(isHovered ? EmeraldTheme.primary.opacity(0.1) : .clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(tooltip)
    }
}

// MARK: - 文獻引用面板

struct ReferenceLibraryPane: View {
    let libraries: [Library]
    let onInsertCitation: (Entry) -> Void
    
    @State private var searchText = ""
    @State private var selectedFilter = "all"
    
    private var allEntries: [Entry] {
        libraries.flatMap { library in
            (library.entries as? Set<Entry>) ?? []
        }.sorted { $0.title < $1.title }
    }
    
    private var filteredEntries: [Entry] {
        if searchText.isEmpty { return allEntries }
        return allEntries.filter { entry in
            entry.title.localizedCaseInsensitiveContains(searchText) ||
            entry.author.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜尋
            VStack(spacing: 12) {
                HStack {
                    MaterialIcon(name: "search", size: 18, color: EmeraldTheme.textMuted)
                    
                    TextField("搜尋文獻庫...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                
                // 篩選按鈕
                HStack(spacing: 8) {
                    FilterButton(title: "所有來源", isSelected: true)
                    FilterButton(title: "最近", isSelected: false)
                    FilterButton(title: "期刊", isSelected: false)
                }
            }
            .padding(16)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1),
                alignment: .bottom
            )
            
            // 引用列表
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredEntries.prefix(20)) { entry in
                        ReferenceCard(entry: entry, onInsert: {
                            onInsertCitation(entry)
                        })
                    }
                    
                    // 拖放區域
                    VStack(spacing: 8) {
                        MaterialIcon(name: "drag_indicator", size: 20, color: EmeraldTheme.textMuted)
                        Text("拖放 PDF 至此新增")
                            .font(.system(size: 11))
                            .foregroundColor(EmeraldTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .foregroundColor(Color.white.opacity(0.1))
                    )
                }
                .padding(16)
            }
        }
        .background(EmeraldTheme.glassBackground)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 1),
            alignment: .leading
        )
    }
}

// MARK: - 篩選按鈕

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Button(action: {}) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isSelected ? EmeraldTheme.primary : EmeraldTheme.textMuted)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? EmeraldTheme.primary.opacity(0.2) : Color.white.opacity(0.05))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? EmeraldTheme.borderAccent : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 引用卡片

struct ReferenceCard: View {
    let entry: Entry
    let onInsert: () -> Void
    
    @State private var isHovered = false
    
    // 類型顏色
    private var typeColor: Color {
        switch entry.entryType.lowercased() {
        case "book": return .orange
        case "article": return .blue
        default: return .purple
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(typeColor)
                        .frame(width: 8, height: 8)
                    
                    Text(entry.author)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(EmeraldTheme.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text(entry.year)
                    .font(.system(size: 10))
                    .foregroundColor(EmeraldTheme.textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text(entry.title)
                .font(.system(size: 12))
                .foregroundColor(isHovered ? EmeraldTheme.textPrimary : EmeraldTheme.textMuted)
                .lineLimit(2)
            
            HStack {
                Text(entry.publication.isEmpty ? "未知來源" : entry.publication)
                    .font(.system(size: 10))
                    .foregroundColor(EmeraldTheme.textMuted)
                    .italic()
                    .lineLimit(1)
                
                Spacer()
                
                if isHovered {
                    Button(action: onInsert) {
                        MaterialIcon(name: "add_circle", size: 16, color: EmeraldTheme.primary)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(isHovered ? 0.07 : 0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? EmeraldTheme.borderAccent : Color.white.opacity(0.05), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Preview

struct EmeraldDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let doc = Document(context: context)
        doc.title = "第一章：量子生物現象的基礎"
        
        return EmeraldDashboardView(document: doc)
            .environmentObject(AppTheme())
            .environment(\.managedObjectContext, context)
            .frame(width: 1400, height: 900)
    }
}
