//
//  ModernEntryDetailView+Sections.swift
//  OVEREND
//
//  書目詳情視圖區塊 - 從 ModernEntryDetailView 拆分
//  包含：AI 分析區、標籤區、標題區、書目資訊區、引用格式區、附件區
//

import SwiftUI
import PDFKit

// MARK: - AI 智慧分析區

@available(macOS 26.0, *)
extension ModernEntryDetailView {
    
    var aiSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                DetailSectionHeader(title: "AI 智慧分析", icon: "apple.intelligence")
                
                Spacer()
            }
            
            // AI 摘要
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("摘要")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.textMuted)
                    
                    Spacer()
                    
                    Button(action: generateSummary) {
                        if isGeneratingSummary {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Label("生成", systemImage: "sparkles")
                                .font(.system(size: 14))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .disabled(isGeneratingSummary)
                }
                
                if aiSummary.isEmpty {
                    Text("點擊「生成」讓 AI 自動摘要此文獻")
                        .font(.system(size: 15))
                        .foregroundColor(theme.textMuted)
                        .italic()
                } else {
                    Text(aiSummary)
                        .font(.system(size: 15))
                        .foregroundColor(theme.textPrimary)
                        .textSelection(.enabled)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.accentLight.opacity(0.5))
            )
            
            // AI 關鍵詞
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("關鍵詞")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.textMuted)
                    
                    Spacer()
                    
                    Button(action: extractKeywords) {
                        if isExtractingKeywords {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Label("提取", systemImage: "tag")
                                .font(.system(size: 14))
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .disabled(isExtractingKeywords)
                }
                
                if aiKeywords.isEmpty {
                    Text("點擊「提取」讓 AI 自動識別關鍵詞")
                        .font(.system(size: 15))
                        .foregroundColor(theme.textMuted)
                        .italic()
                } else {
                    FlowLayout(spacing: 6) {
                        ForEach(aiKeywords, id: \.self) { keyword in
                            Text(keyword)
                                .font(.system(size: 14))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(theme.accent.opacity(0.2))
                                )
                                .foregroundColor(theme.accent)
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.accentLight.opacity(0.5))
            )
        }
    }
}

// MARK: - 標籤管理區

@available(macOS 26.0, *)
extension ModernEntryDetailView {
    
    var tagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                DetailSectionHeader(title: "標籤", icon: "tag")
                
                Spacer()
                
                Button(action: { showSmartTagSuggestion = true }) {
                    Label("AI 建議", systemImage: "sparkles")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .tint(.purple)
                .popover(isPresented: $showSmartTagSuggestion) {
                    SmartTagSuggestionView(
                        entryTitle: entry.title,
                        onAccept: { tags in
                            addSuggestedTags(tags)
                            showSmartTagSuggestion = false
                        },
                        onCancel: {
                            showSmartTagSuggestion = false
                        }
                    )
                }
                
                Button(action: { isAddingTag = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .popover(isPresented: $isAddingTag) {
                    tagAddingPopover
                }
            }
            
            if let tags = entry.tags as? Set<Tag>, !tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(Array(tags).sorted(by: { $0.name < $1.name })) { tag in
                        HStack(spacing: 4) {
                            Text(tag.name)
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                            
                            Button(action: {
                                removeTag(tag)
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(tag.color)
                        .cornerRadius(4)
                    }
                }
            } else {
                Text("尚無標籤")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
                    .italic()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.sidebar.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border.opacity(0.5), lineWidth: 1)
                )
        )
    }
    
