import SwiftUI

struct DateFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var startDate: Date
    @Binding var endDate: Date
    @State private var selectedButton: String?
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("快捷选择")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            QuickDateButton(
                                title: "今天",
                                isSelected: selectedButton == "今天",
                                action: {
                                    startDate = calendar.startOfDay(for: Date())
                                    endDate = calendar.endOfDay(for: Date())
                                    selectedButton = "今天"
                                    dismiss()
                                }
                            )
                            
                            QuickDateButton(
                                title: "昨天",
                                isSelected: selectedButton == "昨天",
                                action: {
                                    let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                                    startDate = calendar.startOfDay(for: yesterday)
                                    endDate = calendar.endOfDay(for: yesterday)
                                    selectedButton = "昨天"
                                    dismiss()
                                }
                            )
                            
                            QuickDateButton(
                                title: "前天",
                                isSelected: selectedButton == "前天",
                                action: {
                                    let dayBeforeYesterday = calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()
                                    startDate = calendar.startOfDay(for: dayBeforeYesterday)
                                    endDate = calendar.endOfDay(for: dayBeforeYesterday)
                                    selectedButton = "前天"
                                    dismiss()
                                }
                            )
                            
                            QuickDateButton(
                                title: "当月",
                                isSelected: selectedButton == "当月",
                                action: {
                                    let components = calendar.dateComponents([.year, .month], from: Date())
                                    startDate = calendar.date(from: components) ?? Date()
                                    endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) ?? Date()
                                    selectedButton = "当月"
                                    dismiss()
                                }
                            )
                            
                            QuickDateButton(
                                title: "当季度",
                                isSelected: selectedButton == "当季度",
                                action: {
                                    let components = calendar.dateComponents([.year], from: Date())
                                    let year = components.year ?? calendar.component(.year, from: Date())
                                    let quarter = (calendar.component(.month, from: Date()) - 1) / 3
                                    startDate = calendar.date(from: DateComponents(year: year, month: quarter * 3 + 1)) ?? Date()
                                    endDate = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: startDate) ?? Date()
                                    selectedButton = "当季度"
                                    dismiss()
                                }
                            )
                            
                            QuickDateButton(
                                title: "当年",
                                isSelected: selectedButton == "当年",
                                action: {
                                    let components = calendar.dateComponents([.year], from: Date())
                                    startDate = calendar.date(from: components) ?? Date()
                                    endDate = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startDate) ?? Date()
                                    selectedButton = "当年"
                                    dismiss()
                                }
                            )
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 44)
                }
                
                Section(header: Text("自定义日期")) {
                    DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                    DatePicker("结束日期", selection: $endDate, displayedComponents: .date)
                }
            }
            .navigationTitle("日期筛选")
            .navigationBarItems(trailing: Button("完成") {
                dismiss()
            })
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
                .foregroundColor(isSelected ? .white : .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }
} 