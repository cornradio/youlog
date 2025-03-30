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
                Label("保存到相册", systemImage: "square.and.arrow.down")
            }

            Button(action: {
                selectedTag = item.tag
                showingTagEditor = true
            }) {
                Label("编辑标签", systemImage: "tag")
            }

            Button(action: {
                editedNote = item.note ?? ""
                showingNoteEditor = true
            }) {
                Label("编辑笔记", systemImage: "pencil")
            }
            

            Button(role: .destructive, action: {
                //显示确认
                showingDeleteAlert = true
            }) {
                Label("删除照片", systemImage: "trash")
            }
            //增加一个按钮 强制删除 - 不提示弹窗
            Button(role: .destructive, action: {
                modelContext.delete(item)
            }) {
                Label("强制删除", systemImage: "delete.left")
            }
            
        }
    }
    
