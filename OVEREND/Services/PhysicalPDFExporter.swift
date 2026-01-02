//
//  PhysicalPDFExporter.swift
//  OVEREND
//
//  物理 PDF 導出引擎 - 確保輸出與畫布完全一致
//

import Foundation
import AppKit
import PDFKit
import UniformTypeIdentifiers

/// 物理 PDF 導出器 - 像素級精確導出
class PhysicalPDFExporter {

    // MARK: - 主要導出方法

    /// 導出多頁面文檔為 PDF
    static func export(
        pages: [PageModel],
        metadata: ThesisMetadata?,
        to url: URL
    ) throws {
        // 創建 PDF 上下文
        let pdfDocument = PDFDocument()

        // 逐頁渲染
        for (index, page) in pages.enumerated() {
            let pdfPage = try renderPage(page, metadata: metadata)
            pdfDocument.insert(pdfPage, at: index)
        }

        // 寫入元數據
        if let metadata = metadata {
            embedMetadata(metadata, into: pdfDocument)
        }

        // 儲存檔案
        guard pdfDocument.write(to: url) else {
            throw PDFExportError.writeFailed
        }
    }

    /// 導出單頁為 PDF
    static func exportSinglePage(
        _ page: PageModel,
        metadata: ThesisMetadata?,
        to url: URL
    ) throws {
        try export(pages: [page], metadata: metadata, to: url)
    }

    // MARK: - 頁面渲染

    /// 渲染單一頁面為 PDFPage
    private static func renderPage(
        _ page: PageModel,
        metadata: ThesisMetadata?
    ) throws -> PDFPage {
        // 使用精確的 A4 尺寸（Points）
        let pageRect = CGRect(origin: .zero, size: A4PageSize.sizeInPoints)

        // 創建 PDF 上下文
        var mediaBox = pageRect
        guard let context = CGContext(url: URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + ".pdf") as CFURL, mediaBox: &mediaBox, nil) else {
            throw PDFExportError.contextCreationFailed
        }

        // 開始頁面
        context.beginPDFPage(nil)

        // 設定座標系（PDF 座標系原點在左下角，需要翻轉）
        context.translateBy(x: 0, y: pageRect.height)
        context.scaleBy(x: 1.0, y: -1.0)

        // 繪製頁面背景
        context.setFillColor(NSColor.white.cgColor)
        context.fill(pageRect)

        // 繪製邊距導引線（僅用於除錯，最終版本應移除）
        #if DEBUG
        if page.showMarginGuides {
            drawMarginGuides(page: page, in: context, pageRect: pageRect)
        }
        #endif

        // 繪製頁首
        if let headerText = page.headerText {
            drawHeader(
                text: headerText,
                page: page,
                in: context,
                pageRect: pageRect
            )
        }

        // 繪製主要內容
        drawContent(
            page: page,
            in: context,
            pageRect: pageRect,
            metadata: metadata
        )

        // 繪製頁尾與頁碼
        drawFooter(
            page: page,
            in: context,
            pageRect: pageRect
        )

        // 結束頁面
        context.endPDFPage()
        context.closePDF()

        // 創建 PDFPage
        guard let pdfData = try? Data(contentsOf: context.url as URL),
              let pdfDoc = PDFDocument(data: pdfData),
              let pdfPage = pdfDoc.page(at: 0) else {
            throw PDFExportError.pageCreationFailed
        }

