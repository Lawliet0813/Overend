import SwiftUI

struct SmartTagSuggestionView: View {
    let entryTitle: String
    let onAccept: ([String]) -> Void
    let onCancel: () -> Void
    
    @EnvironmentObject var theme: AppTheme
    @StateObject private var learningService = LearningService.shared
    @State private var predictions: [TagPrediction] = []
    @State private var selectedTags: Set<String> = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AI Tag Suggestions")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .foregroundColor(theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(theme.elevated)
            
            Divider()
            
            // Content
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Analyzing title...")
                        .padding()
                } else if predictions.isEmpty {
                    emptyState
                } else {
                    suggestionList
                }
            }
            .padding()
            
            // Footer
            if !predictions.isEmpty {
                Divider()
                HStack {
                    Button("Skip") {
                        learningService.recordFeedback(accepted: false, tags: [], for: entryTitle)
                        onCancel()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(theme.textSecondary)
                    
                    Spacer()
                    
                    Button(action: acceptSelected) {
                        Text("Add Selected (\(selectedTags.count))")
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedTags.isEmpty ? Color.gray.opacity(0.3) : theme.accent)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedTags.isEmpty)
                }
                .padding()
                .background(theme.elevated)
            }
        }
        .frame(width: 350)
        .background(theme.background)
        .cornerRadius(12)
        .shadow(radius: 10)
        .onAppear {
            analyze()
        }
    }
    
    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Based on your tagging habits:")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
            
            ForEach(predictions) { prediction in
                HStack {
                    Toggle(isOn: Binding(
                        get: { selectedTags.contains(prediction.tag) },
                        set: { isSelected in
                            if isSelected {
                                selectedTags.insert(prediction.tag)
                            } else {
                                selectedTags.remove(prediction.tag)
                            }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(prediction.tag)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(theme.textPrimary)
                            
                            HStack(spacing: 4) {
                                Text("\(Int(prediction.confidence * 100))% confidence")
                                    .foregroundColor(confidenceColor(prediction.confidence))
                                
                                Text("•")
                                    .foregroundColor(theme.textTertiary)
                                
                                Text(prediction.reason)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .foregroundColor(theme.textSecondary)
                            }
                            .font(.caption2)
                        }
                    }
                    .toggleStyle(CheckboxToggleStyle(theme: theme))
                }
                .padding(8)
                .background(theme.elevated)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border, lineWidth: 1)
                )
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.largeTitle)
                .foregroundColor(theme.textTertiary)
            Text("No suggestions available")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            Text("Keep adding tags manually to help AI learn your preferences.")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func analyze() {
        // Simulate network/processing delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.predictions = learningService.predictTags(for: entryTitle)
            // Default select high confidence tags
            self.selectedTags = Set(self.predictions.filter { $0.confidence > 0.7 }.map { $0.tag })
            self.isLoading = false
        }
    }
    
    private func acceptSelected() {
        let tags = Array(selectedTags)
        learningService.recordFeedback(accepted: true, tags: tags, for: entryTitle)
        onAccept(tags)
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence > 0.8 { return .green }
        if confidence > 0.5 { return .orange }
        return .gray
    }
}

// Simple Checkbox Style
struct CheckboxToggleStyle: ToggleStyle {
    var theme: AppTheme
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? theme.accent : theme.textSecondary)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            configuration.label
        }
    }
}
