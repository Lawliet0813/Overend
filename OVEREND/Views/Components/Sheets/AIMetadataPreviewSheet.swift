//
//  AIMetadataPreviewSheet.swift
//  OVEREND
//
//  AI 提取的 PDF 元數據預覽和確認界面
//

import SwiftUI

/// AI元數據預覽Sheet
struct AIMetadataPreviewSheet: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.dismiss) private var dismiss

    let metadata: PDFMetadata
    let pdfURL: URL
    let onConfirm: (PDFMetadata) -> Void
    let onRetry: () -> Void

    @State private var editedMetadata: PDFMetadata
    @State private var isEditing = false

    init(
        metadata: PDFMetadata,
        pdfURL: URL,
        onConfirm: @escaping (PDFMetadata) -> Void,
        onRetry: @escaping () -> Void
    ) {
        self.metadata = metadata
        self.pdfURL = pdfURL
        self.onConfirm = onConfirm
        self.onRetry = onRetry
        self._editedMetadata = State(initialValue: metadata)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 標題欄
            header

            Divider()

            // 內容區域
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // 可信度指示器
                    confidenceSection

                    // 元數據預覽
                    metadataPreview

                    // 摘要（如果有）
                    if let abstract = editedMetadata.abstract {
                        abstractSection(abstract)
                    }
                }
                .padding(DesignTokens.Spacing.lg)
            }

            Divider()

            // 操作按鈕
            actionButtons
        }
        .frame(width: 600, height: 700)
        .background(theme.background)
    }

    // MARK: - 子視圖

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text("AI 書目提取")
                    .font(.system(size: DesignTokens.Typography.title1, weight: .bold))
                    .foregroundColor(theme.textPrimary)

                Text(pdfURL.lastPathComponent)
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(theme.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            // 編輯按鈕
            IconButton(
                icon: isEditing ? "checkmark.circle.fill" : "pencil.circle",
                action: {
                    isEditing.toggle()
                },
                size: .medium
            )
            .environmentObject(theme)
        }
        .padding(DesignTokens.Spacing.lg)
    }

    private var confidenceSection: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ConfidenceProgressIndicator(confidence: editedMetadata.confidence)
                .environmentObject(theme)

            if editedMetadata.confidence != .high {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: DesignTokens.IconSize.small))
                        .foregroundColor(theme.warning)

                    Text("建議檢查並修正提取的資訊")
                        .font(.system(size: DesignTokens.Typography.caption))
                        .foregroundColor(theme.textMuted)
                }
                .padding(DesignTokens.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                        .fill(theme.warning.opacity(0.1))
                )
            }
        }
    }

    private var metadataPreview: some View {
        CardView {
            VStack(spacing: DesignTokens.Spacing.md) {
                // 標題
                MetadataField(
                    label: "標題",
                    value: $editedMetadata.title,
                    isEditing: isEditing,
                    isRequired: true
                )

                // 作者
                MetadataListField(
                    label: "作者",
                    values: $editedMetadata.authors,
                    isEditing: isEditing,
                    placeholder: "輸入作者名稱"
                )

                Divider()

                // 年份和DOI
                HStack(spacing: DesignTokens.Spacing.md) {
                    MetadataField(
                        label: "年份",
                        value: Binding(
                            get: { editedMetadata.year ?? "" },
                            set: { editedMetadata.year = $0.isEmpty ? nil : $0 }
                        ),
                        isEditing: isEditing
                    )

                    MetadataField(
                        label: "DOI",
                        value: Binding(
                            get: { editedMetadata.doi ?? "" },
                            set: { editedMetadata.doi = $0.isEmpty ? nil : $0 }
                        ),
                        isEditing: isEditing
                    )
                }

                // 期刊
                MetadataField(
                    label: "期刊/會議",
                    value: Binding(
                        get: { editedMetadata.journal ?? "" },
                        set: { editedMetadata.journal = $0.isEmpty ? nil : $0 }
                    ),
                    isEditing: isEditing
                )
            }
        }
        .environmentObject(theme)
    }

    private func abstractSection(_ abstract: String) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("摘要")
                    .font(.system(size: DesignTokens.Typography.caption, weight: .bold))
                    .foregroundColor(theme.textMuted)
                    .textCase(.uppercase)

                if isEditing {
                    TextEditor(text: Binding(
                        get: { editedMetadata.abstract ?? "" },
                        set: { editedMetadata.abstract = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.system(size: DesignTokens.Typography.body))
                    .frame(minHeight: 100)
                    .padding(DesignTokens.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                            .stroke(theme.border, lineWidth: 1)
                    )
                } else {
                    Text(abstract)
                        .font(.system(size: DesignTokens.Typography.body))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(6)
                }
            }
        }
        .environmentObject(theme)
    }

    private var actionButtons: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // 取消按鈕
            SecondaryButton("取消", icon: "xmark") {
                dismiss()
            }
            .environmentObject(theme)

            Spacer()

            // 重試按鈕
            SecondaryButton("重新分析", icon: "arrow.clockwise") {
                onRetry()
                dismiss()
            }
            .environmentObject(theme)

            // 確認按鈕
            PrimaryButton("確認匯入", icon: "checkmark") {
                onConfirm(editedMetadata)
                dismiss()
            }
            .environmentObject(theme)
        }
        .padding(DesignTokens.Spacing.lg)
    }
}

