import Testing
import Foundation
@testable import Shlf

@Suite("FolderWatcher")
struct FolderWatcherTests {

    @Test("Detects new file in watched directory")
    func detectsNewFile() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let changed = LockedFlag()
        let watcher = FolderWatcher(folderURL: tempDir)
        let bridge = TestBridge { changed.set() }
        watcher.delegate = bridge
        watcher.start()

        let file = tempDir.appendingPathComponent("new.txt")
        try Data("data".utf8).write(to: file)

        // Poll for change notification
        for _ in 0..<30 {
            if changed.value { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        watcher.stop()
        #expect(changed.value)
    }

    @Test("Detects file deletion")
    func detectsDeletion() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let file = tempDir.appendingPathComponent("delete-me.txt")
        try Data("data".utf8).write(to: file)

        let changed = LockedFlag()
        let watcher = FolderWatcher(folderURL: tempDir)
        let bridge = TestBridge { changed.set() }
        watcher.delegate = bridge
        watcher.start()

        try FileManager.default.removeItem(at: file)

        for _ in 0..<30 {
            if changed.value { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        watcher.stop()
        #expect(changed.value)
    }
}

private final class LockedFlag: @unchecked Sendable {
    private var _value = false
    private let lock = NSLock()
    var value: Bool { lock.lock(); defer { lock.unlock() }; return _value }
    func set() { lock.lock(); _value = true; lock.unlock() }
}

private final class TestBridge: FolderWatcherDelegate, @unchecked Sendable {
    private let handler: () -> Void
    init(handler: @escaping () -> Void) { self.handler = handler }
    func folderDidChange() { handler() }
}
