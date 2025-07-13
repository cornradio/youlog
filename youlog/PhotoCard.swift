import SwiftUI

// MARK: - 图片显示组件
/// 负责显示照片和备注的组件
/// 支持点击查看大图、长按显示操作菜单、点击备注编辑等功能
struct PhotoImageView: View {
    let imageData: Data?           // 图片数据
    let note: String?              // 备注内容
    let onTap: () -> Void         // 点击图片的回调
    let onLongPress: () -> Void   // 长按图片的回调
    let onNoteTap: () -> Void     // 点击备注的回调
    
    var body: some View {
        if let imageData = imageData,
           let uiImage = UIImage(data: imageData) {
            // 有图片数据时显示图片
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
//                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .bottom) {
                    // 如果有备注，在图片底部显示备注
                    if let note = note, !note.isEmpty {
                        VStack {
                            Spacer()
                            ZStack {
                                Text(note)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.black.opacity(0.5))  // 半透明黑色背景
                                    .cornerRadius(8)
                            }
                            .onTapGesture {
                                onNoteTap()  // 点击备注触发编辑
                            }
                        }
                    }
                }
                .onTapGesture {
                    onTap()  // 点击图片触发查看大图
                }
                .simultaneousGesture(
                    // 长按手势，0.5秒后触发
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            onLongPress()  // 长按触发操作菜单
                        }
                )
        } else {
            // 没有图片数据时显示占位符
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
        }
    }
}

// MARK: - 标签按钮组件
/// 显示单个标签的按钮组件
/// 支持点击编辑标签功能
struct TagButton: View {
    let item: Item                 // 照片数据项
    @Binding var selectedTag: String?  // 选中的标签
    
