//
//  SupportDeveloperView.swift
//  youlog
//
//  Created by kasusa on 2025/9/21.
//


import SwiftUI
import SwiftData
import PhotosUI
import Photos
import AVKit
import AVFoundation
import PhotosUI
import SwiftUI

struct SupportDeveloperView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "cup.and.saucer.fill")
                    .resizable()
                    .frame(width: 60, height: 40)
                    .foregroundColor(AppConstants.themeManager.currentTheme.color)
                Text("Youlog 是免费 App，如果觉得这个软件很棒，欢迎用钱支持我！")
                    .multilineTextAlignment(.center)
                    .font(.title3)
                    .padding(.horizontal)
                // 收款码图片（请替换为您的二维码图片）
                Image("donate_qr")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .cornerRadius(16)
                    .shadow(radius: 8)
                    .padding(.bottom, 8)
                
                Text("也欢迎在 App Store 下您的好评！\n 以及把 App 分享给更多朋友！")
                Button(action: openAppStoreReview) {
                    Label("去 App Store 写好评", systemImage: "star.bubble.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppConstants.themeManager.currentTheme.color)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                Spacer()
            }
            .navigationTitle("支持开发者")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
           
        }
    }
    // 替换为您的App Store ID
    private let appStoreID = "6743986266"
    private func openAppStoreReview() {
        let urlStr = "https://apps.apple.com/app/id\(appStoreID)?action=write-review"
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url)
        }
    }
}