import Foundation
import SwiftUI
import UIKit

struct MemorySelectionSheet: View {
    let moments: [SoloraMoment]
    @Binding var selectedIDs: Set<String>

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if moments.isEmpty {
                    ContentUnavailableView {
                        Label("No memories yet", systemImage: "sparkles")
                    } description: {
                        Text("Save a career moment first, then come back to make something from it.")
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            selectionHeader

                            ForEach(Array(moments.enumerated()), id: \.element.id) { index, moment in
                                memoryRow(moment, index: index)
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 80)
                    }
                    .background(SoloraTheme.paper)
                    .safeAreaInset(edge: .bottom) {
                        Button("Use \(selectedIDs.count) \(selectedIDs.count == 1 ? "memory" : "memories")") {
                            dismiss()
                        }
                        .font(.headline.weight(.bold))
                        .foregroundStyle(SoloraTheme.cream)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .disabled(selectedIDs.isEmpty)
                        .opacity(selectedIDs.isEmpty ? 0.42 : 1)
                        .accessibilityHint("Closes selection and uses these memories")
                    }
                }
            }
            .navigationTitle("Select memories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var selectionHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Build with real proof")
                    .font(.title3.weight(.bold))
                Text("Choose any combination. Every preview and action will use only these memories.")
                    .font(.subheadline)
                    .foregroundStyle(SoloraTheme.ink.opacity(0.58))
            }
            Spacer(minLength: 12)
            Button(selectedIDs.count == moments.count ? "Clear" : "Select all") {
                withAnimation(SoloraMotion.responsive) {
                    if selectedIDs.count == moments.count {
                        selectedIDs.removeAll()
                    } else {
                        selectedIDs = Set(moments.map(\.id))
                    }
                }
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(SoloraTheme.coral)
            .frame(minHeight: 44)
        }
        .padding(.bottom, 4)
    }

    private func memoryRow(_ moment: SoloraMoment, index: Int) -> some View {
        let isSelected = selectedIDs.contains(moment.id)

        return Button {
            withAnimation(SoloraMotion.responsive) {
                if isSelected { selectedIDs.remove(moment.id) } else { selectedIDs.insert(moment.id) }
            }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                SoloraOrbView(
                    size: 42,
                    color: SoloraTheme.orbColors[index % SoloraTheme.orbColors.count],
                    showsHalo: isSelected,
                    mediaPath: moment.bubblePhotoPath,
                    stickerPath: moment.bubbleStickerPath
                )
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(moment.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(SoloraTheme.ink)
                        .multilineTextAlignment(.leading)
                    Text(moment.summary)
                        .font(.caption)
                        .foregroundStyle(SoloraTheme.ink.opacity(0.58))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? SoloraTheme.coral : SoloraTheme.ink.opacity(0.22))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? SoloraTheme.coral.opacity(0.08) : Color.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 15))
            .soloraHairline(isSelected ? SoloraTheme.coral.opacity(0.34) : SoloraTheme.ink.opacity(0.08), radius: 15)
        }
        .buttonStyle(SoloraPressButtonStyle())
        .accessibilityLabel("\(moment.title). \(moment.summary)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

struct TalkingPointsSheet: View {
    let moments: [SoloraMoment]
    let target: String

    @Environment(\.dismiss) private var dismiss
    @State private var draft: String
    @State private var copied = false

    init(moments: [SoloraMoment], target: String) {
        self.moments = moments
        self.target = target
        _draft = State(initialValue: TalkingPointsComposer.compose(moments: moments, target: target))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(target.isEmpty ? "Your talking points" : target)
                        .font(.title2.weight(.bold))
                    Text("An editable narrative built from \(moments.count) selected \(moments.count == 1 ? "memory" : "memories").")
                        .font(.subheadline)
                        .foregroundStyle(SoloraTheme.ink.opacity(0.58))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)

                TextEditor(text: $draft)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 16)
                    .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 18))
                    .padding(.horizontal, 16)
                    .accessibilityLabel("Editable talking points")

                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = draft
                        copied = true
                    } label: {
                        Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.bordered)

                    ShareLink(item: draft) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SoloraTheme.ink)
                }
                .font(.headline.weight(.bold))
                .padding(16)
            }
            .background(SoloraTheme.paper)
            .navigationTitle("Talking points")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }
}

enum TalkingPointsComposer {
    static func compose(moments: [SoloraMoment], target: String) -> String {
        guard !moments.isEmpty else {
            return "Select at least one memory to build useful talking points."
        }

        let focus = target.trimmingCharacters(in: .whitespacesAndNewlines)
        let opening = focus.isEmpty
            ? "I want to share a few moments that show how I approach meaningful work."
            : "I’m interested in \(focus) because my strongest experiences show a consistent pattern of turning ambiguity into useful progress."
        let evidence = moments.enumerated().map { index, moment in
            "\(index + 1). \(moment.title)\n   Evidence: \(moment.summary)"
        }.joined(separator: "\n\n")
        let outcomes = moments.map(\.title).joined(separator: ", ")

        return """
        OPENING
        \(opening)

        EVIDENCE TO USE
        \(evidence)

        OUTCOMES
        Connect the practical result of each example back to the role. Together, \(outcomes) demonstrate repeatable judgement—not a one-off success.

        REFLECTION
        What I learned: name the decision you would repeat, and one thing you would improve next time.

        QUESTIONS TO ASK
        • What would excellent progress look like in the first 90 days?
        • Which challenge needs the most judgement from this role right now?
        • How does the team turn learning into better decisions?
        """
    }
}
