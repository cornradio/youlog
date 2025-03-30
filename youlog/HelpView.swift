import SwiftUI
struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("如何拍出合适的照片")
                            .font(.title)
                            .bold()
                        
                        Text("1. 位置选择")
                            .font(.headline)
                        Text("• 选择固定的拍摄位置，保持每天在同一位置拍摄\n• 确保背景简洁，避免杂乱\n• 选择有特色的背景，如窗户、墙面等\n• 保持拍摄距离一致")
                        
                        Text("2. 动作姿势")
                            .font(.headline)
                        Text("• 保持自然放松的姿势\n• 可以尝试不同的动作，但建议每天保持相似\n• 注意保持身体姿态的一致性\n• 可以加入一些手势或道具增加趣味性")
                        
                        Text("3. 光线控制")
                            .font(.headline)
                        Text("• 选择光线充足的时间段\n• 避免强烈的直射光\n• 注意光线的方向，建议使用侧光或柔和的自然光\n• 保持每天拍摄时间相近，确保光线条件一致")
                    }
                    
                    Group {
                        Text("4. 拍摄技巧")
                            .font(.headline)
                        Text("• 使用手机支架保持稳定\n• 开启网格线辅助构图\n• 注意保持画面水平\n• 可以尝试不同的拍摄角度")
                        
                        Text("5. 注意事项")
                            .font(.headline)
                        Text("• 确保拍摄环境整洁\n• 注意服装搭配的协调性\n• 保持心情愉悦，展现真实的自己\n• 记录下每天的变化和进步")
                    }
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("完成") {
                dismiss()
            })
        }
    }
}
