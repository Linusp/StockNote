import SwiftUI

struct SettingsView: View {
    @AppStorage("tushareToken") private var tushareToken = ""
    @AppStorage("dataSource") private var dataSource = "eastmoney"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("数据源", selection: $dataSource) {
                        Text("东方财富（免费）").tag("eastmoney")
                        Text("Tushare（需Token）").tag("tushare")
                    }

                    if dataSource == "tushare" {
                        SecureField("Tushare Token", text: $tushareToken)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("数据源设置")
                } footer: {
                    if dataSource == "tushare" {
                        Text("请在 tushare.pro 注册获取免费 Token")
                    }
                }

                Section("关于") {
                    LabeledContent("版本") {
                        Text("1.0.0")
                    }
                    Link("GitHub", destination: URL(string: "https://github.com/Linusp/stocknote-ios")!)
                }

                Section("数据管理") {
                    NavigationLink {
                        ExportImportView()
                    } label: {
                        Label("导出/导入", systemImage: "square.and.arrow.up.on.square")
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}

// MARK: - Export/Import View

struct ExportImportView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var exportURL: URL?
    @State private var alertMessage = ""
    @State private var showingAlert = false

    var body: some View {
        Form {
            Section {
                Button {
                    exportData()
                } label: {
                    Label("导出数据", systemImage: "square.and.arrow.up")
                }

                Button {
                    showingImportPicker = true
                } label: {
                    Label("导入数据", systemImage: "square.and.arrow.down")
                }
            } footer: {
                Text("数据以 JSON 格式导出，可用于备份或迁移")
            }
        }
        .navigationTitle("导出/导入")
        .sheet(isPresented: $showingExportSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importData(from: url)
                }
            case .failure(let error):
                alertMessage = "导入失败: \(error.localizedDescription)"
                showingAlert = true
            }
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func exportData() {
        // TODO: Implement export using SwiftData queries
        alertMessage = "导出功能开发中"
        showingAlert = true
    }

    private func importData(from url: URL) {
        // TODO: Implement import
        alertMessage = "导入功能开发中"
        showingAlert = true
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
}
