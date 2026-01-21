//
//  PDFExporter.swift
//  OVEREND
//
//  PDF 匯出器 - 使用 WebKit createPDF API
//

import Foundation
import WebKit
import AppKit

/// PDF 匯出器 - 使用 WebKit createPDF API
class WebKitPDFExporter: NSObject {
    
    // 保持 WebView 和 Delegate 的強引用
    private static var activeExporters: [WebKitPDFExporter] = []
    
    // 隱藏視窗用於渲染
    private static var offscreenWindow: NSWindow?
    
    private var webView: WKWebView?
    private var template: FormatTemplate?
    private var outputURL: URL?
    private var completion: ((Result<Void, Error>) -> Void)?
    private var previewCompletion: ((Result<Data, Error>) -> Void)?
    
    /// 將文件匯出為 PDF
    static func export(
        document: Document,
        template: FormatTemplate,
        to url: URL,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // 確保文檔有效
        guard !document.isDeleted, !document.isFault else {
            completion(.failure(NSError(domain: "PDFExporter", code: -1, userInfo: [NSLocalizedDescriptionKey: "文檔無效"])))
            return
        }
        
        export(content: document.attributedString, template: template, to: url, completion: completion)
    }
    
    /// 使用內容直接匯出為 PDF（不依賴 Document 物件）
    static func export(
        content: NSAttributedString,
        template: FormatTemplate,
        to url: URL,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let exporter = WebKitPDFExporter()
        exporter.template = template
        exporter.outputURL = url
        exporter.completion = completion
        activeExporters.append(exporter)

        // 1. 內容 → HTML
        let html = DocumentFormatter.toHTML(content, template: template)

        // 🔍 Debug: 輸出 HTML 內容長度和前 500 字元
        print("📄 WebKitPDFExporter - HTML 長度：\(html.count) 字元")
        print("📄 WebKitPDFExporter - 內容預覽：\(String(html.prefix(500)))")
        print("📄 WebKitPDFExporter - NSAttributedString 長度：\(content.length) 字元")
        print("📄 WebKitPDFExporter - 純文字預覽：\(String(content.string.prefix(200)))")

        loadHTMLAndExport(html, exporter: exporter)
    }

    /// 直接使用 HTML 匯出為 PDF（避免雙重轉換）
    static func exportFromHTML(
        _ html: String,
        template: FormatTemplate,
        to url: URL,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let exporter = WebKitPDFExporter()
        exporter.template = template
        exporter.outputURL = url
        exporter.completion = completion
        activeExporters.append(exporter)

        print("📄 WebKitPDFExporter (from HTML) - HTML 長度：\(html.count) 字元")
        print("📄 WebKitPDFExporter (from HTML) - 內容預覽：\(String(html.prefix(500)))")

        loadHTMLAndExport(html, exporter: exporter)
    }

    /// 載入 HTML 並執行 PDF 匯出的共用方法
    private static func loadHTMLAndExport(_ html: String, exporter: WebKitPDFExporter) {
        // 2. 建立離線視窗（必須加入視窗層級才能正確渲染）
        setupOffscreenWindow()

        // 3. 配置 WKWebView
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true

        // 建立有尺寸的 WebView（A4 大小：595 x 842 點）
        let webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 595, height: 842),
            configuration: config
        )
        webView.navigationDelegate = exporter
        exporter.webView = webView

        // 將 WebView 加入視窗（重要！否則可能無法正確渲染）
        offscreenWindow?.contentView = webView

        // 4. 載入 HTML
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    /// 設定離線視窗
    private static func setupOffscreenWindow() {
        if offscreenWindow == nil {
            offscreenWindow = NSWindow(
                contentRect: CGRect(x: -10000, y: -10000, width: 595, height: 842),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            offscreenWindow?.isReleasedWhenClosed = false
        }
    }
    
    /// 預覽 PDF（不儲存）
    static func preview(
        document: Document,
        template: FormatTemplate,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        let exporter = WebKitPDFExporter()
        exporter.template = template
        exporter.previewCompletion = completion
        activeExporters.append(exporter)
        
        let html = DocumentFormatter.toHTML(
            document.attributedString,
            template: template
        )
        
        // 建立離線視窗
        setupOffscreenWindow()
        
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        
        let webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 595, height: 842),
            configuration: config
        )
        webView.navigationDelegate = exporter
        exporter.webView = webView
        
        offscreenWindow?.contentView = webView
        
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    /// 使用 WebKit createPDF API 建立 PDF
    private func createPDFWithWebKitAPI() {
        guard let webView = webView else {
            finishWithError(NSError(domain: "WebKitPDFExporter", code: -1, userInfo: [NSLocalizedDescriptionKey: "WebView 未初始化"]))
            return
        }
        
        let pdfConfiguration = WKPDFConfiguration()
        // 🔧 關鍵修正：設定為 nil 讓 WebKit 使用 CSS @page 規則自動分頁
        // 這樣才能正確識別 page-break-after: always
        pdfConfiguration.rect = nil
        
        webView.createPDF(configuration: pdfConfiguration) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let data):
                    print("✅ PDF 建立成功，大小：\(data.count) bytes")
                    
                    if let url = self.outputURL {
                        // 匯出模式
                        do {
                            try data.write(to: url)
                            print("✅ PDF 已儲存至：\(url.path)")
                            self.completion?(.success(()))
                        } catch {
                            print("❌ PDF 儲存失敗：\(error)")
                            self.completion?(.failure(error))
                        }
                    } else {
                        // 預覽模式
                        self.previewCompletion?(.success(data))
                    }
                    
                case .failure(let error):
                    print("❌ PDF 建立失敗：\(error)")
                    self.finishWithError(error)
                }
                
                self.cleanup()
            }
        }
    }
    
    private func finishWithError(_ error: Error) {
        if outputURL != nil {
            completion?(.failure(error))
        } else {
            previewCompletion?(.failure(error))
        }
        cleanup()
    }
    
    private func cleanup() {
        webView = nil
        WebKitPDFExporter.offscreenWindow?.contentView = nil
        WebKitPDFExporter.activeExporters.removeAll { $0 === self }
    }
}

// MARK: - WKNavigationDelegate

extension WebKitPDFExporter: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // HTML 載入完成
        print("✅ WebView HTML 載入完成")
        
        // 檢查 WebView 內容
        webView.evaluateJavaScript("document.body.innerHTML.length") { length, error in
            if let length = length as? Int {
                print("📏 WebView 內容長度：\(length) 字元")
                
                if length == 0 {
                    print("⚠️ WebView 內容為空！")
                }
            }
            if let error = error {
                print("❌ JavaScript 錯誤：\(error)")
            }
        }
        
        webView.evaluateJavaScript("document.body.scrollHeight") { height, error in
            if let height = height as? CGFloat {
                print("📏 WebView 內容高度：\(height) px")
            }
        }
        
        // 等待一小段時間讓 CSS 渲染完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.createPDFWithWebKitAPI()
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ WebView 導航失敗：\(error)")
        finishWithError(error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("❌ WebView 預載入失敗：\(error)")
        finishWithError(error)
    }
}
