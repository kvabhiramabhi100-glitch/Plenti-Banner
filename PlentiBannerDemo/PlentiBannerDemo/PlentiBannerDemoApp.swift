import SwiftUI
import PlentiBanner

@main
struct PlentiBannerDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ScrollView {
                PlentiBannerView()
            }
            .ignoresSafeArea(edges: .top)
            .background(Color(white: 0.96))
        }
    }
}
