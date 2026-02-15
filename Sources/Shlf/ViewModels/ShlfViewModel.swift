import Foundation
import SwiftUI
@preconcurrency import QuickLookThumbnailing

protocol FileOperations: Sendable {
    func contentsOfDirectory(at url: URL, showHidden: Bool) -> [URL]
    func trashItem(at url: URL) throws
    func moveItem(at srcURL: URL, to dstURL: URL) throws
}

struct DefaultFileOperations: FileOperations {
    func contentsOfDirectory(at url: URL, showHidden: Bool) -> [URL] {
        var options: FileManager.DirectoryEnumerationOptions = [.skipsSubdirectoryDescendants]
        if !showHidden {
            options.insert(.skipsHiddenFiles)
        }
        return (try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .nameKey],
            options: options
        )) ?? []
    }

    func trashItem(at url: URL) throws {
        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }

    func moveItem(at srcURL: URL, to dstURL: URL) throws {
        try FileManager.default.moveItem(at: srcURL, to: dstURL)
    }
}

@MainActor
final class ShlfViewModel: ObservableObject {
    @Published var files: [FileItem] = []
    @Published var fileCount: Int = 0
    @Published var thumbnails: [URL: NSImage] = [:]

    private var config: AppConfig
    private var folderWatcher: FolderWatcher?
    private let fileOps: FileOperations

    private let enableWatchers: Bool

    init(config: AppConfig = .load(), fileOps: FileOperations = DefaultFileOperations(), enableWatchers: Bool = true) {
        self.config = config
        self.fileOps = fileOps
        self.enableWatchers = enableWatchers
        if enableWatchers {
            setupFolderWatcher()
        }
        refresh()
    }

    func refresh() {
        let urls = fileOps.contentsOfDirectory(at: config.resolvedFolderURL, showHidden: config.showHiddenFiles)
        var items = urls.compactMap { FileItem.from(url: $0) }
        items.sort { $0.modificationDate > $1.modificationDate }
        if items.count > config.maxItems {
            items = Array(items.prefix(config.maxItems))
        }
        files = items
        fileCount = items.count

        if enableWatchers {
            loadThumbnails(for: items)
        }
    }

    func copyFile(_ item: FileItem) {
        Clipboard.copyFile(at: item.url)
    }

    func deleteFile(_ item: FileItem) {
        do {
            try fileOps.trashItem(at: item.url)
            refresh()
        } catch {
            // Silently fail — file may already be gone
        }
    }

    func renameFile(_ item: FileItem, to newName: String) -> Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let directory = item.url.deletingLastPathComponent()
        let destination = directory.appendingPathComponent(trimmed)

        guard destination != item.url else { return true }

        do {
            try fileOps.moveItem(at: item.url, to: destination)
            refresh()
            return true
        } catch {
            return false
        }
    }

    private func setupFolderWatcher() {
        let bridge = WatcherBridge { [weak self] in
            self?.refresh()
        }
        let watcher = FolderWatcher(folderURL: config.resolvedFolderURL)
        watcher.delegate = bridge
        watcher.start()
        folderWatcher = watcher
        _folderBridge = bridge
    }

    private var _folderBridge: WatcherBridge?

    private func loadThumbnails(for items: [FileItem]) {
        for item in items {
            let url = item.url
            guard thumbnails[url] == nil else { continue }
            Task { [weak self] in
                let request = QLThumbnailGenerator.Request(
                    fileAt: url,
                    size: CGSize(width: 96, height: 96),
                    scale: 2.0,
                    representationTypes: .thumbnail
                )
                let generator = QLThumbnailGenerator.shared
                if let representation = try? await generator.generateBestRepresentation(for: request) {
                    self?.thumbnails[url] = representation.nsImage
                }
            }
        }
    }
}

private final class WatcherBridge: FolderWatcherDelegate, @unchecked Sendable {
    private let handler: @MainActor () -> Void

    init(handler: @escaping @MainActor () -> Void) {
        self.handler = handler
    }

    func folderDidChange() {
        Task { @MainActor in
            handler()
        }
    }
}
