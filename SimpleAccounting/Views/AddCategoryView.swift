import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // 分类类型
    @State private var categoryType: String = "expense"
    // 分类名称
    @State private var categoryName: String = ""
    // 选中图标
    @State private var selectedIcon: String = "tag"
    // 选中颜色
    @State private var selectedColor: String = "#007AFF"
    // 错误提示
    @State private var showError = false
    @State private var errorMessage = ""

    // 可选的图标列表
    private let availableIcons = [
        "tag", "cart", "car", "fork.knife", "film", "book", "house",
        "briefcase", "star", "heart", "gift", "creditcard", "banknote",
        "airplane", "bus", "tram", "bicycle", "figure.walk", "cross",
        "pills", "cup.and.saucer", "leaf", "flame", "snowflake", "sun.max",
        "moon", "cloud", "umbrella", "paintbrush", "pencil", "scissors",
        "hammer", "wrench", "gear", "phone", "envelope", "music.note",
        "gamecontroller", "tv", "desktopcomputer", "keyboard", "camera",
        "photo", "printer", "doc", "folder", "trash", "arrow.up.circle",
        "arrow.down.circle", "plus.circle", "minus.circle", "checkmark.circle"
    ]

    // 可选颜色列表
    private let availableColors = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD",
        "#98D8C8", "#95A5A6", "#2ECC71", "#F1C40F", "#3498DB", "#E74C3C",
        "#9B59B6", "#1ABC9C", "#34495E", "#E67E22", "#16A085", "#C0392B",
        "#007AFF", "#5856D6", "#FF2D55", "#FF9500", "#FFCC00", "#00C7BE"
    ]

    var body: some View {
        NavigationStack {
            Form {
                // 分类类型选择
                Section {
                    Picker("类型", selection: $categoryType) {
                        Text("支出").tag("expense")
                        Text("收入").tag("income")
                    }
                    .pickerStyle(.segmented)
                }

                // 分类名称输入
                Section {
                    TextField("分类名称（10字以内）", text: $categoryName)
                        .onChange(of: categoryName) { _, newValue in
                            if newValue.count > 10 {
                                categoryName = String(newValue.prefix(10))
                            }
                        }
                }

                // 图标选择
                Section("选择图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 15) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(selectedIcon == icon ? Color(hex: selectedColor) : .gray)
                                    
                                    if selectedIcon == icon {
                                        Circle()
                                            .fill(Color(hex: selectedColor))
                                            .frame(width: 6, height: 6)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedIcon == icon ? Color(hex: selectedColor) : Color.gray.opacity(0.3), lineWidth: selectedIcon == icon ? 2 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // 颜色选择
                Section("选择颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 15) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.caption)
                                            .opacity(selectedColor == color ? 1 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // 预览
                Section("预览") {
                    HStack {
                        Image(systemName: selectedIcon)
                            .foregroundColor(Color(hex: selectedColor))
                            .frame(width: 30, height: 30)
                            .background(Color(hex: selectedColor).opacity(0.1))
                            .cornerRadius(15)
                        Text(categoryName.isEmpty ? "分类名称" : categoryName)
                        Spacer()
                        Text(categoryType == "expense" ? "支出" : "收入")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("添加分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveCategory()
                    }
                    .disabled(categoryName.isEmpty)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "请输入分类名称"
            showError = true
            return
        }

        guard trimmedName.count <= 10 else {
            errorMessage = "分类名称不能超过10个字"
            showError = true
            return
        }

        let category = Category(
            name: trimmedName,
            icon: selectedIcon,
            color: selectedColor,
            type: categoryType,
            sortOrder: 0,
            isDefault: false
        )

        modelContext.insert(category)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            showError = true
        }
    }
}

#Preview {
    let schema = Schema([
        Transaction.self,
        Category.self,
        Ledger.self,
        Tag.self,
        Budget.self
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: configuration)

    return AddCategoryView()
        .modelContainer(container)
}
