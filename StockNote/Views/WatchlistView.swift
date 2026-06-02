import SwiftUI
import SwiftData

struct WatchlistView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var stocks: [Stock]
    @Query private var tags: [Tag]

    @State private var selectedTag: Tag?
    @State private var showingAddStock = false
    @State private var showingTagManager = false
    @State private var searchText = ""
    @State private var isRefreshing = false

    var filteredStocks: [Stock] {
        var result = stocks
        if let tag = selectedTag {
            result = result.filter { $0.tags.contains(tag) }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.code.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result.sorted { $0.addedAt > $1.addedAt }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tag filter bar
                if !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            TagChip(tag: nil, isSelected: selectedTag == nil) {
                                selectedTag = nil
                            }
                            ForEach(tags) { tag in
                                TagChip(tag: tag, isSelected: selectedTag == tag) {
                                    selectedTag = tag
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(Color(.systemGroupedBackground))
                }

                // Stock list
                List {
                    ForEach(filteredStocks) { stock in
                        StockRow(stock: stock)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteStock(stock)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await refreshPrices()
                }
                .overlay {
                    if filteredStocks.isEmpty {
                        ContentUnavailableView {
                            Label("暂无自选股", systemImage: "star")
                        } description: {
                            Text("点击右上角添加股票")
                        }
                    }
                }
            }
            .navigationTitle("自选")
            .searchable(text: $searchText, prompt: "搜索股票")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingTagManager = true
                    } label: {
                        Image(systemName: "tag")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddStock = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddStock) {
                AddStockView()
            }
            .sheet(isPresented: $showingTagManager) {
                TagManagerView()
            }
        }
    }

    private func deleteStock(_ stock: Stock) {
        modelContext.delete(stock)
    }

    private func refreshPrices() async {
        isRefreshing = true
        defer { isRefreshing = false }

        let codes = stocks.map { $0.zsCode }
        guard !codes.isEmpty else { return }

        do {
            let quotes = try await PriceService.shared.getQuotes(zsCodes: codes)
            for stock in stocks {
                if let quote = quotes[stock.zsCode] {
                    stock.lastPrice = quote.price
                    stock.changePercent = quote.changePercent
                }
            }
        } catch {
            print("Failed to refresh prices: \(error)")
        }
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let tag: Tag?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tag?.name ?? "全部")
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    WatchlistView()
        .modelContainer(for: [Stock.self, Tag.self], inMemory: true)
}
