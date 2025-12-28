//
//  LibrarySidebarView.swift
//  OVEREND
//
//  左側邊欄 - 庫列表與組群樹
//

import SwiftUI
import UniformTypeIdentifiers

struct LibrarySidebarView: View {
    @Binding var selectedLibrary: Library?
    @ObservedObject var viewModel: LibraryViewModel
    @StateObject private var groupVM = GroupViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isShowingNewLibraryPopover = false
    @State private var newLibraryName = ""
    @State private var isShowingNewGroupPopover = false
    @State private var newGroupName = ""
    @State private var selectedGroup: Group?

    var body: some View {
        VStack(spacing: 0) {
            // 頂部工具欄
            HStack {
                Text("文獻庫")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    newLibraryName = ""
                    isShowingNewLibraryPopover = true
                }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .help("創建新文獻庫")
                .sheet(isPresented: $isShowingNewLibraryPopover) {
                    NewLibraryPopoverView(
                        libraryName: $newLibraryName,
                        isPresented: $isShowingNewLibraryPopover,
                        onCreate: { name in
                            viewModel.createLibrary(name: name)
                        }
                    )
                }
            }
            .padding()

            Divider()

            // 主列表
            List(selection: $selectedLibrary) {
                // 寫作區塊
                Section {
                    NavigationLink {
                        WriterContainerView()
                    } label: {
                        Label("我的文件", systemImage: "pencil.and.outline")
                            .font(.body)
                    }
                } header: {
                    Text("寫作")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                // 智能群組區塊
                Section {
                    NavigationLink(value: nil as Library?) {
                        Label("最近添加", systemImage: "clock")
                            .font(.body)
                    }
                    NavigationLink(value: nil as Library?) {
                        Label("有 PDF 附件", systemImage: "doc.fill")
                            .font(.body)
                    }
                    NavigationLink(value: nil as Library?) {
                        Label("待讀", systemImage: "bookmark")
                            .font(.body)
                    }
                } header: {
                    Text("智慧資料夾")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                // 文獻庫區塊
                Section {
                    ForEach(viewModel.libraries) { library in
                        LibraryRow(library: library, isFirstLibrary: viewModel.libraries.first?.id == library.id)
                            .tag(library)
                            .contextMenu {
                                // 第一個文獻庫（文獻總數）不可刪除
                                if viewModel.libraries.first?.id != library.id {
                                    Button("重新命名") {
                                        renameLibrary(library)
                                    }
                                    Button("刪除", role: .destructive) {
                                        deleteLibrary(library)
                                    }
                                    
                                    Divider()
                                }
                                
                                Button("導出 BibTeX") {
                                    exportLibrary(library)
                                }
                            }
                    }
                } header: {
                    Text("文獻庫")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                // 組群區塊（當有選中的 Library 時顯示）
                if let library = selectedLibrary {
                    Section {
                        if groupVM.groups.isEmpty {
                            Text("無資料夾")
                                .font(.body)
                                .foregroundColor(.secondary)
                        } else {
                            OutlineGroup(groupVM.groups, children: \.childrenArrayOptional) { group in
                                GroupRow(group: group)
                                    .contextMenu {
                                        Button("新增子資料夾") {
                                            createSubgroup(in: group)
                                        }
                                        Button("重新命名") {
                                            renameGroup(group)
                                        }
                                        Divider()
                                        Button("刪除", role: .destructive) {
                                            groupVM.deleteGroup(group)
                                        }
                                    }
                            }
                        }
                        
                        Button(action: {
                            newGroupName = ""
                            isShowingNewGroupPopover = true
                        }) {
                            Label("新增資料夾", systemImage: "folder.badge.plus")
                                .font(.body)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    } header: {
                        Text("資料夾")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
            }
            .listStyle(.sidebar)
            .onChange(of: selectedLibrary) { newLibrary in
                groupVM.library = newLibrary
            }
        }
        .frame(minWidth: 200)
        .sheet(isPresented: $isShowingNewGroupPopover) {
            NewGroupPopoverView(
                groupName: $newGroupName,
                isPresented: $isShowingNewGroupPopover,
                onCreate: { name in
                    groupVM.createGroup(name: name)
                }
            )
        }
    }

    // MARK: - Library Actions

    private func renameLibrary(_ library: Library) {
        #if canImport(AppKit)
        if let newName = DialogHelper.showTextInputDialog(
            title: "重新命名文獻庫",
            message: "請輸入新的文獻庫名稱",
            defaultValue: library.name,
            okButtonTitle: "重新命名",
            cancelButtonTitle: "取消"
        ) {
            viewModel.updateLibrary(library, name: newName)
        }
        #endif
    }

    private func deleteLibrary(_ library: Library) {
        #if canImport(AppKit)
        let confirmed = DialogHelper.showConfirmDialog(
            title: "刪除文獻庫",
            message: "確定要刪除「\(library.name)」嗎？此操作無法復原。",
            confirmButtonTitle: "刪除",
            cancelButtonTitle: "取消",
            style: .warning
        )

        if confirmed {
            viewModel.deleteLibrary(library)
        }
        #endif
    }
    
    private func exportLibrary(_ library: Library) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.text]
        panel.nameFieldStringValue = "\(library.name).bib"
        panel.prompt = "導出"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try BibTeXGenerator.exportLibrary(library, to: url, in: viewContext)
                } catch {
                    print("導出失敗: \(error)")
                }
            }
        }
    }
    
