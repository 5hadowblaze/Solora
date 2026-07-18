import SwiftUI

struct TodayView: View {
    let moments: [SoloraMoment]

    var body: some View {
        NavigationStack {
            List {
                Section("Your living lore") {
                    Text("A small record today becomes evidence you can use tomorrow.")
                        .foregroundStyle(.secondary)
                    Button("Simulate event ending") { }
                        .accessibilityHint("Creates a sample completed event")
                }
                Section("Recent moments") {
                    ForEach(moments) { moment in MomentRow(moment: moment) }
                }
            }
            .navigationTitle("Today")
        }
    }
}

struct MomentRow: View {
    let moment: SoloraMoment
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(moment.title).font(.headline)
            Text(moment.summary).font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
