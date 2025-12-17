//
//  EmptyStateView.swift
//  youlog
//
//  Created by kasusa on 2025/3/28.
//

import SwiftUI

struct EmptyStateView: View {
    var title: String = "No Photos found"
    var systemImage: String = "photo.on.rectangle.angled"
    var description: String = "Try changing your filters or adding new photos"
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(AppConstants.themeManager.currentTheme.color.opacity(0.5))
                .padding()
                .background(
                    Circle()
                        .fill(AppConstants.themeManager.currentTheme.color.opacity(0.1))
                        .frame(width: 120, height: 120)
                )
                .padding(.bottom, 10)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    EmptyStateView()
}
