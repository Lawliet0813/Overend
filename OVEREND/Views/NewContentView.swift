//
//  NewContentView.swift
//  OVEREND
//
//  現代化主視圖 - 採用 NavigationSplitView 與三欄式佈局
//

import SwiftUI
import CoreData

struct NewContentView: View {
    @Environment(\.managedObjectContext) var viewContext
    @StateObject private var theme = AppTheme()
    @StateObject private var viewState = MainViewState()
    @StateObject var libraryVM = LibraryViewModel()  // Changed from private to internal
    
    // 側邊欄選擇
    @State private var sidebarSelection: SidebarItemType? = .allEntries
    
    // 視圖寬度狀態
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // MARK: - 側邊欄
            NewSidebarView(selection: $sidebarSelection)
                .environmentObject(theme)
                .environmentObject(viewState)
                .navigationTitle("OVEREND")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button(action: { createManualEntry() }) {
                                Label("新增空白書目", systemImage: "plus.square")
                            }
                            
                            Button(action: { importPDF() }) {
                                Label("匯入 PDF...", systemImage: "doc.text")
                            }
                            
                            Button(action: { importBibTeX() }) {
                                Label("匯入 BibTeX...", systemImage: "text.quote")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
        } detail: {
            // MARK: - 內容區 (包含列表與詳情)
            ZStack {
                // 背景
                theme.background.ignoresSafeArea()
                
                if libraryVM.isLoading {
                    ProgressView("載入文獻庫...")
                } else if let library = libraryVM.libraries.first {
                    // 根據側邊欄選擇顯示不同內容
                    if let selection = sidebarSelection {
                        if selection == .drafts {
                            DraftsListView()
                                .environmentObject(theme)
                                .environment(\.managedObjectContext, viewContext)
                        } else {
                            ModernEntryListView(library: library, filterMode: selection)
                                .environmentObject(theme)
                                .environmentObject(viewState)
                                .environment(\.managedObjectContext, viewContext)
                                .id(selection) // 強制刷新視圖以確保能夠重置狀態
                        }
                    } else {
                        Text("請選擇項目")
                            .foregroundColor(theme.textSecondary)
                    }
                } else {
                    // 無文獻庫時的空狀態
                    VStack {
                        Text("無法載入文獻庫")
                            .foregroundColor(theme.textSecondary)
                        Button("重試") {
                            Task {
                                await libraryVM.fetchLibraries()
                            }
                        }
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .preferredColorScheme(theme.colorScheme)
        .environmentObject(theme)
        .environmentObject(viewState)
        .onAppear {
            // 確保有文獻庫數據
            if libraryVM.libraries.isEmpty {
                Task {
                    await libraryVM.fetchLibraries()
                }
            }
        }
    }
}

#Preview {
    NewContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
