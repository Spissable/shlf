import Foundation
import UniformTypeIdentifiers

struct FileItem: Identifiable, Equatable, Sendable {
    let id: URL
    let url: URL
    let filename: String
    let fileSize: Int64
    let modificationDate: Date

    init(url: URL, filename: String, fileSize: Int64, modificationDate: Date) {
        self.id = url
        self.url = url
        self.filename = filename
        self.fileSize = fileSize
        self.modificationDate = modificationDate
    }

    static func from(url: URL) -> FileItem? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .nameKey])
            let name = resourceValues.name ?? url.lastPathComponent
            let size = Int64(resourceValues.fileSize ?? 0)
            let date = resourceValues.contentModificationDate ?? Date.distantPast
            return FileItem(url: url, filename: name, fileSize: size, modificationDate: date)
        } catch {
            return nil
        }
    }

    var isVideo: Bool {
        guard let uttype = UTType(filenameExtension: url.pathExtension) else { return false }
        return uttype.conforms(to: .movie)
    }

    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: modificationDate, relativeTo: Date())
    }
}
