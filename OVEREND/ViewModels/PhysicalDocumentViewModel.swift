//
//  PhysicalDocumentViewModel.swift
//  OVEREND
//
//  物理文檔視圖模型 - 管理多頁面文檔與自動溢流
//

import Foundation
import SwiftUI
import AppKit
import Combine

/// 物理文檔視圖模型 - 處理跨頁文字流與格式繼承
class PhysicalDocumentViewModel: ObservableObject {
    /// 所有頁面陣列
    @Published var pages: [PageModel] = []

    /// 當前編輯的頁面索引
    @Published var currentPageIndex: Int = 0

    /// 文檔標題
    @Published var documentTitle: String = "未命名文件"

    /// 行政狀態（影響新頁面的格式）
    @Published var currentAdministrativeState: AdministrativeState = .mainBody

    /// 是否啟用自動溢流
    @Published var autoFlowEnabled: Bool = true

    /// 孤行保護（避頭尾規範）
    @Published var orphanProtectionEnabled: Bool = true

    // MARK: - 初始化

    init() {
        // 創建第一頁
        let firstPage = PageModel(
            pageNumber: 1,
            pageNumberStyle: .arabic,
            administrativeState: .mainBody,
            margins: .nccu
        )
        pages.append(firstPage)
    }

    // MARK: - 頁面管理

    /// 當前頁面
    var currentPage: PageModel? {
        guard currentPageIndex < pages.count else { return nil }
        return pages[currentPageIndex]
    }

    /// 新增頁面（繼承前一頁的樣式）
    @discardableResult
    func addPage(after pageIndex: Int? = nil) -> PageModel {
        let insertIndex = pageIndex ?? pages.count - 1
        let previousPage = pages[insertIndex]

        // 創建新頁面並繼承樣式
        let newPage = previousPage.createNextPage()

        // 插入到正確位置
        pages.insert(newPage, at: insertIndex + 1)

        // 重新編號後續頁面
        renumberPages(from: insertIndex + 1)

        return newPage
    }

    /// 刪除頁面
    func deletePage(at index: Int) {
        guard pages.count > 1, index < pages.count else { return }

        pages.remove(at: index)

        // 重新編號
        renumberPages(from: index)

        // 調整當前頁面索引
        if currentPageIndex >= pages.count {
            currentPageIndex = pages.count - 1
        }
    }

    /// 重新編號頁面
    private func renumberPages(from startIndex: Int) {
        guard startIndex < pages.count else { return }

        for i in startIndex..<pages.count {
            // 保持頁碼連續性，考慮行政狀態
            if i > 0 {
                let previousPage = pages[i - 1]
                pages[i].pageNumber = previousPage.pageNumber + 1
            }
        }
    }

    // MARK: - 自動溢流

    /// 檢查頁面是否需要溢流
    func checkAndHandleOverflow(for pageIndex: Int, textStorage: NSTextStorage, layoutManager: NSLayoutManager, textContainer: NSTextContainer) {
        guard autoFlowEnabled, pageIndex < pages.count else { return }

        let page = pages[pageIndex]
        let maxHeight = page.contentSize.height

        // 確保佈局完成
        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)