        return pdfPage
    }

    // MARK: - 繪製組件

    /// 繪製邊距導引線（除錯用）
    private static func drawMarginGuides(page: PageModel, in context: CGContext, pageRect: CGRect) {
        context.saveGState()

        context.setStrokeColor(NSColor.systemBlue.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(0.5)
        context.setLineDash(phase: 0, lengths: [3, 2])

        let margins = page.margins

        // 上邊距
        context.move(to: CGPoint(x: 0, y: pageRect.height - margins.top.toPoints))
        context.addLine(to: CGPoint(x: pageRect.width, y: pageRect.height - margins.top.toPoints))

        // 下邊距
        context.move(to: CGPoint(x: 0, y: margins.bottom.toPoints))
        context.addLine(to: CGPoint(x: pageRect.width, y: margins.bottom.toPoints))

        // 左邊距
        context.move(to: CGPoint(x: margins.left.toPoints, y: 0))
        context.addLine(to: CGPoint(x: margins.left.toPoints, y: pageRect.height))

        // 右邊距
        context.move(to: CGPoint(x: pageRect.width - margins.right.toPoints, y: 0))
        context.addLine(to: CGPoint(x: pageRect.width - margins.right.toPoints, y: pageRect.height))

        context.strokePath()
        context.restoreGState()
    }

    /// 繪製頁首
    private static func drawHeader(
        text: String,
        page: PageModel,
        in context: CGContext,
        pageRect: CGRect
    ) {
        let headerFont = NSFont.systemFont(ofSize: 10)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: NSColor.darkGray
        ]

        let headerString = NSAttributedString(string: text, attributes: attributes)
        let headerSize = headerString.size()

        // 計算頁首位置（在上邊距內）
        let headerRect = CGRect(
            x: page.margins.left.toPoints,
            y: pageRect.height - page.margins.top.toPoints + 10,
            width: page.contentSize.width,
            height: headerSize.height
        )

        // 翻轉座標系以正確繪製文字
        context.saveGState()
        context.translateBy(x: 0, y: pageRect.height)
        context.scaleBy(x: 1.0, y: -1.0)

        headerString.draw(in: headerRect)

        context.restoreGState()
    }

    /// 繪製主要內容
    private static func drawContent(
        page: PageModel,
        in context: CGContext,
        pageRect: CGRect,
        metadata: ThesisMetadata?
    ) {
        guard let contentData = page.contentData,
              var attributedString = try? NSAttributedString(
                data: contentData,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
              ) else {
            return
        }

        // 處理動態標籤
        if let metadata = metadata {
            attributedString = DynamicTagProcessor.process(
                attributedString: attributedString,
                metadata: metadata
            )
        }

        // 創建 Framesetter 用於文字排版
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString as CFAttributedString)

        // 定義內容區域
        let contentRect = CGRect(
            x: page.margins.left.toPoints,
            y: page.margins.bottom.toPoints,
            width: page.contentSize.width,
            height: page.contentSize.height
        )

        let path = CGPath(rect: contentRect, transform: nil)

        // 創建 Frame 並繪製
        let frame = CTFramesetterCreateFrame(
            framesetter,
            CFRangeMake(0, 0),
            path,
            nil
        )

        // 翻轉座標系
        context.saveGState()
        context.translateBy(x: 0, y: pageRect.height)
        context.scaleBy(x: 1.0, y: -1.0)

        CTFrameDraw(frame, context)

        context.restoreGState()
    }

    /// 繪製頁尾與頁碼
    private static func drawFooter(
        page: PageModel,
        in context: CGContext,
        pageRect: CGRect
    ) {
        let footerFont = NSFont.systemFont(ofSize: 10)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: NSColor.darkGray
        ]

        // 頁碼
        if page.pageNumberStyle != .none {
            let pageNumberString = NSAttributedString(
                string: page.formattedPageNumber,
                attributes: attributes
            )
            let pageNumberSize = pageNumberString.size()

            let pageNumberRect = CGRect(
                x: pageRect.width - page.margins.right.toPoints - pageNumberSize.width,
                y: page.margins.bottom.toPoints - 20,
                width: pageNumberSize.width,
                height: pageNumberSize.height
            )

            context.saveGState()
            context.translateBy(x: 0, y: pageRect.height)
            context.scaleBy(x: 1.0, y: -1.0)

            pageNumberString.draw(in: pageNumberRect)

            context.restoreGState()
        }

        // 頁尾文字
        if let footerText = page.footerText {
            let footerString = NSAttributedString(string: footerText, attributes: attributes)
            let footerRect = CGRect(
                x: page.margins.left.toPoints,
                y: page.margins.bottom.toPoints - 20,
                width: page.contentSize.width,
                height: 20
            )

            context.saveGState()
            context.translateBy(x: 0, y: pageRect.height)
            context.scaleBy(x: 1.0, y: -1.0)

            footerString.draw(in: footerRect)

            context.restoreGState()
        }
    }

    // MARK: - 元數據嵌入

    /// 嵌入元數據到 PDF
    private static func embedMetadata(_ metadata: ThesisMetadata, into pdfDocument: PDFDocument) {
        let attributes: [PDFDocumentAttribute: Any] = [
            .titleAttribute: metadata.titleChinese,
            .authorAttribute: metadata.authorChinese,
            .subjectAttribute: metadata.fullDegreeChinese,
            .creatorAttribute: "OverEnd - 學術論文編輯系統",
            .producerAttribute: "OverEnd Physical Canvas Engine",
            .creationDateAttribute: Date(),
            .modificationDateAttribute: metadata.updatedAt,
            .keywordsAttribute: metadata.keywordsChinese
        ]

        pdfDocument.documentAttributes = attributes
    }

    // MARK: - 字體嵌入

    /// 確保字體被嵌入 PDF（防止跑版）
    static func embedFonts(in pdfDocument: PDFDocument) {
        // PDFKit 在 macOS 上會自動嵌入使用的字體
        // 此方法預留給未來擴展（如需手動控制字體嵌入）
    }

    // MARK: - 批次導出

    /// 批次導出多個文檔
    static func batchExport(
        documents: [(pages: [PageModel], metadata: ThesisMetadata?, filename: String)],
        to directory: URL,
        progressHandler: ((Int, Int) -> Void)? = nil
    ) throws {
        for (index, doc) in documents.enumerated() {
            let fileURL = directory.appendingPathComponent(doc.filename).appendingPathExtension("pdf")

            try export(
                pages: doc.pages,
                metadata: doc.metadata,
                to: fileURL
            )

            progressHandler?(index + 1, documents.count)
        }
    }

    // MARK: - 預覽生成

    /// 生成預覽圖片（用於縮圖顯示）
    static func generatePreview(
        page: PageModel,
        size: CGSize = CGSize(width: 200, height: 283),
        scale: CGFloat = 2.0
    ) throws -> NSImage {
        let pdfPage = try renderPage(page, metadata: nil)

        let bounds = pdfPage.bounds(for: .mediaBox)
        let targetSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        let image = NSImage(size: targetSize)
        image.lockFocus()

        if let context = NSGraphicsContext.current?.cgContext {
            context.setFillColor(NSColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: targetSize))

            let scaleX = targetSize.width / bounds.width
            let scaleY = targetSize.height / bounds.height
            let scale = min(scaleX, scaleY)

            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: 0, y: bounds.height)
            context.scaleBy(x: 1.0, y: -1.0)

            context.drawPDFPage(pdfPage.pageRef!)
        }

        image.unlockFocus()
        return image
    }
}

// MARK: - 錯誤類型

enum PDFExportError: LocalizedError {
    case contextCreationFailed
    case pageCreationFailed
    case writeFailed
    case invalidPageData
    case fontEmbeddingFailed

    var errorDescription: String? {
        switch self {
        case .contextCreationFailed:
            return "無法創建 PDF 上下文"
        case .pageCreationFailed:
            return "無法創建 PDF 頁面"
        case .writeFailed:
            return "無法寫入 PDF 檔案"
        case .invalidPageData:
            return "頁面資料無效"
        case .fontEmbeddingFailed:
            return "字體嵌入失敗"
        }
    }
}

// MARK: - 導出選項

struct PDFExportOptions {
    var embedFonts: Bool = true
    var includeMetadata: Bool = true
    var compression: CompressionLevel = .standard
    var colorSpace: ColorSpace = .deviceRGB

    enum CompressionLevel {
        case none
        case standard
        case maximum
    }

    enum ColorSpace {
        case deviceRGB
        case deviceCMYK
        case deviceGray
    }
}
