import SwiftUI
struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("基本功能")
                            .font(.title)
                            .bold()
                        
                        Text("# 添加照片")
                            .font(.headline)
                        Text("• 点击右上角"+"按钮\n• 选择【拍照】或【从相册选择】\n• 拍照时可以选择标签\n• 支持竖屏拍摄\n• 长按拍照按钮调用原相机")
                        
                        Text("# 照片管理")
                            .font(.headline)
                        Text("• 点击照片可以查看大图\n• 长按照片可以打开更多选项\n• 支持删除单张照片\n• 可以保存照片到相册")
                        
                        Text("# 标签系统 ⭐")
                            .font(.headline)
                        Text("• 默认标签：全部、未分类\n• 可以添加自定义标签\n• 点击标签可以筛选照片\n• 支持删除自定义标签")
                    }
                    
                    Group {
                        Text("# 照片备注 ⭐")
                            .font(.headline)
                        Text("• 点击照片底部的备注区域可以添加/编辑备注\n• 备注会显示在照片底部\n• 支持多行文本")
                        
                        Text("# 视图切换")
                            .font(.headline)
                        Text("• 支持网格视图和列表视图\n• 点击右上角视图图标切换\n• 网格视图适合快速浏览\n• 列表视图适合查看详细信息")
                    }
                    
                    Group {
                        Text("# 图片打包 ⭐")
                            .font(.headline)
                        Text("• 进入设置-图片打包功能\n• 点击打包图片按钮\n• 图片将被保存到设备的文件 app 中")
                        
                        Text("# 播放模式使用技巧")
                            .font(.headline)
                        Text("• 选择同一标签下的照片进入播放模式\n• 系统会按时间顺序展示照片\n• 可以快速对比形体变化\n• 建议每月或每季度进行一次对比\n• 播放时可以调整速度")
                    }
                    //增加一个linke按钮 跳转到 cornradio.org 是隐私政策

                    Link(destination: URL(string: "https://cornradio.org")!) {
                        Image(systemName: "link")
                        Text(NSLocalizedString("privacy_policy", comment: ""))
                            .font(.headline)
                    }
                }
                .padding()
            }
            .navigationBarItems(trailing: Button(NSLocalizedString("done", comment: "")) {
                dismiss()
            }
            .foregroundColor(AppConstants.themeManager.currentTheme.color))
        }
    }
}
