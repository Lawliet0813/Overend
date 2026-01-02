//
//  NotionStyleBlockView.swift
//  OVEREND
//
//  Notion 風格的單個區塊視圖
//

import SwiftUI

struct NotionStyleBlockView: View {
    @EnvironmentObject var theme: AppTheme
    @Binding var block: ContentBlock
    @FocusState.Binding var focusedBlockId: UUID?
    
    let onDelete: () -> Void
    let onNewBlock: () -> Void
    let onConvertType: (BlockType) -> Void
    
    @State private var showCommandMenu = false
    @State private var commandQuery = ""
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 區塊圖示/控制項
            blockIcon
            
            // 區塊內容
            blockContent
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(focusedBlockId == block.id ? theme.card.opacity(0.5) : Color.clear)
        )
        .overlay(alignment: .topLeading) {
            if showCommandMenu {
                CommandMenuView(
                    query: $commandQuery,
                    onSelect: { type in
                        onConvertType(type)
                        showCommandMenu = false
                        commandQuery = ""
                    },
                    onDismiss: {
                        showCommandMenu = false
                        commandQuery = ""
                    }
                )
                .offset(x: 40, y: 30)
            }
        }
    }
    
    @ViewBuilder
    private var blockIcon: some View {
        switch block.type {
        case .checkbox:
            Button(action: {
                block.isChecked?.toggle()
            }) {
                Image(systemName: block.isChecked == true ? "checkmark.square.fill" : "square")
                    .foregroundColor(block.isChecked == true ? theme.accent : theme.textMuted)
            }
            .buttonStyle(.plain)
            .frame(width: 20, height: 24)
            
        case .bulletList:
            Text("•")
                .font(.headline)
                .foregroundColor(theme.textMuted)
                .frame(width: 20, height: 24)
            
        case .numberedList:
            Text("\(block.order + 1).")
                .font(.body)
                .foregroundColor(theme.textMuted)
                .frame(width: 20, height: 24, alignment: .trailing)
            
        case .divider:
            Image(systemName: "minus")
                .foregroundColor(theme.textMuted)
                .frame(width: 20, height: 24)
            
        default:
            Image(systemName: block.type.icon)
                .font(.caption)
                .foregroundColor(theme.textMuted)
                .frame(width: 20, height: 24)
        }
    }
    
    @ViewBuilder
    private var blockContent: some View {
        switch block.type {
        case .heading1:
            TextField("標題 1", text: $block.content, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 32, weight: .bold))
                .focused($focusedBlockId, equals: block.id)
                .onSubmit(onNewBlock)
                .onChange(of: block.content) { newValue in
                    handleTextChange(newValue)
                }
            
        case .heading2:
            TextField("標題 2", text: $block.content, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 24, weight: .semibold))
                .focused($focusedBlockId, equals: block.id)
                .onSubmit(onNewBlock)
                .onChange(of: block.content) { newValue in
                    handleTextChange(newValue)
                }
            
        case .heading3:
            TextField("標題 3", text: $block.content, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 18, weight: .medium))
                .focused($focusedBlockId, equals: block.id)
                .onSubmit(onNewBlock)
                .onChange(of: block.content) { newValue in
                    handleTextChange(newValue)
                }
            
        case .quote:
            HStack {
                Rectangle()
                    .fill(theme.accent)
                    .frame(width: 3)
                
                TextField("引用內容", text: $block.content, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.body.italic())
                    .foregroundColor(theme.textMuted)
                    .focused($focusedBlockId, equals: block.id)
                    .onSubmit(onNewBlock)
                    .onChange(of: block.content) { newValue in
                        handleTextChange(newValue)
                    }
            }
            .padding(.leading, 8)
            
        case .code:
            TextField("程式碼", text: $block.content, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(theme.card)
                .cornerRadius(4)
                .focused($focusedBlockId, equals: block.id)
                .onSubmit(onNewBlock)
                .onChange(of: block.content) { newValue in
                    handleTextChange(newValue)
                }
            
        case .divider:
            Divider()
                .frame(maxWidth: .infinity)
            
        case .callout:
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                TextField("標註內容", text: $block.content, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .focused($focusedBlockId, equals: block.id)
                    .onSubmit(onNewBlock)
                    .onChange(of: block.content) { newValue in
                        handleTextChange(newValue)
                    }
            }
            .padding(12)
            .background(theme.card)
            .cornerRadius(8)
            
        default: // paragraph, bulletList, numberedList, checkbox
            TextField(placeholderText, text: $block.content, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .focused($focusedBlockId, equals: block.id)
                .onSubmit(onNewBlock)
                .onChange(of: block.content) { newValue in
                    handleTextChange(newValue)
                }
        }
    }
    
    private var placeholderText: String {
        switch block.type {
        case .paragraph: return "輸入 / 以選擇區塊類型"
        case .bulletList, .numberedList: return "清單項目"
        case .checkbox: return "待辦事項"
        default: return "輸入內容"
        }
    }
    
    private func handleTextChange(_ newValue: String) {
        // 檢測斜線命令
        if newValue.hasPrefix("/") {
            commandQuery = String(newValue.dropFirst())
            showCommandMenu = true
        } else if showCommandMenu && !newValue.hasPrefix("/") {
            showCommandMenu = false
            commandQuery = ""
        }
        
        // 檢測空行刪除
        if newValue.isEmpty && focusedBlockId == block.id {
            // 可以在這裡處理刪除邏輯
        }
    }
}

// MARK: - 命令選單視圖

struct CommandMenuView: View {
    @EnvironmentObject var theme: AppTheme
    @Binding var query: String
    let onSelect: (BlockType) -> Void
    let onDismiss: () -> Void
    
    @State private var selectedIndex = 0
    
    private var filteredCommands: [BlockCommand] {
        if query.isEmpty {
            return BlockCommand.allCommands
        }
        return BlockCommand.allCommands.filter { $0.matches(query) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(filteredCommands.enumerated()), id: \.element.id) { index, command in
                Button(action: {
                    onSelect(command.type)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: command.type.icon)
                            .frame(width: 20)
                            .foregroundColor(theme.accent)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(command.type.displayName)
                                .font(.body)
                                .foregroundColor(theme.textPrimary)
                            
                            Text(command.displayText)
                                .font(.caption)
                                .foregroundColor(theme.textMuted)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        selectedIndex == index ? theme.card : Color.clear
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    if hovering {
                        selectedIndex = index
                    }
                }
            }
        }
        .frame(width: 280)
        .background(theme.background)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}

#Preview {
    NotionStyleBlockView(
        block: .constant(ContentBlock(type: .paragraph, content: "測試內容")),
        focusedBlockId: FocusState<UUID?>().projectedValue,
        onDelete: {},
        onNewBlock: {},
        onConvertType: { _ in }
    )
    .environmentObject(AppTheme())
}
