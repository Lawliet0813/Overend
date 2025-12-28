//
//  ModernEntryDetailView.swift
//  OVEREND
//
//  現代化書目詳情面板 - 右側顯示詳細資訊
//

import SwiftUI
import PDFKit

/// 現代化書目詳情視圖
struct ModernEntryDetailView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var entry: Entry
    var onClose: (() -> Void)?
    
    @State private var showPDFViewer = false
    @State private var selectedAttachment: Attachment?
    
    var body: some View {
        VStack(spacing: 0) {
            // 頂部工具列（含關閉按鈕）
            HStack {
                Text("書目詳情")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button(action: { onClose?() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textMuted)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(theme.itemHover)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(theme.toolbar)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 1)
            }
            
            // 內容
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 標題區
                    headerSection
                    
                    Divider()
                    
                    // 書目資訊
                    metadataSection
                    
                    Divider()
                    
                    // 引用格式
                    citationSection
                    
                    Divider()
                    
                    // PDF 附件（含預覽）
                    attachmentSection
                    
                    Spacer()
                }
                .padding(20)
            }
        }
        .background(theme.sidebar)
        .sheet(isPresented: $showPDFViewer) {
            if let attachment = selectedAttachment {
                PDFViewerSheet(attachment: attachment)
                    .environmentObject(theme)
            }
        }
    }
    
    // MARK: - PDF 預覽區
    
    private func pdfPreviewSection(attachment: Attachment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailSectionHeader(title: "PDF 預覽", icon: "doc.richtext")
            
            // PDF 縮圖
            PDFThumbnailView(url: URL(fileURLWithPath: attachment.filePath))
                .frame(height: 200)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border, lineWidth: 1)
                )
                .onTapGesture {
                    selectedAttachment = attachment
                    showPDFViewer = true
                }
            
            // 開啟按鈕
            Button(action: {
                selectedAttachment = attachment
                showPDFViewer = true
            }) {
                HStack {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                    Text("全螢幕開啟")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.accentLight)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - 標題區
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 類型標籤
            Text(entry.entryType.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(theme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.accentLight)
                )
            
            // 標題
            Text(entry.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            // 作者
            if let author = entry.fields["author"], !author.isEmpty {
                Text(author)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
            }
        }
    }
    
    // MARK: - 書目資訊
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailSectionHeader(title: "書目資訊", icon: "info.circle")
            
            VStack(spacing: 12) {
                if let year = entry.fields["year"], !year.isEmpty {
                    DetailMetadataRow(label: "年份", value: year)
                }
                
                if let journal = entry.fields["journal"], !journal.isEmpty {
                    DetailMetadataRow(label: "期刊", value: journal)
                }
                
                if let volume = entry.fields["volume"], !volume.isEmpty {
                    DetailMetadataRow(label: "卷期", value: volume)
                }
                
                if let pages = entry.fields["pages"], !pages.isEmpty {
                    DetailMetadataRow(label: "頁碼", value: pages)
                }
                
                if let doi = entry.fields["doi"], !doi.isEmpty {
                    DetailMetadataRow(label: "DOI", value: doi, isLink: true)
                }
                
                DetailMetadataRow(label: "引用鍵", value: entry.citationKey)
            }
        }
    }
    
    // MARK: - 引用格式
    
    private var citationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailSectionHeader(title: "引用格式", icon: "quote.bubble")
            
            VStack(spacing: 12) {
                DetailCitationCard(
                    format: "APA 7th",
                    citation: CitationService.generateAPA(entry: entry)
                )
                
                DetailCitationCard(
                    format: "MLA 9th",
                    citation: CitationService.generateMLA(entry: entry)
                )
            }
        }
    }
    
    // MARK: - 附件區
    
    private var attachmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                DetailSectionHeader(title: "附件", icon: "paperclip")
                
                Spacer()
                
                Button(action: importPDF) {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                        .foregroundColor(theme.accent)
                }
                .buttonStyle(.plain)
            }
            
            if entry.attachmentArray.isEmpty {
                Text("尚未添加附件")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(entry.attachmentArray, id: \.id) { attachment in
                        DetailAttachmentCard(attachment: attachment) {
                            selectedAttachment = attachment
                            showPDFViewer = true
                        }
                        .environmentObject(theme)
                    }
                }
                
                // PDF 預覽（在附件卡片下方）
                if let firstAttachment = entry.attachmentArray.first {
                    Divider()
                        .padding(.vertical, 8)
                    
                    pdfPreviewSection(attachment: firstAttachment)
                }
            }
        }
    }
    
    // MARK: - 方法
    
    private func importPDF() {
        PDFService.selectPDFFile { url in
            guard let url = url else { return }
            
            do {
                try PDFService.addPDFAttachment(from: url, to: entry, context: viewContext)
            } catch {
                print("添加 PDF 失敗：\(error)")
            }
        }
    }
}

