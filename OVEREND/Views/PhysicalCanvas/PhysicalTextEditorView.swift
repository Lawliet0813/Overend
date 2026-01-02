//
//  PhysicalTextEditorView.swift
//  OVEREND
//
//  物理文字編輯器 - NSTextView 封裝，確保座標系與 PDF 完全對應
//

import SwiftUI
import AppKit

/// 物理文字編輯器 - 提供精確的物理座標控制
struct PhysicalTextEditorView: NSViewRepresentable {
    @Binding var attributedString: NSAttributedString
    @ObservedObject var page: PageModel
    let displayScale: CGFloat
    var onTextChange: ((NSAttributedString) -> Void)?

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        // 建立 Text System Stack
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        // TextContainer 使用頁面的物理內容尺寸
        let containerSize = NSSize(
            width: page.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )

        let textContainer = NSTextContainer(size: containerSize)
        textContainer.widthTracksTextView = false // 固定寬度
        textContainer.heightTracksTextView = false
        layoutManager.addTextContainer(textContainer)

        // 創建自訂 TextView
        let textView = PhysicalTextView(frame: .zero, textContainer: textContainer)
        textView.physicalPage = page

        // 基本設定
        textView.minSize = NSSize(width: page.contentSize.width, height: page.contentSize.height)
        textView.maxSize = NSSize(width: page.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = []

        textView.isRichText = true
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true

        // 字體設定（學術論文標準）
        let defaultFont = NSFont(name: "Times New Roman", size: 12) ?? NSFont.systemFont(ofSize: 12)
        textView.font = defaultFont
        textView.textColor = .textColor

        // 排版設定
        textView.usesFontPanel = true
        textView.usesRuler = true
        textView.importsGraphics = true

        // 學術寫作最佳化
        textView.isContinuousSpellCheckingEnabled = true
        textView.isGrammarCheckingEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true
        textView.smartInsertDeleteEnabled = true

        // 學術論文段落樣式（雙倍行距）
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.paragraphSpacing = 0
        paragraphStyle.lineHeightMultiple = 2.0 // 雙倍行距
        paragraphStyle.firstLineHeadIndent = 28.35 // 2 字符縮排（12pt * 2 = 24pt ≈ 28.35）
        textView.defaultParagraphStyle = paragraphStyle

        // 移除 textContainerInset - 我們已經用 PageModel 的 margins 處理
        textView.textContainerInset = .zero

        // 設定代理
        textView.delegate = context.coordinator

        // 初始內容
        textView.textStorage?.setAttributedString(attributedString)

        // 儲存到 coordinator
        context.coordinator.textView = textView

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? PhysicalTextView else { return }

        // 更新物理頁面參考
        textView.physicalPage = page

        // 防止更新迴圈
        if !context.coordinator.isUpdating {
            let currentText = textView.attributedString()
            if currentText != attributedString {
                context.coordinator.isUpdating = true

                let selectedRange = textView.selectedRange()
                textView.textStorage?.setAttributedString(attributedString)

                if selectedRange.location <= attributedString.length {
                    textView.setSelectedRange(selectedRange)
                }

                context.coordinator.isUpdating = false
            }
        }

        // 更新 container 尺寸（如果邊距改變）
        if let textContainer = textView.textContainer {
            let newSize = NSSize(
                width: page.contentSize.width,
                height: CGFloat.greatestFiniteMagnitude
            )
            if textContainer.size != newSize {
                textContainer.size = newSize
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PhysicalTextEditorView
        var isUpdating = false
        weak var textView: PhysicalTextView?

        init(_ parent: PhysicalTextEditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating,
                  let textView = notification.object as? NSTextView else { return }

            isUpdating = true
            let newValue = textView.attributedString()
            parent.attributedString = newValue
            parent.onTextChange?(newValue)

            // 檢查是否需要溢流到下一頁
            checkOverflow(textView: textView)

            isUpdating = false
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            // 未來可以在這裡追蹤選取範圍變化
        }

        /// 檢查文字是否溢出當前頁面
        private func checkOverflow(textView: NSTextView) {
            guard let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else { return }

            // 計算實際使用的高度
            layoutManager.ensureLayout(for: textContainer)
            let usedRect = layoutManager.usedRect(for: textContainer)

            // 檢查是否超過頁面內容高度
            let maxHeight = parent.page.contentSize.height

            if usedRect.height > maxHeight {
                // 觸發溢流事件（在後續階段實作）
                print("⚠️ 文字溢流：需要建立新頁面")
                print("使用高度: \(usedRect.height)pt，最大高度: \(maxHeight)pt")
            }
        }
    }
}

// MARK: - 自訂 NSTextView

/// 物理 TextView - 具備物理座標感知能力
class PhysicalTextView: NSTextView {
    /// 關聯的物理頁面
    weak var physicalPage: PageModel?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // 繪製物理座標網格（除錯用，可選）
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "ShowPhysicalGrid") {
            drawPhysicalGrid()
        }
        #endif
    }

    /// 繪製物理座標網格（除錯輔助）
    private func drawPhysicalGrid() {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        context.saveGState()
        context.setStrokeColor(NSColor.systemGray.withAlphaComponent(0.1).cgColor)
        context.setLineWidth(0.5)

        // 每 1cm 一條線
        let gridSpacing = UnitLength.centimeter(1).toPoints

        // 垂直線
        var x: CGFloat = 0
        while x < bounds.width {
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: bounds.height))
            x += gridSpacing
        }

        // 水平線
        var y: CGFloat = 0
        while y < bounds.height {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: bounds.width, y: y))
            y += gridSpacing
        }

        context.strokePath()
        context.restoreGState()
    }

    /// 取得當前游標的物理座標
    func currentPhysicalPosition() -> CGPoint? {
        guard let layoutManager = self.layoutManager,
              let textContainer = self.textContainer else { return nil }

        let selectedRange = self.selectedRange()
        guard selectedRange.location != NSNotFound else { return nil }

        let glyphIndex = layoutManager.glyphIndexForCharacter(at: selectedRange.location)
        let rect = layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textContainer)

        return CGPoint(x: rect.origin.x, y: rect.origin.y)
    }

    /// 計算剩餘可用高度
    func remainingHeight() -> CGFloat {
        guard let layoutManager = self.layoutManager,
              let textContainer = self.textContainer,
              let physicalPage = self.physicalPage else { return 0 }

        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)
        let maxHeight = physicalPage.contentSize.height

        return max(0, maxHeight - usedRect.height)
    }
}

// MARK: - 預覽

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var page = PageModel.preview
        @State private var text: NSAttributedString = {
            let str = """
            第一章 緒論

            1.1 研究背景

            本研究旨在探討......

            （此處為測試內容）
            """
            return NSAttributedString(string: str)
        }()

        var body: some View {
            PhysicalTextEditorView(
                attributedString: $text,
                page: page,
                displayScale: 1.0
            )
            .frame(width: 500, height: 700)
            .background(Color.white)
        }
    }

    return PreviewWrapper()
}
