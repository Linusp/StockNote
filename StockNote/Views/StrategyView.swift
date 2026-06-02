import SwiftUI
import SwiftData
import Charts

struct StrategyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var strategies: [Strategy]

    @State private var selectedStrategy: Strategy?
    @State private var showingAddStrategy = false
    @State private var showingAddDeal = false

    var body: some View {
        NavigationStack {
            if strategies.isEmpty {
                ContentUnavailableView {
                    Label("暂无策略", systemImage: "chart.pie")
                } description: {
                    Text("点击下方按钮创建投资策略")
                } actions: {
                    Button("新建策略") {
                        showingAddStrategy = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                VStack(spacing: 0) {
                    // Strategy picker
                    Picker("策略", selection: $selectedStrategy) {
                        ForEach(strategies) { strategy in
                            Text(strategy.name).tag(strategy as Strategy?)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    if let strategy = selectedStrategy {
                        StrategyDetailView(strategy: strategy)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                showingAddStrategy = true
                            } label: {
                                Label("新建策略", systemImage: "plus")
                            }
                            if selectedStrategy != nil {
                                Button {
                                    showingAddDeal = true
                                } label: {
                                    Label("记录交易", systemImage: "plus.circle")
                                }
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .navigationTitle("策略")
        .onAppear {
            if selectedStrategy == nil, let first = strategies.first {
                selectedStrategy = first
            }
        }
        .sheet(isPresented: $showingAddStrategy) {
            AddStrategyView()
        }
        .sheet(isPresented: $showingAddDeal) {
            if let strategy = selectedStrategy {
                AddDealView(strategy: strategy)
            }
        }
    }
}

// MARK: - Strategy Detail

struct StrategyDetailView: View {
    @Bindable var strategy: Strategy

    var positions: [(code: String, name: String, amount: Double, costPrice: Double)] {
        var map: [String: (name: String, amount: Double, cost: Double)] = [:]

        let sortedDeals = strategy.deals.sorted { $0.date < $1.date }
        for deal in sortedDeals {
            guard let code = deal.code else { continue }
            let name = deal.name ?? code

            var current = map[code] ?? (name, 0, 0)
            if deal.type == .buy {
                current.cost += deal.price * deal.amount + deal.fee
                current.amount += deal.amount
            } else if deal.type == .sell {
                let ratio = deal.amount / current.amount
                current.cost -= current.cost * ratio
                current.amount -= deal.amount
            }
            map[code] = current
        }

        return map.filter { $0.value.amount > 0.0001 }
            .map { (code: $0.key, name: $0.value.name, amount: $0.value.amount, costPrice: $0.value.cost / $0.value.amount) }
            .sorted { $0.code < $1.code }
    }

    var body: some View {
        List {
            // Summary section
            Section("资产概览") {
                LabeledContent("现金余额") {
                    Text(String(format: "%.2f", strategy.cashBalance))
                        .fontWeight(.semibold)
                }
                LabeledContent("总投入") {
                    Text(String(format: "%.2f", strategy.totalPrincipal))
                }
                LabeledContent("持仓数") {
                    Text("\(positions.count)")
                }
            }

            // Positions
            if !positions.isEmpty {
                Section("当前持仓") {
                    ForEach(positions, id: \.code) { pos in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(pos.name)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(Int(pos.amount))股")
                                    .foregroundStyle(.secondary)
                            }
                            Text("成本: \(String(format: "%.3f", pos.costPrice))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Recent deals
            Section("最近交易") {
                if strategy.deals.isEmpty {
                    Text("暂无交易记录")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(strategy.deals.sorted { $0.date > $1.date }.prefix(10)) { deal in
                        DealRow(deal: deal)
                    }
                }
            }
        }
    }
}

// MARK: - Deal Row

struct DealRow: View {
    let deal: Deal

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(deal.type.label)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(dealColor.opacity(0.15))
                        .foregroundStyle(dealColor)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    if let name = deal.name {
                        Text(name)
                    } else if deal.type == .deposit || deal.type == .withdraw {
                        Text("现金")
                    }
                }

                Text(deal.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(String(format: "%.2f", deal.totalValue))
                .fontWeight(.medium)
                .foregroundStyle(deal.type == .buy || deal.type == .withdraw ? .green : .red)
        }
    }

    private var dealColor: Color {
        switch deal.type {
        case .buy: return .red
        case .sell: return .green
        case .deposit: return .blue
        case .withdraw: return .orange
        }
    }
}

#Preview {
    StrategyView()
        .modelContainer(for: [Strategy.self, Deal.self], inMemory: true)
}
