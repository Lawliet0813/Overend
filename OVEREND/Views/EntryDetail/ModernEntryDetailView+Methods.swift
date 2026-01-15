//
//  ModernEntryDetailView+Methods.swift
//  OVEREND
//
//  書目詳情方法擴展 - 從 ModernEntryDetailView 拆分
//

import SwiftUI
import PDFKit
import Vision
import CoreData

// MARK: - Tag 管理方法

@available(macOS 26.0, *)
extension ModernEntryDetailView {
    
    func toggleTag(_ tag: Tag) {
        var currentTags = entry.tags as? Set<Tag> ?? []
        if currentTags.contains(tag) {
            currentTags.remove(tag)
        } else {
            currentTags.insert(tag)
        }
        entry.tags = currentTags
        try? viewContext.save()
    }

    func removeTag(_ tag: Tag) {
        var currentTags = entry.tags as? Set<Tag> ?? []
        currentTags.remove(tag)
        entry.tags = currentTags
        try? viewContext.save()
    }

    func addSuggestedTags(_ tagNames: [String]) {
        guard let library = entry.library else { return }
        var currentTags = entry.tags as? Set<Tag> ?? []
        var updated = false
        
        for name in tagNames {
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            request.predicate = NSPredicate(format: "name == %@ AND library == %@", name, library)
            
            if let existingTag = try? viewContext.fetch(request).first {
                if !currentTags.contains(existingTag) {
                    currentTags.insert(existingTag)
                    updated = true
                }
            } else {
                let newTag = Tag(context: viewContext, name: name, library: library)
                let colors = ["#FF3B30", "#FF9500", "#FFCC00", "#4CD964", "#5AC8FA", "#007AFF", "#5856D6", "#FF2D55"]
                newTag.colorHex = colors.randomElement() ?? "#007AFF"
                currentTags.insert(newTag)
                updated = true
            }
        }
        
        if updated {
            entry.tags = currentTags
            try? viewContext.save()
            ToastManager.shared.showSuccess("已加入 \(tagNames.count) 個標籤")
        }
    }

    func createNewTag(name: String) {
        guard let library = entry.library else { return }
        let newTag = Tag(context: viewContext, name: name, library: library)
        let colors = ["#FF3B30", "#FF9500", "#FFCC00", "#4CD964", "#5AC8FA", "#007AFF", "#5856D6", "#FF2D55"]
        newTag.colorHex = colors.randomElement() ?? "#007AFF"
        
        var currentTags = entry.tags as? Set<Tag> ?? []
        currentTags.insert(newTag)
        entry.tags = currentTags
        
        try? viewContext.save()
        
        LearningService.shared.learnTagging(title: entry.title, tags: [newTag.name])
        
        newTagSearchText = ""
    }
}

// MARK: - AI 方法

@available(macOS 26.0, *)
extension ModernEntryDetailView {
    
    func generateSummary() {
        isGeneratingSummary = true
        
        Task {
            do {
                let abstract = entry.fields["abstract"] ?? ""
                let content = entry.fields["note"] ?? ""
                
                let summary = try await aiService.document.generateSummary(
                    title: entry.title,
                    abstract: abstract,
                    content: content
                )
                
                await MainActor.run {
                    aiSummary = summary
                    entry.fields["ai_summary"] = summary
                    try? viewContext.save()
                    isGeneratingSummary = false
                    ToastManager.shared.showSuccess("摘要生成完成")
                }
            } catch {
                await MainActor.run {
                    isGeneratingSummary = false
                    ToastManager.shared.showError("生成失敗：\(error.localizedDescription)")
                }
            }
        }
    }
    
