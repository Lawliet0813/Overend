//
//  OCRService.swift
//  OVEREND
//
//  統一 OCR 服務 - 使用 Vision Framework
//
//  功能：
//  - 文字識別（繁體中文、簡體中文、英文）
//  - 區域識別
//  - 結合版面分析的智慧 OCR
//

import Foundation
import Vision
import CoreGraphics
import AppKit

// MARK: - OCR Configuration

/// OCR 配置
struct OCRConfiguration {
    /// 識別語言（按優先順序）
    var recognitionLanguages: [String] = ["zh-Hant", "zh-Hans", "en-US"]
    
    /// 識別精度
    var recognitionLevel: VNRequestTextRecognitionLevel = .accurate
    
    /// 是否使用語言校正
    var usesLanguageCorrection: Bool = true
    
    /// 最小文字高度（像素）
    var minimumTextHeight: Float = 0.0
    
    /// 自訂識別區域（nil 表示全頁）
    var regionOfInterest: CGRect? = nil
    
    /// 預設配置
    static let `default` = OCRConfiguration()
    
    /// 快速識別配置
    static let fast = OCRConfiguration(
        recognitionLevel: .fast,
        usesLanguageCorrection: false
    )
    
    /// 高精度配置（用於學術文獻）
    static let academic = OCRConfiguration(
        recognitionLanguages: ["zh-Hant", "zh-Hans", "en-US"],
        recognitionLevel: .accurate,
        usesLanguageCorrection: true,
        minimumTextHeight: 0.0
    )
}

// MARK: - OCR Result

/// 識別的文字區塊
struct RecognizedTextBlock: Identifiable {
    let id: UUID
    let text: String
    let confidence: Float
    let boundingBox: CGRect          // 正規化座標 (0-1)
    let absoluteBounds: CGRect?      // 實際像素座標
    
    init(
        text: String,
        confidence: Float,
        boundingBox: CGRect,
        absoluteBounds: CGRect? = nil
    ) {
        self.id = UUID()
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.absoluteBounds = absoluteBounds
    }
}

/// OCR 結果
struct OCRResult {
    /// 所有識別的文字區塊
    let textBlocks: [RecognizedTextBlock]
    
    /// 處理時間（秒）
    let processingTime: TimeInterval
    
    /// 圖片尺寸
    let imageSize: CGSize
    
    /// 平均信心度
    var averageConfidence: Float {
        guard !textBlocks.isEmpty else { return 0 }
        return textBlocks.reduce(0) { $0 + $1.confidence } / Float(textBlocks.count)
    }
    
    /// 合併所有文字（按位置排序）
    var fullText: String {
        // 按 Y 座標（從上到下）再按 X 座標（從左到右）排序
        let sorted = textBlocks.sorted { block1, block2 in
            // 容差範圍內視為同一行
            let tolerance: CGFloat = 0.02
            if abs(block1.boundingBox.midY - block2.boundingBox.midY) < tolerance {
                return block1.boundingBox.minX < block2.boundingBox.minX
            }
            // Y 座標高的（值大的）在上方
            return block1.boundingBox.midY > block2.boundingBox.midY
        }
        
        return sorted.map { $0.text }.joined(separator: "\n")
    }
    
    /// 空結果
    static let empty = OCRResult(textBlocks: [], processingTime: 0, imageSize: .zero)
}

// MARK: - OCR Error

/// OCR 錯誤
enum OCRError: Error, LocalizedError {
    case invalidImage
    case visionRequestFailed(Error)
    case noTextFound
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "無效的圖片格式"
        case .visionRequestFailed(let error):
            return "文字識別失敗：\(error.localizedDescription)"
        case .noTextFound:
            return "未識別到任何文字"
        case .cancelled:
            return "OCR 操作已取消"
        }
    }
}

// MARK: - OCR Service

