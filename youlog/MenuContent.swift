import SwiftUI

// 共享的菜单内容视图
    struct MenuContent: View {
        let uiImage: UIImage
        let item: Item
        @Binding var selectedTag: String?
        @Binding var editedNote: String
        @Binding var showingDeleteAlert: Bool
        @Binding var showingSaveSuccess: Bool
        @Binding var showingTagEditor: Bool
        @Binding var showingNoteEditor: Bool
        @Environment(\.modelContext) private var modelContext  // 添加 modelContext
        
        var body: some View {
            Button(action: {
                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                showingSaveSuccess = true
            }) {
                Label(NSLocalizedString("save_to_photos", comment: ""), systemImage: "square.and.arrow.down")
            }
            
            Button(action: {
                // 使用与ImageDetailView相同的分享实现
                let av = UIActivityViewController(activityItems: [uiImage], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    av.popoverPresentationController?.sourceView = window
                    av.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                    window.rootViewController?.present(av, animated: true, completion: nil)
                }
            }) {
                Label(NSLocalizedString("share_photo", comment: ""), systemImage: "square.and.arrow.up")
            }

            Button(action: {
                selectedTag = item.tag
                showingTagEditor = true
            }) {
                Label(NSLocalizedString("edit_tags", comment: ""), systemImage: "tag")
            }

            Button(action: {
                editedNote = item.note ?? ""
                showingNoteEditor = true
            }) {
                Label(NSLocalizedString("edit_note", comment: ""), systemImage: "pencil")
            }
            
            // Button(role: .destructive, action: {
            //     //显示确认
            //     showingDeleteAlert = true
            // }) {
            //     Label("删除照片", systemImage: "trash")
            // }
            //增加一个按钮 强制删除 - 不提示弹窗
            Button(role: .destructive, action: {
                modelContext.delete(item)
            }) {
                Label(NSLocalizedString("permanent_delete", comment: ""), systemImage: "delete.left")
            }
        }
    }
    
// 分享Sheet
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
    
