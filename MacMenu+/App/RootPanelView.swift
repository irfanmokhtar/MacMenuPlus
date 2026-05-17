import SwiftUI

/// Container view — slots each module as a section. Owns the overall panel frame.
struct RootPanelView: View {
    var body: some View {
        VStack(spacing: 0) {
            ClipboardPanelView()
            Divider()
            AppSwitcherPanelSection()
        }
        .frame(width: 360)
    }
}
