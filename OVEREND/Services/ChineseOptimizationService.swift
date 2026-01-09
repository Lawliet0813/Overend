//
//  ChineseOptimizationService.swift
//  OVEREND
//
//  中文優化服務 - 處理標點、間距、繁簡轉換及術語檢查
//

import Foundation

class ChineseOptimizationService {
    static let shared = ChineseOptimizationService()
    
    private init() {}
    
    // MARK: - 標點符號轉換
    
    /// 將半形標點轉換為全形標點（針對中文語境）
    func convertToFullWidthPunctuation(_ text: String) -> String {
        var result = text
        let replacements: [(String, String)] = [
            (",", "，"),
            (".", "。"),
            ("?", "？"),
            ("!", "！"),
            (":", "："),
            (";", "；"),
            ("(", "（"),
            (")", "）"),
            ("[", "【"),
            ("]", "】")
        ]
        
        for (half, full) in replacements {
            // 簡單替換，實際應用可能需要更複雜的上下文判斷（例如不替換英文單字中的點）
            // 這裡假設使用者選取的是中文段落
            result = result.replacingOccurrences(of: half, with: full)
        }
        return result
    }
    
    // MARK: - 中英文間距調整
    
    /// 在中文與英文/數字之間加入空格
    func adjustSpacing(_ text: String) -> String {
        var result = text
        
        // 中文與英文/數字之間加空格
        // 漢字範圍：\u4e00-\u9fa5
        // 英文/數字：[a-zA-Z0-9]
        
        // 中文接英文/數字
        result = result.replacingOccurrences(
            of: "([\\u4e00-\\u9fa5])([a-zA-Z0-9])",
            with: "$1 $2",
            options: .regularExpression
        )
        
        // 英文/數字接中文
        result = result.replacingOccurrences(
            of: "([a-zA-Z0-9])([\\u4e00-\\u9fa5])",
            with: "$1 $2",
            options: .regularExpression
        )
        
        return result
    }
    
    // MARK: - 繁簡轉換
    
    enum Script {
        case traditional
        case simplified
    }
    
    /// 繁簡轉換（使用簡單對照表或系統 API，此處為模擬實作）
    func convertScript(_ text: String, to script: Script) -> String {
        // 在 macOS 上可以使用 CFStringTransform
        let transform = script == .simplified ? kCFStringTransformMandarinLatin : kCFStringTransformLatinHangul // 這裡只是示意外殼
        
        // 實際使用 CoreFoundation 的字串轉換
        let mutableString = NSMutableString(string: text)
        
        if script == .simplified {
            // 繁轉簡 (Traditional -> Simplified)
            // macOS 內建轉換標識符：kCFStringTransformTraditionalChineseToSimplifiedChinese (需確認 availability)
            // 由於 Swift String 橋接，這裡使用簡單的 CFStringTransform
            CFStringTransform(mutableString, nil, "Traditional-Simplified" as CFString, false)
        } else {
            // 簡轉繁 (Simplified -> Traditional)
            CFStringTransform(mutableString, nil, "Simplified-Traditional" as CFString, false)
        }
        
        return mutableString as String
    }
    
    // MARK: - 台灣學術用語檢查
    
    struct TerminologySuggestion {
        let original: String
        let suggestion: String
        let reason: String
    }
    
    /// 檢查並建議台灣學術用語
    func checkTerminology(_ text: String) -> [TerminologySuggestion] {
        var suggestions: [TerminologySuggestion] = []
        
        // 常見兩岸用語對照表 (大陸 -> 台灣)
        let termMap: [(String, String)] = [
            ("智能", "智慧"),
            ("信息", "資訊"),
            ("網絡", "網路"),
            ("軟件", "軟體"),
            ("硬件", "硬體"),
            ("硬盤", "硬碟"),
            ("鼠標", "滑鼠"),
            ("屏幕", "螢幕"),
            ("程序", "程式"),
            ("視頻", "影片"),
            ("音頻", "音訊"),
            ("服務器", "伺服器"),
            ("雲端", "雲端"), // 相同
            ("大數據", "大數據"), // 相同
            ("人工智能", "人工智慧"),
            ("算法", "演算法"),
            ("默認", "預設"),
            ("支持", "支援"),
            ("優化", "最佳化"), // 或優化，視上下文
            ("項目", "專案"), // Project -> 專案
            ("交互", "互動"),
            ("用戶", "使用者"),
            ("界面", "介面"),
            ("高清", "高畫質"),
            ("打印", "列印"),
            ("複印", "影印"),
            ("查找", "搜尋"), // 或尋找
            ("鏈接", "連結"),
            ("卸載", "移除"), // Uninstall
            ("上傳", "上傳"), // 相同
            ("下載", "下載")  // 相同
        ]
        
        for (cn, tw) in termMap {
            if text.contains(cn) {
                suggestions.append(TerminologySuggestion(
                    original: cn,
                    suggestion: tw,
                    reason: "建議使用台灣學術慣用語「\(tw)」"
                ))
            }
        }
        
        return suggestions
    }
}
