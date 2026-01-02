//
//  ProfessionalEditorView.swift
//  OVEREND
//
//  專業編輯器視圖 - 整合 Physical Canvas Engine
//

import SwiftUI
import AppKit

/// 專業編輯器視圖
struct ProfessionalEditorView: View {
    @EnvironmentObject var theme: AppTheme
    @EnvironmentObject var viewState: MainViewState
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var document: Document

    // Physical Canvas ViewModel
    @StateObject private var canvasViewModel = PhysicalDocumentViewModel()

    // 編輯器模式
    @State private var editorMode: EditorMode = .physicalCanvas
    @State private var showCitationPanel = true
    @State private var wordCount: Int = 0
    @State private var isSaving: Bool = false
    @State private var lastSaved: Date?
    @State private var autoSaveTimer: Timer?

    init(document: Document) {
        self.document = document
    }

    enum EditorMode {
        case physicalCanvas  // Physical Canvas 模式（預設）
        case richText        // 傳統富文本模式
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 增強型格式工具列
            enhancedToolbar

            // 主編輯區域
            HStack(spacing: 0) {
                // 編輯器（根據模式切換）
                editorContent

                // 右側面板（可折疊）
                if showCitationPanel {
                    Divider()

                    VStack(spacing: 0) {
                        // 面板標題
                        HStack {
                            Text("引用文獻")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.textPrimary)

                            Spacer()

                            Button(action: {
                                withAnimation(AnimationSystem.Easing.quick) {
                                    showCitationPanel = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.textMuted)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(theme.toolbar)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(theme.border)
                                .frame(height: 1)
                        }

                        // 引用面板
                        CitationInspector { entry in
                            insertCitation(from: entry)
                        }
                    }
                    .frame(width: 280)
                    .transition(.move(edge: .trailing))
                }
            }

            // 底部狀態列
            statusBar
        }
        .background(theme.background)
        .onAppear {
            loadDocumentContent()
            updateWordCount()
        }
        .onDisappear {
            saveDocument()
            autoSaveTimer?.invalidate()
        }
    }
    
    // MARK: - 子視圖

    /// 編輯器內容（根據模式切換）
    private var editorContent: some View {
        SwiftUI.Group {
            switch editorMode {
            case .physicalCanvas:
                // Physical Canvas 多頁編輯器
                MultiPageDocumentView()
                    .environmentObject(canvasViewModel)
                    .environmentObject(theme)

            case .richText:
                // 傳統富文本編輯器
                legacyEditorCanvas
            }
        }
    }

    /// 增強型工具列
    private var enhancedToolbar: some View {
        HStack(spacing: 12) {
            // 模式切換
            Picker("", selection: $editorMode) {
                Label("物理畫布", systemImage: "doc.on.doc")
                    .tag(EditorMode.physicalCanvas)
                Label("富文本", systemImage: "doc.richtext")
                    .tag(EditorMode.richText)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            Divider()
                .frame(height: 16)

            // 字數統計
            HStack(spacing: 4) {
                Image(systemName: "textformat.characters")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
                Text("\(wordCount) 字")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
            }

            // 頁數（Physical Canvas 模式）
            if editorMode == .physicalCanvas {
                HStack(spacing: 4) {
                    Image(systemName: "doc.plaintext")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                    Text("\(canvasViewModel.totalPages) 頁")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                }
            }

            Spacer()

            // 引用面板切換
            Button(action: {
                withAnimation(AnimationSystem.Easing.quick) {
                    showCitationPanel.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: showCitationPanel ? "sidebar.right" : "sidebar.left")
                        .font(.system(size: 14))
                    Text(showCitationPanel ? "隱藏引用" : "顯示引用")
                        .font(.system(size: 14))
                }
                .foregroundColor(theme.accent)
            }
            .buttonStyle(.plain)

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
                    Text("已儲存於 \(formatTime(saved))")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.border)
                .frame(height: 1)
        }
    }

    /// 底部狀態列
    private var statusBar: some View {
        HStack(spacing: 16) {
            // 文稿名稱
            Text(document.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.textPrimary)

            Spacer()

            // 編輯模式指示
            Text(editorMode == .physicalCanvas ? "物理畫布模式" : "富文本模式")
                .font(.system(size: 12))
                .foregroundColor(theme.textMuted)

            // 自動儲存狀態
            HStack(spacing: 4) {
                Circle()
                    .fill(isSaving ? .orange : .green)
                    .frame(width: 6, height: 6)
                Text("自動儲存")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textMuted)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 28)
        .background(theme.toolbar)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(theme.border)
                .frame(height: 1)
        }
    }

    // MARK: - 傳統編輯器（富文本模式）

    private var legacyEditorCanvas: some View {
        Text("傳統富文本編輯器（開發中）")
            .font(.system(size: 16))
            .foregroundColor(theme.textMuted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.background)
    }
    
    // MARK: - 方法

    /// 載入文稿內容
    private func loadDocumentContent() {
        // TODO: 從 document.rtfData 載入到 canvasViewModel
        // 目前先使用空白文稿
        canvasViewModel.documentTitle = document.title
    }

    /// 更新字數統計
    private func updateWordCount() {
        wordCount = canvasViewModel.totalWordCount()
    }

    /// 格式化時間
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    /// 插入引用
    private func insertCitation(from entry: Entry) {
        // TODO: 整合到 Physical Canvas
        let author = formatAuthorShort(entry.fields["author"] ?? "Unknown")
        let year = entry.fields["year"] ?? "n.d."
        let citation = "(\(author), \(year))"

        ToastManager.shared.showInfo("引用功能整合中：\(citation)")
        scheduleAutoSave()
    }

    /// 格式化作者名稱
    private func formatAuthorShort(_ author: String) -> String {
        let parts = author.components(separatedBy: " and ")
        guard let firstAuthor = parts.first else { return author }

        if firstAuthor.range(of: "\\p{Han}", options: .regularExpression) != nil {
            return String(firstAuthor.prefix(1))
        }

        let nameParts = firstAuthor.components(separatedBy: ", ")
        return nameParts.first ?? firstAuthor
    }

    /// 排程自動儲存
    private func scheduleAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            saveDocument()
        }
    }

    /// 儲存文稿
    private func saveDocument() {
        isSaving = true

        // TODO: 從 canvasViewModel 取得內容並儲存到 document.rtfData
        document.updatedAt = Date()

        do {
            try viewContext.save()
            lastSaved = Date()
            updateWordCount()
        } catch {
            print("❌ 儲存失敗：\(error.localizedDescription)")
            ToastManager.shared.showError("儲存失敗")
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
