//
//  NewContentView+Actions.swift
//  OVEREND
//
//  NewContentView 的功能擴充 - 匯入與新增
//

import SwiftUI
import UniformTypeIdentifiers
import CoreData

extension NewContentView {
    
    // MARK: - 新增/匯入相關方法
    
    func importPDF() {
        guard let library = libraryVM.libraries.first else {
            ToastManager.shared.showError("請先建立文獻庫")
            return
        }
        
        let panel = NSOpenPanel()
        panel.title = "匯入 PDF 檔案"
        panel.message = "選擇 PDF 檔案，AI 將自動提取書目信息"
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.prompt = "匯入"
        
        panel.begin { response in
            if response == .OK {
                let urls = panel.urls
                if urls.count == 1 {
                    // 單檔處理
                    processSinglePDF(url: urls[0], library: library)
                } else if urls.count > 1 {
                    // 批次處理
                    batchImportPDFs(urls: urls, into: library)
                }
            }
        }
    }
    
    func importBibTeX() {
        guard let library = libraryVM.libraries.first else {
            ToastManager.shared.showError("請先建立文獻庫")
            return
        }
        
        let panel = NSOpenPanel()
        panel.title = "匯入 BibTeX 檔案"
        panel.message = "選擇 .bib 檔案匯入書目資料"
        panel.allowedContentTypes = [.text, UTType(filenameExtension: "bib")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "匯入"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    let entries = try BibTeXParser.parseFile(at: url)
                    let count = try BibTeXParser.importEntries(entries, into: library, context: viewContext)
                    ToastManager.shared.showSuccess("成功匯入 \(count) 筆書目")
                } catch {
                    ToastManager.shared.showError("匯入失敗：\(error.localizedDescription)")
                }
            }
        }
    }
    
    func createManualEntry() {
        guard let library = libraryVM.libraries.first else { return }
        
        let newEntry = Entry(context: viewContext)
        newEntry.id = UUID()
        newEntry.createdAt = Date()
        newEntry.updatedAt = Date()
        newEntry.library = library
        newEntry.entryType = "article"
        newEntry.citationKey = "untitled\(Int(Date().timeIntervalSince1970))"
        newEntry.fields = [
            "title": "未命名文獻",
            "year": String(Calendar.current.component(.year, from: Date()))
        ]
        
        try? viewContext.save()
        
        // 應通知 UI 選中此新項目 (TODO: 透過 MainViewState 或 Notification)
        ToastManager.shared.showSuccess("已建立新書目")
    }
    
    // MARK: - 輔助方法
    
    private func processSinglePDF(url: URL, library: Library) {
        ToastManager.shared.showInfo("正在提取 PDF 內容...")
        
        Task {
            do {
                // 1. 使用 LiteratureAgent 智能提取元數據
                let agentResult = try await LiteratureAgent.shared.extractPDFMetadata(from: url)
                
                var metadata = PDFMetadata(
                    title: agentResult.title,
                    authors: agentResult.authors,
                    year: agentResult.year,
                    doi: agentResult.doi,
                    abstract: agentResult.abstract,
                    journal: agentResult.journal,
                    entryType: agentResult.entryType,
                    confidence: agentResult.confidence > 0.7 ? .high : (agentResult.confidence > 0.4 ? .medium : .low)
                )
                metadata.volume = nil
                metadata.pages = nil
                
                // 2. 另外提取純文本用於備份或進一步分析
                let (_, pdfText) = try PDFService.shared.extractPDFMetadata(from: url)
                
                // 3. 建立 Entry
                await MainActor.run {
                    createEntryFromPDF(metadata: metadata, text: pdfText, url: url, library: library, useAI: true)
                }
            } catch {
                await MainActor.run {
                     // 失敗時使用基本檔案名創建
                    ToastManager.shared.showWarning("AI 提取失敗，將使用檔案名創建: \(error.localizedDescription)")
                    let filename = url.deletingPathExtension().lastPathComponent
                    let basicMetadata = PDFMetadata(title: filename)
                    createEntryFromPDF(metadata: basicMetadata, text: nil, url: url, library: library, useAI: false)
                }
            }
        }
    }
    
    private func createEntryFromPDF(metadata: PDFMetadata, text: String?, url: URL, library: Library, useAI: Bool) {
        let entry = Entry(context: viewContext)
        entry.id = UUID()
        entry.createdAt = Date()
        entry.updatedAt = Date()
        entry.library = library
        entry.entryType = metadata.entryType
        
        // 生成 Citation Key
        var key = ""
        if let firstAuthor = metadata.authors.first {
            key += firstAuthor.components(separatedBy: " ").last?.lowercased() ?? "author"
        }
        if let year = metadata.year {
            key += year
        }
        entry.citationKey = key.isEmpty ? "entry\(Int(Date().timeIntervalSince1970))" : key
        
        // 填入欄位
        var fields: [String: String] = ["title": metadata.title]
        if !metadata.authors.isEmpty { fields["author"] = metadata.authors.joined(separator: " and ") }
        if let year = metadata.year { fields["year"] = year }
        if let doi = metadata.doi { fields["doi"] = doi }
        
        entry.fields = fields
        entry.bibtexRaw = PDFMetadataExtractor.generateBibTeX(from: metadata, citationKey: entry.citationKey)
        
        // 添加附件
        _ = try? PDFService.shared.addPDFAttachment(from: url, to: entry, context: viewContext)
        
        // 如果需要 AI 進一步分析
        if useAI, let text = text, !text.isEmpty {
            Task {
                do {
                    let aiMetadata = try await UnifiedAIService.shared.document.extractMetadata(from: text)
                    await MainActor.run {
                        // 更新欄位
                        if let aiTitle = aiMetadata.title, !aiTitle.isEmpty {
                            entry.fields["title"] = aiTitle
                        }
                        if !aiMetadata.authors.isEmpty {
                            entry.fields["author"] = aiMetadata.authorsBibTeX
                        }
                        // ... 其他欄位更新
                        try? viewContext.save()
                        ToastManager.shared.showSuccess("AI 優化完成")
                    }
                } catch {
                    print("AI Optimization failed: \(error)")
                }
            }
        }
        
        try? viewContext.save()
        ToastManager.shared.showSuccess("已匯入 PDF")
    }
    
    private func batchImportPDFs(urls: [URL], into library: Library) {
        ToastManager.shared.showInfo("正在背景匯入 \(urls.count) 個檔案...")
        
        Task.detached {
            for url in urls {
                await MainActor.run {
                    processSinglePDF(url: url, library: library)
                }
            }
        }
    }
}
