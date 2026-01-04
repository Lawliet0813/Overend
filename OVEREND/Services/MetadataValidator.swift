//
//  MetadataValidator.swift
//  OVEREND
//
//  元數據驗證器 - 驗證並修正 AI 提取的元數據
//

import Foundation

/// 元數據驗證結果
struct ValidationResult {
    let metadata: PDFMetadata
    let warnings: [String]
    let autoFixed: Bool
}

struct MetadataValidator {
    
    /// 驗證並修正提取的元數據
    static func validate(_ metadata: PDFMetadata) -> ValidationResult {
        var warnings: [String] = []
        var correctedMetadata = metadata
        var autoFixed = false
        
        // 1. 檢查標題是否為單位
        if containsInstitutionKeywords(metadata.title) {
            warnings.append("標題可能是作者單位，請檢查")
        }
        
        // 2. 轉換民國年份
        if let yearStr = metadata.year, let year = Int(yearStr), year < 200 && year > 50 {
            correctedMetadata.year = String(year + 1911)
            warnings.append("已自動轉換民國年份：\(year) → \(year + 1911)")
            autoFixed = true
        }
        
        // 3. 檢查必填欄位
        if metadata.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            warnings.append("標題為空")
        }
        
        // 4. 檢查年份合理性
        if let yearStr = correctedMetadata.year, let year = Int(yearStr) {
            let currentYear = Calendar.current.component(.year, from: Date())
            if year < 1900 || year > currentYear + 5 {
                warnings.append("年份可能不正確：\(year)")
            }
        }
        
        return ValidationResult(
            metadata: correctedMetadata,
            warnings: warnings,
            autoFixed: autoFixed
        )
    }
    
    /// 檢查文字是否包含單位關鍵字
    private static func containsInstitutionKeywords(_ text: String) -> Bool {
        let keywords = [
            // 中文
            "大學", "學系", "研究所", "學院", "研究中心",
            // 英文
            "Department", "University", "Institute", "College", "School"
        ]
        return keywords.contains { text.contains($0) }
    }
}
