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