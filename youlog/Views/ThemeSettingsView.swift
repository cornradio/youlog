import SwiftUI

struct ThemeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = AppConstants.themeManager
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("外观设置")) {
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.primary)
                            .font(.title2)
                        
                        Text("永远使用暗色主题")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { themeManager.alwaysUseDarkTheme },
                            set: { themeManager.setAlwaysUseDarkTheme($0) }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: themeManager.currentTheme.color))
                    }
                }
                
                Section(header: Text("选择主题色")) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        HStack {
                            Image(systemName: theme.systemImage)
                                .foregroundColor(theme.color)
                                .font(.title2)
                            
                            Text(theme.rawValue)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark")
                                    .foregroundColor(theme.color)
                                    .font(.title3)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            themeManager.setTheme(theme)
                        }
                    }
                }
                
                Section(header: Text("预览"), footer: Text("主题色会影响应用中的按钮、标签和强调色（部分按钮颜色需重启app后生效）")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("主题色预览")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.color)
                        
                        HStack {
                            Button("主要按钮") {
                                // 预览按钮
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(themeManager.currentTheme.color)
                            .cornerRadius(8)
                            
                            Button("次要按钮") {
                                // 预览按钮
                            }
                            .foregroundColor(themeManager.currentTheme.color)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(themeManager.currentTheme.color.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(themeManager.currentTheme.color)
                            Text("标签示例")
                                .foregroundColor(themeManager.currentTheme.color)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(themeManager.currentTheme.color.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("主题设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.color)
                }
            }
        }
    }
}

#Preview {
    ThemeSettingsView()
}