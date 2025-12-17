import SwiftUI

struct DateFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var startDate: Date
    @Binding var endDate: Date
    let items: [Item] // 添加实际数据参数
    @State private var selectedButton: String?
    @State private var showingSlider = false
    
    private let calendar = Calendar.current
    
    // 计算最早图片日期和今天
    private var earliestDate: Date {
        if let earliestItem = items.min(by: { $0.timestamp < $1.timestamp }) {
            return calendar.startOfDay(for: earliestItem.timestamp)
        }
        // 如果没有数据，使用一年前作为默认值
        return calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    }
    
    private var today: Date {
        return Date()
    }
    

    
    // 获取一天的开始时间（00:00）
    private func startOfDay(_ date: Date) -> Date {
        return calendar.startOfDay(for: date)
    }
    
    // 获取一天的结束时间（23:59:59）
    private func endOfDay(_ date: Date) -> Date {
        return calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay(date)) ?? date
    }
    
    var body: some View {
        NavigationView {
            Form {

                
                Section {
                    NavigationLink(destination: AllImagesView(items: items)) {
                        Label("查看所有图片预览", systemImage: "photo.stack")
                    }
                    
                    NavigationLink(destination: NoteListView(items: items)) {
                        Label("查看所有笔记", systemImage: "note.text")
                    }
                }
                
                Section(header: Text(NSLocalizedString("quick_select", comment: ""))) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // 今天
                            QuickDateButton(
                                title: "今天",
                                isSelected: selectedButton == "今天",
                                action: {
                                    startDate = startOfDay(Date())
                                    endDate = endOfDay(Date())
                                    selectedButton = "今天"
                                    dismiss()
                                }
                            )
                            
                            // 近三天
                            QuickDateButton(
                                title: "近三天",
                                isSelected: selectedButton == "近三天",
                                action: {
                                    let threeDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()
                                    startDate = startOfDay(threeDaysAgo)
                                    endDate = endOfDay(Date())
                                    selectedButton = "近三天"
                                    dismiss()
                                }
                            )
                            
                            // 近一周
                            QuickDateButton(
                                title: "近一周",
                                isSelected: selectedButton == "近一周",
                                action: {
                                    let oneWeekAgo = calendar.date(byAdding: .day, value: -6, to: Date()) ?? Date()
                                    startDate = startOfDay(oneWeekAgo)
                                    endDate = endOfDay(Date())
                                    selectedButton = "近一周"
                                    dismiss()
                                }
                            )
                            
                            // 近一个月
                            QuickDateButton(
                                title: "近一个月",
                                isSelected: selectedButton == "近一个月",
                                action: {
                                    let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                                    startDate = startOfDay(oneMonthAgo)
                                    endDate = endOfDay(Date())
                                    selectedButton = "近一个月"
                                    dismiss()
                                }
                            )
                            
                            // 全部 (2025-01-01 至今)
                            QuickDateButton(
                                title: "全部",
                                isSelected: selectedButton == "全部",
                                action: {
                                    var components = DateComponents()
                                    components.year = 2025
                                    components.month = 1
                                    components.day = 1
                                    if let start = calendar.date(from: components) {
                                        startDate = startOfDay(start)
                                        endDate = endOfDay(Date())
                                        selectedButton = "全部"
                                        dismiss()
                                    }
                                }
                            )
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 44)
                }
                
                Section(header: Text(NSLocalizedString("custom_date", comment: ""))) {
                    DatePicker(NSLocalizedString("start_date", comment: ""), selection: $startDate, displayedComponents: .date)
                    DatePicker(NSLocalizedString("end_date", comment: ""), selection: $endDate, displayedComponents: .date)
                }


            }
            .navigationTitle(NSLocalizedString("date_filter", comment: ""))
            .navigationBarItems(trailing: Button(NSLocalizedString("done", comment: "")) {
                dismiss()
            }
            .foregroundColor(AppConstants.themeManager.currentTheme.color))
        }
    }
}

struct QuickDateButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : AppConstants.themeManager.currentTheme.color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppConstants.themeManager.currentTheme.color : AppConstants.themeManager.currentTheme.color.opacity(0.1))
                .cornerRadius(8)
        }
    }
} 