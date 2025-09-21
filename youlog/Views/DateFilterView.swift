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

                
                Section(header: Text(NSLocalizedString("quick_select", comment: ""))) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            QuickDateButton(
                                title: NSLocalizedString("today", comment: ""),
                                isSelected: selectedButton == NSLocalizedString("today", comment: ""),
                                action: {
                                    startDate = startOfDay(Date())
                                    endDate = endOfDay(Date())
                                    selectedButton = NSLocalizedString("today", comment: "")
                                    dismiss()
                                }
                            )
                            
                            QuickDateButton(
                                title: NSLocalizedString("yesterday", comment: ""),
                                isSelected: selectedButton == NSLocalizedString("yesterday", comment: ""),
                                action: {
                                    let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                                    startDate = startOfDay(yesterday)
                                    endDate = endOfDay(yesterday)
                                    selectedButton = NSLocalizedString("yesterday", comment: "")
                                    dismiss()
                                }
                            )
                            
                            QuickDateButton(
                                title: NSLocalizedString("day_before_yesterday", comment: ""),
                                isSelected: selectedButton == NSLocalizedString("day_before_yesterday", comment: ""),
                                action: {
                                    let dayBeforeYesterday = calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()
                                    startDate = startOfDay(dayBeforeYesterday)
                                    endDate = endOfDay(dayBeforeYesterday)
                                    selectedButton = NSLocalizedString("day_before_yesterday", comment: "")
                                    dismiss()
                                }
                            )
                            
                            QuickDateButton(
                                title: NSLocalizedString("current_month", comment: ""),
                                isSelected: selectedButton == NSLocalizedString("current_month", comment: ""),
                                action: {
                                    let components = calendar.dateComponents([.year, .month], from: Date())
                                    startDate = calendar.date(from: components) ?? Date()
                                    endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) ?? Date()
                                    selectedButton = NSLocalizedString("current_month", comment: "")
                                    dismiss()
                                }
                            )
                            
                            QuickDateButton(
                                title: NSLocalizedString("current_quarter", comment: ""),
                                isSelected: selectedButton == NSLocalizedString("current_quarter", comment: ""),
                                action: {
                                    let components = calendar.dateComponents([.year], from: Date())
                                    let year = components.year ?? calendar.component(.year, from: Date())
                                    let quarter = (calendar.component(.month, from: Date()) - 1) / 3
                                    startDate = calendar.date(from: DateComponents(year: year, month: quarter * 3 + 1)) ?? Date()
                                    endDate = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: startDate) ?? Date()
                                    selectedButton = NSLocalizedString("current_quarter", comment: "")
                                    dismiss()
                                }
                            )
                            
                            QuickDateButton(
                                title: NSLocalizedString("current_year", comment: ""),
                                isSelected: selectedButton == NSLocalizedString("current_year", comment: ""),
                                action: {
                                    let components = calendar.dateComponents([.year], from: Date())
                                    startDate = calendar.date(from: components) ?? Date()
                                    endDate = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startDate) ?? Date()
                                    selectedButton = NSLocalizedString("current_year", comment: "")
                                    dismiss()
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