import SwiftUI
import SwiftData

struct TagManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var tags: [Tag]

    @State private var showingAddTag = false
    @State private var newTagName = ""
    @State private var newTagColor = "#3B82F6"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(tags) { tag in
                        HStack {
                            Circle()
                                .fill(Color(hex: tag.color))
                                .frame(width: 16, height: 16)
                            Text(tag.name)
                            Spacer()
                            Text("\(tag.stocks.count)只")
                                .foregroundStyle(.secondary)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteTag(tag)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("标签列表")
                } footer: {
                    if tags.isEmpty {
                        Text("暂无标签，点击右上角添加")
                    }
                }
            }
            .navigationTitle("标签管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddTag = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("新建标签", isPresented: $showingAddTag) {
                TextField("标签名称", text: $newTagName)
                Button("取消", role: .cancel) {
                    newTagName = ""
                }
                Button("创建") {
                    createTag()
                }
            } message: {
                Text("输入标签名称")
            }
        }
    }

    private func createTag() {
        guard !newTagName.isEmpty else { return }

        let colors = Tag.colors
        let randomColor = colors.randomElement() ?? "#3B82F6"

        let tag = Tag(name: newTagName, color: randomColor)
        modelContext.insert(tag)
        newTagName = ""
    }

    private func deleteTag(_ tag: Tag) {
        modelContext.delete(tag)
    }
}

#Preview {
    TagManagerView()
        .modelContainer(for: [Tag.self, Stock.self], inMemory: true)
}
