import SwiftUI

@main
struct ShlfApp: App {
    @StateObject private var viewModel = ShlfViewModel()

    var body: some Scene {
        MenuBarExtra {
            ShlfPopover(viewModel: viewModel)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "folder.fill")
                if viewModel.fileCount > 0 {
                    Text("\(viewModel.fileCount)")
                        .font(.system(size: 10, weight: .medium))
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
