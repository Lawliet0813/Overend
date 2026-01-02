//
//  BlockType.swift
//  OVEREND
//
//  Notion 風格的區塊類型定義
//

import Foundation

/// 區塊類型枚舉
enum BlockType: String, Codable, CaseIterable {
    case paragraph = "paragraph"
    case heading1 = "heading1"
    case heading2 = "heading2"
    case heading3 = "heading3"
    case bulletList = "bulletList"
    case numberedList = "numberedList"
    case checkbox = "checkbox"
    case quote = "quote"
    case code = "code"
    case divider = "divider"
    case image = "image"
    case citation = "citation"
    case equation = "equation"
    case callout = "callout"
    case toggle = "toggle"
    
    var displayName: String {
        switch self {
        case .paragraph: return "段落"
        case .heading1: return "標題 1"
        case .heading2: return "標題 2"
        case .heading3: return "標題 3"
        case .bulletList: return "項目符號清單"
        case .numberedList: return "編號清單"
        case .checkbox: return "待辦事項"
        case .quote: return "引用"
        case .code: return "代碼"
        case .divider: return "分隔線"
        case .image: return "圖片"
        case .citation: return "文獻引用"
        case .equation: return "數學公式"
        case .callout: return "標註框"
        case .toggle: return "摺疊區塊"
        }
    }
    
    var icon: String {
        switch self {
        case .paragraph: return "text.alignleft"
        case .heading1: return "textformat.size.larger"
        case .heading2: return "textformat.size"
        case .heading3: return "textformat.size.smaller"
        case .bulletList: return "list.bullet"
        case .numberedList: return "list.number"
        case .checkbox: return "checkmark.square"
        case .quote: return "quote.bubble"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .divider: return "minus"
        case .image: return "photo"
        case .citation: return "book.closed"
        case .equation: return "function"
        case .callout: return "lightbulb"
        case .toggle: return "chevron.right"
        }
    }
    
    var slashCommand: String {
        switch self {
        case .paragraph: return "/text"
        case .heading1: return "/h1"
        case .heading2: return "/h2"
        case .heading3: return "/h3"
        case .bulletList: return "/bullet"
        case .numberedList: return "/number"
        case .checkbox: return "/todo"
        case .quote: return "/quote"
        case .code: return "/code"
        case .divider: return "/divider"
        case .image: return "/image"
        case .citation: return "/cite"
        case .equation: return "/math"
        case .callout: return "/callout"
        case .toggle: return "/toggle"
        }
    }
}

/// 內容區塊模型
struct ContentBlock: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var type: BlockType
    var content: String
    var metadata: [String: String]? // 用於存儲額外資訊（如圖片URL、引用ID等）
    var isChecked: Bool? // 用於 checkbox 類型
    var children: [ContentBlock]? // 用於巢狀區塊（toggle）
    var order: Int // 排序用
    
    init(type: BlockType, content: String = "", order: Int = 0, metadata: [String: String]? = nil) {
        self.type = type
        self.content = content
        self.order = order
        self.metadata = metadata
        
        if type == .checkbox {
            self.isChecked = false
        }
    }
}

/// 區塊命令建議
struct BlockCommand: Identifiable {
    let id = UUID()
    let type: BlockType
    let keywords: [String]
    
    var displayText: String {
        type.slashCommand
    }
    
    var description: String {
        type.displayName
    }
    
    func matches(_ query: String) -> Bool {
        let lowercaseQuery = query.lowercased()
        return type.slashCommand.lowercased().contains(lowercaseQuery) ||
               type.displayName.lowercased().contains(lowercaseQuery) ||
               keywords.contains { $0.lowercased().contains(lowercaseQuery) }
    }
    
    static let allCommands: [BlockCommand] = [
        BlockCommand(type: .paragraph, keywords: ["text", "p", "段落"]),
        BlockCommand(type: .heading1, keywords: ["heading", "h1", "標題", "大標題"]),
        BlockCommand(type: .heading2, keywords: ["heading", "h2", "標題", "中標題"]),
        BlockCommand(type: .heading3, keywords: ["heading", "h3", "標題", "小標題"]),
        BlockCommand(type: .bulletList, keywords: ["list", "ul", "清單", "列表"]),
        BlockCommand(type: .numberedList, keywords: ["list", "ol", "編號", "數字"]),
        BlockCommand(type: .checkbox, keywords: ["todo", "task", "check", "待辦", "任務"]),
        BlockCommand(type: .quote, keywords: ["blockquote", "引用", "引文"]),
        BlockCommand(type: .code, keywords: ["codeblock", "程式", "代碼"]),
        BlockCommand(type: .divider, keywords: ["hr", "line", "分隔", "橫線"]),
        BlockCommand(type: .image, keywords: ["img", "photo", "圖片", "照片"]),
        BlockCommand(type: .citation, keywords: ["cite", "reference", "引用", "文獻"]),
        BlockCommand(type: .equation, keywords: ["latex", "formula", "公式", "數學"]),
        BlockCommand(type: .callout, keywords: ["info", "note", "標註", "提示"]),
        BlockCommand(type: .toggle, keywords: ["collapse", "折疊", "摺疊"])
    ]
}
