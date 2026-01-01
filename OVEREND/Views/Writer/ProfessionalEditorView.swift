//
//  ProfessionalEditorView.swift
//  OVEREND
//
//  專業編輯器視圖 - Word 風格寫作介面
//

import SwiftUI
import AppKit

/// 專業編輯器視圖
struct ProfessionalEditorView: View {
    @EnvironmentObject var theme: AppTheme
    @EnvironmentObject var viewState: MainViewState
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var document: Document
    
    @State private var attributedString: NSAttributedString
    @State private var textView: NSTextView?
    @State private var wordCount: Int = 0
    @State private var isSaving: Bool = false
    @State private var lastSaved: Date?
    @State private var autoSaveTimer: Timer?
    
    init(document: Document) {
        self.document = document
        _attributedString = State(initialValue: document.attributedString)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Word 風格格式工具列
            formatToolbar
            
            // 主編輯區域
            HStack(spacing: 0) {
                // A4 畫布編輯區
                editorCanvas
                
                Divider()
                
                // 右側引用面板
                CitationInspector { entry in
                    insertCitation(from: entry)
                }
            }
        }
        .background(theme.background)
        .onAppear {
            updateWordCount()
        }
        .onDisappear {
            saveDocument()
            autoSaveTimer?.invalidate()
        }
    }
    
    // MARK: - 格式工具列
    
    private var formatToolbar: some View {
        HStack(spacing: 12) {
            // 字體選擇
            HStack(spacing: 4) {
                Text("新細明體")
                    .font(.system(size: 15))
                Image(systemName: "chevron.down")
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.itemHover)
            .cornerRadius(4)
            
            // 字體大小
            HStack(spacing: 4) {
                Text("12")
                    .font(.system(size: 15))
                Image(systemName: "chevron.down")
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.itemHover)
            .cornerRadius(4)
            
            Divider()
                .frame(height: 16)
            
            // 格式按鈕組
            HStack(spacing: 8) {
                FormatButton(icon: "bold") {
                    if let tv = textView {
                        RichTextEditor.toggleBold(in: tv)
                    }
                }
                
                FormatButton(icon: "italic") {
                    if let tv = textView {
                        RichTextEditor.toggleItalic(in: tv)
                    }
                }
                
                FormatButton(icon: "text.aligncenter") {
                    // 置中對齊
                }
            }
            
            Divider()
                .frame(height: 16)
            
            // 引用按鈕
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 14))
                    Text("引用文獻")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(theme.accent)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // 儲存狀態
            if isSaving {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.5)
                    Text("儲存中...")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                }
            } else if let saved = lastSaved {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    Text("已儲存")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 40)
        .background(theme.toolbar)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.border)
                .frame(height: 1)
        }
    }
    
    // MARK: - A4 編輯畫布
    
    private var editorCanvas: some View {
        ScrollView {
            VStack {
                // A4 頁面
                VStack(alignment: .leading, spacing: 0) {
                    RichTextEditor(
                        attributedString: $attributedString,
                        onTextChange: { newValue in
                            updateWordCount()
                            scheduleAutoSave()
                        }
                    )
                }
                .frame(width: 700, height: 990)
                .padding(80)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.page)
                        .shadow(color: .black.opacity(theme.isDarkMode ? 0.4 : 0.15), radius: 20, x: 0, y: 10)
                )
                .padding(.top, 32)
                .padding(.bottom, 80)
            }
            .frame(maxWidth: .infinity)
        }
        .background(theme.background)
    }
    
    // MARK: - 方法
    
    private func updateWordCount() {
        let text = attributedString.string
        var count = 0
        text.enumerateSubstrings(in: text.startIndex..., options: .byWords) { _, _, _, _ in
            count += 1
        }
        let chineseCount = text.unicodeScalars.filter {
            CharacterSet(charactersIn: "\u{4E00}"..."\u{9FFF}").contains($0)
        }.count
        wordCount = count + chineseCount
    }
    
    private func insertCitation(from entry: Entry) {
        guard let tv = textView else { return }
        
        let author = formatAuthorShort(entry.fields["author"] ?? "Unknown")
        let year = entry.fields["year"] ?? "n.d."
        let citation = "(\(author), \(year))"
        
        RichTextEditor.insertCitation(citation, at: tv)
        attributedString = tv.attributedString()
        scheduleAutoSave()
    }
    
    private func formatAuthorShort(_ author: String) -> String {
        let parts = author.components(separatedBy: " and ")
        guard let firstAuthor = parts.first else { return author }
        
        if firstAuthor.range(of: "\\p{Han}", options: .regularExpression) != nil {
            return String(firstAuthor.prefix(1))
        }
        
        let nameParts = firstAuthor.components(separatedBy: ", ")
        return nameParts.first ?? firstAuthor
    }
    
    private func scheduleAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            saveDocument()
        }
    }
    
    private func saveDocument() {
        isSaving = true
        
        document.attributedString = attributedString
        document.updatedAt = Date()
        
        do {
            try viewContext.save()
            lastSaved = Date()
        } catch {
            print("儲存失敗：\(error.localizedDescription)")
        }
        
        isSaving = false
    }
}

/// 格式按鈕
struct FormatButton: View {
    @EnvironmentObject var theme: AppTheme
    let icon: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isHovered ? theme.accent : theme.textMuted)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    let theme = AppTheme()
    let viewState = MainViewState()
    let context = PersistenceController.preview.container.viewContext
    let doc = Document(context: context, title: "測試文稿")
    
    return ProfessionalEditorView(document: doc)
        .environmentObject(theme)
        .environmentObject(viewState)
        .environment(\.managedObjectContext, context)
        .frame(width: 1200, height: 800)
}
