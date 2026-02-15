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
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        var urls: [URL] = []
        for i in 0..<count {
            let file = tempDir.appendingPathComponent("file\(i).txt")
            try "content \(i)".data(using: .utf8)!.write(to: file)
            let date = Date().addingTimeInterval(Double(-count + i))
            try FileManager.default.setAttributes(
                [.modificationDate: date], ofItemAtPath: file.path)
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
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let vm = ShlfViewModel(config: config, enableWatchers: false)

        #expect(vm.files.isEmpty)
        #expect(vm.fileCount == 0)
    }

    @Test("Rename updates the file list")
    func renameUpdatesFileList() throws {
        let (tempDir, _) = try makeTempFiles(count: 1)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let vm = ShlfViewModel(config: config, enableWatchers: false)

        let original = vm.files[0]
        let result = vm.renameFile(original, to: "renamed.txt")

        #expect(result == true)
        #expect(vm.files.count == 1)
        #expect(vm.files[0].filename == "renamed.txt")
    }

    @Test("Rename to same name returns true without error")
    func renameToSameName() throws {
        let (tempDir, _) = try makeTempFiles(count: 1)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let vm = ShlfViewModel(config: config, enableWatchers: false)

        let original = vm.files[0]
        let result = vm.renameFile(original, to: original.filename)

        #expect(result == true)
        #expect(vm.files[0].filename == original.filename)
    }

    @Test("Rename with empty name returns false")
    func renameEmptyNameFails() throws {
        let (tempDir, _) = try makeTempFiles(count: 1)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let vm = ShlfViewModel(config: config, enableWatchers: false)

        let original = vm.files[0]
        let result = vm.renameFile(original, to: "   ")

        #expect(result == false)
        #expect(vm.files[0].filename == original.filename)
    }

    @Test("Rename to existing file returns false")
    func renameToExistingFileFails() throws {
        let (tempDir, _) = try makeTempFiles(count: 2)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let vm = ShlfViewModel(config: config, enableWatchers: false)

        // Try to rename file1 to file0's name — should fail because file0 already exists
        let target = vm.files[0]
        let other = vm.files[1]
        let result = vm.renameFile(target, to: other.filename)

        #expect(result == false)
    }

    @Test("Rename whitespace-only name returns false")
    func renameWhitespaceOnlyFails() throws {
        let (tempDir, _) = try makeTempFiles(count: 1)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let vm = ShlfViewModel(config: config, enableWatchers: false)

        let original = vm.files[0]
        let result = vm.renameFile(original, to: "\t\n  ")

        #expect(result == false)
    }

    @Test("Rename trims whitespace from new name")
    func renameTrimsWhitespace() throws {
        let (tempDir, _) = try makeTempFiles(count: 1)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let vm = ShlfViewModel(config: config, enableWatchers: false)

        let original = vm.files[0]
        let result = vm.renameFile(original, to: "  newname.txt  ")

        #expect(result == true)
        #expect(vm.files[0].filename == "newname.txt")
    }

    @Test("Rename nonexistent file returns false")
    func renameNonexistentFileFails() throws {
        let (tempDir, _) = try makeTempFiles(count: 1)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let config = AppConfig(watchedFolder: tempDir.path, showHiddenFiles: false, maxItems: 50)
        let vm = ShlfViewModel(config: config, enableWatchers: false)

        let ghost = FileItem(
            url: tempDir.appendingPathComponent("ghost.txt"),
            filename: "ghost.txt",
            fileSize: 0,
            modificationDate: Date()
        )
        let result = vm.renameFile(ghost, to: "new.txt")

        #expect(result == false)
    }
}
