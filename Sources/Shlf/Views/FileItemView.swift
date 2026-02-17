import SwiftUI

struct FileItemView: View {
    let item: FileItem
    let thumbnail: NSImage?
    let onDelete: () -> Void
    @Binding var editingFileID: URL?
    @Binding var editName: String

    private var isEditing: Bool { editingFileID == item.id }

    @State private var playing = false

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Group {
                        if playing {
                            VideoPlayerView(url: item.url)
                        } else if let thumbnail {
                            Image(nsImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Image(systemName: "doc")
                                .font(.system(size: 24))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(3)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .overlay {
                    if item.isVideo && !playing {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .draggable(item.url) {
                    if let thumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Image(systemName: "doc")
                            .font(.system(size: 24))
                            .frame(width: 60, height: 60)
                    }
                }
            .onTapGesture(count: 2) {
                NSWorkspace.shared.open(item.url)
            }
            .onTapGesture {
                if item.isVideo {
                    playing.toggle()
                }
            }

            HStack(spacing: 6) {
                if isEditing {
                    CommitTextField(
                        text: $editName,
                        onCommit: { editingFileID = nil },
                        onCancel: {
                            editName = item.filename
                            editingFileID = nil
                        }
                    )
                } else {
                    Text(item.filename)
                        .font(.caption2)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture(count: 2) {
                            editingFileID = item.id
                        }
                }

                if !isEditing {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 9))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Move to Trash")
                }
            }

            Text(item.relativeDate)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(4)
    }
}
