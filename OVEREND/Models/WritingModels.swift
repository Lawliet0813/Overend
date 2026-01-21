//
//  WritingModels.swift
//  OVEREND
//
//  Writing Assistant 資料模型
//

import Foundation
import SwiftUI

// MARK: - Writing Suggestion

struct WritingSuggestion: Identifiable, Equatable {
    let id = UUID()
    let category: WritingSuggestionCategory
    let issue: String
    let suggestion: String
    let explanation: String
    let position: Int

    static func == (lhs: WritingSuggestion, rhs: WritingSuggestion) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Text Highlight

struct WritingTextHighlight: Identifiable {
    let id = UUID()
    let range: Range<String.Index>?
    let color: Color
    let suggestion: WritingSuggestion
}

// MARK: - Suggestion Category

enum WritingSuggestionCategory: String, CaseIterable, Identifiable {
    case all = "全部"
    case grammar = "語法"
    case spelling = "拼寫"
    case punctuation = "標點"
    case style = "風格"
    case clarity = "清晰度"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .all: return .purple
        case .grammar: return .blue
        case .spelling: return .red
        case .punctuation: return .yellow
        case .style: return .green
        case .clarity: return .indigo
        }
    }

    var icon: String {
        switch self {
        case .all: return "star.fill"
        case .grammar: return "text.alignleft"
        case .spelling: return "textformat.abc"
        case .punctuation: return "textformat.abc"
        case .style: return "paintbrush"
        case .clarity: return "eye"
        }
    }
}