        // 檢查是否溢出
        if usedRect.height > maxHeight {
            performAutoFlow(
                from: pageIndex,
                textStorage: textStorage,
                layoutManager: layoutManager,
                textContainer: textContainer,
                maxHeight: maxHeight
            )
        }
    }

    /// 執行自動溢流
    private func performAutoFlow(
        from pageIndex: Int,
        textStorage: NSTextStorage,
        layoutManager: NSLayoutManager,
        textContainer: NSTextContainer,
        maxHeight: CGFloat
    ) {
        // 找出溢出的文字範圍
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        var overflowGlyphIndex: Int?

        // 遍歷每個 glyph 找到超過高度限制的位置
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { rect, usedRect, textContainer, glyphRange, stop in
            if rect.maxY > maxHeight {
                overflowGlyphIndex = glyphRange.location
                stop.pointee = true
            }
        }

        guard let overflowGlyph = overflowGlyphIndex else { return }

        // 轉換為字符索引
        let overflowCharIndex = layoutManager.characterIndexForGlyph(at: overflowGlyph)

        // 孤行保護：確保不會在段落中間截斷
        let adjustedCharIndex = orphanProtectionEnabled ?
            adjustOverflowPosition(at: overflowCharIndex, in: textStorage) :
            overflowCharIndex

        // 分割文字
        let totalLength = textStorage.length
        guard adjustedCharIndex < totalLength else { return }

        let overflowRange = NSRange(location: adjustedCharIndex, length: totalLength - adjustedCharIndex)
        let overflowText = textStorage.attributedSubstring(from: overflowRange)

        // 從當前頁面移除溢出文字
        textStorage.deleteCharacters(in: overflowRange)

        // 創建或更新下一頁
        let nextPageIndex = pageIndex + 1
        if nextPageIndex < pages.count {
            // 下一頁已存在，插入溢出文字到開頭
            if let nextPageData = pages[nextPageIndex].contentData {
                let mutableText = NSMutableAttributedString(attributedString: overflowText)
                if let existingText = try? NSAttributedString(
                    data: nextPageData,
                    options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil
                ) {
                    mutableText.append(existingText)
                }
                pages[nextPageIndex].contentData = try? mutableText.data(
                    from: NSRange(location: 0, length: mutableText.length),
                    documentAttributes: [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.rtf]
                )
            } else {
                pages[nextPageIndex].contentData = try? overflowText.data(
                    from: NSRange(location: 0, length: overflowText.length),
                    documentAttributes: [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.rtf]
                )
            }
        } else {
            // 創建新頁面
            let newPage = addPage(after: pageIndex)
            newPage.contentData = try? overflowText.data(
                from: NSRange(location: 0, length: overflowText.length),
                documentAttributes: [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.rtf]
            )
        }
    }

    /// 調整溢流位置以避免孤行
    private func adjustOverflowPosition(at position: Int, in textStorage: NSTextStorage) -> Int {
        let text = textStorage.string as NSString

        // 找到當前段落範圍
        let paragraphRange = text.paragraphRange(for: NSRange(location: position, length: 0))

        // 計算段落中的行數
        let paragraphText = text.substring(with: paragraphRange)
        let lineCount = paragraphText.components(separatedBy: .newlines).count

        // 如果會產生孤行（段落最後一行單獨在下一頁），則將整個段落移到下一頁
        if position > paragraphRange.location && position < paragraphRange.upperBound {
            // 檢查是否為段落最後一行
            let remainingInParagraph = paragraphRange.upperBound - position
            let avgLineLength = paragraphRange.length / max(lineCount, 1)

            if remainingInParagraph < avgLineLength * 2 {
                // 保留至少兩行在當前頁，或將整個段落移到下一頁
                return paragraphRange.location
            }
        }

        // 檢查標題孤立（標題不應單獨在頁面底部）
        if position > 0 {
            let attributes = textStorage.attributes(at: position - 1, effectiveRange: nil)
            if let font = attributes[.font] as? NSFont {
                // 如果是大字體（可能是標題），將其移到下一頁
                if font.pointSize > 16 {
                    return paragraphRange.location
                }
            }
        }

        return position
    }

    // MARK: - 章節與狀態管理

    /// 開始新章節（影響頁碼格式）
    func startNewSection(state: AdministrativeState, resetPageNumber: Bool = false) {
        currentAdministrativeState = state

        if let currentPage = currentPage {
            currentPage.administrativeState = state
            currentPage.pageNumberStyle = state.defaultPageNumberStyle

            if resetPageNumber {
                currentPage.pageNumber = 1
                renumberPages(from: currentPageIndex)
            }
        }
    }

    /// 插入分頁符（強制新頁）
    func insertPageBreak(at pageIndex: Int? = nil) {
        let index = pageIndex ?? currentPageIndex
        let newPage = addPage(after: index)
        currentPageIndex = pages.firstIndex(where: { $0.id == newPage.id }) ?? currentPageIndex
    }

    // MARK: - 文檔統計

    /// 總頁數
    var totalPages: Int {
        pages.count
    }

    /// 總字數（所有頁面）
    func totalWordCount() -> Int {
        var count = 0
        for page in pages {
            if let data = page.contentData,
               let attrString = try? NSAttributedString(
                data: data,
                options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
               ) {
                let text = attrString.string
                let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                count += words.count
            }
        }
        return count
    }

    /// 總字符數
    func totalCharacterCount() -> Int {
        var count = 0
        for page in pages {
            if let data = page.contentData,
               let attrString = try? NSAttributedString(
                data: data,
                options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
               ) {
                count += attrString.length
            }
        }
        return count
    }
}

// MARK: - 預覽

extension PhysicalDocumentViewModel {
    static var preview: PhysicalDocumentViewModel {
        let vm = PhysicalDocumentViewModel()
        vm.documentTitle = "測試論文"
        return vm
    }
}
