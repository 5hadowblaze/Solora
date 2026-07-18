import SwiftUI

struct YouView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Image(systemName: "person.crop.circle.fill").font(.system(size: 68)).foregroundStyle(SoloraTheme.coral)
                Text("Your world is yours").font(.title2.bold())
                Text("Privacy, preferences, and the story you are building.").multilineTextAlignment(.center).foregroundStyle(.secondary)
            }.padding(32).navigationTitle("You")
        }
    }
}
