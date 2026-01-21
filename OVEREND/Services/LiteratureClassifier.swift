import CoreML
import NaturalLanguage

/// 文獻類型分類服務
class LiteratureClassifier {
    
    // MARK: - 單例
    
    static let shared = LiteratureClassifier()
    
    private var model: MLModel?
    
    private init() {
        loadModel()
    }
    
    
    // MARK: - 載入模型
    
    private func loadModel() {
        do {
            // 假設你的模型檔名為 LiteratureTypeClassifier.mlmodel
            // Xcode 編譯後會生成 LiteratureTypeClassifier 類別
            let config = MLModelConfiguration()
            
            // 這裡需要替換成你實際的模型名稱
            // model = try LiteratureTypeClassifier(configuration: config).model
            
            print("✅ 文獻分類模型載入成功")
            
        } catch {
            print("❌ 模型載入失敗: \(error)")
        }
    }
    
    
    // MARK: - 分類方法
    
    /// 預測文獻類型
    func classify(text: String) -> LiteratureType {
        guard let model = model else {
            return .unknown
        }
        
        do {
            // 使用 NLModel 進行預測
            let nlModel = try NLModel(mlModel: model)
            
            if let prediction = nlModel.predictedLabel(for: text) {
                return LiteratureType(rawValue: prediction) ?? .unknown
            }
            
        } catch {
            print("預測失敗: \(error)")
        }
        
        return .unknown
    }
    
    
    /// 批次分類
    func classifyBatch(_ texts: [String]) -> [LiteratureType] {
        return texts.map { classify(text: $0) }
    }
}


// MARK: - 文獻類型列舉

enum LiteratureType: String {
    case journalArticle = "Journal Article"
    case conferencePaper = "Conference Paper"
    case thesis = "Thesis"
    case bookChapter = "Book Chapter"
    case unknown = "Unknown"
    
    var displayName: String {
        switch self {
        case .journalArticle: return "期刊論文"
        case .conferencePaper: return "會議論文"
        case .thesis: return "學位論文"
        case .bookChapter: return "書籍章節"
        case .unknown: return "未知"
        }
    }
    
    var bibtexType: String {
        switch self {
        case .journalArticle: return "article"
        case .conferencePaper: return "inproceedings"
        case .thesis: return "phdthesis"
        case .bookChapter: return "incollection"
        case .unknown: return "misc"
        }
    }
}
