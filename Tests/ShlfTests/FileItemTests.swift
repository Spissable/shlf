import Foundation
import Testing

@testable import Shlf

@Suite("FileItem")
struct FileItemTests {

    @Test("Creates FileItem from URL")
    func createFromURL() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let file = tempDir.appendingPathComponent("test.png")
        try Data("hello".utf8).write(to: file)

        let item = FileItem.from(url: file)
        #expect(item != nil)
        #expect(item?.filename == "test.png")
        #expect(item?.fileSize == 5)
        #expect(item?.url == file)
    }

    @Test("Returns nil for nonexistent file")
    func nonexistentFile() {
        let url = URL(fileURLWithPath: "/nonexistent/\(UUID().uuidString).txt")
        let item = FileItem.from(url: url)
        #expect(item == nil)
    }

    @Test("Sorts newest first")
    func sortOrder() {
        let now = Date()
        let first = FileItem(
            url: URL(fileURLWithPath: "/a"), filename: "a",
            fileSize: 0, modificationDate: now.addingTimeInterval(-60))
        let second = FileItem(
            url: URL(fileURLWithPath: "/b"), filename: "b",
            fileSize: 0, modificationDate: now)
        let third = FileItem(
            url: URL(fileURLWithPath: "/c"), filename: "c",
            fileSize: 0, modificationDate: now.addingTimeInterval(-120))

        let sorted = [first, second, third].sorted { $0.modificationDate > $1.modificationDate }
        #expect(sorted.map(\.filename) == ["b", "a", "c"])
    }

    @Test("Relative date produces non-empty string")
    func relativeDate() {
        let item = FileItem(
            url: URL(fileURLWithPath: "/x"), filename: "x",
            fileSize: 0, modificationDate: Date().addingTimeInterval(-300))
        #expect(!item.relativeDate.isEmpty)
    }
}
