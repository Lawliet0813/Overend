//
//  SimpleContentView+Import.swift
//  OVEREND
//
//  匯入相關方法擴展 - 從 SimpleContentView 拆分
//

import SwiftUI
import UniformTypeIdentifiers
import CoreData

// MARK: - 匯入方法

extension SimpleContentView {
    
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let library = libraryVM.libraries.first else {
            ToastManager.shared.showError("請先建立文獻庫")
            return false
        }
        
        var importedCount = 0
        let group = DispatchGroup()
        
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                group.enter()
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    defer { group.leave() }
                    guard let url = url, url.pathExtension.lowercased() == "pdf" else { return }
                    
                    DispatchQueue.main.async {
                        self.extractAndShowMetadata(from: url, library: library)
                        importedCount += 1
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if importedCount > 0 {
                ToastManager.shared.showInfo("正在處理 \(importedCount) 個 PDF...")
            }
        }
        
        return true
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
                    self.extractAndShowMetadata(from: urls[0], library: library)
                } else if urls.count > 1 {
                    self.batchImportPDFs(urls: urls, into: library)
                }
            }
        }
    }
    
    func extractAndShowMetadata(from url: URL, library: Library) {
        currentPDFURL = url
        isExtractingMetadata = true
        processingStartTime = Date()
        
        Task {
            // 優先使用 Agent 提取（macOS 26.0+）
            if #available(macOS 26.0, *) {
                do {
                    let agent = LiteratureAgent.shared
                    let agentResult = try await agent.extractPDFMetadata(from: url)
                    
                    let metadata = PDFMetadata(
                        title: agentResult.title,
                        authors: agentResult.authors,
                        year: agentResult.year,
                        doi: agentResult.doi,
                        abstract: agentResult.abstract,
                        journal: agentResult.journal,
                        volume: nil,
                        pages: nil,
                        entryType: agentResult.entryType,
                        confidence: agentResult.confidence > 0.7 ? .high : (agentResult.confidence > 0.4 ? .medium : .low)
                    )
                    
                    var pdfText: String? = nil
                    if let (_, extractedText) = try? PDFService.shared.extractPDFMetadata(from: url) {
                        pdfText = extractedText
                    }
                    
                    await MainActor.run {
                        let vm = ExtractionWorkbenchViewModel(context: viewContext, library: library)
                        vm.addPendingExtraction(
                            metadata: metadata,
                            pdfURL: url,
                            pdfText: pdfText,
                            logs: "🤖 Agent 驅動提取完成\n信心度: \(String(format: "%.0f", agentResult.confidence * 100))%"
                        )
                        
                        extractionWorkbenchVM = vm
                        isExtractingMetadata = false
                        showExtractionWorkbench = true
                        extractedMetadata = metadata
                        currentExtractionLogs = "Agent 提取完成"
                    }
                    return
                    
                } catch {
                    logWarning("Agent 提取失敗，使用傳統方法: \(error.localizedDescription)", category: .general)
                }
            }
            
            // 傳統方法（降級方案）
            let useGemini = UserDefaults.standard.bool(forKey: "useGeminiForPDF")
            let (metadata, logs) = await PDFMetadataExtractor.extractMetadata(from: url, useGemini: useGemini)
            
            var pdfText: String? = nil
            if let (_, extractedText) = try? PDFService.shared.extractPDFMetadata(from: url) {
                pdfText = extractedText
            }
            
            await MainActor.run {
                let vm = ExtractionWorkbenchViewModel(context: viewContext, library: library)
                vm.addPendingExtraction(
                    metadata: metadata,
                    pdfURL: url,
                    pdfText: pdfText,
                    logs: logs
                )
                
                extractionWorkbenchVM = vm
                isExtractingMetadata = false
                showExtractionWorkbench = true
                extractedMetadata = metadata
                currentExtractionLogs = logs
            }
        }
    }
    
    func batchImportPDFs(urls: [URL], into library: Library) {
        let totalCount = urls.count
        let libraryID = library.objectID
        
        ToastManager.shared.showInfo("正在背景處理 \(totalCount) 個 PDF 文件...")
        
        Task.detached(priority: .userInitiated) {
            let container = PersistenceController.shared.container
            let backgroundContext = container.newBackgroundContext()
            backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            var successCount = 0
            var failedCount = 0
            
            guard let backgroundLibrary = try? backgroundContext.existingObject(with: libraryID) as? Library else {
                await MainActor.run {
                    ToastManager.shared.showError("無法在背景存取文獻庫")
                }
                return
            }
            
            for (index, url) in urls.enumerated() {
                let startTime = Date()
                let useGemini = UserDefaults.standard.bool(forKey: "useGeminiForPDF")
                
                let (metadata, logs) = await PDFMetadataExtractor.extractMetadata(from: url, useGemini: useGemini)
                
                await backgroundContext.perform {
                    do {
                        try self.savePDFEntry(metadata: metadata, pdfURL: url, library: backgroundLibrary, context: backgroundContext)
                        successCount += 1
                        
                        if (index + 1) % 5 == 0 {
                            try backgroundContext.save()
                        }
                    } catch {
                        failedCount += 1
                        #if DEBUG
                        print("匯入失敗: \(error)")
                        #endif
                    }
                }
                
                #if DEBUG
                if NotionConfig.isAutoCreateEnabled {
                    let duration = Date().timeIntervalSince(startTime)
                    Task {
                        try? await NotionService.shared.createRecord(
                            metadata: metadata,
                            fileURL: url,
                            processingTime: duration,
                            logs: logs
                        )
                    }
                }
                #endif
                
                if (index + 1) % 5 == 0 {
                    await MainActor.run {
                        ToastManager.shared.showInfo("已處理 \(index + 1)/\(totalCount)...")
                    }
                }
            }
            
            await backgroundContext.perform {
                try? backgroundContext.save()
            }
            
            await MainActor.run {
                if failedCount == 0 {
                    ToastManager.shared.showSuccess("成功匯入 \(successCount) 個 PDF")
                } else {
                    ToastManager.shared.showWarning("成功 \(successCount) 個，失敗 \(failedCount) 個")
                }
            }
        }
    }
    
    func savePDFEntry(metadata: PDFMetadata, pdfURL: URL, library: Library, context: NSManagedObjectContext) throws {
        let entry = Entry(context: context)
        entry.id = UUID()
        entry.entryType = metadata.entryType
        entry.citationKey = generateCitationKey(from: metadata)
        entry.createdAt = Date()
        entry.updatedAt = Date()
        entry.library = library
        
        var fields: [String: String] = ["title": metadata.title]
        if !metadata.authors.isEmpty { fields["author"] = metadata.authors.joined(separator: " and ") }
        if let year = metadata.year { fields["year"] = year }
        if let doi = metadata.doi { fields["doi"] = doi }
        if let journal = metadata.journal { fields["journal"] = journal }
        if let abstract = metadata.abstract { fields["abstract"] = abstract }
        
        entry.fields = fields
        entry.bibtexRaw = PDFMetadataExtractor.generateBibTeX(from: metadata, citationKey: entry.citationKey)
        try PDFService.shared.addPDFAttachment(from: pdfURL, to: entry, context: context)
    }
    
    func generateCitationKey(from metadata: PDFMetadata) -> String {
        var key = ""
        if let firstAuthor = metadata.authors.first {
            let lastName = firstAuthor.components(separatedBy: " ").last ?? firstAuthor
            key = lastName.lowercased()
        }
        if let year = metadata.year { key += year }
        let titleWords = metadata.title.components(separatedBy: .whitespaces).prefix(2).map { $0.lowercased() }.joined()
        key += titleWords
        key = key.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        if key.count < 5 { key += "\(Int(Date().timeIntervalSince1970) % 10000)" }
        return key.isEmpty ? "entry\(Int(Date().timeIntervalSince1970))" : key
    }
}
