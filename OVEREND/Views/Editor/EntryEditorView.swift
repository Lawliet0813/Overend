//
//  EntryEditorView.swift
//  OVEREND
//
//  書目編輯器 - 創建或編輯書目
//

import SwiftUI
import CoreData

struct EntryEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let library: Library
    let entryToEdit: Entry?
    
    // 表單狀態
    @State private var entryType: String = "article"
    @State private var citationKey: String = ""
    @State private var title: String = ""
    @State private var author: String = ""
    @State private var year: String = ""
    @State private var journal: String = ""
    @State private var publisher: String = ""
    @State private var booktitle: String = ""
    @State private var otherFields: [FieldItem] = []
    
    // 論文特定狀態
    @State private var isThesisPublished: Bool = false
    
    // 錯誤處理
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // 書目類型（學術術語）
    // 書目類型（基於 APA 7th）
    let entryTypes: [(label: String, value: String)] = [
        ("期刊文章 (Journal Article)", "article"),
        ("圖書 (Book)", "book"),
        ("書籍章節 (Book Chapter)", "incollection"),
        ("研究報告 (Report)", "techreport"),
        ("研討會論文 (Conference Paper)", "inproceedings"),
        ("博士論文 (Doctoral Dissertation)", "phdthesis"),
        ("碩士論文 (Master's Thesis)", "mastersthesis"),
        ("網頁 (Webpage)", "misc")
    ]
    
    init(library: Library, entry: Entry? = nil) {
        self.library = library
        self.entryToEdit = entry
    }
    
    var body: some View {
        Form {
            Section("基本資訊") {
                Picker("類型", selection: $entryType) {
                    ForEach(entryTypes, id: \.value) { type in
                        Text(type.label).tag(type.value)
                    }
                }
                
                TextField("引用鍵 (如：chen2023)", text: $citationKey)
                
                // 自動生成 Key 按鈕
                if citationKey.isEmpty && !author.isEmpty && !year.isEmpty {
                    Button("自動生成 Key") {
                        citationKey = BibTeXGenerator.generateCitationKey(
                            author: author,
                            year: year,
                            title: title
                        )
                    }
                    .font(.caption)
                }
            }
            
            Section("核心字段") {
                TextField("標題 (Title)", text: $title)
                TextField("作者 (Author)", text: $author)
                TextField("年份 (Year)", text: $year)
                
                if entryType == "article" {
                    TextField("期刊 (Journal)", text: $journal)
                } else if entryType == "book" {
                    TextField("出版社 (Publisher)", text: $publisher)
                } else if entryType == "incollection" {
                    TextField("書名 (Book Title)", text: $booktitle)
                    TextField("出版社 (Publisher)", text: $publisher)
                } else if entryType == "inproceedings" {
                    TextField("會議名稱 (Conference Name)", text: $booktitle)
                } else if entryType == "techreport" {
                    TextField("機構 (Institution)", text: $publisher)
                } else if entryType == "phdthesis" || entryType == "mastersthesis" {
                    Toggle("已出版 (Published)", isOn: $isThesisPublished)
                    
                    TextField("學校 (School)", text: $publisher) // 映射到 school
                    
                    if isThesisPublished {
                        TextField("資料庫/出版社 (Database/Publisher)", text: $journal) // 借用 journal 存儲資料庫名，或使用 note
                    }
                }
            }
            
            Section("其他字段") {
                ForEach($otherFields) { $field in
                    HStack {
                        TextField("字段名", text: $field.key)
                            .frame(width: 100)
                        Divider()
                        TextField("內容", text: $field.value)
                        
                        Button(action: {
                            if let index = otherFields.firstIndex(where: { $0.id == field.id }) {
                                otherFields.remove(at: index)
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Button(action: {
                    otherFields.append(FieldItem(key: "", value: ""))
                }) {
                    Label("添加字段", systemImage: "plus")
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 500)
        .padding()
        .navigationTitle(entryToEdit == nil ? "新建書目" : "編輯書目")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") {
                    saveEntry()
                }
                .disabled(citationKey.isEmpty || title.isEmpty)
            }
        }
        .onAppear {
            if let entry = entryToEdit {
                loadEntry(entry)
            }
        }
        .alert("錯誤", isPresented: $showingError) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - 邏輯處理
    
    private func loadEntry(_ entry: Entry) {
        entryType = entry.entryType
        citationKey = entry.citationKey
        
        let fields = entry.fields
        title = fields["title"] ?? ""
        author = fields["author"] ?? ""
        year = fields["year"] ?? ""
        journal = fields["journal"] ?? ""
        publisher = fields["publisher"] ?? ""
        booktitle = fields["booktitle"] ?? ""
        
        // 對於 thesis 和 report，publisher 字段可能存儲 school 或 institution
        if publisher.isEmpty {
            publisher = fields["school"] ?? fields["institution"] ?? ""
        }
        
        // 判斷論文是否已出版
        if entryType == "phdthesis" || entryType == "mastersthesis" {
            let typeField = fields["type"] ?? ""
            // 如果 type 包含 "Unpublished"，則為未出版
            // 如果 type 包含 "Doctoral" 或 "Master" 但不含 "Unpublished"，則視為已出版
            if typeField.lowercased().contains("unpublished") {
                isThesisPublished = false
            } else {
                // 默認情況，如果有資料庫名稱（存於 journal 或 note），則可能已出版
                // 這裡簡單默認為 false，除非明確標記
                isThesisPublished = !typeField.isEmpty && !typeField.lowercased().contains("unpublished")
            }
            
            // 如果是已出版，嘗試從 journal 讀取資料庫名稱
            if isThesisPublished {
                journal = fields["journal"] ?? ""
            }
        }
        
        // 載入其他字段
        let standardKeys = ["title", "author", "year", "journal", "publisher", "booktitle"]
        otherFields = fields
            .filter { !standardKeys.contains($0.key) }
            .map { FieldItem(key: $0.key, value: $0.value) }
            .sorted { $0.key < $1.key }
    }
    
    private func saveEntry() {
        // 1. 收集所有字段
        var fields: [String: String] = [:]
        
        if !title.isEmpty { fields["title"] = title }
        if !author.isEmpty { fields["author"] = author }
        if !year.isEmpty { fields["year"] = year }
        
        if entryType == "article" && !journal.isEmpty { fields["journal"] = journal }
        if (entryType == "book" || entryType == "incollection") && !publisher.isEmpty { fields["publisher"] = publisher }
        if (entryType == "inproceedings" || entryType == "incollection") && !booktitle.isEmpty { fields["booktitle"] = booktitle }
        if entryType == "techreport" && !publisher.isEmpty { fields["institution"] = publisher }
        if (entryType == "phdthesis" || entryType == "mastersthesis") {
            if !publisher.isEmpty { fields["school"] = publisher }
            
            // 處理論文類型字串
            let isPhD = entryType == "phdthesis"
            if isThesisPublished {
                fields["type"] = isPhD ? "Doctoral dissertation" : "Master's thesis"
                if !journal.isEmpty { fields["journal"] = journal } // 存儲資料庫名稱
            } else {
                fields["type"] = isPhD ? "Unpublished doctoral dissertation" : "Unpublished master's thesis"
            }
        }
        
        for item in otherFields where !item.key.isEmpty {
            fields[item.key] = item.value
        }
        
        // 2. 驗證 Key 唯一性 (如果是新建或修改了 Key)
        if entryToEdit?.citationKey != citationKey {
            let uniqueKey = BibTeXGenerator.ensureUniqueCitationKey(citationKey, in: viewContext)
            if uniqueKey != citationKey {
                // 如果 Key 已存在，自動添加後綴
                citationKey = uniqueKey
            }
        }
        
        // 3. 保存
        viewContext.performAndWait {
            if let entry = entryToEdit {
                // 更新現有書目
                entry.citationKey = citationKey
                entry.entryType = entryType
                entry.updateFields(fields)
            } else {
                // 創建新書目
                _ = Entry(
                    context: viewContext,
                    citationKey: citationKey,
                    entryType: entryType,
                    fields: fields,
                    library: library
                )
            }
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                errorMessage = "保存失敗: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
}

// 輔助結構：用於列表編輯
struct FieldItem: Identifiable {
    let id = UUID()
    var key: String
    var value: String
}
