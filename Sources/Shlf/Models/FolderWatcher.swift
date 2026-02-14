import Foundation

protocol FolderWatcherDelegate: AnyObject, Sendable {
    func folderDidChange()
}

final class FolderWatcher: @unchecked Sendable {
    private let folderURL: URL
    private var fileDescriptor: Int32 = -1
    private var source: DispatchSourceFileSystemObject?
    weak var delegate: FolderWatcherDelegate?

    init(folderURL: URL) {
        self.folderURL = folderURL
    }

    func start() {
        stop()
        fileDescriptor = open(folderURL.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .rename, .delete, .attrib],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            self?.delegate?.folderDidChange()
        }
        source.setCancelHandler { [fd = fileDescriptor] in
            close(fd)
        }
        source.resume()
        self.source = source
    }

    func stop() {
        source?.cancel()
        source = nil
        fileDescriptor = -1
    }

    deinit {
        stop()
    }
}
