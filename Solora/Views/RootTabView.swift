import SwiftUI
import UIKit

struct RootTabView: View {
    let container: AppContainer
    @State private var moments: [SoloraMoment]

    init(container: AppContainer) {
        self.container = container
        _moments = State(initialValue: container.moments)
    }

    var body: some View {
        TabView {
            TodayView(moments: moments, onSave: saveReflection).tabItem { Label("Today", systemImage: "sun.max.fill") }
            ArchiveView(moments: moments).tabItem { Label("Archive", systemImage: "archivebox.fill") }
            CreateView().tabItem { Label("Create", systemImage: "plus.circle.fill") }
            WorldView(manifest: container.worldManifest).tabItem { Label("World", systemImage: "sparkles") }
            YouView().tabItem { Label("You", systemImage: "person.crop.circle.fill") }
        }
        .tint(SoloraTheme.coral)
    }

    private func saveReflection(_ reflection: String) {
        moments.insert(
            DemoFixtures.postEventReflection(id: UUID().uuidString, date: .now, reflection: reflection),
            at: 0
        )
        UIAccessibility.post(notification: .announcement, argument: "Reflection saved to your archive")
    }
}
