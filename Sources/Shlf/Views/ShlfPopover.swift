import SwiftUI

struct ShlfPopover: View {
    @ObservedObject var viewModel: ShlfViewModel
    @State private var editingFileID: URL?
    @State private var editName = ""

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 6)
    ]

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.files.isEmpty {
                emptyState
            } else {
                fileGrid
            }

            Divider()

            HStack {
                Spacer()
                Button("Quit Shlf") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(8)
            }
        }
        .frame(width: 360, height: 400)
        .contentShape(Rectangle())
        .onTapGesture {
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
        .onChange(of: editingFileID) { oldID, newID in
            if let oldID, let item = viewModel.files.first(where: { $0.id == oldID }) {
                _ = viewModel.renameFile(item, to: editName)
            }
            if let newID, let item = viewModel.files.first(where: { $0.id == newID }) {
                editName = item.filename
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No files")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fileGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(viewModel.files) { item in
                    FileItemView(
                        item: item,
                        thumbnail: viewModel.thumbnails[item.url],
                        onDelete: { viewModel.deleteFile(item) },
                        editingFileID: $editingFileID,
                        editName: $editName
                    )
                }
            }
            .padding(12)
        }
    }
}