// MARK: - 元數據欄位組件

/// 單個元數據欄位
struct MetadataField: View {
    @EnvironmentObject var theme: AppTheme

    let label: String
    @Binding var value: String
    let isEditing: Bool
    var isRequired: Bool = false
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack(spacing: DesignTokens.Spacing.xxs) {
                Text(label)
                    .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                    .foregroundColor(theme.textMuted)

                if isRequired {
                    Text("*")
                        .foregroundColor(theme.error)
                }
            }

            if isEditing {
                TextField(placeholder.isEmpty ? label : placeholder, text: $value)
                    .textFieldStyle(.plain)
                    .font(.system(size: DesignTokens.Typography.body))
                    .padding(DesignTokens.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                            .stroke(theme.border, lineWidth: 1)
                    )
            } else {
                Text(value.isEmpty ? "未填寫" : value)
                    .font(.system(size: DesignTokens.Typography.body))
                    .foregroundColor(value.isEmpty ? theme.textMuted : theme.textPrimary)
            }
        }
    }
}

/// 列表型元數據欄位（如作者列表）
struct MetadataListField: View {
    @EnvironmentObject var theme: AppTheme

    let label: String
    @Binding var values: [String]
    let isEditing: Bool
    let placeholder: String

    @State private var newValue = ""

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(label)
                .font(.system(size: DesignTokens.Typography.caption, weight: .medium))
                .foregroundColor(theme.textMuted)

            if isEditing {
                VStack(spacing: DesignTokens.Spacing.xs) {
                    ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            TextField(placeholder, text: Binding(
                                get: { values[index] },
                                set: { values[index] = $0 }
                            ))
                            .textFieldStyle(.plain)
                            .font(.system(size: DesignTokens.Typography.body))
                            .padding(DesignTokens.Spacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                    .stroke(theme.border, lineWidth: 1)
                            )

                            Button {
                                values.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(theme.error)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // 添加新作者
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        TextField("添加\(label)", text: $newValue)
                            .textFieldStyle(.plain)
                            .font(.system(size: DesignTokens.Typography.body))
                            .padding(DesignTokens.Spacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                    .stroke(theme.accent.opacity(0.3), lineWidth: 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                            .fill(theme.accent.opacity(0.05))
                                    )
                            )
                            .onSubmit {
                                if !newValue.isEmpty {
                                    values.append(newValue)
                                    newValue = ""
                                }
                            }

                        Button {
                            if !newValue.isEmpty {
                                values.append(newValue)
                                newValue = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(theme.accent)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                if values.isEmpty {
                    Text("未填寫")
                        .font(.system(size: DesignTokens.Typography.body))
                        .foregroundColor(theme.textMuted)
                } else {
                    Text(values.joined(separator: ", "))
                        .font(.system(size: DesignTokens.Typography.body))
                        .foregroundColor(theme.textPrimary)
                }
            }
        }
    }
}

#Preview {
    let theme = AppTheme()
    let sampleMetadata = PDFMetadata(
        title: "Deep Learning for Natural Language Processing",
        authors: ["John Smith", "Jane Doe"],
        year: "2024",
        doi: "10.1234/example.doi",
        abstract: "This paper presents a comprehensive study of deep learning techniques applied to natural language processing tasks. We demonstrate significant improvements over traditional methods...",
        journal: "Journal of AI Research",
        volume: "42",
        pages: "123-145",
        entryType: "article",
        confidence: .high
    )

    return AIMetadataPreviewSheet(
        metadata: sampleMetadata,
        pdfURL: URL(fileURLWithPath: "/example/paper.pdf"),
        onConfirm: { _ in print("Confirmed") },
        onRetry: { print("Retry") }
    )
    .environmentObject(theme)
}
