//
//  EditorTypes.swift
//  OVEREND
//
//  編輯器類型定義 - 從 DocumentEditorView 拆分
//

import Foundation
import AppKit

// MARK: - 格式樣式

enum FormatStyle {
    case bold, italic, underline, strikethrough
}

// MARK: - 標題層級

enum HeadingLevel: Int, CaseIterable, Identifiable {
    case normal = 0
    case h1 = 1
    case h2 = 2
    case h3 = 3
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .normal: return "內文"
        case .h1: return "標題 1"
        case .h2: return "標題 2"
        case .h3: return "標題 3"
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .normal: return 12
        case .h1: return 24
        case .h2: return 18
        case .h3: return 14
        }
    }
}

// MARK: - 列表類型

enum ListType {
    case bullet
    case numbered
}

// MARK: - 插入類型

enum InsertType {
    case image
    case table
    case footnote
}

// MARK: - 中文優化類型

enum ChineseOptimizationType {
    case punctuation
    case spacing
    case toTraditional
    case toSimplified
    case terminology
}
