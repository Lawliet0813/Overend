//
//  ClaudeWritingAssistantView+Insert.swift
//  OVEREND
//
//  插入功能擴展 - 圖片、表格、註腳
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Insert Extension

extension ClaudeWritingAssistantView {
    
    // MARK: - Insert Image
    
    func insertImage() {
        let panel = NSOpenPanel()
        panel.title = "選擇圖片"
        panel.allowedContentTypes = [.image, .png, .jpeg, .gif]
        panel.allowsMultipleSelection = false
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                self.insertImageFromURL(url)
            }
        }
    }
    
    private func insertImageFromURL(_ url: URL) {
        guard let image = NSImage(contentsOf: url) else {
            ToastManager.shared.showError("無法載入圖片")
            return
        }
        
        // 計算適當的尺寸（最大寬度 500）
        let maxWidth: CGFloat = 500
        let scaleFactor = min(1.0, maxWidth / image.size.width)
        let newSize = NSSize(
            width: image.size.width * scaleFactor,
            height: image.size.height * scaleFactor
        )
        
        // 建立附件
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(origin: .zero, size: newSize)
        
        // 建立帶有附件的 AttributedString
        let attachmentString = NSMutableAttributedString(attachment: attachment)
        attachmentString.append(NSAttributedString(string: "\n"))
        
        // 插入到當前位置
        viewModel.attributedText.append(attachmentString)
        viewModel.text = viewModel.attributedText.string
        
        ToastManager.shared.showSuccess("已插入圖片")
    }
    
    // MARK: - Insert Table
    
    func insertTable() {
        // 插入 Markdown 格式表格
        let tableTemplate = """
        
        | 欄位 1 | 欄位 2 | 欄位 3 |
        |--------|--------|--------|
        | 內容 1 | 內容 2 | 內容 3 |
        | 內容 4 | 內容 5 | 內容 6 |
        
        """
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: viewModel.selectedFontSize - 2, weight: .regular),
            .foregroundColor: viewModel.selectedTextColor
        ]
        
        let tableString = NSAttributedString(string: tableTemplate, attributes: attributes)
        viewModel.attributedText.append(tableString)
        viewModel.text = viewModel.attributedText.string
        
        ToastManager.shared.showSuccess("已插入表格")
    }
    
    // MARK: - Insert Footnote
    
    func insertFootnote() {
        // 計算註腳編號
        let text = viewModel.attributedText.string
        let footnotePattern = #"\[\^\d+\]"#
        let regex = try? NSRegularExpression(pattern: footnotePattern)
        let existingCount = regex?.numberOfMatches(
            in: text,
            range: NSRange(location: 0, length: text.count)
        ) ?? 0
        
        let footnoteNumber = existingCount + 1
        let footnoteReference = "[^\(footnoteNumber)]"
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: viewModel.selectedFontSize * 0.8),
            .foregroundColor: NSColor.systemBlue,
            .superscript: NSNumber(value: 1)
        ]
        
        let footnoteString = NSAttributedString(string: footnoteReference, attributes: attributes)
        viewModel.attributedText.append(footnoteString)
        viewModel.text = viewModel.attributedText.string
        
        ToastManager.shared.showSuccess("已插入註腳 \(footnoteReference)")
    }
    
    // MARK: - Insert Divider
    
    func insertDivider() {
        let divider = """
        
        ───────────────────────────────────────
        
        """
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: viewModel.selectedFontSize),
            .foregroundColor: NSColor.separatorColor
        ]
        
        let dividerString = NSAttributedString(string: divider, attributes: attributes)
        viewModel.attributedText.append(dividerString)
        viewModel.text = viewModel.attributedText.string
        
        ToastManager.shared.showSuccess("已插入分隔線")
    }
    
    // MARK: - Insert Current Date
    
    func insertCurrentDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 M 月 d 日"
        let dateString = formatter.string(from: Date())
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: viewModel.selectedFontSize),
            .foregroundColor: viewModel.selectedTextColor
        ]
        
        let dateAttributed = NSAttributedString(string: dateString, attributes: attributes)
        viewModel.attributedText.append(dateAttributed)
        viewModel.text = viewModel.attributedText.string
        
        ToastManager.shared.showSuccess("已插入日期")
    }
}
