//
//  MultiPageDocumentView.swift
//  OVEREND
//
//  多頁面文檔視圖 - 完整的論文編輯界面
//

import SwiftUI

/// 多頁面文檔視圖 - 包含頁面導航、工具列等
struct MultiPageDocumentView: View {
    @EnvironmentObject var viewModel: PhysicalDocumentViewModel
    @EnvironmentObject var theme: AppTheme
    @State private var selectedPageIndex: Int = 0

    var body: some View {
        HStack(spacing: 0) {
            // 左側：頁面縮圖導航
            pageNavigationSidebar
                .frame(width: 180)
                .background(theme.sidebar)
            
            Divider()
            
            // 主要編輯區域
            if let page = viewModel.pages[safe: selectedPageIndex] {
                pageEditorView(for: page, at: selectedPageIndex)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                emptyStateView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(theme.background)
    }

    // MARK: - 子視圖

    /// 頁面導航側邊欄
    private var pageNavigationSidebar: some View {
        VStack(spacing: 0) {
            // 標題
            HStack {
                Text("頁面")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Button(action: { viewModel.insertPageBreak() }) {
                    Image(systemName: "plus.rectangle.on.rectangle")
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.borderless)
            }
            .padding(12)
            .background(theme.toolbar)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 1)
            }

            // 頁面列表
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                        pageThumbnailCard(page: page, index: index)
                    }
                }
                .padding(10)
            }

            Divider()

            // 統計資訊
            documentStatsView
        }
    }

    /// 頁面縮圖卡片
    private func pageThumbnailCard(page: PageModel, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // 頁面預覽（簡化版）
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .aspectRatio(210.0/297.0, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(selectedPageIndex == index ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: selectedPageIndex == index ? 2 : 1)
                )

            // 頁面資訊
            HStack {
                Text("第 \(page.formattedPageNumber) 頁")
                    .font(.caption)
                    .fontWeight(selectedPageIndex == index ? .semibold : .regular)

                Spacer()

                // 狀態標記
                pageStateIndicator(for: page)
            }
        }
        .padding(8)
        .background(selectedPageIndex == index ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onTapGesture {
            selectedPageIndex = index
        }
        .contextMenu {
            Button("插入分頁") {
                viewModel.insertPageBreak(at: index)
            }
            if viewModel.pages.count > 1 {
                Divider()
                Button("刪除頁面", role: .destructive) {
                    viewModel.deletePage(at: index)
                }
            }
        }
    }

    /// 頁面狀態指示器
    private func pageStateIndicator(for page: PageModel) -> some View {
        SwiftUI.Group {
            switch page.administrativeState {
            case .cover:
                Image(systemName: "book.closed.fill")
                    .foregroundColor(.purple)
            case .preface:
                Image(systemName: "text.alignleft")
                    .foregroundColor(.blue)
            case .tableOfContents:
                Image(systemName: "list.bullet")
                    .foregroundColor(.green)
            case .mainBody:
                Image(systemName: "text.book.closed")
                    .foregroundColor(.primary)
            case .appendix:
                Image(systemName: "paperclip")
                    .foregroundColor(.orange)
            case .bibliography:
                Image(systemName: "books.vertical")
                    .foregroundColor(.brown)
            }
        }
        .font(.caption)
    }

    /// 頁面編輯器視圖
    private func pageEditorView(for page: PageModel, at index: Int) -> some View {
        PageEditorContainer(
            page: page,
            viewModel: viewModel,
            pageIndex: index
        )
    }

    /// 文檔統計視圖
    private var documentStatsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.secondary)
                Text("總頁數: \(viewModel.totalPages)")
                    .font(.caption)
            }

            HStack {
                Image(systemName: "textformat.abc")
                    .foregroundColor(.secondary)
                Text("字數: \(viewModel.totalWordCount())")
                    .font(.caption)
            }

            HStack {
                Image(systemName: "character")
                    .foregroundColor(.secondary)
                Text("字符: \(viewModel.totalCharacterCount())")
                    .font(.caption)
            }
        }
        .padding()
    }

    /// 空狀態視圖
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("選擇一個頁面開始編輯")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    /// 文檔工具列
    private var documentToolbar: some ToolbarContent {
        ToolbarItemGroup {
            // 章節狀態選擇器
            Menu {
                ForEach([
                    AdministrativeState.cover,
                    .preface,
                    .tableOfContents,
                    .mainBody,
                    .appendix,
                    .bibliography
                ], id: \.self) { state in
                    Button(stateDisplayName(state)) {
                        viewModel.startNewSection(state: state)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "book.pages")
                    Text(stateDisplayName(viewModel.currentAdministrativeState))
                }
            }

            Divider()

            // 頁碼格式
            Menu {
                ForEach([
                    PageNumberStyle.arabic,
                    .romanLower,
                    .romanUpper,
                    .alphabetLower,
                    .alphabetUpper,
                    .none
                ], id: \.self) { style in
                    Button(pageNumberStyleName(style)) {
                        if let currentPage = viewModel.currentPage {
                            currentPage.pageNumberStyle = style
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "number")
                    Text("頁碼")
                }
            }

            Divider()

            // 顯示選項
            Toggle(isOn: Binding(
                get: { viewModel.currentPage?.showRulers ?? true },
                set: { viewModel.currentPage?.showRulers = $0 }
            )) {
                Image(systemName: "ruler")
            }

            Toggle(isOn: Binding(
                get: { viewModel.currentPage?.showMarginGuides ?? true },
                set: { viewModel.currentPage?.showMarginGuides = $0 }
            )) {
                Image(systemName: "square.grid.3x3")
            }
        }
    }

    // MARK: - 輔助方法

    private func stateDisplayName(_ state: AdministrativeState) -> String {
        switch state {
        case .cover: return "封面"
        case .preface: return "前言"
        case .tableOfContents: return "目錄"
        case .mainBody: return "正文"
        case .appendix: return "附錄"
        case .bibliography: return "參考文獻"
        }
    }

    private func pageNumberStyleName(_ style: PageNumberStyle) -> String {
        switch style {
        case .arabic: return "阿拉伯數字 (1, 2, 3)"
        case .romanLower: return "小寫羅馬 (i, ii, iii)"
        case .romanUpper: return "大寫羅馬 (I, II, III)"
        case .alphabetLower: return "小寫字母 (a, b, c)"
        case .alphabetUpper: return "大寫字母 (A, B, C)"
        case .none: return "無頁碼"
        }
    }
}

