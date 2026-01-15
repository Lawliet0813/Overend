//
//  EntryDetailSubviews.swift
//  OVEREND
//
//  書目詳情子元件 - 從 ModernEntryDetailView 拆分
//

import SwiftUI
import PDFKit

// MARK: - 區塊標題

struct DetailSectionHeader: View {
    @EnvironmentObject var theme: AppTheme
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text(title)
                .font(.system(size: 16, weight: .bold))
        }
        .foregroundColor(theme.textMuted)
    }
}

// MARK: - 書目資料列

struct DetailMetadataRow: View {
    @EnvironmentObject var theme: AppTheme
    let label: String
    let value: String
    var isLink: Bool = false
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(theme.textMuted)
                .frame(width: 60, alignment: .leading)
            
            if isLink {
                Link(value, destination: URL(string: "https://doi.org/\(value)") ?? URL(string: "https://doi.org")!)
                    .font(.system(size: 14))
                    .foregroundColor(theme.accent)
            } else {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textPrimary)
            }
            
            Spacer()
        }
    }
}

// MARK: - 引用格式卡片

struct DetailCitationCard: View {
    @EnvironmentObject var theme: AppTheme
    let format: String
    let citation: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(format)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.accent)
                
                Spacer()
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(citation, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 15))
                        .foregroundColor(theme.textMuted)
                }
                .buttonStyle(.plain)
                .help("複製引用")
            }
            
            Text(citation)
                .font(.system(size: 15))
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

// MARK: - 附件卡片

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
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text("\(attachment.pageCount) 頁")
                            .font(.system(size: 14))
                            .foregroundColor(theme.textMuted)
                        
                        Text(formatFileSize(attachment.fileSize))
                            .font(.system(size: 14))
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
                    .font(.system(size: 16, weight: .bold))
                
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

// MARK: - PDF 縮圖視圖

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

// MARK: - PDF Kit 視圖

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
