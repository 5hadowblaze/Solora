import SwiftUI

struct TodayView: View {
    let moments: [SoloraMoment]
    let onSave: (String) -> Void
    @State private var showsPostEventPrompt = false
    @State private var savedReflection = false

    var body: some View {
        NavigationStack {
            ZStack {
                SoloraTheme.paper.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Good afternoon, Amir")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            Text("One moment is ready to become part of your lore.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("3:00 PM")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(SoloraTheme.coral)
                                    Text("Product strategy workshop")
                                        .font(.title3.weight(.bold))
                                    Text("Ended 2 minutes ago · Calendar")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "calendar.badge.checkmark")
                                    .font(.title2)
                                    .foregroundStyle(SoloraTheme.coral)
                            }

                            Button {
                                savedReflection = false
                                showsPostEventPrompt = true
                            } label: {
                                Label("Turn this into a Solora", systemImage: "sparkles")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .foregroundStyle(.white)
                                    .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens a sample post-event reflection")
                        }
                        .padding(18)
                        .background(.white, in: RoundedRectangle(cornerRadius: SoloraTheme.cardRadius))
                        .overlay {
                            RoundedRectangle(cornerRadius: SoloraTheme.cardRadius)
                                .stroke(SoloraTheme.ink.opacity(0.08))
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Latest Soloras")
                                    .font(.title2.weight(.bold))
                                Spacer()
                                Text("\(moments.count) memories")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            ForEach(Array(moments.prefix(3).enumerated()), id: \.element.id) { index, moment in
                                MomentRow(moment: moment, color: orbColors[index % orbColors.count])
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showsPostEventPrompt) {
                PostEventReflectionView { reflection in
                    onSave(reflection)
                    savedReflection = true
                    showsPostEventPrompt = false
                }
            }
            .overlay(alignment: .bottom) {
                if savedReflection {
                    Label("Reflection saved to your archive", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 12))
                        .padding()
                        .accessibilityAddTraits(.isStaticText)
                }
            }
        }
    }

    private var orbColors: [Color] {
        [SoloraTheme.gold, SoloraTheme.lavender, SoloraTheme.coral]
    }
}

private struct PostEventReflectionView: View {
    let onSave: (String) -> Void
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
                    Button("Save reflection") { onSave(reflection) }
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
    var color: Color = SoloraTheme.gold

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            SoloraOrbView(size: 46, color: color)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(moment.title)
                    .font(.headline)
                    .foregroundStyle(SoloraTheme.ink)
                Text(moment.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14).stroke(SoloraTheme.ink.opacity(0.07))
        }
        .accessibilityElement(children: .combine)
    }
}
