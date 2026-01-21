//
//  DraftsListView.swift
//  OVEREND
//
//  草稿列表 - 管理與開啟寫作文件
//

import SwiftUI
import CoreData

struct DraftsListView: View {
    @EnvironmentObject var theme: AppTheme
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Document.updatedAt, ascending: false)],
        animation: .default
    )
    private var documents: FetchedResults<Document>

    @State private var selectedDocument: Document?
    @State private var showCreateAlert = false
    @State private var newDocTitle = ""
    @State private var isSidebarCollapsed = false

    var body: some View {
        HStack(spacing: 0) {
            // 左側：草稿列表（可收起）
            if !isSidebarCollapsed {
                VStack(spacing: 0) {
                    // 標題與工具列
                    HStack {
                        Text("我的草稿")
                            .font(theme.fontDisplaySmall)
                            .foregroundColor(theme.textPrimary)
                        Spacer()

                        // 收起按鈕
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isSidebarCollapsed = true
                            }
                        }) {
                            Image(systemName: "sidebar.left")
                                .font(.system(size: 14))
                                .foregroundColor(theme.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .help("收起側邊欄")

                        Button(action: { showCreateAlert = true }) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 16))
                                .foregroundColor(theme.accent)
                        }
                        .buttonStyle(.plain)
                        .help("新增草稿")
                    }
                    .padding(theme.spacingMD)
                    .background(theme.background)

                    Divider()

                    List(selection: $selectedDocument) {
                        ForEach(documents) { doc in
                            Button(action: { selectedDocument = doc }) {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(theme.accent)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(doc.title )
                                            .font(theme.bodyFont())
                                            .foregroundColor(theme.textPrimary)
                                        Text(doc.updatedAt.formatted())
                                            .font(theme.captionFont())
                                            .foregroundColor(theme.textSecondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(selectedDocument == doc ? theme.emeraldSelected : Color.clear)
                        }
                        .onDelete(perform: deleteDocuments)
                    }
                    .listStyle(.plain)
                }
                .frame(minWidth: 250, maxWidth: 350)
                .transition(.move(edge: .leading))
            }

            // 收起狀態的浮動按鈕
            if isSidebarCollapsed {
                VStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isSidebarCollapsed = false
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "sidebar.left")
                                .font(.system(size: 16))
                                .foregroundColor(theme.accent)
                            Text("草稿")
                                .font(.system(size: 10))
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding(8)
                        .background(theme.card)
                        .cornerRadius(theme.cornerRadiusMD)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .help("展開草稿列表")
                    .padding(.leading, 8)
                    .padding(.top, 8)

                    Spacer()
                }
                .transition(.opacity)
            }

            Divider()
            
            // 右側：編輯器（使用新的 AI 寫作助手）
            if let doc = selectedDocument {
                ClaudeWritingAssistantView(document: doc)
                    .environmentObject(theme)
                    .environment(\.managedObjectContext, viewContext)
                    .id(doc.id) // 強制刷新編輯器
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(theme.textMuted)
                    Text("選擇或建立新草稿")
                        .font(theme.fontDisplaySmall)
                        .foregroundColor(theme.textSecondary)
                    Button("新增草稿") {
                        showCreateAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.background)
            }
        }
        .alert("新增草稿", isPresented: $showCreateAlert) {
            TextField("標題", text: $newDocTitle)
            Button("取消", role: .cancel) { newDocTitle = "" }
            Button("建立") {
                createDocument()
            }
        }
    }
    
    private func createDocument() {
        let title = newDocTitle.isEmpty ? "未命名草稿" : newDocTitle
        let newDoc = Document(context: viewContext)
        newDoc.id = UUID()
        newDoc.title = title
        newDoc.createdAt = Date()
        newDoc.updatedAt = Date()
        // Initialize with empty content
        newDoc.attributedString = NSAttributedString(string: "")
        
        try? viewContext.save()
        selectedDocument = newDoc
        newDocTitle = ""
    }
    
    private func deleteDocuments(offsets: IndexSet) {
        withAnimation {
            offsets.map { documents[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
            if let selected = selectedDocument, selected.isDeleted {
                selectedDocument = nil
            }
        }
    }
}
