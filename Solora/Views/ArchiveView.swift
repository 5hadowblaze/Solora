import SwiftUI

struct ArchiveView: View {
    let moments: [SoloraMoment]

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filteredMoments: [SoloraMoment] {
        guard !query.isEmpty else { return moments }
        return moments.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.summary.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SoloraTheme.paper.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(moments.count)")
                                .font(.system(size: 58, weight: .black, design: .rounded))
                                .tracking(-2)
                            Text("memories")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(SoloraTheme.ink.opacity(0.48))
                        }
                        .padding(.bottom, 8)

                        ForEach(Array(filteredMoments.enumerated()), id: \.element.id) { index, moment in
                            MomentRow(
                                moment: moment,
                                color: SoloraTheme.orbColors[index % SoloraTheme.orbColors.count]
                            )
                            .soloraEntrance(index: index, distance: 7)
                        }
                    }
                    .padding(18)
                }
            }
            .foregroundStyle(SoloraTheme.ink)
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search your lore")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }
}
