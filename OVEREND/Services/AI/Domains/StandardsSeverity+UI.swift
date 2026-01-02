import SwiftUI

extension StandardsSeverity {
    var color: Color {
        switch self {
        case .error:
            return .red
        case .warning:
            return .orange
        case .suggestion:
            return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .suggestion:
            return "lightbulb.fill"
        }
    }
}
