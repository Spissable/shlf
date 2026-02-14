import Foundation

struct AppConfig: Codable, Equatable, Sendable {
    var watchedFolder: String
    var showHiddenFiles: Bool
    var maxItems: Int

    static let `default` = AppConfig(
        watchedFolder: "~/Desktop",
        showHiddenFiles: false,
        maxItems: 50
    )

    var resolvedFolderURL: URL {
        let expanded = NSString(string: watchedFolder).expandingTildeInPath
        return URL(fileURLWithPath: expanded, isDirectory: true)
    }

    static var configDirectoryURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/shlf", isDirectory: true)
    }

    static var configFileURL: URL {
        configDirectoryURL.appendingPathComponent("config.json")
    }

    static func load() -> AppConfig {
        let url = configFileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            let config = AppConfig.default
            config.save()
            return config
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(AppConfig.self, from: data)
        } catch {
            return .default
        }
    }

    func save() {
        let url = AppConfig.configFileURL
        let dir = AppConfig.configDirectoryURL
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(self)
            try data.write(to: url, options: .atomic)
        } catch {
            // Silently fail — config is non-critical
        }
    }
}