    func extractKeywords() {
        isExtractingKeywords = true
        
        Task {
            do {
                let abstract = entry.fields["abstract"] ?? entry.title
                
                let keywords = try await aiService.document.extractKeywords(
                    title: entry.title,
                    abstract: abstract
                )
                
                await MainActor.run {
                    aiKeywords = keywords
                    entry.fields["ai_keywords"] = keywords.joined(separator: ", ")
                    try? viewContext.save()
                    isExtractingKeywords = false
                    ToastManager.shared.showSuccess("已提取 \(keywords.count) 個關鍵詞")
                }
            } catch {
                await MainActor.run {
                    isExtractingKeywords = false
                    ToastManager.shared.showError("提取失敗：\(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - 編輯模式方法

@available(macOS 26.0, *)
extension ModernEntryDetailView {
    
    func enterEditMode() {
        isEditMode = true
        editedTitle = entry.title
        editedFields = entry.fields
        hasUnsavedChanges = false
    }
    
    func saveChanges() {
        guard !editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            ToastManager.shared.showError("標題為必填欄位")
            return
        }
        
        editedFields["title"] = editedTitle
        entry.fields = editedFields
        entry.updatedAt = Date()
        
        entry.bibtexRaw = generateBibTeX()
        
        do {
            try viewContext.save()
            
            isEditMode = false
            hasUnsavedChanges = false
            
            ToastManager.shared.showSuccess("已儲存變更")
        } catch {
            ToastManager.shared.showError("儲存失敗：\(error.localizedDescription)")
        }
    }
    
    func cancelEdit() {
        if hasUnsavedChanges {
            showUnsavedAlert = true
        } else {
            isEditMode = false
            editedTitle = entry.title
            editedFields = entry.fields
        }
    }
    
    func generateBibTeX() -> String {
        var bibtex = "@\(entry.entryType){\(entry.citationKey),\n"
        
        bibtex += "  title = {\(editedTitle)},\n"
        
        let fieldOrder = ["author", "year", "journal", "volume", "pages", "doi", "abstract"]
        for field in fieldOrder {
            if let value = editedFields[field], !value.isEmpty {
                bibtex += "  \(field) = {\(value)},\n"
            }
        }
        
        bibtex += "}"
        return bibtex
    }
}

// MARK: - AI 提取方法

@available(macOS 26.0, *)
extension ModernEntryDetailView {
    
    func performAIExtraction() {
        guard let pdfAttachment = entry.attachmentArray.first(where: { $0.mimeType == "application/pdf" }) else {
            performAIExtractionFromText()
            return
        }
        
        isExtractingMetadata = true
        
        Task {
            do {
                let pdfURL = URL(fileURLWithPath: pdfAttachment.filePath)
                guard let pdfDocument = PDFDocument(url: pdfURL) else {
                    await MainActor.run {
                        isExtractingMetadata = false
                        ToastManager.shared.showError("無法讀取 PDF 文件")
                    }
                    return
                }
                
                var pdfText = ""
                let pageCount = min(pdfDocument.pageCount, 5)
                for i in 0..<pageCount {
                    if let page = pdfDocument.page(at: i), let pageContent = page.string {
                        pdfText += pageContent + "\n"
                    }
                }
                
                if pdfText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await MainActor.run {
                        ToastManager.shared.showInfo("正在進行 OCR 識別...")
                    }
                    pdfText = try await performOCR(on: pdfDocument, pageCount: pageCount)
                }
                
                guard !pdfText.isEmpty else {
                    await MainActor.run {
                        isExtractingMetadata = false
                        ToastManager.shared.showError("PDF 無法提取文字（即使 OCR 後）")
                    }
                    return
                }
                
                let metadata = try await aiService.document.extractMetadata(from: pdfText)
                
                await MainActor.run {
                    applyExtractedMetadata(metadata)
                    isExtractingMetadata = false
                }
            } catch {
                await MainActor.run {
                    isExtractingMetadata = false
                    ToastManager.shared.showError("AI 提取失敗：\(error.localizedDescription)")
                }
            }
        }
    }
    
    func performAIExtractionFromText() {
        let abstract = editedFields["abstract"] ?? entry.fields["abstract"] ?? ""
        let title = editedTitle.isEmpty ? entry.title : editedTitle
        
        guard !abstract.isEmpty || !title.isEmpty else {
            ToastManager.shared.showError("沒有 PDF 附件或文字資料可供分析")
            return
        }
        
        isExtractingMetadata = true
        
        Task {
            do {
                let textToAnalyze = "標題: \(title)\n\n摘要: \(abstract)"
                let metadata = try await aiService.document.extractMetadata(from: textToAnalyze)
                
                await MainActor.run {
                    applyExtractedMetadata(metadata)
                    isExtractingMetadata = false
                }
            } catch {
                await MainActor.run {
                    isExtractingMetadata = false
                    ToastManager.shared.showError("AI 提取失敗：\(error.localizedDescription)")
                }
            }
        }
    }
    
    func applyExtractedMetadata(_ metadata: ExtractedDocumentMetadata) {
        var fieldsUpdated = 0
        
        if let title = metadata.title, !title.isEmpty, editedTitle.isEmpty {
            editedTitle = title
            fieldsUpdated += 1
        }
        
        if !metadata.authors.isEmpty {
            let authorField = editedFields["author"] ?? ""
            if authorField.isEmpty {
                editedFields["author"] = metadata.authorsBibTeX
                fieldsUpdated += 1
            }
        }
        
        if let year = metadata.year {
            let yearField = editedFields["year"] ?? ""
            if yearField.isEmpty {
                editedFields["year"] = year
                fieldsUpdated += 1
            }
        }
        
        if let journal = metadata.journal {
            let journalField = editedFields["journal"] ?? ""
            if journalField.isEmpty {
                editedFields["journal"] = journal
                fieldsUpdated += 1
            }
        }
        
        if let doi = metadata.doi {
            let doiField = editedFields["doi"] ?? ""
            if doiField.isEmpty {
                editedFields["doi"] = doi
                fieldsUpdated += 1
            }
        }
        
        if let entryType = metadata.entryType {
            editedEntryType = entryType
            fieldsUpdated += 1
        }
        
        if fieldsUpdated > 0 {
            hasUnsavedChanges = true
            ToastManager.shared.showSuccess("已提取 \(fieldsUpdated) 個欄位")
        } else {
            ToastManager.shared.showInfo("未發現新資訊可填入")
        }
    }
}

// MARK: - OCR 方法

@available(macOS 26.0, *)
extension ModernEntryDetailView {
    
    func performOCR(on pdfDocument: PDFDocument, pageCount: Int) async throws -> String {
        var ocrText = ""
        
        for i in 0..<pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }
            
            let pageRect = page.bounds(for: .mediaBox)
            let scale: CGFloat = 2.0
            let imageSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
            
            let image = NSImage(size: imageSize)
            image.lockFocus()
            
            if let context = NSGraphicsContext.current?.cgContext {
                context.setFillColor(NSColor.white.cgColor)
                context.fill(CGRect(origin: .zero, size: imageSize))
                context.scaleBy(x: scale, y: scale)
                page.draw(with: .mediaBox, to: context)
            }
            
            image.unlockFocus()
            
            guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { continue }
            
            let pageText = try await recognizeText(in: cgImage)
            if !pageText.isEmpty {
                ocrText += pageText + "\n\n"
            }
        }
        
        return ocrText
    }
    
    func recognizeText(in image: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
            }
            
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hant", "zh-Hans", "en-US"]
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

// MARK: - 引用預覽

@available(macOS 26.0, *)
extension ModernEntryDetailView {
    
    func generateAPAPreview() -> String {
        let author = editedFields["author"] ?? ""
        let year = editedFields["year"] ?? ""
        let title = editedTitle
        let journal = editedFields["journal"] ?? ""
        let volume = editedFields["volume"] ?? ""
        let pages = editedFields["pages"] ?? ""
        let doi = editedFields["doi"] ?? ""
        
        var citation = ""
        
        if !author.isEmpty {
            citation += author
        } else {
            citation += "作者未知"
        }
        
        citation += " (\(year.isEmpty ? "n.d." : year)). "
        
        citation += title.isEmpty ? "無標題" : title
        citation += ". "
        
        if !journal.isEmpty {
            citation += "*\(journal)*"
            if !volume.isEmpty {
                citation += ", \(volume)"
            }
            if !pages.isEmpty {
                citation += ", \(pages)"
            }
            citation += ". "
        }
        
        if !doi.isEmpty {
            citation += "https://doi.org/\(doi)"
        }
        
        return citation
    }
    
    func generateMLAPreview() -> String {
        let author = editedFields["author"] ?? ""
        let title = editedTitle
        let journal = editedFields["journal"] ?? ""
        let volume = editedFields["volume"] ?? ""
        let year = editedFields["year"] ?? ""
        let pages = editedFields["pages"] ?? ""
        
        var citation = ""
        
        if !author.isEmpty {
            citation += author
        } else {
            citation += "作者未知"
        }
        citation += ". "
        
        citation += "\"" + (title.isEmpty ? "無標題" : title) + ".\" "
        
        if !journal.isEmpty {
            citation += "*\(journal)*"
            if !volume.isEmpty {
                citation += ", vol. \(volume)"
            }
            if !year.isEmpty {
                citation += ", \(year)"
            }
            if !pages.isEmpty {
                citation += ", pp. \(pages)"
            }
            citation += "."
        }
        
        return citation
    }
}

// MARK: - PDF 匯入

@available(macOS 26.0, *)
extension ModernEntryDetailView {
    
    func importPDF() {
        PDFService.shared.selectPDFFile { url in
            guard let url = url else { return }
            
            do {
                try PDFService.shared.addPDFAttachment(from: url, to: entry, context: viewContext)
            } catch {
                print("添加 PDF 失敗：\(error)")
            }
        }
    }
}
