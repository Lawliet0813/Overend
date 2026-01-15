//
//  LayoutModels.swift
//  OVEREND
//
//  統一版面分析模型
//  提供 PDF/圖片版面識別的共用資料結構
//

import Foundation
import CoreGraphics

// MARK: - Layout Region Type

/// 版面區塊類型
enum LayoutRegionType: String, Codable, CaseIterable {
    case text           // 文字區塊
    case image          // 圖片區塊
    case table          // 表格區塊
    case formula        // 數學公式
    case header         // 頁首
    case footer         // 頁尾
    case caption        // 圖表標題
    case sidebar        // 側欄
    case footnote       // 註腳
    case pageNumber     // 頁碼
    case column         // 欄位（多欄版面）
    case unknown        // 未知類型
    
    var displayName: String {
        switch self {
        case .text: return "文字"
        case .image: return "圖片"
        case .table: return "表格"
        case .formula: return "公式"
        case .header: return "頁首"
        case .footer: return "頁尾"
        case .caption: return "圖說"
        case .sidebar: return "側欄"
        case .footnote: return "註腳"
        case .pageNumber: return "頁碼"
        case .column: return "欄位"
        case .unknown: return "未知"
        }
    }
    
    /// 從 LayoutBlockType 轉換
    init(from blockType: LayoutBlockType) {
        switch blockType {
        case .title, .paragraph:
            self = .text
        case .figure:
            self = .image
        case .table:
            self = .table
        case .caption:
            self = .caption
        case .header:
            self = .header
        case .footer:
            self = .footer
        case .column:
            self = .column
        case .unknown:
            self = .unknown
        }
    }
}

// MARK: - Layout Region

/// 版面區塊
struct LayoutRegion: Identifiable, Equatable {
    let id: UUID
    let bounds: CGRect              // 區塊邊界（像素座標）
    let type: LayoutRegionType      // 區塊類型
    var readingOrder: Int           // 閱讀順序
    var text: String?               // 識別的文字內容
    var confidence: Float           // 信心度 (0-1)
    var children: [LayoutRegion]?   // 子區塊（用於巢狀結構）
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        bounds: CGRect,
        type: LayoutRegionType,
        readingOrder: Int = 0,
        text: String? = nil,
        confidence: Float = 1.0,
        children: [LayoutRegion]? = nil
    ) {
        self.id = id
        self.bounds = bounds
        self.type = type
        self.readingOrder = readingOrder
        self.text = text
        self.confidence = confidence
        self.children = children
    }
    
    /// 從 LayoutBlock 建立
    init(from block: LayoutBlock) {
        self.id = block.id
        self.bounds = block.bounds
        self.type = LayoutRegionType(from: block.blockType)
        self.readingOrder = block.readingOrder
        self.text = block.text
        self.confidence = 1.0  // LayoutBlock 沒有 confidence
        self.children = nil
    }
    
    // MARK: - Computed Properties
    
    /// 區塊面積
    var area: CGFloat {
        bounds.width * bounds.height
    }
    
    /// 區塊中心點
    var center: CGPoint {
        CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    /// 寬高比
    var aspectRatio: CGFloat {
        guard bounds.height > 0 else { return 0 }
        return bounds.width / bounds.height
    }
    
    /// 是否為直排文字候選
    var isVerticalTextCandidate: Bool {
        aspectRatio < 0.3 && type == .text
    }
    
    // MARK: - Static Constructors
    
    /// 從 CGRect 建立文字區塊
    static func text(bounds: CGRect, readingOrder: Int = 0) -> LayoutRegion {
        LayoutRegion(bounds: bounds, type: .text, readingOrder: readingOrder)
    }
    
    /// 從 CGRect 建立圖片區塊
    static func image(bounds: CGRect, readingOrder: Int = 0) -> LayoutRegion {
        LayoutRegion(bounds: bounds, type: .image, readingOrder: readingOrder)
    }
    
    // MARK: - Equatable
    
    static func == (lhs: LayoutRegion, rhs: LayoutRegion) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - LayoutBlock Extension

extension LayoutBlock {
    /// 轉換為 LayoutRegion
    func toLayoutRegion() -> LayoutRegion {
        LayoutRegion(from: self)
    }
}

// MARK: - Array Extension

extension Array where Element == LayoutBlock {
    /// 轉換為 LayoutRegion 陣列
    func toLayoutRegions() -> [LayoutRegion] {
        self.map { $0.toLayoutRegion() }
    }
}

extension Array where Element == LayoutRegion {
    /// 依閱讀順序排序
    var sortedByReadingOrder: [LayoutRegion] {
        self.sorted { $0.readingOrder < $1.readingOrder }
    }
    
    /// 文字區塊
    var textRegions: [LayoutRegion] {
        self.filter { $0.type == .text }
    }
    
    /// 合併所有文字（依閱讀順序）
    var extractedText: String {
        sortedByReadingOrder
            .compactMap { $0.text }
            .joined(separator: "\n\n")
    }
}

