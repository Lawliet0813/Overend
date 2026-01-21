//
//  EntryEditSheet.swift
//  OVEREND
//
//  編輯書目資訊表單
//

import SwiftUI
import CoreData

struct EntryEditSheet: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var entry: Entry
    
    // 編輯欄位
    @State private var editedTitle: String = ""
    @State private var editedAuthor: String = ""
    @State private var editedYear: String = ""
    @State private var editedEntryType: String = ""
    @State private var editedCitationKey: String = ""
    @State private var editedJournal: String = ""
    @State private var editedDOI: String = ""
    @State private var editedAbstract: String = ""
    @State private var editedPublisher: String = ""
    @State private var editedURL: String = ""
    
    var onSave: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            HStack {
                Button("取消") {
                    dismiss()
                }
                .foregroundColor(theme.textSecondary)
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Text("編輯書目")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button("儲存") {
                    saveChanges()
                }
                .foregroundColor(theme.accent)
                .fontWeight(.semibold)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
            .background(theme.toolbar)
            
            Divider()
            
            // 編輯表單
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 基本資訊
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            EditField(label: "標題", text: $editedTitle, placeholder: "文獻標題")
                            EditField(label: "作者", text: $editedAuthor, placeholder: "作者（多位以 and 分隔）")
                            
                            HStack(spacing: 16) {
                                EditField(label: "年份", text: $editedYear, placeholder: "2024")
                                    .frame(width: 100)
                                EditField(label: "類型", text: $editedEntryType, placeholder: "article")
                                    .frame(width: 150)
                            }
                            
                            EditField(label: "引用鍵", text: $editedCitationKey, placeholder: "author2024title")
                        }
                        .padding()
                    } label: {
                        Label("基本資訊", systemImage: "doc.text")
                            .foregroundColor(theme.textPrimary)
                    }
                    
                    // 出版資訊
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            EditField(label: "期刊/來源", text: $editedJournal, placeholder: "期刊名稱")
                            EditField(label: "出版者", text: $editedPublisher, placeholder: "出版社")
                            EditField(label: "DOI", text: $editedDOI, placeholder: "10.xxxx/xxxxx")
                            EditField(label: "URL", text: $editedURL, placeholder: "https://...")
                        }
                        .padding()
                    } label: {
                        Label("出版資訊", systemImage: "building.2")
                            .foregroundColor(theme.textPrimary)
                    }
                    
                    // 摘要
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("摘要")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(theme.textMuted)
                            
                            TextEditor(text: $editedAbstract)
                                .font(.system(size: 13))
                                .foregroundColor(theme.textPrimary)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(theme.elevated.opacity(0.5))
                                .cornerRadius(8)
                        }
                        .padding()
                    } label: {
                        Label("摘要", systemImage: "text.alignleft")
                            .foregroundColor(theme.textPrimary)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 500, minHeight: 600)
        .background(theme.background)
        .onAppear {
            loadEntryData()
        }
    }
    
    private func loadEntryData() {
        editedTitle = entry.title
        editedAuthor = entry.fields["author"] ?? ""
        editedYear = entry.fields["year"] ?? ""
        editedEntryType = entry.entryType
        editedCitationKey = entry.citationKey
        editedJournal = entry.fields["journal"] ?? ""
        editedDOI = entry.fields["doi"] ?? ""
        editedAbstract = entry.fields["abstract"] ?? ""
        editedPublisher = entry.fields["publisher"] ?? ""
        editedURL = entry.fields["url"] ?? ""
    }
    
    private func saveChanges() {
        // 更新基本屬性
        entry.entryType = editedEntryType
        entry.citationKey = editedCitationKey
        
        // 更新 fields 字典（包含 title）
        var newFields = entry.fields
        newFields["title"] = editedTitle
        newFields["author"] = editedAuthor
        newFields["year"] = editedYear
        newFields["journal"] = editedJournal
        newFields["doi"] = editedDOI
        newFields["abstract"] = editedAbstract
        newFields["publisher"] = editedPublisher
        newFields["url"] = editedURL
        entry.updateFields(newFields)
        
        entry.updatedAt = Date()
        
        do {
            try viewContext.save()
            ToastManager.shared.showSuccess("書目已更新")
            onSave?()
            dismiss()
        } catch {
            ToastManager.shared.showError("儲存失敗：\(error.localizedDescription)")
        }
    }
}

// MARK: - 編輯欄位元件

struct EditField: View {
    @EnvironmentObject var theme: AppTheme
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.textMuted)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundColor(theme.textPrimary)
                .padding(10)
                .background(theme.elevated.opacity(0.5))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border, lineWidth: 1)
                )
        }
    }
}

#Preview {
    EntryEditSheet(entry: PreviewEntry.sample)
        .environmentObject(AppTheme())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

private enum PreviewEntry {
    static var sample: Entry {
        let context = PersistenceController.preview.container.viewContext
        let entry = Entry(context: context)
        entry.entryType = "article"
        entry.citationKey = "test2024"
        var fields: [String: String] = [:]
        fields["title"] = "測試文獻"
        entry.fieldsJSON = (try? String(data: JSONEncoder().encode(fields), encoding: .utf8)) ?? "{}"
        return entry
    }
}