    // MARK: - Group Actions
    
    private func createSubgroup(in parent: Group) {
        #if canImport(AppKit)
        if let name = DialogHelper.showTextInputDialog(
            title: "新增子資料夾",
            message: "請輸入資料夾名稱",
            defaultValue: "",
            okButtonTitle: "創建",
            cancelButtonTitle: "取消"
        ) {
            groupVM.createGroup(name: name, parent: parent)
        }
        #endif
    }
    
    private func renameGroup(_ group: Group) {
        #if canImport(AppKit)
        if let newName = DialogHelper.showTextInputDialog(
            title: "重新命名資料夾",
            message: "請輸入新的資料夾名稱",
            defaultValue: group.name,
            okButtonTitle: "重新命名",
            cancelButtonTitle: "取消"
        ) {
            groupVM.updateGroup(group, name: newName)
        }
        #endif
    }
}

// MARK: - Group Row

struct GroupRow: View {
    let group: Group
    
    var body: some View {
        HStack {
            Image(systemName: group.iconName ?? "folder")
                .foregroundColor(group.colorHex != nil ? Color(hex: group.colorHex!) : .secondary)
                .font(.body)
            
            Text(group.name)
                .font(.body)
            
            Spacer()
            
            Text("\(group.entryCount)")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.secondary.opacity(0.5)))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - New Group Popover

struct NewGroupPopoverView: View {
    @Binding var groupName: String
    @Binding var isPresented: Bool
    var onCreate: (String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("新增資料夾")
                .font(.headline)
            
            TextField("資料夾名稱", text: $groupName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
                .onSubmit {
                    createGroup()
                }
            
            HStack(spacing: 8) {
                Button("取消") {
                    isPresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("創建") {
                    createGroup()
                }
                .buttonStyle(.borderedProminent)
                .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(16)
    }
    
    private func createGroup() {
        let trimmed = groupName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onCreate(trimmed)
        isPresented = false
    }
}

// MARK: - Group Extension for OutlineGroup

extension Group {
    var childrenArrayOptional: [Group]? {
        let arr = childrenArray
        return arr.isEmpty ? nil : arr
    }
}

// MARK: - New Library Popover View

struct NewLibraryPopoverView: View {
    @Binding var libraryName: String
    @Binding var isPresented: Bool
    var onCreate: (String) -> Void
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text("新增文獻庫")
                .font(.headline)

            #if canImport(AppKit)
            TextField("文獻庫名稱", text: $libraryName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
                .onSubmit {
                    createLibrary()
                }
            #else
            TextField("文獻庫名稱", text: $libraryName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
                .focused($isNameFieldFocused)
                .onSubmit {
                    createLibrary()
                }
            #endif

            HStack(spacing: 8) {
                Button("取消") {
                    isPresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])

                Button("創建") {
                    createLibrary()
                }
                .buttonStyle(.borderedProminent)
                .disabled(libraryName.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(16)
        .onAppear {
            #if !canImport(AppKit)
            // 延遲設置焦點，確保視圖已完全渲染
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isNameFieldFocused = true
            }
            #endif
        }
    }

    private func createLibrary() {
        let trimmed = libraryName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onCreate(trimmed)
        isPresented = false
    }
}

struct LibraryRow: View {
    @ObservedObject var library: Library
    var isFirstLibrary: Bool = false
    @Environment(\.managedObjectContext) private var viewContext
    @State private var entryCount: Int = 0

    var body: some View {
        HStack {
            Label(
                isFirstLibrary ? "文獻總數" : library.name,
                systemImage: library.isDefault ? "star.fill" : "folder"
            )
            .foregroundColor(library.isDefault ? .yellow : .primary)
            .font(.body)

            Spacer()

            Text("\(entryCount)")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.secondary.opacity(0.5)))
        }
        .onAppear {
            updateEntryCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            updateEntryCount()
        }
    }
    
    private func updateEntryCount() {
        let request = Entry.fetchRequest()
        request.predicate = NSPredicate(format: "library == %@", library)
        entryCount = (try? viewContext.count(for: request)) ?? 0
    }
}

