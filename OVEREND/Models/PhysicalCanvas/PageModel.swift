//
//  PageModel.swift
//  OVEREND
//
//  物理 A4 頁面模型 - 嚴格遵守物理尺寸規範
//

import Foundation
import SwiftUI

/// 物理長度單位系統
enum UnitLength {
    case millimeter(Double)
    case centimeter(Double)
    case inch(Double)
    case point(Double)

    /// 轉換為 Point (1 inch = 72 points)
    var toPoints: CGFloat {
        switch self {
        case .millimeter(let value):
            return CGFloat(value * 72.0 / 25.4)
        case .centimeter(let value):
            return CGFloat(value * 72.0 / 2.54)
        case .inch(let value):
            return CGFloat(value * 72.0)
        case .point(let value):
            return CGFloat(value)
        }
    }

    /// 轉換為毫米
    var toMillimeters: Double {
        switch self {
        case .millimeter(let value):
            return value
        case .centimeter(let value):
            return value * 10.0
        case .inch(let value):
            return value * 25.4
        case .point(let value):
            return value * 25.4 / 72.0
        }
    }
}

/// 頁面邊距設定
struct PageMargins: Codable, Equatable {
    var top: UnitLength
    var bottom: UnitLength
    var left: UnitLength
    var right: UnitLength

    /// 政大學術論文規範邊距
    static let nccu = PageMargins(
        top: .centimeter(2.5),
        bottom: .centimeter(2.5),
        left: .centimeter(3.0),
        right: .centimeter(2.0)
    )

    /// Word 預設 A4 邊距
    static let wordDefault = PageMargins(
        top: .centimeter(2.54),
        bottom: .centimeter(2.54),
        left: .centimeter(2.54),
        right: .centimeter(2.54)
    )

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case top, bottom, left, right
    }

    init(top: UnitLength, bottom: UnitLength, left: UnitLength, right: UnitLength) {
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        top = .millimeter(try container.decode(Double.self, forKey: .top))
        bottom = .millimeter(try container.decode(Double.self, forKey: .bottom))
        left = .millimeter(try container.decode(Double.self, forKey: .left))
        right = .millimeter(try container.decode(Double.self, forKey: .right))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(top.toMillimeters, forKey: .top)
        try container.encode(bottom.toMillimeters, forKey: .bottom)
        try container.encode(left.toMillimeters, forKey: .left)
        try container.encode(right.toMillimeters, forKey: .right)
    }
}

/// A4 頁面物理規格
struct A4PageSize {
    static let width = UnitLength.millimeter(210)
    static let height = UnitLength.millimeter(297)

    /// 以 Point 為單位的尺寸
    static var sizeInPoints: CGSize {
        CGSize(width: width.toPoints, height: height.toPoints)
    }
}

/// 頁碼格式
enum PageNumberStyle: String, Codable {
    case arabic          // 1, 2, 3, ...
    case romanLower      // i, ii, iii, ...
    case romanUpper      // I, II, III, ...
    case alphabetLower   // a, b, c, ...
    case alphabetUpper   // A, B, C, ...
    case none            // 無頁碼

    func format(_ number: Int) -> String {
        switch self {
        case .arabic:
            return "\(number)"
        case .romanLower:
            return romanNumeral(number).lowercased()
        case .romanUpper:
            return romanNumeral(number)
        case .alphabetLower:
            return alphabetLetter(number).lowercased()
        case .alphabetUpper:
            return alphabetLetter(number)
        case .none:
            return ""
        }
    }

