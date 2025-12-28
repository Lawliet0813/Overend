//
//  WriterContainerView.swift
//  OVEREND
//
//  寫作模式容器視圖 - 整合文件列表與編輯器
//

import SwiftUI
import CoreData

/// 寫作模式容器
struct WriterContainerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDocument: Document?
    
    var body: some View {
        NavigationSplitView {
            // 左側：文件列表
            DocumentListView(selectedDocument: $selectedDocument)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            // 右側：編輯器
            if let document = selectedDocument {
                WriterView(document: document)
            } else {
                emptyState
            }
        }
        .navigationTitle("寫作")
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "pencil.and.outline")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("選擇或建立文件開始寫作")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("從左側選擇現有文件，或點擊 + 建立新文件")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    WriterContainerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .frame(width: 1000, height: 700)
}
