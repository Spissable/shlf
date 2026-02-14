import SwiftUI

struct ShlfPopover: View {
    @ObservedObject var viewModel: ShlfViewModel

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
                        onCopy: { viewModel.copyFile(item) },
                        onDelete: { viewModel.deleteFile(item) }
                    )
                }
            }
            .padding(12)
        }
    }
}