    private func romanNumeral(_ number: Int) -> String {
        let romanValues = [
            (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
            (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
            (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")
        ]

        var result = ""
        var remaining = number

        for (value, numeral) in romanValues {
            while remaining >= value {
                result += numeral
                remaining -= value
            }
        }

        return result
    }

    private func alphabetLetter(_ number: Int) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let index = (number - 1) % 26
        return String(letters[letters.index(letters.startIndex, offsetBy: index)])
    }
}

/// 行政狀態 - 追蹤文件結構與格式繼承
enum AdministrativeState: String, Codable {
    case cover           // 封面
    case preface         // 前言區（謝辭、摘要等）
    case tableOfContents // 目錄
    case mainBody        // 正文
    case appendix        // 附錄
    case bibliography    // 參考文獻

    /// 該狀態下的預設頁碼格式
    var defaultPageNumberStyle: PageNumberStyle {
        switch self {
        case .cover, .tableOfContents:
            return .none
        case .preface:
            return .romanLower
        case .mainBody, .appendix, .bibliography:
            return .arabic
        }
    }
}

/// 頁面模型 - 代表一個物理 A4 頁面
class PageModel: Identifiable, ObservableObject, Codable {
    let id: UUID

    /// 頁碼（實際數字，從 1 開始）
    @Published var pageNumber: Int

    /// 頁碼顯示格式
    @Published var pageNumberStyle: PageNumberStyle

    /// 行政狀態
    @Published var administrativeState: AdministrativeState

    /// 頁面邊距
    @Published var margins: PageMargins

    /// 頁首文字（可選）
    @Published var headerText: String?

    /// 頁尾文字（可選）
    @Published var footerText: String?

    /// 該頁面的文字內容（NSAttributedString 的 RTF 資料）
    @Published var contentData: Data?

    /// 是否顯示標尺
    @Published var showRulers: Bool

    /// 是否顯示邊距導引線
    @Published var showMarginGuides: Bool

    // MARK: - 計算屬性

    /// 格式化後的頁碼字串
    var formattedPageNumber: String {
        pageNumberStyle.format(pageNumber)
    }

    /// 內容區域的實際尺寸（扣除邊距後）
    var contentSize: CGSize {
        let totalWidth = A4PageSize.width.toPoints
        let totalHeight = A4PageSize.height.toPoints

        let contentWidth = totalWidth - margins.left.toPoints - margins.right.toPoints
        let contentHeight = totalHeight - margins.top.toPoints - margins.bottom.toPoints

        return CGSize(width: contentWidth, height: contentHeight)
    }

    /// 內容區域的起始座標（左上角）
    var contentOrigin: CGPoint {
        CGPoint(
            x: margins.left.toPoints,
            y: margins.top.toPoints
        )
    }

    // MARK: - 初始化

    init(
        pageNumber: Int = 1,
        pageNumberStyle: PageNumberStyle = .arabic,
        administrativeState: AdministrativeState = .mainBody,
        margins: PageMargins = .nccu,
        headerText: String? = nil,
        footerText: String? = nil,
        showRulers: Bool = true,
        showMarginGuides: Bool = true
    ) {
        self.id = UUID()
        self.pageNumber = pageNumber
        self.pageNumberStyle = pageNumberStyle
        self.administrativeState = administrativeState
        self.margins = margins
        self.headerText = headerText
        self.footerText = footerText
        self.showRulers = showRulers
        self.showMarginGuides = showMarginGuides
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, pageNumber, pageNumberStyle, administrativeState
        case margins, headerText, footerText, contentData
        case showRulers, showMarginGuides
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        pageNumber = try container.decode(Int.self, forKey: .pageNumber)
        pageNumberStyle = try container.decode(PageNumberStyle.self, forKey: .pageNumberStyle)
        administrativeState = try container.decode(AdministrativeState.self, forKey: .administrativeState)
        margins = try container.decode(PageMargins.self, forKey: .margins)
        headerText = try container.decodeIfPresent(String.self, forKey: .headerText)
        footerText = try container.decodeIfPresent(String.self, forKey: .footerText)
        contentData = try container.decodeIfPresent(Data.self, forKey: .contentData)
        showRulers = try container.decode(Bool.self, forKey: .showRulers)
        showMarginGuides = try container.decode(Bool.self, forKey: .showMarginGuides)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(pageNumber, forKey: .pageNumber)
        try container.encode(pageNumberStyle, forKey: .pageNumberStyle)
        try container.encode(administrativeState, forKey: .administrativeState)
        try container.encode(margins, forKey: .margins)
        try container.encodeIfPresent(headerText, forKey: .headerText)
        try container.encodeIfPresent(footerText, forKey: .footerText)
        try container.encodeIfPresent(contentData, forKey: .contentData)
        try container.encode(showRulers, forKey: .showRulers)
        try container.encode(showMarginGuides, forKey: .showMarginGuides)
    }

    // MARK: - 格式繼承

    /// 從另一個頁面繼承樣式設定
    func inheritStyle(from page: PageModel) {
        self.margins = page.margins
        self.administrativeState = page.administrativeState
        self.pageNumberStyle = page.pageNumberStyle
        self.headerText = page.headerText
        self.footerText = page.footerText
        self.showRulers = page.showRulers
        self.showMarginGuides = page.showMarginGuides
    }

    /// 創建新頁面並繼承當前頁面的樣式
    func createNextPage() -> PageModel {
        let nextPage = PageModel(
            pageNumber: self.pageNumber + 1,
            pageNumberStyle: self.pageNumberStyle,
            administrativeState: self.administrativeState,
            margins: self.margins,
            headerText: self.headerText,
            footerText: self.footerText,
            showRulers: self.showRulers,
            showMarginGuides: self.showMarginGuides
        )
        return nextPage
    }
}

// MARK: - 預覽輔助

extension PageModel {
    static var preview: PageModel {
        PageModel(
            pageNumber: 1,
            administrativeState: .mainBody,
            margins: .nccu,
            headerText: "第一章 緒論"
        )
    }
}
