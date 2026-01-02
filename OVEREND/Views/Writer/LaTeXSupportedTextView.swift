//
//  LaTeXSupportedTextView.swift
//  OVEREND
//
//  支援 LaTeX 公式的 NSTextView - 混合模式編輯器
//  實現 "Overleaf without switching" 的核心邏輯：
//  1. 游標離開公式時 -> 自動渲染為圖片
//  2. 游標進入公式時 -> 自動展開為原始碼
//

import AppKit
import Foundation

/// 支援 LaTeX 公式渲染的文字編輯器
class LaTeXSupportedTextView: NSTextView {

    /// LaTeX 公式的自訂屬性鍵
    private static let latexFormulaKey = NSAttributedString.Key("LaTeXFormula")
    
    /// 是否啟用即時渲染（混合模式）
    var enableHybridMode = true

    /// 渲染延遲（秒）
    var renderDelay: TimeInterval = 0.3

    /// 延遲處理計時器
    private var processTimer: Timer?

    /// LaTeX 公式快取
    private var formulaCache: [String: NSImage] = [:]

    // MARK: - Initialization
    
    override init(frame frameRect: NSRect, textContainer: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: textContainer)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        self.isRichText = true
        self.allowsUndo = true
    }

    // MARK: - Text & Selection Handling

    override func didChangeText() {
        super.didChangeText()
        
        guard enableHybridMode else { return }
        
        // 內容變更時，延遲觸發混合模式處理
        processTimer?.invalidate()
        processTimer = Timer.scheduledTimer(withTimeInterval: renderDelay, repeats: false) { [weak self] _ in
            self?.processHybridMode()
        }
    }
    
    override func setSelectedRange(_ charRange: NSRange, affinity: NSSelectionAffinity, stillSelecting flag: Bool) {
        super.setSelectedRange(charRange, affinity: affinity, stillSelecting: flag)
        
        // 選取範圍改變且停止選取時，立即觸發處理
        if !flag && enableHybridMode {
            // 取消之前的延遲處理，立即執行
            processTimer?.invalidate()
            processHybridMode()
        }
    }

    // MARK: - Hybrid Mode Logic
    
    /// 處理混合模式：展開游標處的公式，渲染非游標處的公式
    private func processHybridMode() {
        guard let textStorage = textStorage else { return }
        let currentRange = selectedRange()
        
        // 1. 展開：檢查游標是否接觸到已渲染的公式圖片
        expandFormulas(at: currentRange)
        
        // 2. 渲染：檢查是否有未渲染的公式代碼（且游標不在其中）
        renderFormulas(excluding: currentRange)
    }
    
    /// 展開指定範圍內的公式圖片為文字
    private func expandFormulas(at range: NSRange) {
        guard let textStorage = textStorage else { return }
        
        // 找出範圍內所有的 LaTeX 附件
        var rangesToExpand: [NSRange] = []
        
        // 擴大檢查範圍（前後各 1 字元），以便游標貼近時也能展開
        let checkLocation = max(0, range.location - 1)
        let checkLength = min(textStorage.length - checkLocation, range.length + 2)
        let checkRange = NSRange(location: checkLocation, length: checkLength)
        
        textStorage.enumerateAttribute(Self.latexFormulaKey, in: checkRange, options: []) { value, subRange, _ in
            if value != nil {
                rangesToExpand.append(subRange)
            }
        }
        
        // 從後往前處理
        for subRange in rangesToExpand.reversed() {
            convertImageToLaTeX(at: subRange.location)
        }
    }
    
    /// 渲染不在選取範圍內的公式代碼
    private func renderFormulas(excluding excludedRange: NSRange) {
        guard let textStorage = textStorage else { return }
        
        let fullText = textStorage.string
        // 匹配 $...$ 格式，但排除轉義的 \$
        let pattern = "(?<!\\\\)\\$([^$]+)(?<!\\\\)\\$"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        
        let matches = regex.matches(in: fullText, options: [], range: NSRange(location: 0, length: fullText.utf16.count))
        
        // 從後往前處理
        for match in matches.reversed() {
            let fullRange = match.range
            
            // 如果公式範圍與當前選取範圍（或游標位置）重疊，則跳過（保持編輯狀態）
            // 這裡我們稍微放寬條件：只要游標在公式內或邊緣，就不渲染
            if NSIntersectionRange(fullRange, excludedRange).length > 0 ||
               (excludedRange.location >= fullRange.location && excludedRange.location <= fullRange.upperBound) {
                continue
            }
            
            let formulaRange = match.range(at: 1)
            guard let swiftRange = Range(formulaRange, in: fullText) else { continue }
            let formula = String(fullText[swiftRange])
            
            // 渲染
            renderFormula(formula, at: fullRange, originalText: "$\(formula)$")
        }
    }

    // MARK: - Rendering Helpers
    
    private func renderFormula(_ formula: String, at range: NSRange, originalText: String) {
        guard let textStorage = textStorage else { return }
        
        // 檢查快取
        if let cachedImage = formulaCache[formula] {
            insertRenderedFormula(image: cachedImage, formula: formula, at: range, originalText: originalText)
            return
        }
        
        // 渲染公式
        let fontSize = (font?.pointSize ?? 16)
        // 使用 LaTeXRenderer 服務
        let result = LaTeXRenderer.render(formula: formula, fontSize: fontSize)
        
        switch result {
        case .success(let image):
            formulaCache[formula] = image
            insertRenderedFormula(image: image, formula: formula, at: range, originalText: originalText)
            
        case .error(let errorMessage):
            print("LaTeX 渲染失敗：\(errorMessage)")
        }
    }
    
    private func insertRenderedFormula(image: NSImage, formula: String, at range: NSRange, originalText: String) {
        guard let textStorage = textStorage else { return }
        
        let attachment = NSTextAttachment()
        attachment.image = image
        
        // 調整圖片位置以對齊文字基線
        let fontSize = (font?.pointSize ?? 16)
        attachment.bounds = CGRect(
            x: 0,
            y: -fontSize * 0.25,
            width: image.size.width,
            height: image.size.height
        )
        
        let attachmentString = NSMutableAttributedString(attachment: attachment)
        
        // 添加關鍵屬性：標記這是 LaTeX 公式，並儲存原始碼
        attachmentString.addAttribute(Self.latexFormulaKey, value: formula, range: NSRange(location: 0, length: 1))
        attachmentString.addAttribute(.toolTip, value: originalText, range: NSRange(location: 0, length: 1))
        
        // 保持原有的字體屬性（避免影響周圍文字）
        if let currentFont = font {
            attachmentString.addAttribute(.font, value: currentFont, range: NSRange(location: 0, length: 1))
        }
        
        // 替換文字
        // 注意：這裡可能會改變 textStorage 的長度，這就是為什麼外層迴圈要從後往前
        if range.location + range.length <= textStorage.length {
            textStorage.replaceCharacters(in: range, with: attachmentString)
        }
    }
    
    @discardableResult
    private func convertImageToLaTeX(at location: Int) -> Bool {
        guard let textStorage = textStorage, location < textStorage.length else { return false }
        
        // 檢查是否為 LaTeX 公式
        guard let formula = textStorage.attribute(Self.latexFormulaKey, at: location, effectiveRange: nil) as? String else {
            return false
        }
        
        let latexText = "$\(formula)$"
        let attributedText = NSAttributedString(string: latexText, attributes: [
            .font: font ?? NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.textColor
        ])
        
        textStorage.replaceCharacters(in: NSRange(location: location, length: 1), with: attributedText)
        
        return true
    }
    
    /// 清除快取
    func clearFormulaCache() {
        formulaCache.removeAll()
    }
}

