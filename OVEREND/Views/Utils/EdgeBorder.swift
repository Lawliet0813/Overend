//
//  EdgeBorder.swift
//  OVEREND
//
//  邊框工具擴展 - 允許單獨邊緣繪製邊框
//

import SwiftUI

// MARK: - EdgeBorder Shape

/// 可選邊緣的邊框 Shape
struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        for edge in edges {
            switch edge {
            case .top:
                path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width))
            case .bottom:
                path.addRect(CGRect(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
            case .leading:
                path.addRect(CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height))
            case .trailing:
                path.addRect(CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
            }
        }
        
        return path
    }
}

// MARK: - View Extension

extension View {
    /// 為指定邊緣添加邊框
    /// - Parameters:
    ///   - width: 邊框寬度
    ///   - edges: 要添加邊框的邊緣
    ///   - color: 邊框顏色
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}
