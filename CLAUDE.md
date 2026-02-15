# Shlf

macOS menu bar applet for quick access to a configurable folder.

## Build & Test

```bash
swift build
swift test
swiftlint --strict
swift run
```

Always run `swiftlint --strict` before committing. Zero violations must be maintained.

Requires Xcode toolchain (Swift Testing framework is not in standalone CLT). Ensure `xcode-select -p` points to `/Applications/Xcode.app/Contents/Developer` — if not, run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.

Zero third-party dependencies. Pure Swift/SwiftUI. Targets macOS 14+ (Sonoma). Swift 6 strict concurrency.

## Architecture

```
Sources/Shlf/
├── ShlfApp.swift              # @main, MenuBarExtra with folder icon + file count
├── Models/
│   ├── AppConfig.swift        # Codable config (~/.config/shlf/config.json)
│   ├── FileItem.swift         # Value type: url, filename, size, date, isVideo
│   └── FolderWatcher.swift    # DispatchSource.makeFileSystemObjectSource wrapper
├── ViewModels/
│   └── ShlfViewModel.swift    # @MainActor ObservableObject: file list, thumbnails, actions
├── Views/
│   ├── ShlfPopover.swift      # Scrollable grid of file thumbnails
│   ├── FileItemView.swift     # Single cell: thumbnail/video, filename, copy/delete/rename
│   ├── CommitTextField.swift  # NSViewRepresentable: inline rename with native focus handling
│   └── VideoPlayerView.swift  # NSViewRepresentable wrapping AVPlayerLayer
└── Utilities/
    └── Clipboard.swift        # NSPasteboard file copy
```

### Key patterns

- **Testability**: `ShlfViewModel` takes `enableWatchers: false` in tests to skip DispatchSource and QLThumbnailGenerator (both crash in headless test environments). File operations go through `FileOperations` protocol (`contentsOfDirectory`, `trashItem`, `moveItem`).
- **Folder watching**: `FolderWatcher` uses `DispatchSource` with `O_EVTONLY` file descriptors to watch the configured folder for changes.
- **Config**: Read once on launch from `~/.config/shlf/config.json`. Restart required after editing.
- **Video playback**: Uses `AVPlayerLayer` directly (not `AVPlayerView`) for proper `videoGravity` control. `PlayerLayerView` overrides `intrinsicContentSize` to prevent layout blowout, and cleans up the player in `viewDidMoveToWindow()`.
- **Thumbnails**: Async `QLThumbnailGenerator.generateBestRepresentation` (not the callback API, which crashes under Swift 6 `@MainActor` isolation).
- **Inline rename**: Uses `CommitTextField` (NSViewRepresentable wrapping NSTextField) instead of SwiftUI `TextField` for reliable focus-loss detection in MenuBarExtra popovers. Editing state (`editingFileID`, `editName`) is owned by `ShlfPopover` and passed as bindings. The popover's `onChange(of: editingFileID)` commits the rename when editing ends.

### Gotchas

- `QLThumbnailGenerator.generateRepresentations` (callback API) crashes at runtime with Swift 6 strict concurrency — the callback fires on a background queue and violates `@MainActor` isolation. Use the async `generateBestRepresentation` instead.
- `AVPlayerView` ignores SwiftUI frame constraints via its `intrinsicContentSize`. Solution: use `AVPlayerLayer` in a custom `NSView` with `intrinsicContentSize` returning `noIntrinsicMetric`, placed as an `.overlay` so the parent shape drives sizing.
- Tests must use `enableWatchers: false` or the test process crashes (signal 5 / SIGTRAP) from DispatchSource + QLThumbnail in headless context.
- SwiftUI `TextField` + `@FocusState` does not reliably detect focus loss in MenuBarExtra popovers. Use `NSTextField` via `NSViewRepresentable` with `controlTextDidEndEditing` instead. Also, `onTapGesture(count: 2)` and parent-level `onTapGesture(count: 1)` conflict — the parent's single-tap eats the first click of a double-click.

## Config

`~/.config/shlf/config.json` (created with defaults on first launch):

```json
{
  "maxItems": 50,
  "showHiddenFiles": false,
  "watchedFolder": "~/Desktop"
}
```

## Tests

24 tests across 4 suites using Swift Testing (`import Testing`):

- **AppConfigTests** (6) — parsing, defaults, round-trip, malformed JSON, tilde expansion
- **FileItemTests** (4) — creation from URL, nonexistent file, sort order, relative date
- **FolderWatcherTests** (2) — detects new file, detects deletion (uses temp directories + polling)
- **ShlfViewModelTests** (12) — sort order, file count, count updates on refresh, maxItems, empty folder, rename (success, same-name, empty, whitespace, collision, trimming, nonexistent)
