//
//  VerticalTextHandler.swift
//  OVEREND
//
//  直排文字處理器
//
//  功能：
//  - 偵測文字方向（橫排/直排/混合）
//  - 旋轉圖片以利識別
//  - 座標轉換
//
//  應用場景：
//  - 中文古籍（傳統直排）
//  - 日本學術期刊
//  - 混合版面文獻
//

import Foundation
import CoreGraphics
import Vision
import AppKit

// MARK: - Text Orientation

/// 文字方向
enum TextOrientation: String, CaseIterable {
    case horizontal     // 橫排（左到右）
    case vertical       // 直排（上到下，右到左）
    case mixed          // 混合版面
    
    var displayName: String {
        switch self {
        case .horizontal: return "橫排"
        case .vertical: return "直排"
        case .mixed: return "混合"
        }
    }
}

// MARK: - Orientation Detection Result

/// 文字方向偵測結果
struct OrientationDetectionResult {
    let orientation: TextOrientation
    let confidence: Float
    let horizontalRatio: CGFloat    // 橫排區塊比例
    let verticalRatio: CGFloat      // 直排區塊比例
    let processingTime: TimeInterval
    
    /// 是否需要旋轉處理
    var requiresRotation: Bool {
        orientation == .vertical || (orientation == .mixed && verticalRatio > 0.3)
    }
}

// MARK: - Vertical Text Handler

/// 直排文字處理器
class VerticalTextHandler {
    
    // MARK: - Configuration
    
    /// 處理配置
    struct Configuration {
        /// 最小區塊寬高比（低於此值視為直排）
        var verticalAspectRatioThreshold: CGFloat = 0.3
        
        /// 最小區塊高寬比（高於此值視為直排）
        var minHeightToWidthRatio: CGFloat = 3.0
        
        /// 混合版面偵測閾值
        var mixedThreshold: CGFloat = 0.15
        
        static let `default` = Configuration()
    }
    
    // MARK: - Properties
    
    private let configuration: Configuration
    
    // MARK: - Initialization
    
    init(configuration: Configuration = .default) {
        self.configuration = configuration
    }
    
    // MARK: - Public Methods
    
    /// 偵測圖片中的文字方向
    /// - Parameter image: 輸入圖片
    /// - Returns: 方向偵測結果
    func detectOrientation(from image: CGImage) async -> OrientationDetectionResult {
        let startTime = Date()
        
        // 使用 Vision 取得文字區塊的邊界框
        let boundingBoxes = await getTextBoundingBoxes(from: image)
        
        guard !boundingBoxes.isEmpty else {
            return OrientationDetectionResult(
                orientation: .horizontal,
                confidence: 0.5,
                horizontalRatio: 1.0,
                verticalRatio: 0.0,
                processingTime: Date().timeIntervalSince(startTime)
            )
        }
        
        // 分析每個區塊的方向
        var horizontalCount = 0
        var verticalCount = 0
        
        for box in boundingBoxes {
            let aspectRatio = box.width / box.height
            
            if aspectRatio < configuration.verticalAspectRatioThreshold {
                // 高度遠大於寬度 → 直排
                verticalCount += 1
            } else {
                // 其他視為橫排
                horizontalCount += 1
            }
        }
        
        let total = horizontalCount + verticalCount
        let horizontalRatio = CGFloat(horizontalCount) / CGFloat(total)
        let verticalRatio = CGFloat(verticalCount) / CGFloat(total)
        
        // 判斷整體方向
        let orientation: TextOrientation
        let confidence: Float
        
        if verticalRatio > 0.7 {
            orientation = .vertical
            confidence = Float(verticalRatio)
        } else if horizontalRatio > 0.7 {
            orientation = .horizontal
            confidence = Float(horizontalRatio)
        } else {
            orientation = .mixed
            confidence = Float(max(horizontalRatio, verticalRatio))
        }
        
        return OrientationDetectionResult(
            orientation: orientation,
            confidence: confidence,
            horizontalRatio: horizontalRatio,
            verticalRatio: verticalRatio,
            processingTime: Date().timeIntervalSince(startTime)
        )
    }
    
    /// 旋轉圖片以利識別
    /// - Parameters:
    ///   - image: 輸入圖片
    ///   - orientation: 偵測到的文字方向
    /// - Returns: 旋轉後的圖片（直排會順時針旋轉 90 度）
    func rotateForRecognition(
        image: CGImage,
        orientation: TextOrientation
    ) -> CGImage? {
        guard orientation == .vertical else {
            return image  // 橫排不需旋轉
        }
        
        // 順時針旋轉 90 度
        return rotateImage(image, byDegrees: 90)
    }
    