    private var tagAddingPopover: some View {
        VStack(spacing: 12) {
            TextField("搜尋或建立標籤", text: $newTagSearchText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    // 顯示現有標籤（過濾後）
                    let allTags = (entry.library?.tags as? Set<Tag> ?? [])
                        .sorted { $0.name < $1.name }
                        .filter { tag in
                            newTagSearchText.isEmpty || tag.name.localizedCaseInsensitiveContains(newTagSearchText)
                        }
                    
                    ForEach(allTags) { tag in
                        Button(action: {
                            toggleTag(tag)
                        }) {
                            HStack {
                                Circle()
                                    .fill(tag.color)
                                    .frame(width: 8, height: 8)
                                Text(tag.name)
                                Spacer()
                                if (entry.tags as? Set<Tag>)?.contains(tag) == true {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // 如果搜尋文字不為空且沒有完全匹配的標籤，顯示建立選項
                    if !newTagSearchText.isEmpty && !allTags.contains(where: { $0.name.caseInsensitiveCompare(newTagSearchText) == .orderedSame }) {
                        Divider()
                        Button(action: {
                            createNewTag(name: newTagSearchText)
                        }) {
                            Label("建立 \"\(newTagSearchText)\"", systemImage: "plus.circle")
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(height: 150)
        }
        .padding()
    }
}

// MARK: - 標題區

@available(macOS 26.0, *)
extension ModernEntryDetailView {
    
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 類型標籤
            Text(entry.entryType.uppercased())
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(theme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.accentLight)
                )
            
            // 標題
            if isEditMode {
                EditableMetadataRow(
                    label: "標題",
                    value: $editedTitle,
                    isRequired: true,
                    placeholder: "請輸入標題"
                )
                .environmentObject(theme)
            } else {
                Text(entry.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // 作者
            if isEditMode {
                EditableMetadataRow(
                    label: "作者",
                    value: Binding(
                        get: { editedFields["author"] ?? "" },
                        set: { editedFields["author"] = $0; hasUnsavedChanges = true }
                    ),
                    placeholder: "請輸入作者",
                    hint: "建議格式：Last, F. & Last, F."
                )
                .environmentObject(theme)
            } else if let author = entry.fields["author"], !author.isEmpty {
                Text(author)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
            }
        }
    }
}

// MARK: - 書目資訊區

@available(macOS 26.0, *)
extension ModernEntryDetailView {
    
    var metadataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailSectionHeader(title: "書目資訊", icon: "info.circle")
            
            if isEditMode {
                metadataEditSection
            } else {
                metadataViewSection
            }
        }
    }
    
    private var metadataEditSection: some View {
        VStack(spacing: 16) {
            EditableMetadataRow(
                label: "年份",
                value: Binding(
                    get: { editedFields["year"] ?? "" },
                    set: { editedFields["year"] = $0; hasUnsavedChanges = true }
                ),
                isRequired: false,
                placeholder: "YYYY",
                validator: { value in
                    if value.isEmpty { return (true, nil) }
                    if let year = Int(value), year >= 1900 && year <= 2100 {
                        return (true, nil)
                    }
                    return (false, "請輸入有效年份（1900-2100）")
                }
            )
            .environmentObject(theme)
            
            EditableMetadataRow(
                label: "期刊",
                value: Binding(
                    get: { editedFields["journal"] ?? "" },
                    set: { editedFields["journal"] = $0; hasUnsavedChanges = true }
                ),
                placeholder: "請輸入期刊名稱"
            )
            .environmentObject(theme)
            
            EditableMetadataRow(
                label: "卷期",
                value: Binding(
                    get: { editedFields["volume"] ?? "" },
                    set: { editedFields["volume"] = $0; hasUnsavedChanges = true }
                ),
                placeholder: "如：Vol. 12, No. 3"
            )
            .environmentObject(theme)
            
            EditableMetadataRow(
                label: "頁碼",
                value: Binding(
                    get: { editedFields["pages"] ?? "" },
                    set: { editedFields["pages"] = $0; hasUnsavedChanges = true }
                ),
                placeholder: "如：123-145"
            )
            .environmentObject(theme)
            
            EditableMetadataRow(
                label: "DOI",
                value: Binding(
                    get: { editedFields["doi"] ?? "" },
                    set: { editedFields["doi"] = $0; hasUnsavedChanges = true }
                ),
                placeholder: "如：10.1234/example"
            )
            .environmentObject(theme)
            
            EditableMetadataRow(
                label: "摘要 (abstract)",
                value: Binding(
                    get: { editedFields["abstract"] ?? "" },
                    set: { editedFields["abstract"] = $0; hasUnsavedChanges = true }
                ),
                isMultiline: true,
                placeholder: "請輸入摘要"
            )
            .environmentObject(theme)
            
            // 書籍/會議相關
            EditableMetadataRow(
                label: "出版社 (publisher)",
                value: Binding(
                    get: { editedFields["publisher"] ?? "" },
                    set: { editedFields["publisher"] = $0; hasUnsavedChanges = true }
                ),
                placeholder: "出版社名稱"
            )
            .environmentObject(theme)
            
            EditableMetadataRow(
                label: "書名/會議名 (booktitle)",
                value: Binding(
                    get: { editedFields["booktitle"] ?? "" },
                    set: { editedFields["booktitle"] = $0; hasUnsavedChanges = true }
                ),
                placeholder: "收錄該文章的書籍或會議名稱"
            )
            .environmentObject(theme)
            
            // 碩博士論文相關
            EditableMetadataRow(
                label: "學校 (school)",
                value: Binding(
                    get: { editedFields["school"] ?? "" },
                    set: { editedFields["school"] = $0; hasUnsavedChanges = true }
                ),
                placeholder: "授予學位的學校"
            )
            .environmentObject(theme)
            
            EditableMetadataRow(
                label: "指導教授 (advisor)",
                value: Binding(
                    get: { editedFields["advisor"] ?? "" },
                    set: { editedFields["advisor"] = $0; hasUnsavedChanges = true }
                ),
                placeholder: "指導教授姓名"
            )
            .environmentObject(theme)
            
            EditableMetadataRow(
                label: "科系 (department)",
                value: Binding(
                    get: { editedFields["department"] ?? "" },
                    set: { editedFields["department"] = $0; hasUnsavedChanges = true }
                ),
                placeholder: "研究所/科系名稱"
            )
            .environmentObject(theme)
            
            // 識別碼
            EditableMetadataRow(
                label: "網址 (url)",
                value: Binding(
                    get: { editedFields["url"] ?? "" },
                    set: { editedFields["url"] = $0; hasUnsavedChanges = true }
                ),
                placeholder: "https://..."
            )
            .environmentObject(theme)
            
            EditableMetadataRow(
                label: "關鍵詞 (keywords)",
                value: Binding(
                    get: { editedFields["keywords"] ?? "" },
                    set: { editedFields["keywords"] = $0; hasUnsavedChanges = true }
                ),
                placeholder: "以逗號分隔"
            )
            .environmentObject(theme)
        }
    }
    
    private var metadataViewSection: some View {
        VStack(spacing: 12) {
            if let year = entry.fields["year"], !year.isEmpty {
                DetailMetadataRow(label: "年份 (year)", value: year)
            }
            
            if let journal = entry.fields["journal"], !journal.isEmpty {
                DetailMetadataRow(label: "期刊 (journal)", value: journal)
            }
            
            if let volume = entry.fields["volume"], !volume.isEmpty {
                DetailMetadataRow(label: "卷期 (volume)", value: volume)
            }
            
            if let pages = entry.fields["pages"], !pages.isEmpty {
                DetailMetadataRow(label: "頁碼 (pages)", value: pages)
            }
            
            if let doi = entry.fields["doi"], !doi.isEmpty {
                DetailMetadataRow(label: "DOI", value: doi, isLink: true)
            }
            
            // 碩博論文相關欄位顯示
            if let school = entry.fields["school"], !school.isEmpty {
                DetailMetadataRow(label: "學校 (school)", value: school)
            }
            
            if let advisor = entry.fields["advisor"], !advisor.isEmpty {
                DetailMetadataRow(label: "指導教授 (advisor)", value: advisor)
            }
            
            if let booktitle = entry.fields["booktitle"], !booktitle.isEmpty {
                DetailMetadataRow(label: "書名/會議 (booktitle)", value: booktitle)
            }
            
            if let publisher = entry.fields["publisher"], !publisher.isEmpty {
                DetailMetadataRow(label: "出版社 (publisher)", value: publisher)
            }
            
            if let url = entry.fields["url"], !url.isEmpty {
                DetailMetadataRow(label: "網址 (url)", value: url, isLink: true)
            }
            
            DetailMetadataRow(label: "引用鍵 (citation key)", value: entry.citationKey)
            
            DetailMetadataRow(label: "書目類型 (entry type)", value: Constants.BibTeX.displayName(for: entry.entryType))
        }
    }
}

// MARK: - 引用格式區

@available(macOS 26.0, *)
extension ModernEntryDetailView {
    
    var citationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                DetailSectionHeader(title: "引用格式", icon: "quote.bubble")
                
                if isEditMode {
                    Text("（預覽）")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textMuted)
                }
            }
            
            VStack(spacing: 12) {
                if isEditMode {
                    // 編輯模式：使用 editedFields 生成預覽
                    DetailCitationCard(
                        format: "APA 7th",
                        citation: generateAPAPreview()
                    )
                    
                    DetailCitationCard(
                        format: "MLA 9th",
                        citation: generateMLAPreview()
                    )
                } else {
                    // 查看模式：使用 entry 資料
                    DetailCitationCard(
                        format: "APA 7th",
                        citation: CitationService.shared.generateAPA(entry: entry)
                    )
                    
                    DetailCitationCard(
                        format: "MLA 9th",
                        citation: CitationService.shared.generateMLA(entry: entry)
                    )
                }
            }
        }
    }
}

// MARK: - 附件區

@available(macOS 26.0, *)
extension ModernEntryDetailView {
    
    var attachmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                DetailSectionHeader(title: "附件", icon: "paperclip")
                
                Spacer()
                
                Button(action: importPDF) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                        .foregroundColor(theme.accent)
                }
                .buttonStyle(.plain)
            }
            
            if entry.attachmentArray.isEmpty {
                Text("尚未添加附件")
                    .font(.system(size: 14))
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
            }
        }
    }
}
