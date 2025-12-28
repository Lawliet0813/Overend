//
//  Color+Brand.swift
//  OVEREND
//
//  OVEREND 品牌色彩定義
//

import SwiftUI

extension Color {
    /// OVEREND 主色 - 鋼筆藍 #1A2B3C
    /// 代表專業、可靠、知識深度
    static let overendPrimary = Color(hex: "1A2B3C")

    /// OVEREND 強調色 - 啟發綠 #00F5A0
    /// 代表創新、啟發、生命力
    static let overendAccent = Color(hex: "00F5A0")

    /// OVEREND 背景色 - 紙張灰（自適應 Light/Dark Mode）
    static var overendPaperGray: Color {
        Color(nsColor: .textBackgroundColor)
    }
    
    /// 搜尋欄背景色（自適應 Light/Dark Mode）
    static var overendSearchBackground: Color {
        Color(nsColor: .controlBackgroundColor)
    }

    /// 輔助色 - 深灰
    static let overendDarkGray = Color(hex: "2C3E50")

    /// 輔助色 - 淺灰
    static let overendLightGray = Color(hex: "ECF0F1")

    /// 從 HEX 字串初始化顏色
    /// - Parameter hex: 6位十六進制顏色碼（不含 #）
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0

        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (6 位)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: 1.0
        )
    }
}

// MARK: - NSColor 擴展（用於 AppKit）
#if canImport(AppKit)
import AppKit

extension NSColor {
    /// OVEREND 主色 - 鋼筆藍
    static let overendPrimary = NSColor(hex: "1A2B3C")

    /// OVEREND 強調色 - 啟發綠
    static let overendAccent = NSColor(hex: "00F5A0")

    /// OVEREND 背景色 - 紙張灰
    static let overendPaperGray = NSColor(hex: "F4F4F9")

    /// 從 HEX 字串初始化 NSColor
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0

        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }

        self.init(
            srgbRed: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: 1.0
        )
    }
}
#endif
