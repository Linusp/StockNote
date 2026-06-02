import SwiftUI
import Charts

struct StockRow: View {
    @Bindable var stock: Stock
    @State private var priceHistory: [Double] = []

    var body: some View {
        HStack(spacing: 12) {
            // Stock info
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.name)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(stock.code)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    // Show tags
                    ForEach(stock.tags.prefix(2)) { tag in
                        Text(tag.name)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color(hex: tag.color).opacity(0.2))
                            .foregroundStyle(Color(hex: tag.color))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    if stock.tags.count > 2 {
                        Text("+\(stock.tags.count - 2)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Sparkline
            if !priceHistory.isEmpty {
                SparklineView(data: priceHistory, isPositive: (stock.changePercent ?? 0) >= 0)
                    .frame(width: 50, height: 24)
            }

            // Price
            VStack(alignment: .trailing, spacing: 4) {
                if let price = stock.lastPrice {
                    Text(String(format: "%.2f", price))
                        .font(.headline)
                        .monospacedDigit()
                }
                if let change = stock.changePercent {
                    Text(String(format: "%+.2f%%", change))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(change >= 0 ? .red : .green)
                }
            }
        }
        .padding(.vertical, 4)
        .task {
            await loadHistory()
        }
        .onTapGesture {
            openInTonghuashun()
        }
    }

    private func loadHistory() async {
        do {
            let history = try await PriceService.shared.getHistory(zsCode: stock.zsCode, days: 10)
            priceHistory = history.map { $0.close }
            stock.priceHistory = priceHistory

            // Also update current price
            let quote = try await PriceService.shared.getQuote(zsCode: stock.zsCode)
            stock.lastPrice = quote.price
            stock.changePercent = quote.changePercent
        } catch {
            print("Failed to load history for \(stock.zsCode): \(error)")
        }
    }

    private func openInTonghuashun() {
        // 同花顺 URL scheme
        let code = stock.code
        // Try to open in 同花顺
        if let url = URL(string: "amihexin://stock/\(code)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        // Fallback to 东方财富
        else if let url = URL(string: "emfe://stockdetail?code=\(code)"),
                UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Sparkline

struct SparklineView: View {
    let data: [Double]
    let isPositive: Bool

    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Price", value)
                )
                .foregroundStyle(isPositive ? Color.red : Color.green)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartYScale(domain: .automatic(includesZero: false))
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    List {
        StockRow(stock: Stock(zsCode: "600519.SH", code: "600519", name: "贵州茅台"))
    }
    .modelContainer(for: [Stock.self, Tag.self], inMemory: true)
}
