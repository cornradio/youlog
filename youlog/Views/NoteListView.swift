import SwiftUI

struct NoteListView: View {
    let items: [Item]
    @State private var editingNoteItem: Item?
    @State private var editingNoteText = ""
    @State private var showingNoteEditor = false
    @State private var showingFullScreenImage: Item? // Track which item's image to show full screen
    
    var itemsWithNotes: [Item] {
        items.filter { $0.note != nil && !$0.note!.isEmpty }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        List {
            ForEach(itemsWithNotes) { item in
                Button(action: {
                    editingNoteItem = item
                    editingNoteText = item.note ?? ""
                    showingNoteEditor = true
                }) {
                    HStack(alignment: .top, spacing: 12) {
                        // Thumbnail Image
                        if let imageData = item.imageData, let image = UIImage(data: imageData) {
                            Button(action: {
                                showingFullScreenImage = item
                            }) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(PlainButtonStyle()) // Prevent list row tap from interfering
                        } else {
                            // Placeholder if no image (though unlikely for youlog items)
                            Rectangle()
                                .fill(Color.secondary.opacity(0.1))
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if let note = item.note {
                                Text(note)
                                    .font(.body)
                                    .lineLimit(3)
                                    .foregroundColor(.primary)
                            }
                            
                            Text(dateFormatter.string(from: item.timestamp))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("所有笔记")
        .overlay(
            Group {
                if itemsWithNotes.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "note.text.badge.plus")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("还没有笔记")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        )
        // Note Editor Sheet
        .sheet(isPresented: $showingNoteEditor) {
            if let item = editingNoteItem {
                NoteEditorView(note: Binding(
                    get: { item.note ?? "" },
                    set: { item.note = $0 }
                ))
            }
        }
        // Full Screen Image Cover
        .fullScreenCover(item: $showingFullScreenImage) { item in
            if let imageData = item.imageData, let image = UIImage(data: imageData) {
                NoteImageDetailView(image: image)
            }
        }
    }
}

// Simple View for Full Screen Image in Note List
struct NoteImageDetailView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

#Preview {
    NoteListView(items: [])
}
