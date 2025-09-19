import SwiftUI

struct LiquidGlassTestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isInteractive = false
    @State private var showContainer = false
    @State private var showUnion = false
    @State private var offsetX: CGFloat = 0
    @Namespace private var namespace
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // 标题
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(AppConstants.themeManager.currentTheme.color)
                        
                        Text("Liquid Glass 效果测试")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("基于 Apple 官方指南实现的各种 Liquid Glass 效果")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // 基础 Glass 效果
                    VStack(alignment: .leading, spacing: 16) {
                        Text("基础 Glass 效果")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            // 默认 Capsule 形状
                            Text("Hello, World!")
                                .font(.title3)
                                .padding()
                                .glassEffect()
                            
                            // 自定义圆角矩形
                            Text("自定义圆角")
                                .font(.title3)
                                .padding()
                                .glassEffect(in: .rect(cornerRadius: 16.0))
                            
                            // 带颜色和交互的效果
                            Text("交互式 Glass")
                                .font(.title3)
                                .padding()
                                .glassEffect(.regular.tint(.orange).interactive(isInteractive))
                        }
                    }
                    
                    // 交互控制
                    VStack(spacing: 12) {
                        Text("交互控制")
                            .font(.headline)
                        
                        Toggle("启用交互效果", isOn: $isInteractive)
                            .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Glass 容器效果
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Glass 容器效果")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Toggle("显示容器效果", isOn: $showContainer)
                            .padding(.horizontal)
                        
                        if showContainer {
                            GlassEffectContainer(spacing: 40.0) {
                                HStack(spacing: 40.0) {
                                    Image(systemName: "scribble.variable")
                                        .frame(width: 80.0, height: 80.0)
                                        .font(.system(size: 36))
                                        .glassEffect()
                                    
                                    Image(systemName: "eraser.fill")
                                        .frame(width: 80.0, height: 80.0)
                                        .font(.system(size: 36))
                                        .glassEffect()
                                        .offset(x: offsetX, y: 0.0)
                                }
                            }
                            .padding()
                            
                            // 偏移控制
                            VStack {
                                Text("拖动滑块查看形状融合效果")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Slider(value: $offsetX, in: -60...60)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Glass Union 效果
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Glass Union 效果")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Toggle("显示 Union 效果", isOn: $showUnion)
                            .padding(.horizontal)
                        
                        if showUnion {
                            let symbolSet: [String] = ["cloud.bolt.rain.fill", "sun.rain.fill", "moon.stars.fill", "moon.fill"]
                            
                            GlassEffectContainer(spacing: 20.0) {
                                HStack(spacing: 20.0) {
                                    ForEach(symbolSet.indices, id: \.self) { item in
                                        Image(systemName: symbolSet[item])
                                            .frame(width: 60.0, height: 60.0)
                                            .font(.system(size: 28))
                                            .glassEffect()
                                            .glassEffectUnion(id: item < 2 ? "group1" : "group2", namespace: namespace)
                                    }
                                }
                            }
                            .padding()
                            
                            Text("前两个图标为一组，后两个图标为另一组")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // 更多示例
                    VStack(alignment: .leading, spacing: 16) {
                        Text("更多示例")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            // 按钮样式
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "heart.fill")
                                    Text("Glass 按钮")
                                }
                                .padding()
                                .glassEffect(.regular.tint(.pink).interactive())
                            }
                            
                            // 卡片样式
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "photo")
                                        .foregroundColor(AppConstants.themeManager.currentTheme.color)
                                    Text("Glass 卡片")
                                        .font(.headline)
                                    Spacer()
                                }
                                
                                Text("这是一个使用 Liquid Glass 效果的卡片示例，展示了如何在自定义组件中应用这种材质效果。")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .glassEffect(in: .rect(cornerRadius: 12))
                            
                            // 圆形图标
                            HStack(spacing: 20) {
                                ForEach(["star.fill", "heart.fill", "bookmark.fill"], id: \.self) { icon in
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                        .background(AppConstants.themeManager.currentTheme.color)
                                        .clipShape(Circle())
                                        .glassEffect(in: .circle)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Liquid Glass 测试")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(AppConstants.themeManager.currentTheme.color)
                }
            }
        }
    }
}

#Preview {
    LiquidGlassTestView()
}