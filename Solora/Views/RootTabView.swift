import SwiftUI
import UIKit

struct RootTabView: View {
    let container: AppContainer
    @State private var moments: [SoloraMoment]
    @State private var selection: RootTab

    init(container: AppContainer) {
        self.container = container
        _moments = State(initialValue: container.moments)
        _selection = State(initialValue: RootTab.launchSelection)
    }

    var body: some View {
        TabView(selection: $selection) {
            TodayView(moments: moments, onSave: saveReflection).tabItem { Label("Today", systemImage: "sun.max.fill") }.tag(RootTab.today)
            ArchiveView(moments: moments).tabItem { Label("Archive", systemImage: "archivebox.fill") }.tag(RootTab.archive)
            CreateView().tabItem { Label("Create", systemImage: "plus.circle.fill") }.tag(RootTab.create)
            WorldView(manifest: container.worldManifest).tabItem { Label("World", systemImage: "sparkles") }.tag(RootTab.world)
            YouView().tabItem { Label("You", systemImage: "person.crop.circle.fill") }.tag(RootTab.you)
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

private enum RootTab: String {
    case today, archive, create, world, you

    static var launchSelection: Self {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-demoTab"),
              arguments.indices.contains(flagIndex + 1),
              let tab = Self(rawValue: arguments[flagIndex + 1]) else {
            return .today
        }
        return tab
    }
}
