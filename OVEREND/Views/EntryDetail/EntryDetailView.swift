//
//  EntryDetailView.swift
//  OVEREND
//
//  右側詳情 - 書目詳細資訊
//

import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

struct EntryDetailView: View {
    let entry: Entry
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isEditing = false
    @State private var isEditingBibTeX = false
    @State private var editedBibTeX = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 標題
                Text(entry.title)
                    .font(.title)
                    .fontWeight(.bold)

                // 作者
                DetailRow(label: "作者", value: entry.author)

                // 年份
                if !entry.year.isEmpty {
                    DetailRow(label: "年份", value: entry.year)
                }

                // 出版物
                if !entry.publication.isEmpty {
                    DetailRow(label: entry.entryType == "article" ? "期刊" : "出版社", value: entry.publication)
                }

                Divider()

                // 引用鍵
                DetailRow(label: "引用鍵", value: entry.citationKey)

                // 類型
                DetailRow(label: "類型", value: entry.entryType)

                Divider()
                
                // 引用格式
                VStack(alignment: .leading, spacing: 12) {
                    Text("引用格式")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // APA 格式
                    CitationRow(
                        format: "APA 7th",
                        citation: CitationService.generateAPA(entry: entry)
                    )
                    
                    // MLA 格式
                    CitationRow(
                        format: "MLA 9th",
                        citation: CitationService.generateMLA(entry: entry)
                    )
                }

                Divider()

                // BibTeX 源代碼
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("BibTeX")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if isEditingBibTeX {
                            Button(action: {
                                saveBibTeX()
                            }) {
                                Label("儲存", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button(action: {
                                isEditingBibTeX = false
                                editedBibTeX = entry.bibtexRaw
                            }) {
                                Label("取消", systemImage: "xmark.circle")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button(action: {
                                copyToClipboard(entry.bibtexRaw)
                            }) {
                                Label("複製", systemImage: "doc.on.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: {
                                editedBibTeX = entry.bibtexRaw
                                isEditingBibTeX = true
                            }) {
                                Label("編輯", systemImage: "pencil")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if isEditingBibTeX {
                        TextEditor(text: $editedBibTeX)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 200)
                            .padding(4)
                            .background(Color.overendPaperGray)
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.accentColor, lineWidth: 2)
                            )
                    } else {
                        Text(entry.bibtexRaw)
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                            .background(Color.overendPaperGray)
                            .cornerRadius(4)
                    }
                }

                // 附件
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("附件")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: importPDF) {
                            Label("匯入 PDF", systemImage: "doc.badge.plus")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }

                    if let attachments = entry.attachments, !attachments.isEmpty {
                        ForEach(Array(attachments)) { attachment in
                            AttachmentRow(
                                attachment: attachment,
                                onDelete: {
                                    deleteAttachment(attachment)
                                }
                            )
                        }
                    } else {
                        Text("尚無附件")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }

