//
//  XYCutLayoutAnalyzer.swift
//  OVEREND
//
//  XY-Cut 版面分析演算法
//
//  用途：
//  - 分析雙欄或多欄 PDF 版面
//  - 按正確閱讀順序重組文字
//  - 提升 OCR 文字準確度
//
//  演算法原理：
//  透過遞迴式水平/垂直切割，將頁面分割為邏輯區塊，
//  並根據學術論文閱讀習慣（左上→左下→右上→右下）排序
//

import Foundation
import PDFKit
import Vision

// MARK: - 版面區塊

/// 版面區塊類型
enum LayoutBlockType: String, CaseIterable {
    case title = "title"           // 標題
    case paragraph = "paragraph"   // 段落
    case figure = "figure"         // 圖片
    case table = "table"           // 表格
    case caption = "caption"       // 圖表標題
    case header = "header"         // 頁首
    case footer = "footer"         // 頁尾
    case column = "column"         // 欄位容器
    case unknown = "unknown"       // 未知
    
    var displayName: String {
        switch self {
        case .title: return "標題"
        case .paragraph: return "段落"
        case .figure: return "圖片"
        case .table: return "表格"
        case .caption: return "圖表標題"
        case .header: return "頁首"
        case .footer: return "頁尾"
        case .column: return "欄位"
        case .unknown: return "未知"
        }
    }
}

/// 版面區塊結構
struct LayoutBlock: Identifiable {
    let id: UUID
    let bounds: CGRect              // 區塊邊界（頁面座標系）
    var readingOrder: Int           // 閱讀順序
    let blockType: LayoutBlockType  // 區塊類型
    let depth: Int                  // 切割深度
    var children: [LayoutBlock]     // 子區塊（用於巢狀結構）
    var text: String?               // 區塊內文字
    
    init(
        bounds: CGRect,
        readingOrder: Int = 0,
        blockType: LayoutBlockType = .unknown,
        depth: Int = 0,
        children: [LayoutBlock] = [],
        text: String? = nil
    ) {
        self.id = UUID()
        self.bounds = bounds
        self.readingOrder = readingOrder
        self.blockType = blockType
        self.depth = depth
        self.children = children
        self.text = text
    }
    
    /// 區塊面積
    var area: CGFloat {
        bounds.width * bounds.height
    }
    
    /// 區塊中心點
    var center: CGPoint {
        CGPoint(x: bounds.midX, y: bounds.midY)
    }
}

// MARK: - 版面分析結果

/// 版面分析結果
struct LayoutAnalysisResult {
    let blocks: [LayoutBlock]           // 分析出的區塊
    let pageSize: CGSize                 // 頁面尺寸
    let columnCount: Int                 // 偵測到的欄數
    let processingTime: TimeInterval     // 處理時間
    
    /// 是否為多欄版面
    var isMultiColumn: Bool {
        columnCount > 1
    }
    
    /// 依閱讀順序排列的區塊
    var blocksInReadingOrder: [LayoutBlock] {
        blocks.sorted { $0.readingOrder < $1.readingOrder }
    }
}

// MARK: - XY-Cut 版面分析器

/// XY-Cut 版面分析器
class XYCutLayoutAnalyzer {
    
    // MARK: - 設定
    
    /// 分析設定
    struct Configuration {
        var minBlockWidth: CGFloat = 50          // 最小區塊寬度
        var minBlockHeight: CGFloat = 20         // 最小區塊高度
        var columnGapThreshold: CGFloat = 30     // 欄間距閾值
        var paragraphGapThreshold: CGFloat = 15  // 段落間距閾值
        var maxRecursionDepth: Int = 10          // 最大遞迴深度
        var ignoreHeaderFooter: Bool = true      // 是否忽略頁首/頁尾
        var headerHeightRatio: CGFloat = 0.08    // 頁首高度比例
        var footerHeightRatio: CGFloat = 0.08    // 頁尾高度比例
    }
    
    static var configuration = Configuration()
    
    // MARK: - 公開方法
    