/// 頁面編輯器容器 - 處理單頁編輯與溢流偵測
struct PageEditorContainer: View {
    @ObservedObject var page: PageModel
    @ObservedObject var viewModel: PhysicalDocumentViewModel
    let pageIndex: Int

    @State private var attributedString: NSAttributedString

    init(page: PageModel, viewModel: PhysicalDocumentViewModel, pageIndex: Int) {
        self.page = page
        self.viewModel = viewModel
        self.pageIndex = pageIndex

        // 初始化內容
        if let data = page.contentData,
           let attrString = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
           ) {
            _attributedString = State(initialValue: attrString)
        } else {
            _attributedString = State(initialValue: NSAttributedString(string: ""))
        }
    }

    var body: some View {
        PhysicalCanvasView(
            page: page,
            attributedString: $attributedString,
            onTextChange: { newText in
                handleTextChange(newText)
            }
        )
    }

    private func handleTextChange(_ newText: NSAttributedString) {
        // 儲存到頁面模型
        if let data = try? newText.data(
            from: NSRange(location: 0, length: newText.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        ) {
            page.contentData = data
        }

        // 未來可在此處觸發溢流檢查
        // viewModel.checkAndHandleOverflow(...)
    }
}

// MARK: - 安全陣列存取

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - 預覽

#Preview {
    MultiPageDocumentView()
        .frame(width: 1200, height: 800)
}