                // 筆記
                if let notes = entry.userNotes, !notes.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("筆記")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(notes)
                            .font(.body)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .alert("錯誤", isPresented: $showingError) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("編輯") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            if let library = entry.library {
                NavigationStack {
                    EntryEditorView(library: library, entry: entry)
                }
            }
        }
    }

    // MARK: - PDF 匯入

    private func importPDF() {
        PDFService.selectPDFFile { url in
            guard let url = url else { return }

            do {
                try PDFService.addPDFAttachment(from: url, to: entry, context: viewContext)
            } catch let error as PDFService.PDFError {
                errorMessage = error.localizedDescription
                showingError = true
            } catch {
                errorMessage = "匯入 PDF 失敗: \(error.localizedDescription)"
                showingError = true
            }
        }
    }

    private func deleteAttachment(_ attachment: Attachment) {
        do {
            try PDFService.deleteAttachment(attachment, context: viewContext)
        } catch {
            errorMessage = "刪除附件失敗: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func copyToClipboard(_ text: String) {
        #if canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // 同時提供純文字和 RTF 格式
        pasteboard.setString(text, forType: .string)
        
        // 轉換 Markdown 斜體 *text* 為 RTF 斜體
        if let rtfData = convertToRTF(text) {
            pasteboard.setData(rtfData, forType: .rtf)
        }
        #endif
    }
    
    /// 將 Markdown 斜體轉換為 RTF 格式
    private func convertToRTF(_ markdown: String) -> Data? {
        #if canImport(AppKit)
        // 使用 NSAttributedString 來建立 RTF
        let attributedString = NSMutableAttributedString()
        
        // 解析 Markdown 斜體
        var currentIndex = markdown.startIndex
        var inItalic = false
        var currentText = ""
        
        while currentIndex < markdown.endIndex {
            let char = markdown[currentIndex]
            
            if char == "*" {
                // 找到星號
                if !currentText.isEmpty {
                    // 添加當前累積的文字
                    let font: NSFont
                    if inItalic {
                        // 斜體字
                        let descriptor = NSFont.systemFont(ofSize: 12).fontDescriptor
                            .withSymbolicTraits(.italic)
                        font = NSFont(descriptor: descriptor, size: 12) ?? NSFont.systemFont(ofSize: 12)
                    } else {
                        // 正常字
                        font = NSFont.systemFont(ofSize: 12)
                    }
                    
                    let attrs: [NSAttributedString.Key: Any] = [.font: font]
                    attributedString.append(NSAttributedString(string: currentText, attributes: attrs))
                    currentText = ""
                }
                inItalic.toggle()
            } else {
                currentText.append(char)
            }
            
            currentIndex = markdown.index(after: currentIndex)
        }
        
        // 添加剩餘文字
        if !currentText.isEmpty {
            let font: NSFont
            if inItalic {
                let descriptor = NSFont.systemFont(ofSize: 12).fontDescriptor
                    .withSymbolicTraits(.italic)
                font = NSFont(descriptor: descriptor, size: 12) ?? NSFont.systemFont(ofSize: 12)
            } else {
                font = NSFont.systemFont(ofSize: 12)
            }
            
            let attrs: [NSAttributedString.Key: Any] = [.font: font]
            attributedString.append(NSAttributedString(string: currentText, attributes: attrs))
        }
        
        // 轉換為 RTF
        let range = NSRange(location: 0, length: attributedString.length)
        return try? attributedString.data(from: range, documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        #else
        return nil
        #endif
    }
    
    private func saveBibTeX() {
        // 解析編輯後的 BibTeX
        do {
            let entries = try BibTeXParser.parse(editedBibTeX)
            
            guard let parsedEntry = entries.first else {
                errorMessage = "無法解析 BibTeX 內容"
                showingError = true
                return
            }
            
            // 更新基本資訊
            entry.citationKey = parsedEntry.citationKey
            entry.entryType = parsedEntry.type
            entry.bibtexRaw = editedBibTeX
            
            // 更新所有欄位
            entry.updateFields(parsedEntry.fields)
            
            // 儲存變更
            do {
                try viewContext.save()
                isEditingBibTeX = false
                print("成功更新 BibTeX")
            } catch {
                errorMessage = "儲存失敗: \(error.localizedDescription)"
                showingError = true
                viewContext.rollback()
            }
        } catch {
            errorMessage = "BibTeX 格式錯誤: \(error.localizedDescription)"
            showingError = true
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.body)
        }
    }
}

struct AttachmentRow: View {
    let attachment: Attachment
    var onDelete: (() -> Void)?

    var body: some View {
        HStack {
            Image(systemName: "doc.fill")
                .foregroundColor(.red)

            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.fileName)
                    .font(.body)

                HStack {
                    Text(attachment.fileSizeFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if attachment.pageCount > 0 {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(attachment.pageCount) 頁")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Button(action: openPDF) {
                Image(systemName: "eye")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .help("查看 PDF")

            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("刪除附件")
            }
        }
        .padding(8)
        .background(Color.overendPaperGray)
        .cornerRadius(4)
    }

    private func openPDF() {
        #if canImport(AppKit)
        NSWorkspace.shared.open(attachment.fileURL)
        #endif
    }
}

// MARK: - Citation Row

struct CitationRow: View {
    let format: String
    let citation: String
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(format)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: {
                    copyToClipboard(citation)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                }) {
                    Label(copied ? "已複製" : "複製", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            
            Text(citation)
                .font(.body)
                .italic()
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.overendPaperGray)
                .cornerRadius(4)
        }
    }
    
    private func copyToClipboard(_ text: String) {
        #if canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}
