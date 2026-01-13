//
//  EmeraldReaderView.swift
//  OVEREND
//
//  Emerald Reader - 分割視圖 (左編輯器 + 右PDF)
//

import SwiftUI
import PDFKit
import CoreData

// MARK: - 主視圖

struct EmeraldReaderView: View {
    @ObservedObject var document: Document
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var attributedText: NSAttributedString
    @State private var textViewRef: NSTextView?
    @State private var showQuickCite = false
    @State private var citationSearchText = ""
    @State private var pdfZoom: CGFloat = 1.25
    @State private var currentPage = 1
    @State private var totalPages = 14
    
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
            // 左側編輯器
            EditorSplitPane(
                document: document,
                attributedText: $attributedText,
                textViewRef: $textViewRef,
                showQuickCite: $showQuickCite,
                citationSearchText: $citationSearchText,
                libraries: Array(libraries)
            )
            .frame(maxWidth: .infinity)
            
            // 分隔線
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 1)
            
            // 右側 PDF
            PDFSplitPane(
                pdfZoom: $pdfZoom,
                currentPage: $currentPage,
                totalPages: totalPages
            )
            .frame(maxWidth: .infinity)
        }
        .background(EmeraldTheme.backgroundDark)
    }
}

// MARK: - 編輯器面板

struct EditorSplitPane: View {
    let document: Document
    @Binding var attributedText: NSAttributedString
    @Binding var textViewRef: NSTextView?
    @Binding var showQuickCite: Bool
    @Binding var citationSearchText: String
    let libraries: [Library]
    
    private var allEntries: [Entry] {
        libraries.flatMap { ($0.entries as? Set<Entry>) ?? [] }
    }
    
