//
//  ClaudeWritingAssistantView+ChineseOptimization.swift
//  OVEREND
//
//  中文優化和論文格式功能擴展
//

import SwiftUI
import AppKit

// MARK: - Chinese Optimization Extension

extension ClaudeWritingAssistantView {
    
    // MARK: - Chinese Optimization
    
    /// 標點符號全形化
    func optimizePunctuation() {
        let text = viewModel.attributedText.string
        let optimized = ChineseOptimizationService.shared.convertToFullWidthPunctuation(text)
        
        if optimized != text {
            replaceAllText(with: optimized)
            ToastManager.shared.showSuccess("標點符號已轉換為全形")
        } else {
            ToastManager.shared.showInfo("沒有需要轉換的標點符號")
        }
    }
    
    /// 中英文間距調整
    func optimizeSpacing() {
        let text = viewModel.attributedText.string
        let optimized = ChineseOptimizationService.shared.adjustSpacing(text)
        
        if optimized != text {
            replaceAllText(with: optimized)
            ToastManager.shared.showSuccess("中英文間距已調整")
        } else {
            ToastManager.shared.showInfo("間距已經正確")
        }
    }
    
    /// 轉換為繁體中文
    func convertToTraditional() {
        let text = viewModel.attributedText.string
        let converted = ChineseOptimizationService.shared.convertScript(text, to: .traditional)
        
        if converted != text {
            replaceAllText(with: converted)
            ToastManager.shared.showSuccess("已轉換為繁體中文")
        } else {
            ToastManager.shared.showInfo("文字已經是繁體中文")
        }
    }
    
    /// 轉換為簡體中文
    func convertToSimplified() {
        let text = viewModel.attributedText.string
        let converted = ChineseOptimizationService.shared.convertScript(text, to: .simplified)
        
        if converted != text {
            replaceAllText(with: converted)
            ToastManager.shared.showSuccess("已轉換為簡體中文")
        } else {
            ToastManager.shared.showInfo("文字已經是簡體中文")
        }
    }
    
    /// 術語檢查與修正
    func checkTerminology() {
        let text = viewModel.attributedText.string
        let suggestions = ChineseOptimizationService.shared.checkTerminology(text)
        
        if suggestions.isEmpty {
            ToastManager.shared.showSuccess("未發現需要修正的術語")
            return
        }
        
        var optimizedText = text
        for suggestion in suggestions {
            optimizedText = optimizedText.replacingOccurrences(of: suggestion.original, with: suggestion.suggestion)
        }
        
        replaceAllText(with: optimizedText)
        ToastManager.shared.showSuccess("已修正 \(suggestions.count) 個術語")
    }
    
    /// 執行完整中文優化
    func fullChineseOptimization() {
        var text = viewModel.attributedText.string
        
        // 1. 標點符號全形化
        text = ChineseOptimizationService.shared.convertToFullWidthPunctuation(text)
        
        // 2. 中英文間距調整
        text = ChineseOptimizationService.shared.adjustSpacing(text)
        
        // 3. 術語檢查
        let suggestions = ChineseOptimizationService.shared.checkTerminology(text)
        for suggestion in suggestions {
            text = text.replacingOccurrences(of: suggestion.original, with: suggestion.suggestion)
        }
        
        replaceAllText(with: text)
        ToastManager.shared.showSuccess("中文優化完成")
    }
    
    // MARK: - NCCU Thesis Format
    
    /// 套用政大論文格式
    func applyNCCUFormat() {
        let textStorage = NSTextStorage(attributedString: viewModel.attributedText)
        NCCUFormatService.shared.applyFormat(to: textStorage)
        viewModel.attributedText = NSMutableAttributedString(attributedString: textStorage)
        viewModel.text = viewModel.attributedText.string
        ToastManager.shared.showSuccess("已套用政大論文格式")
    }
    
    /// 顯示封面輸入表單
    /// 這個方法將由 Sheet 修飾符觸發，需在主視圖中設置
    
    // MARK: - Private Helpers
    
    private func replaceAllText(with newText: String) {
        // 保持原有屬性，只替換文字
        let range = NSRange(location: 0, length: viewModel.attributedText.length)
        
        // 獲取原有屬性
        var attributes: [NSAttributedString.Key: Any] = [:]
        if range.length > 0 {
            attributes = viewModel.attributedText.attributes(at: 0, effectiveRange: nil)
        } else {
            attributes = [
                .font: NSFont.systemFont(ofSize: viewModel.selectedFontSize),
                .foregroundColor: viewModel.selectedTextColor
            ]
        }
        
        let newAttributedText = NSMutableAttributedString(string: newText, attributes: attributes)
        viewModel.attributedText = newAttributedText
        viewModel.text = newText
    }
}
