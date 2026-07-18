import SwiftUI

struct WorldView: View {
    let manifest: WorldManifest
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: SoloraTheme.cardRadius).fill(SoloraTheme.ink)
                        SoloraOrbView(size: 150, color: SoloraTheme.lavender).offset(x: 185, y: -52)
                        SoloraOrbView(size: 72, color: SoloraTheme.gold).offset(x: 134, y: 46)
                        VStack(alignment: .leading, spacing: 7) {
                            Text(manifest.title).font(.title.bold())
                            Text(manifest.subtitle).foregroundStyle(SoloraTheme.cream.opacity(0.82))
                        }.foregroundStyle(SoloraTheme.cream).padding(24)
                    }.frame(height: 220).accessibilityElement(children: .combine)
                    Text("Memory Shelves").font(.title2.bold())
                    ForEach(manifest.shelves, id: \.self) { shelf in
                        Label(shelf, systemImage: "books.vertical.fill")
                            .frame(maxWidth: .infinity, alignment: .leading).padding()
                            .background(SoloraTheme.cream, in: RoundedRectangle(cornerRadius: SoloraTheme.cardRadius))
                    }
                }.padding()
            }.navigationTitle("World")
        }
    }
}
