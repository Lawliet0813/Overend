//
//  ThesisMetadataEditorView.swift
//  OVEREND
//
//  論文元數據編輯視圖 - 動態標籤管理中心
//

import SwiftUI
import SwiftData

/// 論文元數據編輯視圖
struct ThesisMetadataEditorView: View {
    @Bindable var metadata: ThesisMetadata
    @State private var selectedTab: MetadataTab = .basic

    enum MetadataTab: String, CaseIterable {
        case basic = "基本資訊"
        case academic = "學術資訊"
        case abstract = "摘要與關鍵字"
        case acknowledgement = "謝辭"
        case tags = "動態標籤"
    }

    var body: some View {
        VStack(spacing: 0) {
            // 標籤頁選擇器
            Picker("", selection: $selectedTab) {
                ForEach(MetadataTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            // 內容區域
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .basic:
                        basicInfoSection
                    case .academic:
                        academicInfoSection
                    case .abstract:
                        abstractSection
                    case .acknowledgement:
                        acknowledgementSection
                    case .tags:
                        tagsReferenceSection
                    }
                }
                .padding()
            }
        }
        .onChange(of: metadata) { _, _ in
            metadata.touch()
        }
    }

    // MARK: - 基本資訊

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("基本資訊")
                .font(.title2)
                .fontWeight(.bold)

            FormFieldGroup(title: "論文題目") {
                VStack(spacing: 12) {
                    FormTextField(
                        title: "中文題目",
                        text: $metadata.titleChinese,
                        placeholder: "請輸入中文論文題目"
                    )

                    FormTextField(
                        title: "英文題目",
                        text: $metadata.titleEnglish,
                        placeholder: "Enter English Title"
                    )
                }
            }

            FormFieldGroup(title: "作者資訊") {
                VStack(spacing: 12) {
                    FormTextField(
                        title: "中文姓名",
                        text: $metadata.authorChinese,
                        placeholder: "王小明"
                    )

                    FormTextField(
                        title: "英文姓名",
                        text: $metadata.authorEnglish,
                        placeholder: "Wang, Hsiao-Ming"
                    )

                    FormTextField(
                        title: "學號",
                        text: $metadata.studentID,
                        placeholder: "112753001"
                    )
                }
            }

            FormFieldGroup(title: "日期") {
                HStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text("民國年")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("113", value: $metadata.yearROC, format: .number)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading) {
                        Text("西元年")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("2024", value: $metadata.yearAD, format: .number)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading) {
                        Text("月份")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("6", value: $metadata.month, format: .number)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
        }
    }

    // MARK: - 學術資訊

    private var academicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("學術資訊")
                .font(.title2)
                .fontWeight(.bold)

            FormFieldGroup(title: "指導教授") {
                VStack(spacing: 12) {
                    FormTextField(
                        title: "中文姓名",
                        text: $metadata.advisorChinese,
                        placeholder: "李大同"
                    )

                    FormTextField(
                        title: "英文姓名",
                        text: $metadata.advisorEnglish,
                        placeholder: "Lee, Ta-Tung"
                    )

                    Divider()
                        .padding(.vertical, 4)

                    Text("共同指導教授（可選）")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    FormTextField(
                        title: "中文姓名",
                        text: Binding(
                            get: { metadata.coAdvisorChinese ?? "" },
                            set: { metadata.coAdvisorChinese = $0.isEmpty ? nil : $0 }
                        ),
                        placeholder: "可選"
                    )

                    FormTextField(
                        title: "英文姓名",
                        text: Binding(
                            get: { metadata.coAdvisorEnglish ?? "" },
                            set: { metadata.coAdvisorEnglish = $0.isEmpty ? nil : $0 }
                        ),
                        placeholder: "Optional"
                    )
                }
            }

            FormFieldGroup(title: "學校與系所") {
                VStack(spacing: 12) {
                    FormTextField(
                        title: "學校（中文）",
                        text: $metadata.universityChinese,
                        placeholder: "國立政治大學"
                    )

                    FormTextField(
                        title: "學校（英文）",
                        text: $metadata.universityEnglish,
                        placeholder: "National Chengchi University"
                    )

                    FormTextField(
                        title: "系所（中文）",
                        text: $metadata.departmentChinese,
                        placeholder: "資訊科學系"
                    )

                    FormTextField(
                        title: "系所（英文）",
                        text: $metadata.departmentEnglish,
                        placeholder: "Department of Computer Science"
                    )
                }
            }

            FormFieldGroup(title: "學位類型") {
                Picker("", selection: $metadata.degreeType) {
                    ForEach(DegreeType.allCases, id: \.self) { type in
                        Text(type.nameChinese).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - 摘要

    private var abstractSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("摘要與關鍵字")
                .font(.title2)
                .fontWeight(.bold)

            FormFieldGroup(title: "中文摘要") {
                TextEditor(text: $metadata.abstractChinese)
                    .frame(minHeight: 150)
                    .font(.body)
                    .border(Color.secondary.opacity(0.2))
            }

            FormFieldGroup(title: "中文關鍵字") {
                KeywordsEditor(keywords: $metadata.keywordsChinese, language: .chinese)
            }

            Divider()
                .padding(.vertical)

            FormFieldGroup(title: "英文摘要") {
                TextEditor(text: $metadata.abstractEnglish)
                    .frame(minHeight: 150)
                    .font(.body)
                    .border(Color.secondary.opacity(0.2))
            }

            FormFieldGroup(title: "英文關鍵字") {
                KeywordsEditor(keywords: $metadata.keywordsEnglish, language: .english)
            }
        }
    }

    // MARK: - 謝辭

    private var acknowledgementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("謝辭")
                .font(.title2)
                .fontWeight(.bold)

            Text("撰寫您的謝辭內容")
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextEditor(text: $metadata.acknowledgement)
                .frame(minHeight: 300)
                .font(.body)
                .border(Color.secondary.opacity(0.2))
        }
    }

    // MARK: - 動態標籤參考

    private var tagsReferenceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("動態標籤參考")
                .font(.title2)
                .fontWeight(.bold)

            Text("在編輯器中使用 {{標籤名稱}} 來插入動態內容，當元數據更新時會自動同步")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                TagReferenceSection(title: "基本資訊", tags: [
                    ("{{TITLE_CH}}", "中文論文題目"),
                    ("{{TITLE_EN}}", "英文論文題目"),
                    ("{{AUTHOR_CH}}", "中文作者姓名"),
                    ("{{AUTHOR_EN}}", "英文作者姓名"),
                    ("{{STUDENT_ID}}", "學號")
                ])

                TagReferenceSection(title: "指導教授", tags: [
                    ("{{ADVISOR_CH}}", "指導教授（中文）"),
                    ("{{ADVISOR_EN}}", "指導教授（英文）"),
                    ("{{COADVISOR_CH}}", "共同指導（中文）"),
                    ("{{COADVISOR_EN}}", "共同指導（英文）")
                ])

                TagReferenceSection(title: "學校資訊", tags: [
                    ("{{UNIVERSITY_CH}}", "學校名稱（中文）"),
                    ("{{DEPARTMENT_CH}}", "系所名稱（中文）"),
                    ("{{DEGREE_CH}}", "學位類型（中文）"),
                    ("{{DATE_CH}}", "日期（中文格式）")
                ])

                TagReferenceSection(title: "英文資訊", tags: [
                    ("{{UNIVERSITY_EN}}", "學校名稱（英文）"),
                    ("{{DEPARTMENT_EN}}", "系所名稱（英文）"),
                    ("{{DEGREE_EN}}", "學位類型（英文）"),
                    ("{{DATE_EN}}", "日期（英文格式）")
                ])

                TagReferenceSection(title: "摘要與關鍵字", tags: [
                    ("{{ABSTRACT_CH}}", "中文摘要"),
                    ("{{ABSTRACT_EN}}", "英文摘要"),
                    ("{{KEYWORDS_CH}}", "中文關鍵字"),
                    ("{{KEYWORDS_EN}}", "英文關鍵字")
                ])
            }
        }
    }
}

