//
//  MainViewState.swift
//  OVEREND
//
//  主視圖狀態管理 - 三視圖切換
//

import SwiftUI
import Combine

/// 主視圖模式
enum MainViewMode: Equatable {
    case library                    // 文獻管理視圖
    case editorList                 // 文稿列表視圖
    case editorFull(Document)       // 專業編輯器視圖
    
    static func == (lhs: MainViewMode, rhs: MainViewMode) -> Bool {
        switch (lhs, rhs) {
        case (.library, .library):
            return true
        case (.editorList, .editorList):
            return true
        case (.editorFull(let doc1), .editorFull(let doc2)):
            return doc1.id == doc2.id
        default:
            return false
        }
    }
}

/// 側邊欄選中項目
enum SidebarItem: String, CaseIterable {
    case allEntries = "全部文獻"
    case writingCenter = "寫作中心"
    case recentlyViewed = "最近閱覽"
    case bookmarked = "待讀標註"
    
    var icon: String {
        switch self {
        case .allEntries: return "books.vertical"
        case .writingCenter: return "pencil.line"
        case .recentlyViewed: return "clock"
        case .bookmarked: return "bookmark.fill"
        }
    }
    
    var section: SidebarSection {
        switch self {
        case .allEntries, .writingCenter:
            return .resourceManagement
        case .recentlyViewed, .bookmarked:
            return .smartFilters
        }
    }
}

/// 側邊欄區塊
enum SidebarSection: String {
    case resourceManagement = "資源管理"
    case smartFilters = "智能過濾"
    case libraries = "文獻庫"
}

/// 主視圖狀態
class MainViewState: ObservableObject {
    @Published var mode: MainViewMode = .library
    @Published var activeSidebarItem: SidebarItem = .allEntries
    @Published var selectedLibrary: Library?
    @Published var selectedEntry: Entry?
    @Published var searchText: String = ""
    
    /// 切換到文獻管理
    func showLibrary() {
        mode = .library
        activeSidebarItem = .allEntries
    }
    
    /// 切換到寫作中心
    func showWritingCenter() {
        mode = .editorList
        activeSidebarItem = .writingCenter
    }
    
    /// 打開文稿編輯器
    func openDocument(_ document: Document) {
        mode = .editorFull(document)
    }
    
    /// 返回文稿列表
    func backToEditorList() {
        mode = .editorList
    }
}
