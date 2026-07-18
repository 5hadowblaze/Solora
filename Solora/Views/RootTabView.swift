import SwiftUI

struct RootTabView: View {
    let container: AppContainer

    var body: some View {
        TabView {
            TodayView(moments: container.moments).tabItem { Label("Today", systemImage: "sun.max.fill") }
            ArchiveView(moments: container.moments).tabItem { Label("Archive", systemImage: "archivebox.fill") }
            CreateView().tabItem { Label("Create", systemImage: "plus.circle.fill") }
            WorldView(manifest: container.worldManifest).tabItem { Label("World", systemImage: "sparkles") }
            YouView().tabItem { Label("You", systemImage: "person.crop.circle.fill") }
        }
        .tint(SoloraTheme.coral)
    }
}
