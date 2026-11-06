import SwiftUI

@main
struct PixelBloomApp: App {
    @StateObject private var store = PaintStore()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(store).tint(Color(red: 0.36, green: 0.43, blue: 0.34))
        }
    }
}
