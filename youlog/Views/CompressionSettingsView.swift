import SwiftUI

// 压缩设置界面
struct CompressionSettingsView: View {
    @StateObject private var settings = CompressionSettings.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("压缩参数")) {
                    // 屏幕宽度倍数设置
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("屏幕宽度倍数")
                            Spacer()
                            Text(String(format: "%.1f", settings.screenWidthMultiplier))
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: $settings.screenWidthMultiplier,
                            in: 0.1...5.0,
                            step: 0.1
                        ) {
                            Text("屏幕宽度倍数")
                        } minimumValueLabel: {
                            Text("0.1")
                                .font(.caption)
                        } maximumValueLabel: {
                            Text("5.0")
                                .font(.caption)
                        }
                        
                        Text("目标宽度: \(Int(settings.targetWidth))px")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 压缩质量设置
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("压缩质量")
                            Spacer()
                            Text(String(format: "%.1f", settings.compressionQuality))
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: $settings.compressionQuality,
                            in: 0.1...1.0,
                            step: 0.1
                        ) {
                            Text("压缩质量")
                        } minimumValueLabel: {
                            Text("0.1")
                                .font(.caption)
                        } maximumValueLabel: {
                            Text("1.0")
                                .font(.caption)
                        }
                        
                        Text("质量越高，文件越大")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("自动压缩")) {
                    Toggle("系统相机拍摄后自动压缩", isOn: $settings.autoCompressSystemCamera)
                    
                    if settings.autoCompressSystemCamera {
                        Text("使用系统相机拍摄的照片将自动按照上述设置进行压缩")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("相机设置")) {
                    Toggle("默认使用系统相机拍照", isOn: $settings.defaultUseSystemCamera)
                    
                    if settings.defaultUseSystemCamera {
                        Text("开启后，点击相机按钮将直接使用系统相机，无需长按")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("重置为默认设置") {
                        settings.resetToDefaults()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("压缩设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CompressionSettingsView()
}