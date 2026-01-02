//
//  AICommandPaletteView.swift
//  OVEREND
//
//  AI 指令控制台 - Cmd+K 快捷鍵彈出的指令面板
//

import SwiftUI
import AppKit

/// AI 指令面板視圖
struct AICommandPaletteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var commandText: String = ""
    @State private var isProcessing: Bool = false
    @State private var selectedTemplate: CommandTemplate?

    let textView: NSTextView
    let metadata: ThesisMetadata?
    let onExecute: (AICommand) -> Void

    // 預設指令範本
    private let templates: [CommandTemplate] = [
        CommandTemplate(
            icon: "person.3",
            title: "第三人稱視角檢查",
            prompt: "請檢查以下文字是否全部使用第三人稱視角撰寫，並指出任何使用第一人稱或第二人稱的地方",
            category: .grammar
        ),
        CommandTemplate(
            icon: "book.closed",
            title: "文獻格式轉 APA",
            prompt: "請將以下文獻引用轉換為 APA 第七版格式",
            category: .citation
        ),
        CommandTemplate(
            icon: "text.alignleft",
            title: "行政規範縮排",
            prompt: "請調整此段落的格式以符合行政規範：首行縮排 2 字符，段落前後 0 行距，行距 2 倍",
            category: .formatting
        ),
        CommandTemplate(
            icon: "doc.text.magnifyingglass",
            title: "學術用語檢查",
            prompt: "請檢查以下文字是否使用恰當的學術用語，並提出改進建議",
            category: .style
        ),
        CommandTemplate(
            icon: "arrow.triangle.2.circlepath",
            title: "改寫為被動語態",
            prompt: "請將以下句子改寫為被動語態，使其更符合學術寫作風格",
            category: .style
        ),
        CommandTemplate(
            icon: "text.word.spacing",
            title: "精簡冗長句子",
            prompt: "請精簡以下句子，去除冗詞贅字，保持原意但提高可讀性",
            category: .style
        ),
        CommandTemplate(
            icon: "checkmark.circle",
            title: "語法錯誤檢查",
            prompt: "請檢查以下文字的語法錯誤、拼寫錯誤和標點符號使用",
            category: .grammar
        ),
        CommandTemplate(
            icon: "increase.indent",
            title: "增加段落縮排",
            prompt: "將選取段落的首行縮排設為 2 個字符（28.35pt）",
            category: .formatting
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            headerView

            Divider()

            // 搜尋與輸入區域
            commandInputArea

            Divider()

            // 範本選擇區域
            if commandText.isEmpty {
                templateGridView
            } else {
                // 顯示過濾後的範本或執行按鈕
                customCommandView
            }

            Divider()

            // 狀態列
            statusBar
        }
        .frame(width: 600, height: 500)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 20)
    }

    // MARK: - 子視圖

    private var headerView: some View {
        HStack {
            Image(systemName: "command.circle.fill")
                .font(.title2)
                .foregroundColor(.accentColor)

            Text("AI 指令控制台")
                .font(.headline)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var commandInputArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("輸入自訂指令或選擇範本")
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("例如：幫我把這段改成學術用語...", text: $commandText)
                .textFieldStyle(.plain)
                .font(.body)
                .padding(8)
                .background(Color(.textBackgroundColor))
                .cornerRadius(6)
                .onSubmit {
                    executeCustomCommand()
                }
        }
        .padding()
    }

    private var templateGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(templates) { template in
                    TemplateCard(template: template) {
                        selectTemplate(template)
                    }
                }
            }
            .padding()
        }
    }

    private var customCommandView: some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                Text("執行自訂指令")
                    .font(.headline)

                Text(commandText)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)

                Button(action: executeCustomCommand) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isProcessing ? "處理中..." : "執行")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)
            }
            .padding()

            Spacer()
        }
    }

    private var statusBar: some View {
        HStack {
            if let selectedRange = getSelectedRange() {
                HStack(spacing: 4) {
                    Image(systemName: "text.cursor")
                        .font(.caption)
                    Text("已選取 \(selectedRange.length) 個字符")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            Text("按 Esc 關閉")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }

    // MARK: - 操作方法

    private func selectTemplate(_ template: CommandTemplate) {
        selectedTemplate = template
        commandText = template.prompt
    }

    private func executeCustomCommand() {
        guard !commandText.isEmpty else { return }

        isProcessing = true

        // 獲取選取的文字與屬性
        let selectedRange = textView.selectedRange()
        let selectedText = selectedRange.length > 0 ?
            textView.textStorage?.attributedSubstring(from: selectedRange) :
            nil

        let context = AICommandContext(
            selectedText: selectedText,
            selectedRange: selectedRange,
            currentFont: textView.font,
            currentParagraphStyle: textView.typingAttributes[.paragraphStyle] as? NSParagraphStyle,
            metadata: metadata
        )

        let command = AICommand(
            prompt: commandText,
            context: context,
            category: selectedTemplate?.category ?? .custom
        )

        // 執行回調
        onExecute(command)

        // 延遲關閉（給予反饋時間）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isProcessing = false
            dismiss()
        }
    }

    private func getSelectedRange() -> NSRange? {
        let range = textView.selectedRange()
        return range.length > 0 ? range : nil
    }
}

// MARK: - 範本卡片

struct TemplateCard: View {
    let template: CommandTemplate
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: template.icon)
                        .font(.title2)
                        .foregroundColor(template.category.color)

                    Spacer()
                }

                Text(template.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)

                Text(template.prompt)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - 資料模型

struct CommandTemplate: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let prompt: String
    let category: CommandCategory
}

// MARK: - NSTextAlignment 擴展

extension NSTextAlignment {
    var displayName: String {
        switch self {
        case .left: return "靠左"
        case .center: return "置中"
        case .right: return "靠右"
        case .justified: return "左右對齊"
        case .natural: return "自然"
        @unknown default: return "未知"
        }
    }
}

// MARK: - 預覽

#Preview {
    AICommandPaletteView(
        textView: NSTextView(),
        metadata: .preview,
        onExecute: { command in
            print("執行指令：\(command.prompt)")
        }
    )
}
