//
//  EntryContextMenu.swift
//  OVEREND
//
//  統一的 Entry 右鍵選單元件
//

import SwiftUI
import AppKit

// MARK: - Entry Context Menu ViewModifier

struct EntryContextMenuModifier: ViewModifier {
    @ObservedObject var entry: Entry
    
    var onShowDetails: (() -> Void)? = nil
    var onOpenPDF: (() -> Void)? = nil
    var onOpenDOI: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    func body(content: Content) -> some View {
        content.contextMenu {
            // 顯示詳情
            if let showDetails = onShowDetails {
                Button(action: showDetails) {
                    Label("顯示詳情", systemImage: "info.circle")
                }
                Divider()
            }
            
            // 開啟操作
            if entry.hasPDF {
                Button(action: {
                    if let action = onOpenPDF {
                        action()
                    } else {
                        openFirstPDF()
                    }
                }) {
                    Label("開啟 PDF", systemImage: "doc.fill")
                }
            }
            
            if let doi = entry.fields["doi"], !doi.isEmpty {
                Button(action: {
                    if let action = onOpenDOI {
                        action()
                    } else {
                        openDOI(doi)
                    }
                }) {
                    Label("開啟 DOI 連結", systemImage: "link")
                }
            }
            
            if entry.hasPDF || (entry.fields["doi"] ?? "").isEmpty == false {
                Divider()
            }
            
            // 複製引用 (子選單)
            Menu("複製引用") {
                Button("APA 7th") {
                    copyToClipboard(entry.generateAPACitation(), message: "已複製 APA 引用")
                }
                
                Button("MLA 9th") {
                    copyToClipboard(entry.generateMLACitation(), message: "已複製 MLA 引用")
                }
                
                Divider()
                
                Button("BibTeX") {
                    copyToClipboard(entry.generateBibTeX(), message: "已複製 BibTeX")
                }
                
                Button("引用鍵") {
                    copyToClipboard(entry.citationKey, message: "已複製引用鍵")
                }
            }
            
            Divider()
            
            // 星號標記
            Button(action: {
                entry.isStarred.toggle()
                try? entry.managedObjectContext?.save()
                ToastManager.shared.showSuccess(entry.isStarred ? "已加入星號標記" : "已移除星號標記")
            }) {
                Label(entry.isStarred ? "取消星號標記" : "加入星號標記",
                      systemImage: entry.isStarred ? "star.fill" : "star")
            }
            
            // 多附件選單
            if entry.attachmentArray.count > 1 {
                Menu("開啟附件") {
                    ForEach(Array(entry.attachmentArray.enumerated()), id: \.element.id) { _, attachment in
                        Button(action: {
                            NSWorkspace.shared.open(attachment.fileURL)
                        }) {
                            Label(attachment.fileName, systemImage: "doc.fill")
                        }
                    }
                }
            }
            
            Divider()
            
            // 編輯
            if let edit = onEdit {
                Button(action: edit) {
                    Label("編輯書目", systemImage: "pencil")
                }
            }
            
            // 刪除
            if let delete = onDelete {
                Button(role: .destructive, action: delete) {
                    Label("刪除", systemImage: "trash")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func openFirstPDF() {
        if let attachment = entry.attachmentArray.first {
            NSWorkspace.shared.open(attachment.fileURL)
        }
    }
    
    private func openDOI(_ doi: String) {
        let doiURL = doi.hasPrefix("http") ? doi : "https://doi.org/\(doi)"
        if let url = URL(string: doiURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func copyToClipboard(_ text: String, message: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        ToastManager.shared.showSuccess(message)
    }
}

// MARK: - View Extension

extension View {
    /// 為 Entry 添加統一的右鍵選單
    func entryContextMenu(
        entry: Entry,
        onShowDetails: (() -> Void)? = nil,
        onOpenPDF: (() -> Void)? = nil,
        onOpenDOI: (() -> Void)? = nil,
        onEdit: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) -> some View {
        self.modifier(EntryContextMenuModifier(
            entry: entry,
            onShowDetails: onShowDetails,
            onOpenPDF: onOpenPDF,
            onOpenDOI: onOpenDOI,
            onEdit: onEdit,
            onDelete: onDelete
        ))
    }
}