/// 統一 OCR 服務
actor OCRService {
    
    // MARK: - Singleton
    
    static let shared = OCRService()
    
    // MARK: - Properties
    
    private var configuration: OCRConfiguration = .default
    
    // MARK: - Public Methods
    
    /// 設定 OCR 配置
    func configure(_ configuration: OCRConfiguration) {
        self.configuration = configuration
    }
    
    /// 從 CGImage 識別文字
    /// - Parameters:
    ///   - image: 輸入圖片
    ///   - configuration: OCR 配置（可選，使用預設配置）
    /// - Returns: OCR 結果
    func recognizeText(
        from image: CGImage,
        configuration: OCRConfiguration? = nil
    ) async throws -> OCRResult {
        let config = configuration ?? self.configuration
        let startTime = Date()
        let imageSize = CGSize(width: image.width, height: image.height)
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.visionRequestFailed(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: OCRResult(
                        textBlocks: [],
                        processingTime: Date().timeIntervalSince(startTime),
                        imageSize: imageSize
                    ))
                    return
                }
                
                let textBlocks = observations.compactMap { observation -> RecognizedTextBlock? in
                    guard let candidate = observation.topCandidates(1).first else {
                        return nil
                    }
                    
                    // 計算實際像素座標
                    let absoluteBounds = CGRect(
                        x: observation.boundingBox.origin.x * CGFloat(image.width),
                        y: (1 - observation.boundingBox.origin.y - observation.boundingBox.height) * CGFloat(image.height),
                        width: observation.boundingBox.width * CGFloat(image.width),
                        height: observation.boundingBox.height * CGFloat(image.height)
                    )
                    
                    return RecognizedTextBlock(
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: observation.boundingBox,
                        absoluteBounds: absoluteBounds
                    )
                }
                
                let result = OCRResult(
                    textBlocks: textBlocks,
                    processingTime: Date().timeIntervalSince(startTime),
                    imageSize: imageSize
                )
                
                continuation.resume(returning: result)
            }
            
            // 配置識別請求
            request.recognitionLevel = config.recognitionLevel
            request.recognitionLanguages = config.recognitionLanguages
            request.usesLanguageCorrection = config.usesLanguageCorrection
            request.minimumTextHeight = config.minimumTextHeight
            
            if let region = config.regionOfInterest {
                request.regionOfInterest = region
            }
            
            // 執行請求
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.visionRequestFailed(error))
            }
        }
    }
    
    /// 從指定區域識別文字
    /// - Parameters:
    ///   - image: 輸入圖片
    ///   - region: 識別區域（正規化座標 0-1）
    /// - Returns: 識別的文字
    func recognizeText(
        from image: CGImage,
        region: CGRect
    ) async throws -> String {
        var config = self.configuration
        config.regionOfInterest = region
        
        let result = try await recognizeText(from: image, configuration: config)
        return result.fullText
    }
    
    /// 從 NSImage 識別文字
    func recognizeText(from nsImage: NSImage) async throws -> OCRResult {
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.invalidImage
        }
        return try await recognizeText(from: cgImage)
    }
    
    /// 結合版面分析的智慧 OCR
    /// - Parameters:
    ///   - image: 輸入圖片
    ///   - layoutRegions: 已分析的版面區塊
    /// - Returns: 按閱讀順序排列的 OCR 結果
    func recognizeTextWithLayout(
        from image: CGImage,
        layoutRegions: [LayoutRegion]
    ) async throws -> OCRResult {
        let startTime = Date()
        let imageSize = CGSize(width: image.width, height: image.height)
        var allTextBlocks: [RecognizedTextBlock] = []
        
        // 對每個版面區塊分別進行 OCR
        for region in layoutRegions.filter({ $0.type == .text }) {
            // 轉換座標為正規化格式
            let normalizedRegion = CGRect(
                x: region.bounds.minX / CGFloat(image.width),
                y: 1 - (region.bounds.maxY / CGFloat(image.height)),
                width: region.bounds.width / CGFloat(image.width),
                height: region.bounds.height / CGFloat(image.height)
            )
            
            var regionConfig = self.configuration
            regionConfig.regionOfInterest = normalizedRegion
            
            do {
                let regionResult = try await recognizeText(from: image, configuration: regionConfig)
                
                // 將區塊文字合併為單一區塊，保留閱讀順序
                if !regionResult.textBlocks.isEmpty {
                    let combinedText = regionResult.textBlocks.map { $0.text }.joined(separator: " ")
                    let avgConfidence = regionResult.averageConfidence
                    
                    let textBlock = RecognizedTextBlock(
                        text: combinedText,
                        confidence: avgConfidence,
                        boundingBox: normalizedRegion,
                        absoluteBounds: region.bounds
                    )
                    allTextBlocks.append(textBlock)
                }
            } catch {
                // 單一區塊失敗不影響其他區塊
                logDebug("⚠️ OCRService: 區塊 OCR 失敗 - \(error.localizedDescription)", category: .general)
            }
        }
        
        return OCRResult(
            textBlocks: allTextBlocks,
            processingTime: Date().timeIntervalSince(startTime),
            imageSize: imageSize
        )
    }
    
    // MARK: - Batch Processing
    
    /// 批次識別多張圖片
    /// - Parameters:
    ///   - images: 圖片陣列
    ///   - progressHandler: 進度回報（0.0 - 1.0）
    /// - Returns: OCR 結果陣列
    func recognizeTextBatch(
        from images: [CGImage],
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> [OCRResult] {
        var results: [OCRResult] = []
        
        for (index, image) in images.enumerated() {
            let result = try await recognizeText(from: image)
            results.append(result)
            
            let progress = Double(index + 1) / Double(images.count)
            progressHandler?(progress)
        }
        
        return results
    }
}

// MARK: - Convenience Extensions

extension OCRService {
    
    /// 快速識別文字（使用快速配置）
    func quickRecognize(from image: CGImage) async throws -> String {
        let result = try await recognizeText(from: image, configuration: .fast)
        return result.fullText
    }
    
    /// 學術文獻識別（使用高精度配置）
    func academicRecognize(from image: CGImage) async throws -> OCRResult {
        return try await recognizeText(from: image, configuration: .academic)
    }
}
