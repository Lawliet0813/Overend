import SwiftUI
import UniformTypeIdentifiers
import PDFKit

/// OCR 測試視圖
struct OCRTestView: View {
    @State private var extractedText = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            // 標題
            Text("PDF OCR 測試")
                .font(.title)
                .fontWeight(.bold)
            
            // 按鈕
            Button(action: selectAndProcessPDF) {
                Label(isProcessing ? "處理中..." : "選擇 PDF 檔案", 
                      systemImage: "doc.text.viewfinder")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isProcessing)
            
            // 錯誤訊息
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // 結果顯示
            ScrollView {
                Text(extractedText.isEmpty ? "尚未提取文字" : extractedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(30)
        .frame(minWidth: 600, minHeight: 500)
    }
    
    
    // MARK: - 方法
    
    private func selectAndProcessPDF() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.message = "選擇要進行 OCR 的 PDF 檔案"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            processPDF(at: url)
        }
    }
    
    private func processPDF(at url: URL) {
        isProcessing = true
        errorMessage = nil
        extractedText = ""
        
        Task {
            do {
                // 讀取 PDF
                guard let document = PDFDocument(url: url),
                      let page = document.page(at: 0) else {
                    throw OCRError.invalidImage
                }
                
                // 轉換為圖片
                let pageRect = page.bounds(for: .mediaBox)
                let renderer = ImageRenderer(content: Image(nsImage: page.thumbnail(of: pageRect.size, for: .mediaBox)))
                
                // 使用 NSImage (簡單方式) OR convert PDFPage to NSImage
                // 這裡使用簡單的 thumbnail
                let image = page.thumbnail(of: pageRect.size, for: .mediaBox)
                
                // 呼叫 OCR 服務
                let result = try await OCRService.shared.recognizeText(from: image)
                
                await MainActor.run {
                    extractedText = result.fullText
                    isProcessing = false
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
}


// MARK: - Preview

#Preview {
    OCRTestView()
}
