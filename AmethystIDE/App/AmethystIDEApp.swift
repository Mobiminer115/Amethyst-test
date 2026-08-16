import SwiftUI

#if os(iOS)
@main
struct AmethystIDEApp: App {
    var body: some Scene {
        WindowGroup {
            WorkspaceView()
        }
    }
}
#endif