    /// 分析 PDF 頁面版面
    /// - Parameter page: PDF 頁面
    /// - Returns: 版面分析結果
    static func analyze(page: PDFPage) -> LayoutAnalysisResult {
        let startTime = Date()
        let pageRect = page.bounds(for: .mediaBox)
        
        // 取得頁面上所有文字區塊的邊界框
        let textBlocks = extractTextBoundingBoxes(from: page)
        
        guard !textBlocks.isEmpty else {
            return LayoutAnalysisResult(
                blocks: [],
                pageSize: pageRect.size,
                columnCount: 1,
                processingTime: Date().timeIntervalSince(startTime)
            )
        }
        
        // 計算有效內容區域（排除頁首/頁尾）
        let contentRect = calculateContentRect(pageRect: pageRect, textBlocks: textBlocks)
        
        // 過濾位於內容區域內的文字區塊
        let filteredBlocks = textBlocks.filter { contentRect.intersects($0) }
        
        // 執行遞迴 XY 切割
        var layoutBlocks = recursiveXYCut(
            bounds: contentRect,
            textBlocks: filteredBlocks,
            depth: 0
        )
        
        // 偵測欄數
        let columnCount = detectColumnCount(blocks: layoutBlocks, pageWidth: pageRect.width)
        
        // 指派閱讀順序
        layoutBlocks = assignReadingOrder(blocks: layoutBlocks, columnCount: columnCount)
        
        return LayoutAnalysisResult(
            blocks: layoutBlocks,
            pageSize: pageRect.size,
            columnCount: columnCount,
            processingTime: Date().timeIntervalSince(startTime)
        )
    }
    
