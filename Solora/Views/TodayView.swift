import SwiftUI

struct TodayView: View {
    let moments: [SoloraMoment]
    @State private var showsPostEventPrompt = false
    @State private var savedReflection = false

    var body: some View {
        NavigationStack {
            List {
                Section("Your living lore") {
                    Text("A small record today becomes evidence you can use tomorrow.")
                        .foregroundStyle(.secondary)
                    Button("Simulate event ending") {
                        savedReflection = false
                        showsPostEventPrompt = true
                    }
                    .accessibilityHint("Opens a sample post-event reflection")
                }
                Section("Recent moments") {
                    ForEach(moments) { moment in MomentRow(moment: moment) }
                }
            }
            .navigationTitle("Today")
            .sheet(isPresented: $showsPostEventPrompt) {
                PostEventReflectionView {
                    savedReflection = true
                    showsPostEventPrompt = false
                }
            }
            .overlay(alignment: .bottom) {
                if savedReflection {
                    Label("Reflection saved to your archive", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(12)
                        .background(.thinMaterial, in: Capsule())
                        .padding()
                        .accessibilityAddTraits(.isStaticText)
                }
            }
        }
    }
}

private struct PostEventReflectionView: View {
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var reflection = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Product strategy workshop", systemImage: "calendar.badge.checkmark")
                        .font(.headline)
                    Text("Today, 3:00–4:00 PM")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Your event just ended")
                }

                Section("Take a minute") {
                    Text("What went better than you expected?")
                    Text("What is one useful follow-up to make?")
                    TextField("Add a quick reflection (optional)", text: $reflection, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Quick reflection")
                }
            }
            .navigationTitle("Capture the moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save reflection") { onSave() }
                        .accessibilityHint("Saves this sample reflection to your archive")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .accessibilityElement(children: .contain)
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
