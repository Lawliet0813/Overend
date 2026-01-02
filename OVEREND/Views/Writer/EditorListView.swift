//
//  EditorListView.swift
//  OVEREND
//
//  文稿列表視圖 - 寫作中心卡片網格
//

import SwiftUI
import CoreData

/// 文稿列表視圖（寫作中心）
struct EditorListView: View {
    @EnvironmentObject var theme: AppTheme
    @EnvironmentObject var viewState: MainViewState
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Document.updatedAt, ascending: false)],
        animation: .default
    )
    private var documents: FetchedResults<Document>
    
    @State private var showNewDocumentSheet = false
    @State private var newDocumentTitle = ""
    
    let columns = [
        GridItem(.adaptive(minimum: 260, maximum: 320), spacing: 24)
    ]
    
    var body: some View {
        ScrollView {
            if documents.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(documents) { document in
                        DocumentCardView(document: document) {
                            viewState.openDocument(document)
                        } onDelete: {
                            deleteDocument(document)
                        }
                        .environmentObject(theme)
                    }
                }
                .padding(32)
            }
        }
        .background(Color.clear)
        .sheet(isPresented: $showNewDocumentSheet) {
            newDocumentSheet
        }
    }
    
    // MARK: - 子視圖
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(theme.accentLight)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "doc.text")
                    .font(.system(size: 40))
                    .foregroundColor(theme.accent)
            }
            
            VStack(spacing: 8) {
                Text("尚無文件")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Text("開始撰寫您的第一份文稿")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textMuted)
            }
            
            Button(action: { showNewDocumentSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("新建文稿")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.accent)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var newDocumentSheet: some View {
        VStack(spacing: 20) {
            Text("新建文稿")
                .font(.headline)
            
            TextField("文稿標題", text: $newDocumentTitle)
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
                .tint(theme.accent)
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
            viewState.openDocument(doc)
            newDocumentTitle = ""
            showNewDocumentSheet = false
        } catch {
            print("建立文稿失敗：\(error.localizedDescription)")
        }
    }
    
    private func deleteDocument(_ document: Document) {
        viewContext.delete(document)
        
        do {
            try viewContext.save()
        } catch {
            print("刪除文稿失敗：\(error.localizedDescription)")
        }
    }
}

#Preview {
    let theme = AppTheme()
    let viewState = MainViewState()
    
    return EditorListView()
        .environmentObject(theme)
        .environmentObject(viewState)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .frame(width: 800, height: 600)
}
