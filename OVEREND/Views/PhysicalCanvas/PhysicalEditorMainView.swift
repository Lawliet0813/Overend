//
//  PhysicalEditorMainView.swift
//  OVEREND
//
//  物理編輯器主視圖 - 整合所有功能的完整編輯器
//

import SwiftUI
import SwiftData

/// 物理編輯器主視圖
struct PhysicalEditorMainView: View {
    @StateObject private var documentViewModel = PhysicalDocumentViewModel()
    @StateObject private var aiExecutor = AICommandExecutor()

    @State private var metadata: ThesisMetadata = .preview
    @State private var showMetadataEditor = false
    @State private var showAICommandPalette = false
    @State private var showExportSheet = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            editorArea
        }
        .navigationTitle("OverEnd 物理編輯器")
        .sheet(isPresented: $showMetadataEditor) {
            metadataEditorSheet
        }
        .sheet(isPresented: $showExportSheet) {
            exportSheet
        }
        .toolbar {
            mainToolbar
        }
        .onAppear {
            setupKeyboardShortcuts()
        }
    }

    // MARK: - 側邊欄

    private var sidebar: some View {
        VStack(spacing: 0) {
            // 文檔資訊卡片
            documentInfoCard

            Divider()

            // 頁面列表
            pageListSection

            Divider()

            // 操作按鈕
            sidebarActions
        }
        .frame(minWidth: 250)
    }

    private var documentInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(documentViewModel.documentTitle)
                        .font(.headline)

                    Text(metadata.titleChinese.isEmpty ? "未設定論文題目" : metadata.titleChinese)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 16) {
                StatItem(icon: "doc", value: "\(documentViewModel.totalPages)", label: "頁")
                StatItem(icon: "textformat", value: "\(documentViewModel.totalWordCount())", label: "字")
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
    }

    private var pageListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("頁面")
                    .font(.headline)
                Spacer()
                Button(action: { documentViewModel.insertPageBreak() }) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top)

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(Array(documentViewModel.pages.enumerated()), id: \.element.id) { index, page in
                        PageListItem(
                            page: page,
                            index: index,
                            isSelected: documentViewModel.currentPageIndex == index,
                            onSelect: { documentViewModel.currentPageIndex = index }
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }

    private var sidebarActions: some View {
        VStack(spacing: 8) {
            Button(action: { showMetadataEditor = true }) {
                Label("編輯元數據", systemImage: "info.circle")
                    .frame(maxWidth: .infinity)
            }

            Button(action: { showExportSheet = true }) {
                Label("導出 PDF", systemImage: "arrow.down.doc")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }

    // MARK: - 編輯區域

    private var editorArea: some View {
        Group {
            if let currentPage = documentViewModel.currentPage {
                MultiPageDocumentView()
                    .environmentObject(documentViewModel)
            } else {
                emptyStateView
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("開始編寫您的論文")
                .font(.headline)

            Button("新增第一頁") {
                documentViewModel.insertPageBreak()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - 工具列

    private var mainToolbar: some ToolbarContent {
        Group {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showMetadataEditor.toggle() }) {
                    Label("元數據", systemImage: "info.circle")
                }

                Button(action: { showAICommandPalette.toggle() }) {
                    Label("AI 助手", systemImage: "sparkles")
                }
                .keyboardShortcut("k", modifiers: .command)

                Button(action: { showExportSheet.toggle() }) {
                    Label("導出", systemImage: "square.and.arrow.up")
                }
            }

            ToolbarItemGroup(placement: .status) {
                Text("第 \(documentViewModel.currentPageIndex + 1) / \(documentViewModel.totalPages) 頁")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Sheets

    private var metadataEditorSheet: some View {
        NavigationStack {
            ThesisMetadataEditorView(metadata: metadata)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") {
                            showMetadataEditor = false
                        }
                    }
                }
        }
        .frame(width: 700, height: 600)
    }

    private var exportSheet: some View {
        PDFExportView(
            documentViewModel: documentViewModel,
            metadata: metadata
        )
        .frame(width: 500, height: 400)
    }

    // MARK: - 輔助方法

    private func setupKeyboardShortcuts() {
        // Cmd+K 開啟 AI 指令面板
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "k" {
                showAICommandPalette = true
                return nil
            }
            return event
        }
    }
}

// MARK: - 輔助組件

struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(value)
                .fontWeight(.semibold)
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

struct PageListItem: View {
    let page: PageModel
    let index: Int
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                // 頁面狀態指示器
                Circle()
                    .fill(stateColor)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("第 \(page.formattedPageNumber) 頁")
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)

                    if let header = page.headerText {
                        Text(header)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: stateIcon)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private var stateColor: Color {
        switch page.administrativeState {
        case .cover: return .purple
        case .preface: return .blue
        case .tableOfContents: return .green
        case .mainBody: return .primary
        case .appendix: return .orange
        case .bibliography: return .brown
        }
    }

    private var stateIcon: String {
        switch page.administrativeState {
        case .cover: return "book.closed"
        case .preface: return "text.alignleft"
        case .tableOfContents: return "list.bullet"
        case .mainBody: return "text.book.closed"
        case .appendix: return "paperclip"
        case .bibliography: return "books.vertical"
        }
    }
}

// MARK: - PDF 導出視圖

struct PDFExportView: View {
    @ObservedObject var documentViewModel: PhysicalDocumentViewModel
    let metadata: ThesisMetadata

    @State private var selectedURL: URL?
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var exportError: Error?
    @State private var exportSuccess = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // 標題
            HStack {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.title)
                    .foregroundColor(.accentColor)

                Text("導出為 PDF")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()
            }

            Divider()

            // 文檔資訊
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(label: "文檔標題", value: metadata.titleChinese)
                InfoRow(label: "作者", value: metadata.authorChinese)
                InfoRow(label: "總頁數", value: "\(documentViewModel.totalPages) 頁")
                InfoRow(label: "字數", value: "\(documentViewModel.totalWordCount()) 字")
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()

            // 進度
            if isExporting {
                VStack(spacing: 8) {
                    ProgressView(value: exportProgress, total: 1.0)
                    Text("正在導出 PDF...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 錯誤訊息
            if let error = exportError {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            // 成功訊息
            if exportSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("導出成功！")
                        .fontWeight(.semibold)
                }
            }

            // 按鈕
            HStack(spacing: 12) {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("選擇位置並導出") {
                    selectLocationAndExport()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isExporting)
            }
        }
        .padding()
    }

    private func selectLocationAndExport() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "\(metadata.titleChinese).pdf"

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }

            Task {
                await exportPDF(to: url)
            }
        }
    }

    private func exportPDF(to url: URL) async {
        isExporting = true
        exportError = nil
        exportSuccess = false

        do {
            try PhysicalPDFExporter.export(
                pages: documentViewModel.pages,
                metadata: metadata,
                to: url
            )

            await MainActor.run {
                exportSuccess = true
                isExporting = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        } catch {
            await MainActor.run {
                exportError = error
                isExporting = false
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - 預覽

#Preview {
    PhysicalEditorMainView()
        .frame(width: 1200, height: 800)
}
