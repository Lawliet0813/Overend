//
//  EncodingDetector.swift
//  OVEREND
//
//  編碼自動偵測工具
//
//  支援編碼：
//  - UTF-8 (含 BOM)
//  - Big5 (台灣舊版資料庫常用)
//  - GB2312 / GB18030 (大陸編碼)
//

import Foundation

/// 編碼偵測結果
struct EncodingDetectionResult {
    let encoding: String.Encoding
    let confidence: Double           // 0.0 - 1.0
    let encodingName: String
    
    var isHighConfidence: Bool {
        confidence >= 0.8
    }
}

/// 編碼偵測工具
class EncodingDetector {
    
    // MARK: - 公開方法
    
    /// 自動偵測資料編碼
    /// - Parameter data: 原始資料
    /// - Returns: 偵測結果
    static func detect(data: Data) -> EncodingDetectionResult {
        // 1. 先檢查 BOM (Byte Order Mark)
        if let bomResult = detectBOM(data: data) {
            return bomResult
        }
        
        // 2. 嘗試 UTF-8 解碼
        if isValidUTF8(data: data) {
            return EncodingDetectionResult(
                encoding: .utf8,
                confidence: 0.95,
                encodingName: "UTF-8"
            )
        }
        
        // 3. Big5 偵測（針對繁體中文）
        let big5Score = calculateBig5Score(data: data)
        
        // 4. GB2312/GB18030 偵測（針對簡體中文）
        let gbScore = calculateGBScore(data: data)
        
        // 5. 根據分數選擇最可能的編碼
        if big5Score > gbScore && big5Score > 0.5 {
            return EncodingDetectionResult(
                encoding: .big5,
                confidence: big5Score,
                encodingName: "Big5"
            )
        } else if gbScore > 0.5 {
            // GB18030 向後相容 GB2312
            return EncodingDetectionResult(
                encoding: String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))),
                confidence: gbScore,
                encodingName: "GB18030"
            )
        }
        
        // 6. 降級到 macOS Roman (Latin-1 相容)
        return EncodingDetectionResult(
            encoding: .macOSRoman,
            confidence: 0.3,
            encodingName: "macOS Roman (fallback)"
        )
    }
    
    /// 使用自動偵測編碼讀取檔案
    /// - Parameter url: 檔案路徑
    /// - Returns: 解碼後的字串
    /// - Throws: 如果無法讀取或解碼
    static func readWithAutoEncoding(url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return try readWithAutoEncoding(data: data)
    }
    
    /// 使用自動偵測編碼解碼資料
    /// - Parameter data: 原始資料
    /// - Returns: 解碼後的字串
    /// - Throws: 如果無法解碼
    static func readWithAutoEncoding(data: Data) throws -> String {
        let detection = detect(data: data)
        
        // 嘗試用偵測到的編碼解碼
        if let string = String(data: data, encoding: detection.encoding) {
            logDebug("📝 EncodingDetector: 使用 \(detection.encodingName) 解碼成功 (信心度: \(String(format: "%.0f%%", detection.confidence * 100)))", category: .general)
            return string
        }
        
        // 降級嘗試：依序嘗試常見編碼
        let fallbackEncodings: [(String.Encoding, String)] = [
            (.utf8, "UTF-8"),
            (.big5, "Big5"),
            (String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))), "GB18030"),
            (.utf16, "UTF-16"),
            (.macOSRoman, "macOS Roman")
        ]
        
        for (encoding, name) in fallbackEncodings {
            if let string = String(data: data, encoding: encoding) {
                logDebug("📝 EncodingDetector: 降級使用 \(name) 解碼成功", category: .general)
                return string
            }
        }
        
        throw EncodingDetectorError.unableToDecodeAnyEncoding
    }
    
    // MARK: - BOM 偵測
    
    /// 偵測 Byte Order Mark
    private static func detectBOM(data: Data) -> EncodingDetectionResult? {
        guard data.count >= 2 else { return nil }
        
        let bytes = [UInt8](data.prefix(4))
        
        // UTF-8 BOM: EF BB BF
        if bytes.count >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF {
            return EncodingDetectionResult(
                encoding: .utf8,
                confidence: 1.0,
                encodingName: "UTF-8 (BOM)"
            )
        }
        
        // UTF-16 BE BOM: FE FF
        if bytes[0] == 0xFE && bytes[1] == 0xFF {
            return EncodingDetectionResult(
                encoding: .utf16BigEndian,
                confidence: 1.0,
                encodingName: "UTF-16 BE (BOM)"
            )
        }
        
        // UTF-16 LE BOM: FF FE
        if bytes[0] == 0xFF && bytes[1] == 0xFE {
            return EncodingDetectionResult(
                encoding: .utf16LittleEndian,
                confidence: 1.0,
                encodingName: "UTF-16 LE (BOM)"
            )
        }
        
        // UTF-32 BE BOM: 00 00 FE FF
        if bytes.count >= 4 && bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0xFE && bytes[3] == 0xFF {
            return EncodingDetectionResult(
                encoding: .utf32BigEndian,
                confidence: 1.0,
                encodingName: "UTF-32 BE (BOM)"
            )
        }
        
        // UTF-32 LE BOM: FF FE 00 00
        if bytes.count >= 4 && bytes[0] == 0xFF && bytes[1] == 0xFE && bytes[2] == 0x00 && bytes[3] == 0x00 {
            return EncodingDetectionResult(
                encoding: .utf32LittleEndian,
                confidence: 1.0,
                encodingName: "UTF-32 LE (BOM)"
            )
        }
        
        return nil
    }
    
    // MARK: - UTF-8 驗證
    
    /// 檢查是否為有效的 UTF-8
    private static func isValidUTF8(data: Data) -> Bool {
        // 快速檢查：嘗試解碼
        guard String(data: data, encoding: .utf8) != nil else {
            return false
        }
        
        // 進一步檢查：是否有高位 ASCII 字元（表示可能是中文）
        let bytes = [UInt8](data)
        var hasHighByte = false
        var i = 0
        
        while i < bytes.count {
            let byte = bytes[i]
            
            if byte >= 0x80 {
                hasHighByte = true
                
                // 檢查 UTF-8 多字節序列
                if byte >= 0xC0 && byte < 0xE0 {
                    // 2 字節序列
                    if i + 1 >= bytes.count || (bytes[i + 1] & 0xC0) != 0x80 {
                        return false
                    }
                    i += 2
                } else if byte >= 0xE0 && byte < 0xF0 {
                    // 3 字節序列 (CJK 字元常用)
                    if i + 2 >= bytes.count ||
                       (bytes[i + 1] & 0xC0) != 0x80 ||
                       (bytes[i + 2] & 0xC0) != 0x80 {
                        return false
                    }
                    i += 3
                } else if byte >= 0xF0 && byte < 0xF8 {
                    // 4 字節序列
                    if i + 3 >= bytes.count ||
                       (bytes[i + 1] & 0xC0) != 0x80 ||
                       (bytes[i + 2] & 0xC0) != 0x80 ||
                       (bytes[i + 3] & 0xC0) != 0x80 {
                        return false
                    }
                    i += 4
                } else {
                    return false
                }
            } else {
                i += 1
            }
        }
        
        return true
    }
    
    // MARK: - Big5 偵測
    
    /// 計算 Big5 可能性分數
    private static func calculateBig5Score(data: Data) -> Double {
        let bytes = [UInt8](data)
        var validPairs = 0
        var totalPairs = 0
        var i = 0
        
        while i < bytes.count - 1 {
            let first = bytes[i]
            let second = bytes[i + 1]
            
            // Big5 高位字節範圍: 0x81-0xFE
            // Big5 低位字節範圍: 0x40-0x7E, 0xA1-0xFE
            if first >= 0x81 && first <= 0xFE {
                totalPairs += 1
                
                if (second >= 0x40 && second <= 0x7E) || (second >= 0xA1 && second <= 0xFE) {
                    validPairs += 1
                    i += 2
                } else {
                    i += 1
                }
            } else {
                i += 1
            }
        }
        
        guard totalPairs > 0 else { return 0.0 }
        return Double(validPairs) / Double(totalPairs)
    }
    
    // MARK: - GB 偵測
    
    /// 計算 GB2312/GB18030 可能性分數
    private static func calculateGBScore(data: Data) -> Double {
        let bytes = [UInt8](data)
        var validPairs = 0
        var totalPairs = 0
        var i = 0
        
        while i < bytes.count - 1 {
            let first = bytes[i]
            let second = bytes[i + 1]
            
            // GB2312 高位字節範圍: 0xA1-0xF7
            // GB2312 低位字節範圍: 0xA1-0xFE
            if first >= 0xA1 && first <= 0xF7 {
                totalPairs += 1
                
                if second >= 0xA1 && second <= 0xFE {
                    validPairs += 1
                    i += 2
                } else {
                    i += 1
                }
            }
            // GB18030 擴展範圍
            else if first >= 0x81 && first <= 0xFE {
                totalPairs += 1
                
                if (second >= 0x40 && second <= 0x7E) || (second >= 0x80 && second <= 0xFE) {
                    validPairs += 1
                    i += 2
                } else {
                    i += 1
                }
            } else {
                i += 1
            }
        }
        
        guard totalPairs > 0 else { return 0.0 }
        return Double(validPairs) / Double(totalPairs)
    }
}

// MARK: - 錯誤類型

enum EncodingDetectorError: LocalizedError {
    case unableToDecodeAnyEncoding
    case fileReadError(String)
    
    var errorDescription: String? {
        switch self {
        case .unableToDecodeAnyEncoding:
            return "無法使用任何已知編碼解碼此檔案"
        case .fileReadError(let message):
            return "檔案讀取失敗：\(message)"
        }
    }
}

// MARK: - Big5 編碼擴展

extension String.Encoding {
    /// Big5 編碼 (台灣繁體中文)
    static let big5 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.big5.rawValue)))
}
