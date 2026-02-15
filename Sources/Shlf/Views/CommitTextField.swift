import SwiftUI

struct CommitTextField: NSViewRepresentable {
    @Binding var text: String
    var onCommit: () -> Void
    var onCancel: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.delegate = context.coordinator
        field.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.lineBreakMode = .byTruncatingMiddle
        field.maximumNumberOfLines = 1
        field.cell?.isScrollable = true
        field.stringValue = text
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        context.coordinator.parent = self
        if field.stringValue != text {
            field.stringValue = text
        }
        if !context.coordinator.didFocus {
            context.coordinator.didFocus = true
            DispatchQueue.main.async {
                field.window?.makeFirstResponder(field)
                guard let editor = field.currentEditor() else { return }
                let nsName = field.stringValue as NSString
                let stemLength = (nsName.deletingPathExtension as NSString).length
                if stemLength < nsName.length {
                    editor.selectedRange = NSRange(location: 0, length: stemLength)
                } else {
                    editor.selectAll(nil)
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CommitTextField
        var didFocus = false
        private var cancelled = false

        init(_ parent: CommitTextField) { self.parent = parent }

        func controlTextDidChange(_ note: Notification) {
            guard let field = note.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl,
                     textView: NSTextView,
                     doCommandBy sel: Selector) -> Bool {
            if sel == #selector(NSResponder.cancelOperation(_:)) {
                cancelled = true
                parent.onCancel()
                return true
            }
            return false
        }

        func controlTextDidEndEditing(_ note: Notification) {
            if cancelled {
                cancelled = false
                return
            }
            parent.onCommit()
        }
    }
}
