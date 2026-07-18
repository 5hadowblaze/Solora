import SwiftUI

struct CreateView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                SoloraOrbView(size: 112, color: SoloraTheme.coral)
                Text("Capture a moment").font(.title2.bold())
                Text("A quiet place to save what happened and why it mattered.").multilineTextAlignment(.center).foregroundStyle(.secondary)
                Button("Write a moment") { }.buttonStyle(.borderedProminent).tint(SoloraTheme.coral)
            }
            .padding(32).navigationTitle("Create")
        }
    }
}
