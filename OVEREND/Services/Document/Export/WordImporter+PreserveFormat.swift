//
//  WordImporter+PreserveFormat.swift
//  OVEREND
//
//  保留原始格式的 Word 匯入器
//

import Foundation
import AppKit

extension WordImporter {
    
    /// 匯入 Word 文件（保留原始格式）
    /// - Parameters:
    ///   - url: DOCX 檔案路徑
    ///   - preserveFormatting: 是否保留原始格式（預設為 true）
    /// - Returns: 完整保留格式的 NSAttributedString
    static func importPreservingFormat(from url: URL) throws -> NSAttributedString {
        // 1. 檢查檔案格式
        let ext = url.pathExtension.lowercased()
        guard ext == "docx" || ext == "doc" else {
            throw ImportError.unsupportedFormat
        }
        
        // 2. 讀取檔案
        guard let data = try? Data(contentsOf: url) else {
            throw ImportError.fileReadFailed
        }
        
        // 3. 轉換成 NSAttributedString（使用 macOS 內建功能）
        // 注意：macOS 只支援 .docx，不支援舊版 .doc
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.officeOpenXML
        ]
        
        do {
            let attributedString = try NSAttributedString(
                data: data,
                options: options,
                documentAttributes: nil
            )
            
            // ✅ 直接回傳，不做任何格式轉換
            return attributedString
            
        } catch {
            print("❌ Word 檔案讀取失敗：\(error)")
            throw ImportError.conversionFailed
        }
    }
    
    /// 匯入 Word 文件（選擇性保留格式）
    /// - Parameters:
    ///   - url: DOCX 檔案路徑
    ///   - preserveFormatting: true = 保留原始格式, false = 套用 OVEREND 範本
    ///   - template: 當 preserveFormatting = false 時使用的範本
    static func importWithOption(
        from url: URL,
        preserveFormatting: Bool,
        template: FormatTemplate? = nil
    ) throws -> NSAttributedString {
        
        if preserveFormatting {
            // 選項 A：保留原始格式
            return try importPreservingFormat(from: url)
            
        } else {
            // 選項 B：套用 OVEREND 範本（原本的行為）
            guard let template = template else {
                throw ImportError.conversionFailed
            }
            return try `import`(from: url, template: template)
        }
    }
}
