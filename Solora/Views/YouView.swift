import SwiftUI

struct YouView: View {
    let vibe: String
    let visualReference: String

    init(
        vibe: String = "Warm & reflective",
        visualReference: String = "Inside Out orbs"
    ) {
        self.vibe = vibe
        self.visualReference = visualReference
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SoloraTheme.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(SoloraTheme.coral)
                                Text("A").font(.title.bold()).foregroundStyle(.white)
                            }
                            .frame(width: 60, height: 60)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Amir")
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                Text(vibe)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        settingsSection("Connected sources") {
                            sourceRow("doc.text.fill", "Master CV", "Ready", SoloraTheme.coral)
                            Divider()
                            sourceRow("calendar", "Calendar", "Synced for demo", SoloraTheme.gold)
                        }

                        settingsSection("Your Solora") {
                            Label("Private by default", systemImage: "lock.fill")
                            Divider()
                            Label("World style: \(worldStyle)", systemImage: "square.grid.2x2.fill")
                            Divider()
                            Label("Vibe: \(vibe)", systemImage: "paintpalette.fill")
                        }

                        Text("Your memories stay yours. Solora only creates from the moments you choose.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                    }
                    .padding(18)
                }
            }
            .navigationTitle("You")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var worldStyle: String {
        if visualReference.localizedCaseInsensitiveContains("fridge") { return "Career Fridge" }
        if visualReference.localizedCaseInsensitiveContains("map") { return "Quest Map" }
        return "Memory Shelves"
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            VStack(alignment: .leading, spacing: 14) { content() }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.white, in: RoundedRectangle(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).stroke(SoloraTheme.ink.opacity(0.07)) }
        }
    }

    private func sourceRow(_ icon: String, _ title: String, _ status: String, _ color: Color) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color).frame(width: 24)
            Text(title).fontWeight(.semibold)
            Spacer()
            Text(status).font(.caption).foregroundStyle(.secondary)
        }
    }
}
