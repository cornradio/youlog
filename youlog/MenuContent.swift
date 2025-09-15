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
        let onEditTime: () -> Void  // 修改时间的回调
        @Environment(\.modelContext) private var modelContext  // 添加 modelContext
        
        var body: some View {
            // 第一组：保存相册、分享照片
            Button(action: {
                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                showingSaveSuccess = true
            }) {
                Label(NSLocalizedString("save_to_photos", comment: ""), systemImage: "photo.on.rectangle")
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
            
            Divider()
            
            // 第二组：编辑标签、修改时间、编辑笔记
            Button(action: {
                selectedTag = item.tag
                showingTagEditor = true
            }) {
                Label(NSLocalizedString("edit_tags", comment: ""), systemImage: "tag")
            }
            
            Button(action: {
                onEditTime()
            }) {
                Label("修改时间", systemImage: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
            }

            Button(action: {
                editedNote = item.note ?? ""
                showingNoteEditor = true
            }) {
                Label(NSLocalizedString("edit_note", comment: ""), systemImage: "square.and.pencil")
            }
            
            Divider()
            
            // 第三组：永久删除
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
    
