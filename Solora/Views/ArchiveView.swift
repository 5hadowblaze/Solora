import SwiftUI

struct ArchiveView: View {
    let moments: [SoloraMoment]
    var body: some View {
        NavigationStack {
            ZStack {
                SoloraTheme.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Archive")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            Text("The evidence behind everything you create.")
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 0) {
                            archiveStat("\(moments.count)", "Soloras")
                            Divider().frame(height: 38)
                            archiveStat("8", "Skills")
                            Divider().frame(height: 38)
                            archiveStat("3", "Themes")
                        }
                        .padding(.vertical, 14)
                        .background(SoloraTheme.cream, in: RoundedRectangle(cornerRadius: 14))

                        Text("Most recent")
                            .font(.title2.weight(.bold))

                        ForEach(Array(moments.enumerated()), id: \.element.id) { index, moment in
                            MomentRow(moment: moment, color: orbColors[index % orbColors.count])
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var orbColors: [Color] {
        [SoloraTheme.coral, SoloraTheme.gold, SoloraTheme.lavender]
    }

    private func archiveStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
