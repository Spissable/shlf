import Testing
import Foundation
@testable import Shlf

struct MockFileOperations: FileOperations {
    let files: [URL]
    var trashedFiles: [URL] = []

    func contentsOfDirectory(at url: URL, showHidden: Bool) -> [URL] {
        files
    }

    func trashItem(at url: URL) throws {
        // No-op in tests
    }
}

@Suite("ShlfViewModel")
@MainActor
struct ShlfViewModelTests {

    private func makeTempFiles(count: Int) throws -> (URL, [URL]) {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        var urls: [URL] = []
        for i in 0..<count {
            let file = tempDir.appendingPathComponent("file\(i).txt")
            try "content \(i)".data(using: .utf8)!.write(to: file)
            let date = Date().addingTimeInterval(Double(-count + i))
            try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: file.path)
            urls.append(file)
        }
        return (tempDir, urls)
    }

    @Test("Files are loaded sorted newest first")
    func filesSortedNewestFirst() throws {
        let (tempDir, _) = try makeTempFiles(count: 3)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let vm = ShlfViewModel(config: config, enableWatchers: false)

        #expect(vm.files.count == 3)
        #expect(vm.files[0].filename == "file2.txt")
    }

    @Test("fileCount reflects total files")
    func fileCountMatchesTotal() throws {
        let (tempDir, _) = try makeTempFiles(count: 5)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let vm = ShlfViewModel(config: config, enableWatchers: false)

        #expect(vm.fileCount == 5)
    }

    @Test("fileCount updates after adding a file")
    func fileCountUpdatesOnRefresh() throws {
        let (tempDir, _) = try makeTempFiles(count: 2)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let vm = ShlfViewModel(config: config, enableWatchers: false)

        #expect(vm.fileCount == 2)

        let newFile = tempDir.appendingPathComponent("new.txt")
        try "new".data(using: .utf8)!.write(to: newFile)

        vm.refresh()
        #expect(vm.fileCount == 3)
    }

    @Test("maxItems limits file count")
    func maxItemsLimit() throws {
        let (tempDir, _) = try makeTempFiles(count: 10)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 3)
        let vm = ShlfViewModel(config: config, enableWatchers: false)

        #expect(vm.files.count == 3)
        #expect(vm.fileCount == 3)
    }

    @Test("Empty folder shows no files")
    func emptyFolder() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let vm = ShlfViewModel(config: config, enableWatchers: false)

        #expect(vm.files.isEmpty)
        #expect(vm.fileCount == 0)
    }
}
