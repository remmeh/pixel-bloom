import SwiftUI

@main
struct PixelBloomApp: App {
    @StateObject private var store = PaintStore()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(store).tint(Color(red: 0.36, green: 0.43, blue: 0.34))
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active { store.flushPendingSaves() }
                }
        }
    }
}
