import SwiftUI
import SwiftData

struct AddStockView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var tags: [Tag]
    @Query private var existingStocks: [Stock]

    @State private var searchText = ""
    @State private var searchResults: [Quote] = []
    @State private var selectedQuote: Quote?
    @State private var selectedTags: Set<Tag> = []
    @State private var isSearching = false
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            List {
                // Search section
                Section {
                    TextField("搜索股票代码或名称", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit {
                            Task { await search() }
                        }
                }

                // Search results
                if isSearching {
                    Section {
                        HStack {
                            ProgressView()
                            Text("搜索中...")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if !searchResults.isEmpty {
                    Section("搜索结果") {
                        ForEach(searchResults) { quote in
                            Button {
                                selectedQuote = quote
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(quote.name)
                                            .foregroundStyle(.primary)
                                        Text(quote.zsCode)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedQuote?.id == quote.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                    if existingStocks.contains(where: { $0.zsCode == quote.zsCode }) {
                                        Text("已添加")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                // Tag selection
                if selectedQuote != nil && !tags.isEmpty {
                    Section("选择标签") {
                        ForEach(tags) { tag in
                            Button {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                }
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(Color(hex: tag.color))
                                        .frame(width: 12, height: 12)
                                    Text(tag.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedTags.contains(tag) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }

                    Section("备注") {
                        TextField("添加备注（可选）", text: $notes)
                    }
                }
            }
            .navigationTitle("添加自选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        addStock()
                    }
                    .disabled(selectedQuote == nil || existingStocks.contains(where: { $0.zsCode == selectedQuote?.zsCode }))
                }
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.count >= 2 {
                    Task { await search() }
                } else {
                    searchResults = []
                }
            }
        }
    }

    private func search() async {
        guard !searchText.isEmpty else { return }

        isSearching = true
        defer { isSearching = false }

        do {
            searchResults = try await EastMoneyAPI.shared.search(keyword: searchText)
        } catch {
            print("Search error: \(error)")
            searchResults = []
        }
    }

    private func addStock() {
        guard let quote = selectedQuote else { return }

        let stock = Stock(
            zsCode: quote.zsCode,
            code: quote.code,
            name: quote.name,
            category: quote.category
        )
        stock.notes = notes.isEmpty ? nil : notes
        stock.tags = Array(selectedTags)

        modelContext.insert(stock)
        dismiss()
    }
}

#Preview {
    AddStockView()
        .modelContainer(for: [Stock.self, Tag.self], inMemory: true)
}
