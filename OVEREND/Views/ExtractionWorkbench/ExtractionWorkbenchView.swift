//
//  ExtractionWorkbenchView.swift
//  OVEREND
//
//  AI 提取工作台主視圖
//

import SwiftUI
import CoreData
import PDFKit

/// AI 提取工作台主視圖
struct ExtractionWorkbenchView: View {
    @EnvironmentObject var theme: AppTheme
    @StateObject var viewModel: ExtractionWorkbenchViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 頂部：進度指示（批次模式）
            if viewModel.pendingExtractions.count > 1 {
                ProgressHeader(
                    current: viewModel.currentIndex,
                    total: viewModel.pendingExtractions.count
                )
            } else {
                // 單檔模式標題
                HStack {
                    Text("AI 書目提取確認")
                        .font(.system(size: DesignTokens.Typography.title3, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(theme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(theme.card)
            }
            
            // 主內容區
            if let extraction = viewModel.currentExtraction {
                HSplitView {
                    // 左側：PDF 預覽
                    PDFPreviewPane(pdfURL: viewModel.currentPDF)
                        .frame(minWidth: 300)
                    
                    // 右側：AI 提取結果
                    ExtractionResultPane(
                        extraction: extraction,
                        onCorrect: viewModel.saveCorrection,
                        onRate: viewModel.saveRating
                    )
                    .frame(minWidth: 400)
                }
            } else {
                // 空狀態
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(theme.textMuted)
                    
                    Text("沒有待處理的 PDF")
                        .font(.system(size: DesignTokens.Typography.headline))
                        .foregroundColor(theme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // 底部：操作按鈕
            if viewModel.pendingExtractions.count > 1 {
                ActionBar(
                    hasPrevious: viewModel.currentIndex > 0,
                    hasNext: viewModel.currentIndex < viewModel.pendingExtractions.count - 1,
                    onPrevious: viewModel.previousPDF,
                    onNext: viewModel.nextPDF,
                    onConfirm: {
                        viewModel.confirmAndCreateEntry()
                        if viewModel.isAllCompleted {
                            dismiss()
                        }
                    },
                    onSkip: viewModel.skipCurrent
                )
            } else {
                SimpleActionBar(
                    onConfirm: {
                        viewModel.confirmAndCreateEntry()
                        dismiss()
                    },
                    onCancel: { dismiss() }
                )
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(theme.background)
    }
}

// MARK: - PDF 預覽面板

/// PDF 預覽面板
struct PDFPreviewPane: View {
    let pdfURL: URL?
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(theme.accent)
                Text("PDF 預覽")
                    .font(.system(size: DesignTokens.Typography.subheadline, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(theme.card)
            
            // PDF 視圖
            if let url = pdfURL {
                PDFKitPreview(url: url)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(theme.textMuted)
                    
                    Text("無法載入 PDF")
                        .font(.system(size: DesignTokens.Typography.body))
                        .foregroundColor(theme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.background)
            }
        }
    }
}

/// PDFKit 包裝視圖
struct PDFKitPreview: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.backgroundColor = NSColor.clear
        return pdfView
    }
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let viewModel = ExtractionWorkbenchViewModel(context: context)
    
    return ExtractionWorkbenchView(viewModel: viewModel)
        .environmentObject(AppTheme())
}
