//
//  FontSystem.swift
//  OVEREND
//
//  繁體中文字體系統配置
//

import SwiftUI

/// 繁體中文優化字體系統
struct FontSystem {
    
    // MARK: - 字體名稱
    
    /// 繁體中文主要字體：蘋方-繁體中文
    private static let chineseFontName = "PingFangTC-Regular"
    private static let chineseFontNameMedium = "PingFangTC-Medium"
    private static let chineseFontNameSemibold = "PingFangTC-Semibold"
    
    // MARK: - 字體大小
    
    enum Size {
        case title       // 24pt
        case headline    // 17pt
        case body        // 14pt
        case callout     // 13pt
        case subheadline // 12pt
        case caption     // 11pt
        
        var points: CGFloat {
            switch self {
            case .title: return 24
            case .headline: return 17
            case .body: return 14
            case .callout: return 13
            case .subheadline: return 12
            case .caption: return 11
            }
        }
    }
    
    // MARK: - 字重
    
    enum Weight {
        case regular
        case medium
        case semibold
        
        var fontName: String {
            switch self {
            case .regular: return chineseFontName
            case .medium: return chineseFontNameMedium
            case .semibold: return chineseFontNameSemibold
            }
        }
        
        var swiftUIWeight: Font.Weight {
            switch self {
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            }
        }
    }
    
    // MARK: - 字體獲取
    
    /// 獲取優化的中文字體
    static func font(size: Size, weight: Weight = .regular) -> Font {
        // 嘗試使用蘋方-繁體中文
        if let _ = NSFont(name: weight.fontName, size: size.points) {
            return Font.custom(weight.fontName, size: size.points)
        }
        
        // Fallback 到系統字體
        return Font.system(size: size.points, weight: weight.swiftUIWeight)
    }
    
    /// 獲取 NSFont（用於 RTF 等需要 NSFont 的場景）
    static func nsFont(size: Size, weight: Weight = .regular) -> NSFont {
        if let font = NSFont(name: weight.fontName, size: size.points) {
            return font
        }
        
        // Fallback
        return NSFont.systemFont(ofSize: size.points)
    }
    
    // MARK: - 行距配置
    
    /// 中文優化行距（1.6 倍）
    static let chineseLineSpacing: CGFloat = 0.6
    
    /// 標準行距
    static let standardLineSpacing: CGFloat = 0.0
}

// MARK: - SwiftUI View 擴展

extension View {
    /// 應用繁體中文優化字體
    func chineseFont(size: FontSystem.Size, weight: FontSystem.Weight = .regular) -> some View {
        self.font(FontSystem.font(size: size, weight: weight))
    }
    
    /// 應用中文行距
    func chineseLineSpacing() -> some View {
        self.lineSpacing(FontSystem.chineseLineSpacing)
    }
}

// MARK: - Text 樣式預設

extension FontSystem {
    /// 預定義的文字樣式
    struct TextStyle {
        /// 標題樣式
        static func title() -> Font {
            font(size: .title, weight: .semibold)
        }
        
        /// 標題樣式
        static func headline() -> Font {
            font(size: .headline, weight: .semibold)
        }
        
        /// 內文樣式
        static func body() -> Font {
            font(size: .body, weight: .regular)
        }
        
        /// 次要內文
        static func callout() -> Font {
            font(size: .callout, weight: .regular)
        }
        
        /// 小標題
        static func subheadline() -> Font {
            font(size: .subheadline, weight: .medium)
        }
        
        /// 註解文字
        static func caption() -> Font {
            font(size: .caption, weight: .regular)
        }
    }
}
