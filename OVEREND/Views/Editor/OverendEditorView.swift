import SwiftUI

struct OverendEditorView: View {
    @State private var text: String = "# 歡迎使用 Overend 2.0\n\n這是一個基於 **Markdown** 與 **Typst** 的下一代學術編輯器。\n\n## 功能特色\n\n1. **繁體中文優先**：針對 CJK 排版優化。\n2. **AI 輔助**：整合 Apple Intelligence。\n3. **即時預覽**：右側即時顯示 PDF 渲染結果。\n"
    @State private var showGlow: Bool = false
    @State private var showPDFPreview: Bool = true
    
    var body: some View {
        HSplitView {
            // Left Pane: Editor
            HStack(spacing: 0) {
                // Gutter
                GutterView(showGlow: $showGlow)
                
                // Text Editor
                MacEditorView(text: $text)
                    .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minWidth: 400)
            
            // Right Pane: PDF Preview
            if showPDFPreview {
                ZStack {
                    Color(nsColor: .windowBackgroundColor)
                    
                    VStack {
                        Image(systemName: "doc.text.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 64, height: 64)
                            .foregroundColor(.secondary)
                        
                        Text("PDF Preview Placeholder")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Typst rendering will appear here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    withAnimation {
                        showGlow.toggle()
                    }
                }) {
                    Label("Toggle AI Glow", systemImage: "sparkles")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    withAnimation {
                        showPDFPreview.toggle()
                    }
                }) {
                    Label("Toggle Preview", systemImage: "sidebar.right")
                }
            }
        }
    }
}

struct OverendEditorView_Previews: PreviewProvider {
    static var previews: some View {
        OverendEditorView()
            .frame(width: 1000, height: 800)
    }
}
