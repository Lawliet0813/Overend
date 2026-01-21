//
//  ClaudeWritingAssistantView+Export.swift
//  OVEREND
//
//  匯出功能擴展 - PDF 和 DOCX 匯出
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Export Extension

extension ClaudeWritingAssistantView {
    
    // MARK: - Export DOCX
    
    func exportDocx() {
        Task {
            await MainActor.run { isExporting = true }
            
            do {
                let panel = NSSavePanel()
                panel.title = "匯出 Word 文件"
                panel.nameFieldStringValue = "\(document.title).docx"
                panel.allowedContentTypes = [UTType(filenameExtension: "docx") ?? .data]
                
                guard let window = NSApp.keyWindow else {
                    await MainActor.run { isExporting = false }
                    return
                }
                
                let response = await panel.beginSheetModal(for: window)
                
                if response == .OK, let url = panel.url {
                    // 使用原生 API 匯出
                    let docAttributes: [NSAttributedString.DocumentAttributeKey: Any] = [
                        .documentType: NSAttributedString.DocumentType.officeOpenXML
                    ]
                    if let data = try? viewModel.attributedText.data(
                        from: NSRange(location: 0, length: viewModel.attributedText.length),
                        documentAttributes: docAttributes
                    ) {
                        try data.write(to: url)
                    } else {
                        // Fallback: 使用 Pandoc
                        if PandocService.isAvailable {
                            try await PandocService.exportToDocx(viewModel.attributedText, outputURL: url)
                        } else {
                            throw NSError(domain: "Export", code: -1, 
                                userInfo: [NSLocalizedDescriptionKey: "無法匯出 DOCX。請安裝 Pandoc：brew install pandoc"])
                        }
                    }
                    
                    await MainActor.run {
                        ToastManager.shared.showSuccess("已成功匯出 DOCX")
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
            } catch {
                await MainActor.run {
                    ToastManager.shared.showError("匯出失敗：\(error.localizedDescription)")
                }
            }
            
            await MainActor.run { isExporting = false }
        }
    }
    
    // MARK: - Export PDF
    
    func exportPDF() {
        Task {
            await MainActor.run { isExporting = true }
            
            do {
                let panel = NSSavePanel()
                panel.title = "匯出 PDF"
                panel.nameFieldStringValue = "\(document.title).pdf"
                panel.allowedContentTypes = [.pdf]
                
                guard let window = NSApp.keyWindow else {
                    await MainActor.run { isExporting = false }
                    return
                }
                
                let response = await panel.beginSheetModal(for: window)
                
                if response == .OK, let url = panel.url {
                    try await exportPDFWithWebKit(to: url)
                    
                    await MainActor.run {
                        ToastManager.shared.showSuccess("已成功匯出 PDF")
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
            } catch {
                await MainActor.run {
                    ToastManager.shared.showError("匯出失敗：\(error.localizedDescription)")
                }
            }
            
            await MainActor.run { isExporting = false }
        }
    }
    
    // MARK: - Private Methods
    
    private func exportPDFWithWebKit(to url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.main.async {
                let template = FormatTemplate.blank
                
                WebKitPDFExporter.export(
                    document: self.document,
                    template: template,
                    to: url
                ) { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}
