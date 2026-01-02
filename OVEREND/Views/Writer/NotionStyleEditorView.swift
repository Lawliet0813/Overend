//
//  NotionStyleEditorView.swift
//  OVEREND
//
//  Notion 風格的區塊編輯器主視圖
//

import SwiftUI
import UniformTypeIdentifiers

struct NotionStyleEditorView: View {
    @EnvironmentObject var theme: AppTheme
    @ObservedObject var document: Document
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var blocks: [ContentBlock] = []
    @FocusState private var focusedBlockId: UUID?
    @State private var draggedBlock: ContentBlock?
    
    // 自動儲存
    @State private var autoSaveTimer: Timer?
    @State private var lastSaved: Date?
    @State private var isSaving = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 文檔標題
                titleSection
                
                // 區塊列表
                LazyVStack(spacing: 2) {
                    ForEach($blocks) { $block in
                        NotionStyleBlockView(
                            block: $block,
                            focusedBlockId: $focusedBlockId,
                            onDelete: {
                                deleteBlock(block)
                            },
                            onNewBlock: {
                                createNewBlock(after: block)
                            },
                            onConvertType: { newType in
                                convertBlockType(block: block, to: newType)
                            }
                        )
                        .onDrag {
                            draggedBlock = block
                            return NSItemProvider(object: block.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: BlockDropDelegate(
                            block: block,
                            blocks: $blocks,
                            draggedBlock: $draggedBlock
                        ))
                    }
                }
                .padding(.top, 24)
                
                // 添加區塊按鈕
                addBlockButton
                    .padding(.top, 16)
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 40)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background(theme.page)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                notionToolbar
            }
        }
        .onAppear {
            loadBlocks()
            startAutoSave()
        }
        .onDisappear {
            saveBlocks()
            stopAutoSave()
        }
        .onChange(of: blocks) { _ in
            scheduleAutoSave()
        }
    }
    
    // MARK: - 標題區域
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("無標題", text: Binding(
                get: { document.title },
                set: { newValue in
                    document.title = newValue
                    document.updatedAt = Date()
                }
            ))
            .textFieldStyle(.plain)
            .font(.system(size: 42, weight: .bold))
            
            HStack(spacing: 16) {
                Label("\(wordCount) 字", systemImage: "doc.text")
                    .font(.caption)
                    .foregroundColor(theme.textMuted)
                
                if let lastSaved = lastSaved {
                    Text("已儲存於 \(lastSaved, style: .time)")
                        .font(.caption)
                        .foregroundColor(theme.textMuted)
                }
                
                if isSaving {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("儲存中...")
                    }
                    .font(.caption)
                    .foregroundColor(theme.textMuted)
                }
            }
        }
    }
    
    // MARK: - 工具列
    
    private var notionToolbar: some View {
        HStack(spacing: 12) {
            // 切換模式按鈕
            Menu {
                Button("Notion 模式", action: {})
                Button("富文本模式", action: { /* 切換回傳統編輯器 */ })
            } label: {
                Label("編輯模式", systemImage: "text.alignleft")
            }
            
            Divider()
                .frame(height: 20)
            
            // 快速插入按鈕
            Button(action: { addBlock(type: .heading1) }) {
                Image(systemName: "textformat.size.larger")
            }
            .help("插入標題")
            
            Button(action: { addBlock(type: .bulletList) }) {
                Image(systemName: "list.bullet")
            }
            .help("插入清單")
            
            Button(action: { addBlock(type: .checkbox) }) {
                Image(systemName: "checkmark.square")
            }
            .help("插入待辦事項")
            
            Button(action: { addBlock(type: .code) }) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
            }
            .help("插入程式碼")
            
            Button(action: { addBlock(type: .citation) }) {
                Image(systemName: "book.closed")
            }
            .help("插入文獻引用")
        }
    }
    
    // MARK: - 添加區塊按鈕
    
    private var addBlockButton: some View {
        Button(action: {
            addBlock(type: .paragraph)
        }) {
            HStack {
                Image(systemName: "plus")
                Text("點擊添加區塊，或輸入 / 選擇類型")
            }
            .font(.body)
            .foregroundColor(theme.textMuted)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 計算屬性
    
    private var wordCount: Int {
        blocks.reduce(0) { $0 + $1.content.count }
    }
    
    // MARK: - 區塊操作
    
    private func loadBlocks() {
        // 從文檔載入區塊數據
        if let rtfData = document.rtfData,
           let jsonString = String(data: rtfData, encoding: .utf8),
           let data = jsonString.data(using: .utf8),
           let loadedBlocks = try? JSONDecoder().decode([ContentBlock].self, from: data) {
            blocks = loadedBlocks.sorted { $0.order < $1.order }
        } else {
            // 如果沒有區塊，創建一個空段落
            blocks = [ContentBlock(type: .paragraph, order: 0)]
        }
    }
    
    private func saveBlocks() {
        isSaving = true
        
        // 更新區塊順序
        for (index, block) in blocks.enumerated() {
            if let blockIndex = blocks.firstIndex(where: { $0.id == block.id }) {
                blocks[blockIndex].order = index
            }
        }
        
        // 將區塊序列化為 JSON
        if let data = try? JSONEncoder().encode(blocks),
           let jsonString = String(data: data, encoding: .utf8) {
            document.rtfData = jsonString.data(using: .utf8)
            document.updatedAt = Date()
            
            do {
                try viewContext.save()
                lastSaved = Date()
            } catch {
                print("Failed to save blocks: \(error)")
            }
        }
        
        isSaving = false
    }
    
    private func addBlock(type: BlockType, after afterBlock: ContentBlock? = nil) {
        let newBlock = ContentBlock(
            type: type,
            order: afterBlock?.order ?? blocks.count
        )
        
        if let afterBlock = afterBlock,
           let index = blocks.firstIndex(where: { $0.id == afterBlock.id }) {
            blocks.insert(newBlock, at: index + 1)
        } else {
            blocks.append(newBlock)
        }
        
        // 聚焦到新區塊
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedBlockId = newBlock.id
        }
    }
    
    private func createNewBlock(after block: ContentBlock) {
        addBlock(type: .paragraph, after: block)
    }
    
    private func deleteBlock(_ block: ContentBlock) {
        if blocks.count > 1 {
            if let index = blocks.firstIndex(where: { $0.id == block.id }) {
                blocks.remove(at: index)
                
                // 聚焦到前一個區塊
                if index > 0 {
                    focusedBlockId = blocks[index - 1].id
                } else if !blocks.isEmpty {
                    focusedBlockId = blocks[0].id
                }
            }
        }
    }
    
    private func convertBlockType(block: ContentBlock, to newType: BlockType) {
        if let index = blocks.firstIndex(where: { $0.id == block.id }) {
            var updatedBlock = blocks[index]
            updatedBlock.type = newType
            
            // 清除命令文字
            if updatedBlock.content.hasPrefix("/") {
                if let spaceIndex = updatedBlock.content.firstIndex(of: " ") {
                    updatedBlock.content = String(updatedBlock.content[updatedBlock.content.index(after: spaceIndex)...])
                } else {
                    updatedBlock.content = ""
                }
            }
            
            blocks[index] = updatedBlock
        }
    }
    
    // MARK: - 自動儲存
    
    private func startAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            saveBlocks()
        }
    }
    
    private func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    private func scheduleAutoSave() {
        // 重置計時器
        stopAutoSave()
        startAutoSave()
    }
}

// MARK: - 拖放代理

struct BlockDropDelegate: DropDelegate {
    let block: ContentBlock
    @Binding var blocks: [ContentBlock]
    @Binding var draggedBlock: ContentBlock?
    
    func performDrop(info: DropInfo) -> Bool {
        draggedBlock = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedBlock = draggedBlock,
              draggedBlock.id != block.id,
              let fromIndex = blocks.firstIndex(where: { $0.id == draggedBlock.id }),
              let toIndex = blocks.firstIndex(where: { $0.id == block.id })
        else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            blocks.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }
}

#Preview {
    NotionStyleEditorView(document: PersistenceController.preview.container.viewContext.registeredObjects.compactMap { $0 as? Document }.first!)
        .environmentObject(AppTheme())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
