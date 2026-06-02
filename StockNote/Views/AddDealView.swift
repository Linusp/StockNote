import SwiftUI
import SwiftData

struct AddDealView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var strategy: Strategy

    @State private var dealType: DealType = .deposit
    @State private var price = ""
    @State private var amount = ""
    @State private var fee = ""
    @State private var date = Date()

    // For stock selection
    @State private var searchText = ""
    @State private var searchResults: [Quote] = []
    @State private var selectedStock: Quote?
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            Form {
                // Deal type
                Section {
                    Picker("交易类型", selection: $dealType) {
                        Text("转入现金").tag(DealType.deposit)
                        Text("转出现金").tag(DealType.withdraw)
                        Text("买入").tag(DealType.buy)
                        Text("卖出").tag(DealType.sell)
                    }
                    .pickerStyle(.segmented)
                }

                // Stock selection (for buy/sell)
                if dealType == .buy || dealType == .sell {
                    Section("选择股票") {
                        TextField("搜索股票", text: $searchText)
                            .textInputAutocapitalization(.never)
                            .onChange(of: searchText) { _, newValue in
                                if newValue.count >= 2 {
                                    Task { await search() }
                                }
                            }

                        if isSearching {
                            HStack {
                                ProgressView()
                                Text("搜索中...")
                            }
                        }

                        ForEach(searchResults) { quote in
                            Button {
                                selectedStock = quote
                                searchText = quote.name
                                searchResults = []
                            } label: {
                                HStack {
                                    Text(quote.name)
                                        .foregroundStyle(.primary)
                                    Text(quote.zsCode)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    if selectedStock?.id == quote.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }

                        if let stock = selectedStock {
                            HStack {
                                Text("已选择:")
                                    .foregroundStyle(.secondary)
                                Text("\(stock.name) (\(stock.zsCode))")
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }

                // Amount
                Section {
                    if dealType == .deposit || dealType == .withdraw {
                        TextField("金额", text: $price)
                            .keyboardType(.decimalPad)
                    } else {
                        TextField("单价", text: $price)
                            .keyboardType(.decimalPad)
                        TextField("数量", text: $amount)
                            .keyboardType(.decimalPad)
                        TextField("手续费", text: $fee)
                            .keyboardType(.decimalPad)
                    }

                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }

                // Summary
                if let total = calculateTotal() {
                    Section("交易金额") {
                        Text(String(format: "%.2f %@", total, strategy.currency))
                            .fontWeight(.bold)
                            .foregroundStyle(dealType == .buy || dealType == .withdraw ? .green : .red)
                    }
                }
            }
            .navigationTitle("记录交易")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveDeal()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        guard let priceValue = Double(price), priceValue > 0 else { return false }

        if dealType == .buy || dealType == .sell {
            guard selectedStock != nil else { return false }
            guard let amountValue = Double(amount), amountValue > 0 else { return false }
        }

        return true
    }

    private func calculateTotal() -> Double? {
        guard let priceValue = Double(price), priceValue > 0 else { return nil }

        if dealType == .deposit || dealType == .withdraw {
            return priceValue
        }

        guard let amountValue = Double(amount), amountValue > 0 else { return nil }
        let feeValue = Double(fee) ?? 0

        if dealType == .buy {
            return priceValue * amountValue + feeValue
        } else {
            return priceValue * amountValue - feeValue
        }
    }

    private func search() async {
        isSearching = true
        defer { isSearching = false }

        do {
            searchResults = try await EastMoneyAPI.shared.search(keyword: searchText, category: "stock")
        } catch {
            searchResults = []
        }
    }

    private func saveDeal() {
        guard let priceValue = Double(price) else { return }

        let deal = Deal(
            type: dealType,
            price: priceValue,
            amount: Double(amount) ?? 0,
            fee: Double(fee) ?? 0,
            code: selectedStock?.zsCode,
            name: selectedStock?.name,
            date: date
        )

        strategy.deals.append(deal)
        dismiss()
    }
}

#Preview {
    let strategy = Strategy(name: "测试策略")
    return AddDealView(strategy: strategy)
        .modelContainer(for: [Strategy.self, Deal.self], inMemory: true)
}