    private var filteredEntries: [Entry] {
        guard !citationSearchText.isEmpty else { return [] }
        return allEntries.filter { entry in
            entry.title.localizedCaseInsensitiveContains(citationSearchText) ||
            entry.author.localizedCaseInsensitiveContains(citationSearchText)
        }
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color(hex: "#111815")
            
            VStack(spacing: 0) {
                // 工具列
                HStack {
                    // 格式按鈕
                    HStack(spacing: 4) {
                        HStack(spacing: 0) {
                            EditorToolBtn(icon: "format_bold")
                            EditorToolBtn(icon: "format_italic")
                            EditorToolBtn(icon: "format_underlined")
                        }
                        .padding(4)
                        .background(EmeraldTheme.surfaceDark)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                        
                        Divider()
                            .frame(height: 24)
                            .background(Color.white.opacity(0.1))
                        
                        // 樣式選擇
                        Menu {
                            Button("內文") {}
                            Button("標題 1") {}
                            Button("標題 2") {}
                            Button("標題 3") {}
                        } label: {
                            HStack(spacing: 4) {
                                Text("Normal")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(EmeraldTheme.textMuted)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(EmeraldTheme.surfaceDark)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                            .frame(height: 24)
                            .background(Color.white.opacity(0.1))
                        
                        EditorToolBtn(icon: "format_list_bulleted")
                        EditorToolBtn(icon: "format_quote")
                    }
                    
                    Spacer()
                    
                    // 引用按鈕
                    Button(action: { showQuickCite.toggle() }) {
                        HStack(spacing: 6) {
                            MaterialIcon(name: "add", size: 14, color: EmeraldTheme.primary)
                            Text("引用")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(EmeraldTheme.primary)
                                .textCase(.uppercase)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(EmeraldTheme.primary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .emeraldGlassBackground()
                .emeraldBottomBorder()
                
                // 編輯內容
                ZStack(alignment: .topLeading) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            RichTextEditorView(
                                attributedText: $attributedText,
                                textViewRef: $textViewRef,
                                onTextChange: {}
                            )
                            .frame(minHeight: 600)
                        }
                        .padding(48)
                    }
                    
                    // 快速引用彈窗
                    if showQuickCite {
                        QuickCiteModal(
                            searchText: $citationSearchText,
                            entries: filteredEntries,
                            onClose: { showQuickCite = false },
                            onInsert: { entry in
                                insertCitation(entry)
                                showQuickCite = false
                            }
                        )
                        .padding(.top, 40)
                        .padding(.leading, 100)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                
                // 底部狀態
                EmeraldStatusBar(items: ["\(attributedText.string.count) 字", document.title])
            }
        }
    }
    
    private func insertCitation(_ entry: Entry) {
        guard let textView = textViewRef else { return }
        
        let insertionPoint = textView.selectedRange().location
        guard let textStorage = textView.textStorage else { return }
        
        let citationText = "(\(entry.author), \(entry.year))"
        let citationAttributed = NSAttributedString(
            string: citationText,
            attributes: [
                .foregroundColor: NSColor.black,
                .font: NSFont.systemFont(ofSize: 12)
            ]
        )
        
        textStorage.insert(citationAttributed, at: insertionPoint)
        attributedText = textView.attributedString()
    }
}

// MARK: - 編輯器工具按鈕

struct EditorToolBtn: View {
    let icon: String
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {}) {
            MaterialIcon(
                name: icon,
                size: 18,
                color: isHovered ? .white : EmeraldTheme.textSecondary
            )
            .frame(width: 32, height: 32)
            .background(isHovered ? Color.white.opacity(0.05) : .clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - 快速引用彈窗

struct QuickCiteModal: View {
    @Binding var searchText: String
    let entries: [Entry]
    let onClose: () -> Void
    let onInsert: (Entry) -> Void
    
    @State private var selectedIndex = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜尋頭部
            HStack(spacing: 12) {
                MaterialIcon(name: "search", size: 18, color: EmeraldTheme.primary)
                
                TextField("搜尋文獻...", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .font(.system(size: 13, weight: .medium))
                
                EmeraldShortcutHint(key: "ESC")
            }
            .padding(12)
            .background(Color(hex: "#182620"))
            .emeraldBottomBorder()
            
            // 結果列表
            ScrollView {
                LazyVStack(spacing: 8) {
                    if !entries.isEmpty {
                        Text("最佳匹配")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(EmeraldTheme.textSecondary)
                            .textCase(.uppercase)
                            .tracking(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                        
                        ForEach(entries.prefix(5)) { entry in
                            QuickCiteResultRow(
                                entry: entry,
                                isSelected: entries.first?.id == entry.id,
                                onTap: { onInsert(entry) }
                            )
                        }
                    } else if !searchText.isEmpty {
                        Text("找不到結果")
                            .font(.system(size: 12))
                            .foregroundColor(EmeraldTheme.textMuted)
                            .padding(16)
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 256)
            
            // 底部提示
            HStack {
                Text("按 **Enter** 插入引用")
                
                Spacer()
                
                Text("**Tab** 預覽 PDF")
            }
            .font(.system(size: 9))
            .foregroundColor(EmeraldTheme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(hex: "#15201b"))
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1),
                alignment: .top
            )
        }
        .frame(width: 400)
        .background(EmeraldTheme.surfaceDark)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(EmeraldTheme.borderAccent, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 30)
    }
}

// MARK: - 搜尋結果行

struct QuickCiteResultRow: View {
    let entry: Entry
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if entry.hasPDF {
                        Text("PDF")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(EmeraldTheme.backgroundDark)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(EmeraldTheme.primary)
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(entry.author)
                        .foregroundColor(EmeraldTheme.primary.opacity(0.8))
                    
                    Circle()
                        .fill(EmeraldTheme.primary.opacity(0.5))
                        .frame(width: 4, height: 4)
                    
                    Text(entry.year)
                        .foregroundColor(EmeraldTheme.primary.opacity(0.8))
                    
                    if !entry.publication.isEmpty {
                        Circle()
                            .fill(EmeraldTheme.primary.opacity(0.5))
                            .frame(width: 4, height: 4)
                        
                        Text(entry.publication)
                            .foregroundColor(EmeraldTheme.primary.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                .font(.system(size: 11))
            }
            .padding(12)
            .background(isSelected ? EmeraldTheme.primary.opacity(0.1) : Color.white.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? EmeraldTheme.borderAccent : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PDF 面板

struct PDFSplitPane: View {
    @Binding var pdfZoom: CGFloat
    @Binding var currentPage: Int
    let totalPages: Int
    
    @State private var selectedTool = "highlight"
    
    var body: some View {
        ZStack {
            // 背景
            Color(hex: "#0d1210")
            
            VStack(spacing: 0) {
                // PDF 標籤列
                HStack(spacing: 0) {
                    PDFTab(filename: "Smith_2021_Sustainable.pdf", isActive: true)
                    PDFTab(filename: "Doe_2019_Renewable.pdf", isActive: false)
                    
                    Button(action: {}) {
                        MaterialIcon(name: "add", size: 18, color: EmeraldTheme.textSecondary)
                            .padding(6)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .background(Color(hex: "#111815"))
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 1),
                    alignment: .bottom
                )
                
                // PDF 內容區
                ZStack {
                    // PDF 預覽佔位
                    ScrollView {
                        VStack {
                            // 模擬 PDF 頁面
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Sustainable Energy Solutions for Modern Grids")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Text("J. Smith, K. Johnson, M. Williams")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .italic()
                                
                                Text("Department of Electrical Engineering, Tech University")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                                
                                Divider()
                                    .background(Color.gray)
                                    .padding(.vertical, 8)
                                
                                Text("Abstract")
                                    .font(.system(size: 11, weight: .bold))
                                    .textCase(.uppercase)
                                
                                Text("The integration of renewable energy sources into the existing power grid poses significant stability challenges...")
                                    .font(.system(size: 10))
                                    .foregroundColor(.black.opacity(0.8))
                                    .lineSpacing(4)
                            }
                            .padding(32)
                            .frame(maxWidth: 500)
                            .background(Color.white)
                            .cornerRadius(4)
                            .shadow(color: .black.opacity(0.3), radius: 20)
                        }
                        .padding(32)
                    }
                    
                    // 浮動工具列
                    VStack {
                        HStack(spacing: 8) {
                            PDFToolButton(icon: "ink_highlighter", isActive: selectedTool == "highlight") {
                                selectedTool = "highlight"
                            }
                            PDFToolButton(icon: "format_underlined", isActive: false) {}
                            PDFToolButton(icon: "sticky_note_2", isActive: false) {}
                            
                            Divider()
                                .frame(height: 16)
                                .background(Color.white.opacity(0.2))
                            
                            Button(action: { pdfZoom = max(0.5, pdfZoom - 0.25) }) {
                                MaterialIcon(name: "remove", size: 18, color: .white)
                                    .padding(6)
                            }
                            .buttonStyle(.plain)
                            
                            Text("\(Int(pdfZoom * 100))%")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white)
                            
                            Button(action: { pdfZoom = min(3.0, pdfZoom + 0.25) }) {
                                MaterialIcon(name: "add", size: 18, color: .white)
                                    .padding(6)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#283932").opacity(0.9))
                        .background(.ultraThinMaterial)
                        .cornerRadius(999)
                        .shadow(color: .black.opacity(0.3), radius: 10)
                        .padding(.top, 16)
                        
                        Spacer()
                    }
                    
                    // 頁碼導航
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Button(action: { currentPage = max(1, currentPage - 1) }) {
                                    MaterialIcon(name: "keyboard_arrow_up", size: 18, color: .white)
                                        .padding(4)
                                }
                                .buttonStyle(.plain)
                                
                                Text("\(currentPage) / \(totalPages)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(EmeraldTheme.textSecondary)
                                    .frame(width: 50)
                                
                                Button(action: { currentPage = min(totalPages, currentPage + 1) }) {
                                    MaterialIcon(name: "keyboard_arrow_down", size: 18, color: .white)
                                        .padding(4)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(EmeraldTheme.surfaceDark)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 10)
                            .padding(24)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - PDF 標籤

struct PDFTab: View {
    let filename: String
    let isActive: Bool
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            MaterialIcon(
                name: "picture_as_pdf",
                size: 14,
                color: isActive ? EmeraldTheme.primary : EmeraldTheme.textSecondary
            )
            
            Text(filename)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isActive ? .white : EmeraldTheme.textSecondary)
                .lineLimit(1)
            
            if isActive {
                Button(action: {}) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(EmeraldTheme.textMuted)
                }
                .buttonStyle(.plain)
                .opacity(isHovered ? 1 : 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isActive ? EmeraldTheme.surfaceDark : (isHovered ? Color.white.opacity(0.05) : .clear))
        .cornerRadius(8)
        .overlay(
            isActive ?
            VStack {
                Spacer()
                Rectangle()
                    .fill(EmeraldTheme.primary)
                    .frame(height: 2)
            } : nil
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - PDF 工具按鈕

struct PDFToolButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            MaterialIcon(
                name: icon,
                size: 18,
                color: isActive ? EmeraldTheme.backgroundDark : .white
            )
            .padding(6)
            .background(isActive ? EmeraldTheme.primary : .clear)
            .cornerRadius(999)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let doc = Document(context: context)
    doc.title = "第四章：電網穩定性"
    
    return EmeraldReaderView(document: doc)
        .environmentObject(AppTheme())
        .environment(\.managedObjectContext, context)
        .frame(width: 1400, height: 900)
}