// MARK: - 子元件

struct DetailSectionHeader: View {
    @EnvironmentObject var theme: AppTheme
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(title)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(theme.textMuted)
    }
}

struct DetailMetadataRow: View {
    @EnvironmentObject var theme: AppTheme
    let label: String
    let value: String
    var isLink: Bool = false
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(theme.textMuted)
                .frame(width: 60, alignment: .leading)
            
            if isLink {
                Link(value, destination: URL(string: "https://doi.org/\(value)") ?? URL(string: "https://doi.org")!)
                    .font(.system(size: 12))
                    .foregroundColor(theme.accent)
            } else {
                Text(value)
                    .font(.system(size: 12))
                    .foregroundColor(theme.textPrimary)
            }
            
            Spacer()
        }
    }
}

struct DetailCitationCard: View {
    @EnvironmentObject var theme: AppTheme
    let format: String
    let citation: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(format)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(theme.accent)
                
                Spacer()
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(citation, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
                .help("複製引用")
            }
            
            Text(citation)
                .font(.system(size: 11))
                .foregroundColor(theme.textPrimary)
                .lineLimit(4)
                .textSelection(.enabled)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border, lineWidth: 1)
                )
        )
    }
}

struct DetailAttachmentCard: View {
    @EnvironmentObject var theme: AppTheme
    let attachment: Attachment
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // PDF 圖標
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "doc.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                }
                
                // 資訊
                VStack(alignment: .leading, spacing: 4) {
                    Text(attachment.fileName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text("\(attachment.pageCount) 頁")
                            .font(.system(size: 10))
                            .foregroundColor(theme.textMuted)
                        
                        Text(formatFileSize(attachment.fileSize))
                            .font(.system(size: 10))
                            .foregroundColor(theme.textMuted)
                    }
                }
                
                Spacer()
                
                if isHovered {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 14))
                        .foregroundColor(theme.accent)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? theme.accentLight : theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isHovered ? theme.accent : theme.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let kb = Double(size) / 1024
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        } else {
            return String(format: "%.1f MB", kb / 1024)
        }
    }
}

// MARK: - PDF 檢視器

struct PDFViewerSheet: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    let attachment: Attachment
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            HStack {
                Text(attachment.fileName)
                    .font(.system(size: 14, weight: .bold))
                
                Spacer()
                
                Button("關閉") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
            .background(theme.toolbar)
            
            // PDF 內容
            PDFKitView(url: URL(fileURLWithPath: attachment.filePath))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 800, height: 600)
    }
}

/// PDF 縮圖視圖
struct PDFThumbnailView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.white.cgColor
        
        if let document = PDFDocument(url: url),
           let page = document.page(at: 0) {
            let thumbnail = page.thumbnail(of: CGSize(width: 320, height: 400), for: .artBox)
            let imageView = NSImageView()
            imageView.image = thumbnail
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            containerView.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            ])
        }
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // 更新縮圖
    }
}

struct PDFKitView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document?.documentURL != url {
            nsView.document = PDFDocument(url: url)
        }
    }
}

#Preview {
    let theme = AppTheme()
    let context = PersistenceController.preview.container.viewContext
    
    let library = Library(context: context)
    library.id = UUID()
    library.name = "Test"
    
    let entry = Entry(context: context)
    entry.id = UUID()
    entry.citationKey = "test2024"
    entry.entryType = "article"
    entry.fields = [
        "title": "測試論文標題",
        "author": "張三 and 李四",
        "year": "2024",
        "journal": "測試期刊"
    ]
    entry.bibtexRaw = "@article{test2024}"
    entry.library = library
    
    return ModernEntryDetailView(entry: entry)
        .environmentObject(theme)
        .environment(\.managedObjectContext, context)
        .frame(width: 320, height: 600)
}
