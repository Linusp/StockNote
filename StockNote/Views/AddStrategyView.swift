import SwiftUI
import SwiftData

struct AddStrategyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var description = ""
    @State private var currency = "CNY"

    let currencies = ["CNY", "USD", "HKD"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("策略名称", text: $name)
                    TextField("描述（可选）", text: $description)
                }

                Section {
                    Picker("基准货币", selection: $currency) {
                        ForEach(currencies, id: \.self) { c in
                            Text(currencyName(c)).tag(c)
                        }
                    }
                }
            }
            .navigationTitle("新建策略")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        createStrategy()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func currencyName(_ code: String) -> String {
        switch code {
        case "CNY": return "人民币 (CNY)"
        case "USD": return "美元 (USD)"
        case "HKD": return "港币 (HKD)"
        default: return code
        }
    }

    private func createStrategy() {
        let strategy = Strategy(
            name: name,
            currency: currency,
            desc: description.isEmpty ? nil : description
        )
        modelContext.insert(strategy)
        dismiss()
    }
}

#Preview {
    AddStrategyView()
        .modelContainer(for: Strategy.self, inMemory: true)
}
