import Foundation
import Testing

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

    func moveItem(at srcURL: URL, to dstURL: URL) throws {
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
        for index in 0..<count {
            let file = tempDir.appendingPathComponent("file\(index).txt")
            try Data("content \(index)".utf8).write(to: file)
            let date = Date().addingTimeInterval(Double(-count + index))
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
        let viewModel = ShlfViewModel(config: config, enableWatchers: false)

        #expect(viewModel.files.count == 3)
        #expect(viewModel.files[0].filename == "file2.txt")
    }

    @Test("fileCount reflects total files")
    func fileCountMatchesTotal() throws {
        let (tempDir, _) = try makeTempFiles(count: 5)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let viewModel = ShlfViewModel(config: config, enableWatchers: false)

        #expect(viewModel.fileCount == 5)
    }

    @Test("fileCount updates after adding a file")
    func fileCountUpdatesOnRefresh() throws {
        let (tempDir, _) = try makeTempFiles(count: 2)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let viewModel = ShlfViewModel(config: config, enableWatchers: false)

        #expect(viewModel.fileCount == 2)

        let newFile = tempDir.appendingPathComponent("new.txt")
        try Data("new".utf8).write(to: newFile)

        viewModel.refresh()
        #expect(viewModel.fileCount == 3)
    }

    @Test("maxItems limits file count")
    func maxItemsLimit() throws {
        let (tempDir, _) = try makeTempFiles(count: 10)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 3)
        let viewModel = ShlfViewModel(config: config, enableWatchers: false)

        #expect(viewModel.files.count == 3)
        #expect(viewModel.fileCount == 3)
    }

    @Test("Empty folder shows no files")
    func emptyFolder() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let viewModel = ShlfViewModel(config: config, enableWatchers: false)

        #expect(viewModel.files.isEmpty)
        #expect(viewModel.fileCount == 0)
    }

    // MARK: - Rename

    @Test("Rename updates the file list")
    func renameUpdatesFileList() throws {
        let (tempDir, _) = try makeTempFiles(count: 1)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let viewModel = ShlfViewModel(config: config, enableWatchers: false)

        let original = viewModel.files[0]
        let result = viewModel.renameFile(original, to: "renamed.txt")

        #expect(result == true)
        #expect(viewModel.files.count == 1)
        #expect(viewModel.files[0].filename == "renamed.txt")
    }

    @Test("Rename to same name returns true without error")
    func renameToSameName() throws {
        let (tempDir, _) = try makeTempFiles(count: 1)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let viewModel = ShlfViewModel(config: config, enableWatchers: false)

        let original = viewModel.files[0]
        let result = viewModel.renameFile(original, to: original.filename)

        #expect(result == true)
        #expect(viewModel.files[0].filename == original.filename)
    }

    @Test("Rename with empty name returns false")
    func renameEmptyNameFails() throws {
        let (tempDir, _) = try makeTempFiles(count: 1)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let viewModel = ShlfViewModel(config: config, enableWatchers: false)

        let original = viewModel.files[0]
        let result = viewModel.renameFile(original, to: "   ")

        #expect(result == false)
        #expect(viewModel.files[0].filename == original.filename)
    }

    @Test("Rename to existing file returns false")
    func renameToExistingFileFails() throws {
        let (tempDir, _) = try makeTempFiles(count: 2)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let viewModel = ShlfViewModel(config: config, enableWatchers: false)

        let target = viewModel.files[0]
        let other = viewModel.files[1]
        let result = viewModel.renameFile(target, to: other.filename)

        #expect(result == false)
    }

    @Test("Rename whitespace-only name returns false")
    func renameWhitespaceOnlyFails() throws {
        let (tempDir, _) = try makeTempFiles(count: 1)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let viewModel = ShlfViewModel(config: config, enableWatchers: false)

        let original = viewModel.files[0]
        let result = viewModel.renameFile(original, to: "\t\n  ")

        #expect(result == false)
    }

    @Test("Rename trims whitespace from new name")
    func renameTrimsWhitespace() throws {
        let (tempDir, _) = try makeTempFiles(count: 1)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let viewModel = ShlfViewModel(config: config, enableWatchers: false)

        let original = viewModel.files[0]
        let result = viewModel.renameFile(original, to: "  newname.txt  ")

        #expect(result == true)
        #expect(viewModel.files[0].filename == "newname.txt")
    }

    @Test("Rename nonexistent file returns false")
    func renameNonexistentFileFails() throws {
        let (tempDir, _) = try makeTempFiles(count: 1)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let viewModel = ShlfViewModel(config: config, enableWatchers: false)

        let ghost = FileItem(
            url: tempDir.appendingPathComponent("ghost.txt"),
            filename: "ghost.txt",
            fileSize: 0,
            modificationDate: Date()
        )
        let result = viewModel.renameFile(ghost, to: "new.txt")

        #expect(result == false)
    }
}
