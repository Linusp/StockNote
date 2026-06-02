import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WatchlistView()
                .tabItem {
                    Label("自选", systemImage: "star.fill")
                }
                .tag(0)

            StrategyView()
                .tabItem {
                    Label("策略", systemImage: "chart.pie.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
