//
//  DocumentListView.swift
//  OVEREND
//
//  文件列表側邊欄 - 管理寫作文件
//

import SwiftUI
import CoreData

/// 文件列表視圖
struct DocumentListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Document.updatedAt, ascending: false)],
        animation: .default
    )
    private var documents: FetchedResults<Document>
    
    @Binding var selectedDocument: Document?
    @State private var showNewDocumentSheet = false
    @State private var newDocumentTitle = ""
    @State private var documentToDelete: Document?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            HStack {
                Label("我的文件", systemImage: "doc.text")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showNewDocumentSheet = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .help("新增文件")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // 文件列表
            if documents.isEmpty {
                emptyState
            } else {
                List(selection: $selectedDocument) {
                    ForEach(documents) { doc in
                        DocumentRow(document: doc, isSelected: selectedDocument?.id == doc.id)
                            .tag(doc)
                            .contextMenu {
                                Button("刪除", role: .destructive) {
                                    documentToDelete = doc
                                    showDeleteConfirmation = true
                                }
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $showNewDocumentSheet) {
            newDocumentSheet
        }
        .alert("確定刪除？", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                if let doc = documentToDelete {
                    deleteDocument(doc)
                }
            }
        } message: {
            Text("「\(documentToDelete?.title ?? "")」將被永久刪除。")
        }
    }
    
    // MARK: - 子視圖
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("尚無文件")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Button("新增文件") {
                showNewDocumentSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var newDocumentSheet: some View {
        VStack(spacing: 20) {
            Text("新增文件")
                .font(.headline)
            
            TextField("文件標題", text: $newDocumentTitle)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
            
            HStack {
                Button("取消") {
                    newDocumentTitle = ""
                    showNewDocumentSheet = false
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("建立") {
                    createDocument()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(newDocumentTitle.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
    
    // MARK: - 方法
    
    private func createDocument() {
        let doc = Document(context: viewContext, title: newDocumentTitle)
        
        do {
            try viewContext.save()
            selectedDocument = doc
            newDocumentTitle = ""
            showNewDocumentSheet = false
        } catch {
            print("建立文件失敗：\(error.localizedDescription)")
        }
    }
    
    private func deleteDocument(_ document: Document) {
        if selectedDocument?.id == document.id {
            selectedDocument = nil
        }
        
        viewContext.delete(document)
        
        do {
            try viewContext.save()
        } catch {
            print("刪除文件失敗：\(error.localizedDescription)")
        }
    }
}

/// 文件列表項目
struct DocumentRow: View {
    @ObservedObject var document: Document
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .foregroundColor(isSelected ? .white : .accentColor)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(document.title)
                    .font(.body)
                    .lineLimit(1)
                
                Text(document.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DocumentListView(selectedDocument: .constant(nil))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .frame(width: 250, height: 400)
}