    var body: some View {
        Menu {
            ForEach(AppConstants.tagManager.availableTags, id: \.self) { tag in
                Button(action: {
                    selectedTag = AppConstants.tagManager.isAllTag(tag) ? nil : tag
                    item.tag = selectedTag
                }) {
                    HStack {
                        Text(tag)
                        if (item.tag == nil && AppConstants.tagManager.isAllTag(tag)) || item.tag == tag {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppConstants.themeManager.currentTheme.color)
                        }
                    }
                }
            }
        } label: {
            Text(item.tag ?? NSLocalizedString("all", comment: ""))
                .font(.caption)
                .foregroundColor(.primary)
                .padding(2)
                .background(AppConstants.themeManager.currentTheme.color.opacity(0.1))  // 主题色背景
                .cornerRadius(4)
                .overlay(
                    // 灰色边框
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// MARK: - 时间显示组件
/// 显示照片拍摄时间的组件
/// 包含时间和日期两部分
struct TimeDisplay: View {
    let timestamp: Date            // 时间戳
    
    // 时间格式化器 - 显示小时:分钟
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    // 日期格式化器 - 显示月/日
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }
    
    var body: some View {
        HStack {
            // 显示时间（小时:分钟）
            Text(timestamp, formatter: timeFormatter)
                .font(.caption)
                .foregroundColor(.primary)
            
            // 显示日期（月/日）
            Text(timestamp, formatter: dateFormatter)
                .font(.caption)
                .bold()
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 照片卡片主视图
/// 单个照片的完整显示组件
/// 包含图片、时间、标签、备注和操作菜单
struct PhotoCard: View {
    let item: Item                 // 照片数据项
    var allItems: [Item] = []      // 所有照片列表，用于全屏浏览
    @Environment(\.modelContext) private var modelContext  // SwiftData 数据上下文
    @State private var showingDeleteAlert = false          // 是否显示删除确认弹窗
    @State private var showingFullScreen = false           // 是否显示全屏浏览
    @State private var showingSaveSuccess = false          // 是否显示保存成功提示
    @State private var showingQuickActions = false         // 是否显示快速操作菜单
    @State private var showingNoteEditor = false           // 是否显示备注编辑器
    @State private var editedNote: String = ""             // 正在编辑的备注内容
    @State private var showingTagEditor = false            // 是否显示标签编辑器
    @State private var selectedTag: String?                // 选中的标签
    @State private var currentImageIndex: Int = 0          // 当前浏览的图片索引
    @State private var isMenuEnabled = true                // 菜单是否启用
    
    init(item: Item, allItems: [Item] = []) {
        self.item = item
        self.allItems = allItems.isEmpty ? [item] : allItems
        _editedNote = State(initialValue: item.note ?? "")
        _selectedTag = State(initialValue: item.tag)
    }
    
    // 获取所有图片的 UIImage 数组，用于全屏浏览
    private var itemImages: [UIImage] {
        allItems.compactMap { item in
            if let imageData = item.imageData {
                return UIImage(data: imageData)
            }
            return nil
        }
    }
    
    // 获取当前照片在所有照片中的索引
    private var currentItemIndex: Int {
        allItems.firstIndex(where: { $0.id == item.id }) ?? 0
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // 图片显示区域
                PhotoImageView(
                    imageData: item.imageData,
                    note: item.note,
                    onTap: { 
                        // 点击图片：设置当前索引并显示全屏浏览
                        currentImageIndex = currentItemIndex
                        showingFullScreen = true
                    },
                    onLongPress: { 
                        // 长按图片：显示快速操作菜单
                        showingQuickActions = true 
                    },
                    onNoteTap: { 
                        // 点击备注：显示备注编辑器
                        showingNoteEditor = true 
                    }
                )
                .contextMenu {
                    // 右键菜单（长按菜单）
                    if let imageData = item.imageData,
                       let uiImage = UIImage(data: imageData) {
                        MenuContent(
                            uiImage: uiImage,
                            item: item,
                            selectedTag: $selectedTag,  // 传递选中的标签
                            editedNote: $editedNote,
                            showingDeleteAlert: $showingDeleteAlert,
                            showingSaveSuccess: $showingSaveSuccess,
                            showingTagEditor: $showingTagEditor,
                            showingNoteEditor: $showingNoteEditor
                        )
                    }
                }
                
                // 底部信息栏：时间、标签、操作按钮
                HStack {
                    // 时间显示
                    TimeDisplay(timestamp: item.timestamp)
                    
                    // 标签显示和编辑
                    TagButton(item: item, selectedTag: $selectedTag)
                    
                    Spacer();
                    
                    // 更多操作菜单
                    Menu {
                        if let imageData = item.imageData,
                           let uiImage = UIImage(data: imageData) {
                            MenuContent(
                                uiImage: uiImage,
                                item: item,
                                selectedTag: $selectedTag,
                                editedNote: $editedNote,
                                showingDeleteAlert: $showingDeleteAlert,
                                showingSaveSuccess: $showingSaveSuccess,
                                showingTagEditor: $showingTagEditor,
                                showingNoteEditor: $showingNoteEditor
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AppConstants.themeManager.currentTheme.color)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // MARK: - 各种弹窗和提示
            // 删除确认弹窗
            .alert(NSLocalizedString("delete_photo", comment: ""), isPresented: $showingDeleteAlert) {
                Button(NSLocalizedString("cancel", comment: ""), role: .cancel) { }
                Button(NSLocalizedString("delete", comment: ""), role: .destructive) {
                    modelContext.delete(item)  // 从数据库中删除照片
                }
            } message: {
                Text(NSLocalizedString("delete_confirm_photo", comment: ""))
            }
            
            // 保存成功提示
            .alert(NSLocalizedString("save_success", comment: ""), isPresented: $showingSaveSuccess) {
                Button(NSLocalizedString("ok", comment: ""), role: .cancel) { }
            } message: {
                Text(NSLocalizedString("saved_to_photos", comment: ""))
            }
            
            // 标签编辑器弹窗
            .sheet(isPresented: $showingTagEditor) {
                TagEditorView(selectedTag: $selectedTag)
                    .onDisappear {
                        // 标签编辑器关闭时，更新照片的标签
                        item.tag = selectedTag
                    }
            }
            
            // 备注编辑器弹窗
            .sheet(isPresented: $showingNoteEditor) {
                NoteEditorView(note: $editedNote)
                    .onAppear {
                        // 打开备注编辑器时，加载当前备注
                        editedNote = item.note ?? ""
                    }
                    .onDisappear {
                        // 备注编辑器关闭时，保存备注到照片
                        item.note = editedNote
                    }
            }
            
            // 全屏图片浏览
            .navigationDestination(isPresented: $showingFullScreen) {
                ImageDetailView(images: itemImages, currentIndex: $currentImageIndex)
            }
        }
    }
}

   