// MARK: - 輔助組件

struct FormFieldGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            content
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct FormTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct KeywordsEditor: View {
    @Binding var keywords: [String]
    let language: Language

    enum Language {
        case chinese
        case english

        var separator: String {
            switch self {
            case .chinese: return "、"
            case .english: return ", "
            }
        }

        var placeholder: String {
            switch self {
            case .chinese: return "輸入關鍵字後按 Return"
            case .english: return "Enter keyword and press Return"
            }
        }
    }

    @State private var newKeyword: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 已有關鍵字
            FlowLayout(spacing: 8) {
                ForEach(keywords.indices, id: \.self) { index in
                    KeywordChip(
                        text: keywords[index],
                        onDelete: {
                            keywords.remove(at: index)
                        }
                    )
                }
            }

            // 新增關鍵字
            TextField(language.placeholder, text: $newKeyword)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    if !newKeyword.isEmpty {
                        keywords.append(newKeyword)
                        newKeyword = ""
                    }
                }
        }
    }
}

struct KeywordChip: View {
    let text: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.2))
        .cornerRadius(12)
    }
}

struct TagReferenceSection: View {
    let title: String
    let tags: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(tags, id: \.0) { tag, description in
                    HStack {
                        Text(tag)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)

                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                }
            }
            .padding(8)
            .background(Color(.textBackgroundColor))
            .cornerRadius(6)
        }
    }
}

// MARK: - 預覽

#Preview {
    ThesisMetadataEditorView(metadata: .preview)
        .frame(width: 700, height: 600)
}
