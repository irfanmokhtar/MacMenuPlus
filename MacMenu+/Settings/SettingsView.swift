import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @Environment(ClipboardStore.self) private var store
    @State private var axTrusted: Bool = AccessibilityPermission.isTrusted

    var body: some View {
        @Bindable var store = store

        Form {
            Section("Clipboard") {
                Stepper(value: $store.capacity, in: 10...200, step: 10) {
                    LabeledContent("History size", value: "\(store.capacity)")
                }
                Button("Clear history now", role: .destructive) {
                    store.clear()
                }
            }

            Section("Shortcuts") {
                KeyboardShortcuts.Recorder("Toggle panel:", name: .togglePanel)
                KeyboardShortcuts.Recorder("Switch windows:", name: .switchApps)
            }

            Section("Accessibility") {
                LabeledContent("Window-raise permission", value: axTrusted ? "Granted" : "Not granted")
                if !axTrusted {
                    Text("Without this permission, the switcher can activate an app but cannot raise a specific window of that app.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Button("Open System Settings") {
                        AccessibilityPermission.openSystemSettings()
                    }
                    Button("Re-check") {
                        axTrusted = AccessibilityPermission.isTrusted
                    }
                }
            }

            Section {
                LabeledContent("Persistence", value: "In-memory (cleared on quit)")
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 420)
        .onAppear {
            axTrusted = AccessibilityPermission.isTrusted
        }
    }
}
