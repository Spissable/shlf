import Testing
import Foundation
@testable import Shlf

@Suite("AppConfig")
struct AppConfigTests {

    @Test("Default config has expected values")
    func defaultValues() {
        let config = AppConfig.default
        #expect(config.watchedFolder == "~/Desktop")
        #expect(config.showHiddenFiles == false)
        #expect(config.maxItems == 50)
    }

    @Test("Config decodes from valid JSON")
    func decodesValidJSON() throws {
        let json = """
        {
            "watchedFolder": "~/Downloads",
            "showHiddenFiles": true,
            "maxItems": 25
        }
        """.data(using: .utf8)!

        let config = try JSONDecoder().decode(AppConfig.self, from: json)
        #expect(config.watchedFolder == "~/Downloads")
        #expect(config.showHiddenFiles == true)
        #expect(config.maxItems == 25)
    }

    @Test("Config encodes to JSON round-trip")
    func roundTrip() throws {
        let original = AppConfig(watchedFolder: "~/Documents", showHiddenFiles: true, maxItems: 10)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppConfig.self, from: data)
        #expect(original == decoded)
    }

    @Test("Malformed JSON returns default on load")
    func malformedJSON() throws {
        let json = "{ not valid json".data(using: .utf8)!
        let result = try? JSONDecoder().decode(AppConfig.self, from: json)
        #expect(result == nil)
    }

    @Test("Resolved folder URL expands tilde")
    func resolvedURL() {
        let config = AppConfig(watchedFolder: "~/Desktop", showHiddenFiles: false, maxItems: 50)
        let resolved = config.resolvedFolderURL
        #expect(!resolved.path.contains("~"))
        #expect(resolved.path.hasSuffix("/Desktop"))
    }

    @Test("Config saves and loads from disk")
    func saveAndLoad() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let configFile = tempDir.appendingPathComponent("config.json")
        let config = AppConfig(watchedFolder: "~/Pictures", showHiddenFiles: true, maxItems: 30)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: configFile, options: .atomic)

        let loadedData = try Data(contentsOf: configFile)
        let loaded = try JSONDecoder().decode(AppConfig.self, from: loadedData)
        #expect(loaded == config)
    }
}