    /// 轉換座標（從旋轉後座標轉回原始座標）
    /// - Parameters:
    ///   - regions: 識別區塊（旋轉後座標）
    ///   - originalSize: 原始圖片尺寸
    ///   - orientation: 文字方向
    /// - Returns: 轉換後的區塊
    func transformCoordinates(
        regions: [LayoutRegion],
        originalSize: CGSize,
        orientation: TextOrientation
    ) -> [LayoutRegion] {
        guard orientation == .vertical else {
            return regions  // 橫排不需轉換
        }
        
        // 將旋轉後的座標轉回原始座標系
        return regions.map { region in
            // 旋轉 90 度後的座標轉換
            // 原始: (x, y, w, h)
            // 旋轉後: (y, originalWidth - x - w, h, w)
            let transformedBounds = CGRect(
                x: originalSize.width - region.bounds.maxY,
                y: region.bounds.minX,
                width: region.bounds.height,
                height: region.bounds.width
            )
            
            return LayoutRegion(
                id: region.id,
                bounds: transformedBounds,
                type: region.type,
                readingOrder: region.readingOrder,
                text: region.text,
                confidence: region.confidence,
                children: region.children
            )
        }
    }
    
    /// 處理混合版面
    /// - Parameter image: 輸入圖片
    /// - Returns: 分離的橫排和直排區塊
    func separateMixedLayout(
        from image: CGImage
    ) async -> (horizontal: [CGRect], vertical: [CGRect]) {
        let boundingBoxes = await getTextBoundingBoxes(from: image)
        
        var horizontal: [CGRect] = []
        var vertical: [CGRect] = []
        
        for box in boundingBoxes {
            let aspectRatio = box.width / box.height
            
            if aspectRatio < configuration.verticalAspectRatioThreshold {
                vertical.append(box)
            } else {
                horizontal.append(box)
            }
        }
        
        return (horizontal, vertical)
    }
    
    // MARK: - Private Methods
    
    /// 使用 Vision 取得文字邊界框
    private func getTextBoundingBoxes(from image: CGImage) async -> [CGRect] {
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                // 轉換正規化座標為像素座標
                let boxes = observations.map { observation -> CGRect in
                    CGRect(
                        x: observation.boundingBox.origin.x * CGFloat(image.width),
                        y: (1 - observation.boundingBox.origin.y - observation.boundingBox.height) * CGFloat(image.height),
                        width: observation.boundingBox.width * CGFloat(image.width),
                        height: observation.boundingBox.height * CGFloat(image.height)
                    )
                }
                
                continuation.resume(returning: boxes)
            }
            
            request.recognitionLevel = .fast
            request.recognitionLanguages = ["zh-Hant", "zh-Hans", "en"]
            
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }
    
    /// 旋轉圖片
    private func rotateImage(_ image: CGImage, byDegrees degrees: CGFloat) -> CGImage? {
        let radians = degrees * .pi / 180
        
        let width = image.width
        let height = image.height
        
        // 旋轉 90 度後寬高互換
        let rotatedWidth = degrees.truncatingRemainder(dividingBy: 180) == 0 ? width : height
        let rotatedHeight = degrees.truncatingRemainder(dividingBy: 180) == 0 ? height : width
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: rotatedWidth,
            height: rotatedHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        // 設定白色背景
        context.setFillColor(CGColor.white)
        context.fill(CGRect(x: 0, y: 0, width: rotatedWidth, height: rotatedHeight))
        
        // 移動到中心並旋轉
        context.translateBy(x: CGFloat(rotatedWidth) / 2, y: CGFloat(rotatedHeight) / 2)
        context.rotate(by: radians)
        context.translateBy(x: -CGFloat(width) / 2, y: -CGFloat(height) / 2)
        
        // 繪製原圖
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return context.makeImage()
    }
}

// MARK: - Convenience Extension

extension VerticalTextHandler {
    
    /// 自動處理圖片（偵測方向 → 旋轉 → 識別）
    func autoProcess(image: CGImage) async throws -> (CGImage, TextOrientation) {
        let detection = await detectOrientation(from: image)
        
        if detection.orientation == .vertical || 
           (detection.orientation == .mixed && detection.verticalRatio > 0.5) {
            if let rotated = rotateForRecognition(image: image, orientation: .vertical) {
                return (rotated, detection.orientation)
            }
        }
        
        return (image, detection.orientation)
    }
}
