//
//  ExtractionResultPane.swift
//  OVEREND
//
//  AI 提取結果顯示面板
//

import SwiftUI
import CoreData

/// AI 提取結果顯示/編輯面板
struct ExtractionResultPane: View {
    let extraction: ExtractionLog
    let onCorrect: (CorrectionData) -> Void
    let onRate: (Int) -> Void
    
    @EnvironmentObject var theme: AppTheme
    
    @State private var isEditing = false
    @State private var editedData = CorrectionData()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 頂部：提取方法和信心度
                HStack(spacing: 12) {
                    ExtractionMethodBadge(method: extraction.extractionMethod)
                    
                    ConfidenceIndicator(confidence: extraction.confidence)
                    
                    Spacer()
                    
                    // PDF 檔名
                    if let fileName = extraction.pdfFileName {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 12))
                            Text(fileName)
                                .font(.system(size: 12))
                                .lineLimit(1)
                        }
                        .foregroundColor(theme.textMuted)
                    }
                }
                
                Divider()
                
                // 欄位對照表
                VStack(spacing: 16) {
                    FieldRow(
                        label: "標題",
                        aiValue: extraction.aiTitle,
                        correctedValue: $editedData.title,
                        isEditing: isEditing
                    )
                    
                    FieldRow(
                        label: "作者",
                        aiValue: extraction.aiAuthors,
                        correctedValue: $editedData.authors,
                        isEditing: isEditing
                    )
                    
                    HStack(spacing: 16) {
                        FieldRow(
                            label: "年份",
                            aiValue: extraction.aiYear,
                            correctedValue: $editedData.year,
                            isEditing: isEditing
                        )
                        .frame(maxWidth: 120)
                        
                        FieldRow(
                            label: "期刊/會議",
                            aiValue: extraction.aiJournal,
                            correctedValue: $editedData.journal,
                            isEditing: isEditing
                        )
                    }
                    
                    FieldRow(
                        label: "DOI",
                        aiValue: extraction.aiDOI,
                        correctedValue: $editedData.doi,
                        isEditing: isEditing
                    )
                }
                
                Divider()
                
                // 評分區
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI 提取準確度評分")
                        .font(.system(size: DesignTokens.Typography.headline, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    
                    StarRating(rating: $editedData.rating)
                    
                    TextField("備註（可選）", text: $editedData.note)
                        .textFieldStyle(.plain)
                        .font(.system(size: DesignTokens.Typography.body))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                .fill(theme.background)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                        .stroke(theme.border, lineWidth: 1)
                                )
                        )
                }
                
                Divider()
                
                // 操作按鈕
                HStack {
                    if !isEditing {
                        Button {
                            withAnimation(AnimationSystem.Easing.spring) {
                                isEditing = true
                                // 初始化編輯資料
                                editedData = CorrectionData(from: extraction)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "pencil")
                                Text("需要修正")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.warning)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                    .fill(theme.warningBackground)
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            withAnimation(AnimationSystem.Easing.spring) {
                                isEditing = false
                                editedData = CorrectionData()
                            }
                        } label: {
                            Text("取消")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                        .fill(theme.card)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                                .stroke(theme.border, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            onCorrect(editedData)
                            withAnimation(AnimationSystem.Easing.spring) {
                                isEditing = false
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark")
                                Text("儲存修正")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                    .fill(theme.accent)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                }
            }
            .padding(20)
        }
        .background(theme.background)
        .onChange(of: editedData.rating) { _, newRating in
            if newRating > 0 {
                onRate(newRating)
            }
        }
        .onAppear {
            // 載入現有的修正資料
            editedData = CorrectionData(from: extraction)
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let log = ExtractionLog(context: context)
    log.id = UUID()
    log.timestamp = Date()
    log.pdfFileName = "einstein1905.pdf"
    log.extractionMethod = "apple_ai"
    log.aiTitle = "On the Electrodynamics of Moving Bodies"
    log.aiAuthors = "Albert Einstein"
    log.aiYear = "1905"
    log.aiJournal = "Annalen der Physik"
    log.aiDOI = "10.1002/andp.19053221004"
    log.aiConfidence = "high"
    
    return ExtractionResultPane(
        extraction: log,
        onCorrect: { data in print("Corrected: \(data)") },
        onRate: { rating in print("Rated: \(rating)") }
    )
    .frame(width: 450, height: 600)
    .environmentObject(AppTheme())
}
