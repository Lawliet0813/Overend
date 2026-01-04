//
//  StarRating.swift
//  OVEREND
//
//  星級評分元件
//

import SwiftUI

/// 互動式星級評分元件
struct StarRating: View {
    @Binding var rating: Int
    @EnvironmentObject var theme: AppTheme
    
    let maxRating: Int = 5
    let size: CGFloat = 24
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundColor(index <= rating ? starColor(for: rating) : theme.textMuted.opacity(0.3))
                    .onTapGesture {
                        withAnimation(AnimationSystem.Easing.quick) {
                            if rating == index {
                                rating = 0  // 點擊同一星星則清除評分
                            } else {
                                rating = index
                            }
                        }
                    }
            }
            
            if rating > 0 {
                Text(ratingLabel)
                    .font(.system(size: DesignTokens.Typography.caption))
                    .foregroundColor(starColor(for: rating))
                    .padding(.leading, 8)
            }
        }
    }
    
    /// 根據評分返回對應顏色
    private func starColor(for rating: Int) -> Color {
        switch rating {
        case 1: return Color(hex: "#F44336")  // 紅色
        case 2: return Color(hex: "#FF9800")  // 橙色
        case 3: return Color(hex: "#FFC107")  // 黃色
        case 4: return Color(hex: "#8BC34A")  // 淺綠
        case 5: return Color(hex: "#4CAF50")  // 綠色
        default: return theme.textMuted
        }
    }
    
    /// 評分標籤
    private var ratingLabel: String {
        switch rating {
        case 1: return "很差"
        case 2: return "較差"
        case 3: return "一般"
        case 4: return "不錯"
        case 5: return "完美"
        default: return ""
        }
    }
}

/// 只讀星級顯示
struct StarRatingDisplay: View {
    let rating: Int
    @EnvironmentObject var theme: AppTheme
    
    let size: CGFloat = 16
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundColor(index <= rating ? starColor(for: rating) : theme.textMuted.opacity(0.3))
            }
        }
    }
    
    private func starColor(for rating: Int) -> Color {
        switch rating {
        case 1, 2: return Color(hex: "#F44336")
        case 3: return Color(hex: "#FFC107")
        case 4, 5: return Color(hex: "#4CAF50")
        default: return Color(hex: "#9E9E9E")
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StarRating(rating: .constant(3))
        StarRating(rating: .constant(5))
        StarRating(rating: .constant(0))
        
        Divider()
        
        StarRatingDisplay(rating: 4)
        StarRatingDisplay(rating: 2)
    }
    .padding()
    .environmentObject(AppTheme())
}
