//
//  SimplifiedEntryDetailView.swift
//  OVEREND
//
//  簡化版書目詳情視圖 - 適用於 macOS 26.0 以下
//

import SwiftUI
import CoreData

/// 簡化版書目詳情視圖（不使用 Apple Intelligence）
struct SimplifiedEntryDetailView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var entry: Entry
    var onClose: (() -> Void)?

    @State private var showPDFViewer = false
    @State private var selectedAttachment: Attachment?
    @State private var isEditMode: Bool = false
    @State private var editedFields: [String: String] = [:]

    var body: some View {
        VStack(spacing: 0) {
            // 頂部工具列
            header

            Divider()

            // 內容區域
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 基本資訊
                    basicInfoSection

                    Divider()

                    // 詳細欄位
                    fieldsSection

                    Divider()

                    // 附件
                    if !entry.attachmentArray.isEmpty {
                        attachmentsSection
                        Divider()
                    }

                    // 標籤
                    if let tags = entry.tags as? Set<Tag>, !tags.isEmpty {
                        tagsSection
                        Divider()
                    }

                    // 筆記
                    notesSection
                }
                .padding(16)
            }
        }
        .background(theme.background)
    }

    // MARK: - 頂部工具列

    private var header: some View {
        HStack {
            Text(isEditMode ? "編輯書目" : "書目詳情")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(theme.textPrimary)

            Spacer()

            if isEditMode {
                Button("取消") {
                    cancelEdit()
                }
                .buttonStyle(.plain)
                .foregroundColor(theme.textMuted)

                Button("儲存") {
                    saveChanges()
                }
                .buttonStyle(.plain)
                .foregroundColor(theme.accent)
            } else {
                Button(action: {
                    enterEditMode()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("編輯")
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(theme.accent)
            }

            if let onClose = onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(theme.textMuted)
            }
        }
        .padding(16)
        .background(theme.card)
    }

    // MARK: - 基本資訊

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 標題
            if isEditMode {
                VStack(alignment: .leading, spacing: 4) {
                    Text("標題 *")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textMuted)
                    TextField("請輸入標題", text: binding(for: "title"))
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, weight: .bold))
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.background)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(theme.border, lineWidth: 1)
                                )
                        )
                }
            } else {
                Text(entry.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 類型和引用鍵
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 12))
                    Text(entry.entryType)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(theme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.accentLight)
                )

                HStack(spacing: 4) {
                    Image(systemName: "key")
                        .font(.system(size: 12))
                    Text(entry.citationKey)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(theme.textMuted)
            }
        }
    }

    // MARK: - 詳細欄位

    private var fieldsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("詳細資訊")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(theme.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                if let author = entry.fields["author"], !author.isEmpty {
                    metadataRow(label: "作者", value: author, key: "author")
                }

                if let year = entry.fields["year"], !year.isEmpty {
                    metadataRow(label: "年份", value: year, key: "year")
                }

                if let journal = entry.fields["journal"], !journal.isEmpty {
                    metadataRow(label: "期刊", value: journal, key: "journal")
                }

                if let publisher = entry.fields["publisher"], !publisher.isEmpty {
                    metadataRow(label: "出版社", value: publisher, key: "publisher")
                }

                if let doi = entry.fields["doi"], !doi.isEmpty {
                    metadataRow(label: "DOI", value: doi, key: "doi")
                }

                if let url = entry.fields["url"], !url.isEmpty {
                    metadataRow(label: "URL", value: url, key: "url")
                }
            }
        }
    }

    private func metadataRow(label: String, value: String, key: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.textMuted)

            if isEditMode {
                TextField("請輸入\(label)", text: binding(for: key))
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(theme.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(theme.border, lineWidth: 1)
                            )
                    )
            } else {
                Text(value)
                    .font(.system(size: 13))
                    .foregroundColor(theme.textPrimary)
                    .textSelection(.enabled)
            }
        }
    }

    // MARK: - 附件

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("附件")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(theme.textPrimary)

            VStack(spacing: 8) {
                ForEach(entry.attachmentArray) { attachment in
                    Button(action: {
                        NSWorkspace.shared.open(attachment.fileURL)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "paperclip")
                                .font(.system(size: 16))
                                .foregroundColor(theme.accent)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(attachment.fileName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(theme.textPrimary)

                                Text(formatFileSize(attachment.fileSize))
                                    .font(.system(size: 11))
                                    .foregroundColor(theme.textMuted)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(theme.textMuted)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.background)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 標籤

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("標籤")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(theme.textPrimary)

            if let tags = entry.tags as? Set<Tag>, !tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(Array(tags).sorted(by: { $0.name < $1.name })) { tag in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(tag.color)
                                .frame(width: 8, height: 8)
                            Text(tag.name)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(theme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.background)
                        )
                    }
                }
            }
        }
    }

    // MARK: - 筆記

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("筆記")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(theme.textPrimary)

            if isEditMode {
                TextEditor(text: Binding(
                    get: { entry.userNotes ?? "" },
                    set: { editedFields["notes"] = $0 }
                ))
                .font(.system(size: 13))
                .frame(minHeight: 100)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(theme.border, lineWidth: 1)
                        )
                )
            } else {
                Text(entry.userNotes ?? "尚無筆記")
                    .font(.system(size: 13))
                    .foregroundColor(entry.userNotes == nil ? theme.textMuted : theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - 編輯模式

    private func enterEditMode() {
        editedFields = entry.fields
        isEditMode = true
    }

    private func cancelEdit() {
        editedFields = [:]
        isEditMode = false
    }

    private func saveChanges() {
        // 更新字段
        entry.fields = editedFields

        // 更新筆記
        if let notes = editedFields["notes"] {
            entry.userNotes = notes.isEmpty ? nil : notes
        }

        // 重新生成 BibTeX
        entry.bibtexRaw = entry.generateBibTeX()
        entry.updatedAt = Date()

        // 保存到 Core Data
        do {
            try viewContext.save()
            isEditMode = false
            ToastManager.shared.showSuccess("已儲存變更")
        } catch {
            ToastManager.shared.showError("儲存失敗：\(error.localizedDescription)")
        }
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { editedFields[key] ?? "" },
            set: { editedFields[key] = $0 }
        )
    }

    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}
