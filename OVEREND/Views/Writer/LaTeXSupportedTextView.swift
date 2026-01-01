//
//  LaTeXSupportedTextView.swift
//  OVEREND
//
//  支援 LaTeX 公式的 NSTextView - 混合模式編輯器
//

import AppKit
import Foundation

/// 支援 LaTeX 公式渲染的文字編輯器
class LaTeXSupportedTextView: NSTextView {

    /// LaTeX 公式的自訂屬性鍵
    private static let latexFormulaKey = NSAttributedString.Key("LaTeXFormula")

    /// 是否啟用即時渲染
    var enableRealTimeRendering = true

    /// 渲染延遲（秒）- 避免頻繁渲染
    var renderDelay: TimeInterval = 0.5

    /// 延遲渲染計時器
    private var renderTimer: Timer?

    /// LaTeX 公式快取（避免重複渲染）
    private var formulaCache: [String: NSImage] = [:]

    override func didChangeText() {
        super.didChangeText()

        guard enableRealTimeRendering else { return }

        // 取消先前的計時器
        renderTimer?.invalidate()

        // 延遲渲染（避免輸入時頻繁渲染）
        renderTimer = Timer.scheduledTimer(withTimeInterval: renderDelay, repeats: false) { [weak self] _ in
            self?.renderAllLaTeXFormulas()
        }
    }

    /// 渲染所有 LaTeX 公式
    func renderAllLaTeXFormulas() {
        guard let textStorage = textStorage else { return }

        let fullText = textStorage.string
        let pattern = "\\$([^$]+)\\$" // 匹配 $...$ 格式

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }

        let matches = regex.matches(in: fullText, options: [], range: NSRange(location: 0, length: fullText.utf16.count))

        // 從後往前處理（避免替換後位置偏移）
        for match in matches.reversed() {
            let formulaRange = match.range(at: 1) // 公式內容（不含 $ 符號）
            let fullRange = match.range // 完整範圍（含 $ 符號）

            guard let swiftRange = Range(formulaRange, in: fullText) else { continue }

            let formula = String(fullText[swiftRange])

            // 檢查是否已經渲染過
            if let existingFormula = textStorage.attribute(Self.latexFormulaKey, at: fullRange.location, effectiveRange: nil) as? String,
               existingFormula == formula {
                // 已經渲染過且公式未變，跳過
                continue
            }

            // 渲染公式
            renderFormula(formula, at: fullRange, originalText: "$\(formula)$")
        }
    }

    /// 渲染單個公式
    private func renderFormula(_ formula: String, at range: NSRange, originalText: String) {
        guard let textStorage = textStorage else { return }

        // 檢查快取
        if let cachedImage = formulaCache[formula] {
            insertRenderedFormula(image: cachedImage, formula: formula, at: range, originalText: originalText)
            return
        }

        // 渲染公式
        let fontSize = (font?.pointSize ?? 16)
        let result = LaTeXRenderer.render(formula: formula, fontSize: fontSize)

        switch result {
        case .success(let image):
            // 加入快取
            formulaCache[formula] = image

            // 插入渲染結果
            insertRenderedFormula(image: image, formula: formula, at: range, originalText: originalText)

        case .error(let errorMessage):
            // 渲染失敗，保留原始文字並加上錯誤提示
            print("LaTeX 渲染失敗：\(errorMessage)")
            // 可選：顯示錯誤提示給用戶
        }
    }

    /// 將渲染好的圖片插入文檔
    private func insertRenderedFormula(image: NSImage, formula: String, at range: NSRange, originalText: String) {
        guard let textStorage = textStorage else { return }

        // 建立 NSTextAttachment
        let attachment = NSTextAttachment()
        attachment.image = image

        // 設定圖片基線對齊
        let fontSize = (font?.pointSize ?? 16)
        attachment.bounds = CGRect(
            x: 0,
            y: -fontSize * 0.2, // 向下偏移 20% 使其與文字基線對齊
            width: image.size.width,
            height: image.size.height
        )

        // 建立屬性字串
        let attachmentString = NSMutableAttributedString(attachment: attachment)

        // 添加自訂屬性（記錄原始 LaTeX 公式）
        attachmentString.addAttribute(Self.latexFormulaKey, value: formula, range: NSRange(location: 0, length: 1))

        // 添加工具提示（hover 顯示原始公式）
        attachmentString.addAttribute(.toolTip, value: originalText, range: NSRange(location: 0, length: 1))

        // 替換文字為圖片
        textStorage.replaceCharacters(in: range, with: attachmentString)
    }

    /// 將圖片轉回 LaTeX 文字（用於編輯）
    func convertImageToLaTeX(at location: Int) -> Bool {
        guard let textStorage = textStorage else { return false }

        // 檢查是否為 LaTeX 公式圖片
        guard let formula = textStorage.attribute(Self.latexFormulaKey, at: location, effectiveRange: nil) as? String else {
            return false
        }

        // 轉回文字
        let latexText = "$\(formula)$"
        let attributedText = NSAttributedString(string: latexText, attributes: [.font: font ?? NSFont.systemFont(ofSize: 16)])

        textStorage.replaceCharacters(in: NSRange(location: location, length: 1), with: attributedText)

        // 將游標移至公式結尾
        setSelectedRange(NSRange(location: location + latexText.count, length: 0))

        return true
    }

    /// 雙擊編輯 LaTeX 公式
    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            let point = convert(event.locationInWindow, from: nil)
            let charIndex = characterIndexForInsertion(at: point)

            // 嘗試將圖片轉回 LaTeX 文字
            if convertImageToLaTeX(at: charIndex) {
                return
            }
        }

        super.mouseDown(with: event)
    }

    /// 清除快取
    func clearFormulaCache() {
        formulaCache.removeAll()
    }
}
