//
//  AICommand.swift
//  OVEREND
//
//  AI 指令相關資料模型
//  Created: 2026-01-03
//

import Foundation
import AppKit
import SwiftUI

// MARK: - 指令分類

/// AI 指令分類
enum CommandCategory: String, CaseIterable {
    case grammar      // 語法
    case citation     // 引用
    case formatting   // 格式
    case style        // 文體
    case custom       // 自訂

    var color: Color {
        switch self {
        case .grammar: return .green
        case .citation: return .blue
        case .formatting: return .orange
        case .style: return .purple
        case .custom: return .gray
        }
    }

    var displayName: String {
        switch self {
        case .grammar: return "語法"
        case .citation: return "引用"
        case .formatting: return "格式"
        case .style: return "文體"
        case .custom: return "自訂"
        }
    }
}

// MARK: - 指令上下文

/// AI 指令執行上下文
struct AICommandContext {
    let selectedText: NSAttributedString?
    let selectedRange: NSRange
    let currentFont: NSFont?
    let currentParagraphStyle: NSParagraphStyle?
    let metadata: ThesisMetadata?

    /// 格式化上下文資訊為提示詞
    func formatForPrompt() -> String {
        var context = ""

        if let text = selectedText?.string, !text.isEmpty {
            context += "選取的文字：\n\(text)\n\n"
        }

        if let font = currentFont {
            context += "當前字體：\(font.fontName) \(font.pointSize)pt\n"
        }

        if let paragraphStyle = currentParagraphStyle {
            context += "段落樣式：\n"
            context += "- 對齊：\(paragraphStyle.alignment.rawValue)\n"
            context += "- 行距倍數：\(paragraphStyle.lineHeightMultiple)\n"
            context += "- 首行縮排：\(paragraphStyle.firstLineHeadIndent)pt\n"
        }

        return context
    }
}

// MARK: - AI 指令

/// AI 指令模型
struct AICommand {
    let id = UUID()
    let prompt: String
    let context: AICommandContext
    let category: CommandCategory
    let timestamp = Date()

    /// 完整的 AI 提示詞（包含上下文）
    var fullPrompt: String {
        var full = prompt + "\n\n"
        full += "上下文資訊：\n"
        full += context.formatForPrompt()
        return full
    }
}