    /// 依閱讀順序提取文字
    /// - Parameters:
    ///   - page: PDF 頁面
    ///   - blocks: 版面區塊
    /// - Returns: 按閱讀順序排列的文字
    static func extractTextInReadingOrder(from page: PDFPage, blocks: [LayoutBlock]) -> String {
        let sortedBlocks = blocks.sorted { $0.readingOrder < $1.readingOrder }
        var result = ""
        
        for block in sortedBlocks {
            if let text = extractTextFromRegion(page: page, rect: block.bounds) {
                result += text.trimmingCharacters(in: .whitespacesAndNewlines)
                result += "\n\n"
            }
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 快速版面分析（使用 Vision Framework）
    /// - Parameter page: PDF 頁面
    /// - Returns: 版面區塊列表
    @available(macOS 13.0, *)
    static func analyzeWithVision(page: PDFPage) async -> [LayoutBlock] {
        guard let pageImage = renderPageToImage(page: page) else {
            return []
        }
        
        var blocks: [LayoutBlock] = []
        let pageRect = page.bounds(for: .mediaBox)
        
        // 使用 Vision 進行文字識別並取得邊界框
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hant", "zh-Hans", "en"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: pageImage, options: [:])
        
        do {
            try handler.perform([request])
            
            if let observations = request.results {
                for (index, observation) in observations.enumerated() {
                    let boundingBox = observation.boundingBox
                    
                    // 將正規化座標轉換為頁面座標
                    let rect = CGRect(
                        x: boundingBox.origin.x * pageRect.width,
                        y: boundingBox.origin.y * pageRect.height,
                        width: boundingBox.width * pageRect.width,
                        height: boundingBox.height * pageRect.height
                    )
                    
                    let block = LayoutBlock(
                        bounds: rect,
                        readingOrder: index,
                        blockType: .paragraph,
                        text: observation.topCandidates(1).first?.string
                    )
                    blocks.append(block)
                }
            }
        } catch {
            AppLogger.debug("⚠️ XYCutLayoutAnalyzer: Vision 分析失敗 - \(error.localizedDescription)")
        }
        
        return blocks
    }
    
    // MARK: - 遞迴 XY 切割
    
    /// 遞迴執行 XY 切割
    private static func recursiveXYCut(
        bounds: CGRect,
        textBlocks: [CGRect],
        depth: Int
    ) -> [LayoutBlock] {
        // 終止條件
        guard depth < configuration.maxRecursionDepth else {
            return [LayoutBlock(bounds: bounds, depth: depth)]
        }
        
        guard bounds.width >= configuration.minBlockWidth &&
              bounds.height >= configuration.minBlockHeight else {
            return []
        }
        
        // 過濾位於當前邊界內的文字區塊
        let relevantBlocks = textBlocks.filter { bounds.intersects($0) }
        
        guard !relevantBlocks.isEmpty else {
            return []
        }
        
        // 如果只有少量文字區塊，視為單一區塊
        if relevantBlocks.count <= 2 || relevantBlocks.allSatisfy({ isSmallBlock($0, in: bounds) }) {
            let combinedBounds = relevantBlocks.reduce(relevantBlocks[0]) { $0.union($1) }
            return [LayoutBlock(bounds: combinedBounds, blockType: .paragraph, depth: depth)]
        }
        
        // 嘗試垂直切割（X 方向）
        if let xCut = findBestVerticalCut(bounds: bounds, textBlocks: relevantBlocks) {
            let leftBounds = CGRect(x: bounds.minX, y: bounds.minY, 
                                   width: xCut - bounds.minX, height: bounds.height)
            let rightBounds = CGRect(x: xCut, y: bounds.minY,
                                    width: bounds.maxX - xCut, height: bounds.height)
            
            let leftBlocks = recursiveXYCut(bounds: leftBounds, textBlocks: textBlocks, depth: depth + 1)
            let rightBlocks = recursiveXYCut(bounds: rightBounds, textBlocks: textBlocks, depth: depth + 1)
            
            return leftBlocks + rightBlocks
        }
        
        // 嘗試水平切割（Y 方向）
        if let yCut = findBestHorizontalCut(bounds: bounds, textBlocks: relevantBlocks) {
            // 注意：PDF 座標系 Y 軸向上，所以 top 是較大的 Y 值
            let topBounds = CGRect(x: bounds.minX, y: yCut,
                                  width: bounds.width, height: bounds.maxY - yCut)
            let bottomBounds = CGRect(x: bounds.minX, y: bounds.minY,
                                     width: bounds.width, height: yCut - bounds.minY)
            
            let topBlocks = recursiveXYCut(bounds: topBounds, textBlocks: textBlocks, depth: depth + 1)
            let bottomBlocks = recursiveXYCut(bounds: bottomBounds, textBlocks: textBlocks, depth: depth + 1)
            
            return topBlocks + bottomBlocks
        }
        
        // 無法進一步切割，返回當前區塊
        let combinedBounds = relevantBlocks.reduce(relevantBlocks[0]) { $0.union($1) }
        return [LayoutBlock(bounds: combinedBounds, blockType: .paragraph, depth: depth)]
    }
    
    // MARK: - 切割點尋找
    
    /// 尋找最佳垂直切割點
    private static func findBestVerticalCut(bounds: CGRect, textBlocks: [CGRect]) -> CGFloat? {
        // 建立 X 軸投影
        var projections: [(start: CGFloat, end: CGFloat)] = []
        
        for block in textBlocks {
            projections.append((block.minX, block.maxX))
        }
        
        // 尋找間隙
        projections.sort { $0.start < $1.start }
        
        var gaps: [(position: CGFloat, width: CGFloat)] = []
        var currentEnd = projections[0].end
        
        for i in 1..<projections.count {
            let gapStart = currentEnd
            let gapEnd = projections[i].start
            let gapWidth = gapEnd - gapStart
            
            if gapWidth >= configuration.columnGapThreshold {
                let gapCenter = (gapStart + gapEnd) / 2
                // 確保切割點在有效範圍內
                if gapCenter > bounds.minX + configuration.minBlockWidth &&
                   gapCenter < bounds.maxX - configuration.minBlockWidth {
                    gaps.append((gapCenter, gapWidth))
                }
            }
            
            currentEnd = max(currentEnd, projections[i].end)
        }
        
        // 返回最寬的間隙中心作為切割點
        return gaps.max { $0.width < $1.width }?.position
    }
    
    /// 尋找最佳水平切割點
    private static func findBestHorizontalCut(bounds: CGRect, textBlocks: [CGRect]) -> CGFloat? {
        // 建立 Y 軸投影
        var projections: [(start: CGFloat, end: CGFloat)] = []
        
        for block in textBlocks {
            projections.append((block.minY, block.maxY))
        }
        
        // 尋找間隙
        projections.sort { $0.start < $1.start }
        
        var gaps: [(position: CGFloat, width: CGFloat)] = []
        var currentEnd = projections[0].end
        
        for i in 1..<projections.count {
            let gapStart = currentEnd
            let gapEnd = projections[i].start
            let gapWidth = gapEnd - gapStart
            
            if gapWidth >= configuration.paragraphGapThreshold {
                let gapCenter = (gapStart + gapEnd) / 2
                // 確保切割點在有效範圍內
                if gapCenter > bounds.minY + configuration.minBlockHeight &&
                   gapCenter < bounds.maxY - configuration.minBlockHeight {
                    gaps.append((gapCenter, gapWidth))
                }
            }
            
            currentEnd = max(currentEnd, projections[i].end)
        }
        
        // 返回最寬的間隙中心作為切割點
        return gaps.max { $0.width < $1.width }?.position
    }
    
    // MARK: - 輔助方法
    
    /// 從 PDF 頁面提取文字邊界框
    private static func extractTextBoundingBoxes(from page: PDFPage) -> [CGRect] {
        var boxes: [CGRect] = []
        
        // 使用 PDFPage 的 selection 功能提取文字位置
        let pageRect = page.bounds(for: .mediaBox)
        
        // 取得頁面上所有文字
        if let pageContent = page.string {
            // 建立選取範圍來取得邊界框
            if let selection = page.selection(for: pageRect) {
                // PDFSelection 提供選取區域的邊界
                for selectionLine in selection.selectionsByLine() {
                    let bounds = selectionLine.bounds(for: page)
                    if bounds.width > 5 && bounds.height > 3 {
                        boxes.append(bounds)
                    }
                }
            }
        }
        
        // 如果無法取得詳細邊界，使用備用方法
        if boxes.isEmpty {
            // 使用 PDFPage 的 characterBounds
            if let annotations = page.annotations as? [PDFAnnotation] {
                for annotation in annotations {
                    boxes.append(annotation.bounds)
                }
            }
        }
        
        return boxes
    }
    
    /// 計算內容區域（排除頁首/頁尾）
    private static func calculateContentRect(pageRect: CGRect, textBlocks: [CGRect]) -> CGRect {
        guard configuration.ignoreHeaderFooter else {
            return pageRect
        }
        
        let headerHeight = pageRect.height * configuration.headerHeightRatio
        let footerHeight = pageRect.height * configuration.footerHeightRatio
        
        return CGRect(
            x: pageRect.minX,
            y: pageRect.minY + footerHeight,
            width: pageRect.width,
            height: pageRect.height - headerHeight - footerHeight
        )
    }
    
    /// 偵測欄數
    private static func detectColumnCount(blocks: [LayoutBlock], pageWidth: CGFloat) -> Int {
        guard blocks.count > 1 else { return 1 }
        
        // 計算區塊的水平位置分佈
        let centerXs = blocks.map { $0.center.x }
        
        // 簡單的欄數偵測：檢查是否有明顯的左右分群
        let midPoint = pageWidth / 2
        let leftCount = centerXs.filter { $0 < midPoint - 50 }.count
        let rightCount = centerXs.filter { $0 > midPoint + 50 }.count
        
        if leftCount > 2 && rightCount > 2 {
            return 2
        }
        
        return 1
    }
    
    /// 指派閱讀順序
    private static func assignReadingOrder(blocks: [LayoutBlock], columnCount: Int) -> [LayoutBlock] {
        var mutableBlocks = blocks
        
        if columnCount == 2 {
            // 雙欄版面：左欄優先，然後右欄
            let midX = mutableBlocks.map { $0.bounds.midX }.reduce(0, +) / CGFloat(mutableBlocks.count)
            
            let leftBlocks = mutableBlocks.filter { $0.bounds.midX < midX }
                .sorted { $0.bounds.maxY > $1.bounds.maxY }  // 從上到下（Y 軸向上）
            let rightBlocks = mutableBlocks.filter { $0.bounds.midX >= midX }
                .sorted { $0.bounds.maxY > $1.bounds.maxY }
            
            var order = 0
            for i in 0..<leftBlocks.count {
                if let index = mutableBlocks.firstIndex(where: { $0.id == leftBlocks[i].id }) {
                    mutableBlocks[index].readingOrder = order
                    order += 1
                }
            }
            for i in 0..<rightBlocks.count {
                if let index = mutableBlocks.firstIndex(where: { $0.id == rightBlocks[i].id }) {
                    mutableBlocks[index].readingOrder = order
                    order += 1
                }
            }
        } else {
            // 單欄版面：從上到下
            let sorted = mutableBlocks.sorted { $0.bounds.maxY > $1.bounds.maxY }
            for (index, block) in sorted.enumerated() {
                if let blockIndex = mutableBlocks.firstIndex(where: { $0.id == block.id }) {
                    mutableBlocks[blockIndex].readingOrder = index
                }
            }
        }
        
        return mutableBlocks
    }
    
    /// 從區域提取文字
    private static func extractTextFromRegion(page: PDFPage, rect: CGRect) -> String? {
        let selection = page.selection(for: rect)
        return selection?.string
    }
    
    /// 判斷是否為小區塊
    private static func isSmallBlock(_ block: CGRect, in bounds: CGRect) -> Bool {
        let areaRatio = (block.width * block.height) / (bounds.width * bounds.height)
        return areaRatio < 0.1
    }
    
    /// 將 PDF 頁面渲染為圖片
    private static func renderPageToImage(page: PDFPage) -> CGImage? {
        let pageRect = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2.0  // 提高解析度
        
        let width = Int(pageRect.width * scale)
        let height = Int(pageRect.height * scale)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.setFillColor(CGColor.white)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        context.scaleBy(x: scale, y: scale)
        page.draw(with: .mediaBox, to: context)
        
        return context.makeImage()
    }
}
