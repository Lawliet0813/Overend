import SwiftUI

struct LearningDashboardView: View {
    @EnvironmentObject var theme: AppTheme
    @StateObject private var learningService = LearningService.shared
    @State private var showClearConfirmation = false
    @State private var showExportSheet = false
    @State private var exportedJSON = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. Header & Maturity
                maturitySection
                
                // 2. Stats Grid
                statsGrid
                
                // 3. Recent Activity
                activitySection
                
                // 4. Data Management
                dataManagementSection
            }
            .padding()
        }
        .navigationTitle("Learning Dashboard")
        .background(theme.background)
        .alert("Clear Learning History?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                learningService.clearData()
            }
        } message: {
            Text("This will reset all learned tag models and statistics. This action cannot be undone.")
        }
        .sheet(isPresented: $showExportSheet) {
            VStack {
                Text("Exported Learning Data")
                    .font(.headline)
                    .padding()
                TextEditor(text: $exportedJSON)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                Button("Close") {
                    showExportSheet = false
                }
                .padding()
            }
        }
    }
    
    // MARK: - Sections
    
    private var maturitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Model Maturity")
                .font(.headline)
                .foregroundColor(theme.textSecondary)
            
            HStack {
                Text(maturityTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.accent)
                
                Spacer()
                
                Text("\(Int(learningService.maturityLevel * 100))%")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            ProgressView(value: learningService.maturityLevel)
                .progressViewStyle(LinearProgressViewStyle(tint: theme.accent))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            Text(maturityDescription)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        }
        .padding()
        .background(theme.elevated)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statCard(
                title: "Total Interactions",
                value: "\(learningService.learningData.totalInteractions)",
                icon: "hand.tap.fill",
                color: .blue
            )
            
            statCard(
                title: "Learned Tags",
                value: "\(learningService.learningData.tagModels.count)",
                icon: "tag.fill",
                color: .purple
            )
            
            statCard(
                title: "Predictions",
                value: "\(learningService.learningData.totalPredictions)",
                icon: "sparkles",
                color: .orange
            )
            
            statCard(
                title: "Accuracy",
                value: accuracyString,
                icon: "target",
                color: .green
            )
        }
    }
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(theme.textSecondary)
            
            if learningService.learningData.recentActivities.isEmpty {
                Text("No recent activity. Start tagging papers to train the AI.")
                    .foregroundColor(theme.textSecondary)
                    .italic()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(learningService.learningData.recentActivities) { activity in
                    activityRow(activity)
                    Divider()
                }
            }
        }
        .padding()
        .background(theme.elevated)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var dataManagementSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                if let json = learningService.exportDataJSON() {
                    exportedJSON = json
                    showExportSheet = true
                }
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Learning Data")
                        .foregroundColor(theme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.elevated)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            Button(role: .destructive, action: {
                showClearConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear Learning History")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Helpers
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        }
        .padding()
        .background(theme.elevated)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func activityRow(_ activity: LearningActivity) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: activityIcon(for: activity.type))
                .foregroundColor(activityColor(for: activity.type))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                
                Text(activity.relatedItemTitle)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(activity.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(theme.textTertiary)
        }
    }
    
    private var maturityTitle: String {
        switch learningService.maturityLevel {
        case 0..<0.2: return "Beginner"
        case 0.2..<0.5: return "Growing"
        case 0.5..<0.8: return "Mature"
        default: return "Expert"
        }
    }
    
    private var maturityDescription: String {
        switch learningService.maturityLevel {
        case 0..<0.2: return "AI is just starting to learn your habits."
        case 0.2..<0.5: return "AI is beginning to understand your preferences."
        case 0.5..<0.8: return "AI can provide accurate suggestions."
        default: return "AI deeply understands your needs."
        }
    }
    
    private var accuracyString: String {
        let total = learningService.learningData.totalPredictions
        guard total > 0 else { return "N/A" }
        let accepted = learningService.learningData.acceptedPredictions
        let percentage = Double(accepted) / Double(total) * 100
        return String(format: "%.1f%%", percentage)
    }
    
    private func activityIcon(for type: LearningActivity.ActivityType) -> String {
        switch type {
        case .learnTag: return "brain.head.profile"
        case .predictTag: return "sparkles"
        case .acceptSuggestion: return "checkmark.circle.fill"
        case .rejectSuggestion: return "xmark.circle.fill"
        }
    }
    
    private func activityColor(for type: LearningActivity.ActivityType) -> Color {
        switch type {
        case .learnTag: return .blue
        case .predictTag: return .orange
        case .acceptSuggestion: return .green
        case .rejectSuggestion: return .gray
        }
    }
}
