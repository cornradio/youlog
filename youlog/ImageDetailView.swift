import SwiftUI

struct ImageDetailView: View {
    let image: UIImage
    let item: Item
    @Environment(\.dismiss) private var dismiss
    @State private var note: String
    @State private var showingNoteEditor = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var showingClearNoteAlert = false
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var dragOffset: CGFloat = 0 // 用于跟踪拖动偏移量
    @State private var isDetailViewActive = true // 控制视图的显示/隐藏
    
    init(image: UIImage, item: Item) {
        self.image = image
        self.item = item
        self._note = State(initialValue: item.note ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 图片区域
                    GeometryReader { geometry in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: .infinity)
                            .scaleEffect(scale)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale = min(max(scale * delta, 1), 4)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    }
                            )
                            .gesture(
                            DragGesture()
                                    .onChanged { value in
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                                    
                            )
                            .offset(offset)
                            
                    }
                    
                    // 笔记预览区域
                    if !note.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("笔记")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Button(action: { showingClearNoteAlert = true }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            
                            Text(note)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineLimit(3)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { 
                        item.note = note
                        dismiss() 
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNoteEditor = true }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingNoteEditor) {
                NoteEditorView(note: $note)
            }
            .alert("清空笔记", isPresented: $showingClearNoteAlert) {
                Button("取消", role: .cancel) { }
                Button("清空", role: .destructive) {
                    note = ""
                }
            } message: {
                Text("确定要清空笔记内容吗？")
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.width > 0 { // 仅检测向右拖动
                        dragOffset = value.translation.width
                    }
                }
                .onEnded { value in
                    if value.translation.width > 100 { // 阈值，可调整
                        item.note = note
                        dismiss()
                    }
                    dragOffset = 0
                }
        )
        .offset(x: dragOffset) // 应用拖动偏移量
    }
}

struct NoteEditorView: View {
    @Binding var note: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $note)
                    .padding()
                    .background(Color(.systemBackground))
            }
            .navigationTitle("编辑笔记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
} 
