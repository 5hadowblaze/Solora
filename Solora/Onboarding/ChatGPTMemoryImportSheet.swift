import SwiftUI
import UIKit

struct ChatGPTMemoryImportSheet: View {
    private enum Stage: Int {
        case prompt
        case paste
        case review
        case complete
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @FocusState private var responseIsFocused: Bool

    let userID: String
    let onImported: (Int) -> Void

    @State private var stage: Stage = .prompt
    @State private var pastedResponse = ""
    @State private var drafts: [CareerMemoryDraft] = []
    @State private var notices: [String] = []
    @State private var errorMessage: String?
    @State private var savedCount = 0

    var body: some View {
        NavigationStack {
            ZStack {
                SoloraTheme.cream.ignoresSafeArea()

                currentStage
                    .id(stage)
                    .transition(reduceMotion ? .opacity : .soloraReveal)
            }
            .foregroundStyle(SoloraTheme.ink)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomAction
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if stage == .paste || stage == .review {
                        Button {
                            goBack()
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SoloraTheme.ink)
                    }
                }

                ToolbarItem(placement: .principal) {
                    if stage != .complete {
                        Text("\(stage.rawValue + 1) of 3")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .foregroundStyle(SoloraTheme.ink.opacity(0.52))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(stage == .complete ? "Close" : "Not now") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SoloraTheme.coral)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(stage == .review && hasUnsavedValidMemories)
    }

    @ViewBuilder
    private var currentStage: some View {
        switch stage {
        case .prompt:
            promptStage
        case .paste:
            pasteStage
        case .review:
            reviewStage
        case .complete:
            completeStage
        }
    }

    private var promptStage: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                stageHeading(
                    eyebrow: "CHATGPT HANDOFF",
                    title: "Ask for the parts of your career worth keeping",
                    detail: "Solora does not connect to your ChatGPT account. You decide what crosses over by copying this prompt yourself."
                )

                VStack(alignment: .leading, spacing: 14) {
                    instruction(1, "Copy Solora's tailored prompt")
                    instruction(2, "Paste it into a ChatGPT conversation")
                    instruction(3, "Bring the JSON response back here")
                }
                .padding(20)
                .background(.white.opacity(0.52), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .soloraHairline(radius: 20)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Your tailored prompt", systemImage: "text.quote")
                            .font(.subheadline.weight(.bold))
                        Spacer()
                        Text("v\(ChatGPTCareerMemoryImport.version)")
                            .font(.caption.monospaced().weight(.bold))
                            .foregroundStyle(SoloraTheme.ink.opacity(0.46))
                    }

                    Text(ChatGPTCareerMemoryImport.prompt)
                        .font(.caption.monospaced())
                        .foregroundStyle(SoloraTheme.ink.opacity(0.72))
                        .lineSpacing(3)
                        .textSelection(.enabled)
                }
                .padding(20)
                .background(SoloraTheme.lavender.opacity(0.11), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .soloraHairline(SoloraTheme.lavender.opacity(0.32), radius: 20)

                Label(
                    "The prompt limits the handoff to career evidence and tells ChatGPT not to include unrelated sensitive information.",
                    systemImage: "lock.shield.fill"
                )
                .font(.footnote.weight(.semibold))
                .foregroundStyle(SoloraTheme.ink.opacity(0.60))
                .padding(16)
                .background(SoloraTheme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    private var pasteStage: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                stageHeading(
                    eyebrow: "BRING IT BACK",
                    title: "Paste ChatGPT's response",
                    detail: "Solora checks the schema before anything can be saved. Markdown fences around the JSON are okay."
                )

                Button {
                    if let clipboardText = UIPasteboard.general.string {
                        pastedResponse = clipboardText
                        errorMessage = nil
                    }
                } label: {
                    Label("Paste from clipboard", systemImage: "doc.on.clipboard.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(SoloraTheme.ink)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(.white.opacity(0.52), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .soloraHairline(radius: 14)
                }
                .buttonStyle(SoloraPressButtonStyle())

                TextEditor(text: $pastedResponse)
                    .font(.footnote.monospaced())
                    .scrollContentBackground(.hidden)
                    .focused($responseIsFocused)
                    .frame(minHeight: 280)
                    .padding(14)
                    .background(.white.opacity(0.54), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .soloraHairline(errorMessage == nil ? SoloraTheme.ink.opacity(0.08) : SoloraTheme.coral.opacity(0.56), radius: 18)
                    .overlay(alignment: .topLeading) {
                        if pastedResponse.isEmpty {
                            Text("Paste the complete JSON response here")
                                .font(.footnote.monospaced())
                                .foregroundStyle(SoloraTheme.ink.opacity(0.34))
                                .padding(20)
                                .allowsHitTesting(false)
                        }
                    }

                if let errorMessage {
                    importMessage(errorMessage, symbol: "exclamationmark.triangle.fill", color: SoloraTheme.coral)
                        .accessibilityLabel("Import error: \(errorMessage)")
                }

                Label("Nothing is saved at this step.", systemImage: "eye.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(SoloraTheme.ink.opacity(0.56))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var reviewStage: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                stageHeading(
                    eyebrow: "YOUR REVIEW",
                    title: "Choose what becomes lore",
                    detail: "Edit every detail that needs context. Only included, valid memories will be written to your private archive."
                )

                if !notices.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(notices, id: \.self) { notice in
                            importMessage(notice, symbol: "info.circle.fill", color: SoloraTheme.gold)
                        }
                    }
                }

                ForEach($drafts) { $draft in
                    CareerMemoryReviewCard(draft: $draft) {
                        withAnimation(reduceMotion ? nil : SoloraMotion.responsive) {
                            drafts.removeAll { $0.id == draft.id }
                        }
                    }
                }

                if drafts.isEmpty {
                    importMessage(
                        "No memories remain. Go back and paste another response.",
                        symbol: "tray.fill",
                        color: SoloraTheme.lavender
                    )
                }

                if let errorMessage {
                    importMessage(errorMessage, symbol: "exclamationmark.triangle.fill", color: SoloraTheme.coral)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var completeStage: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(SoloraTheme.lavender.opacity(0.20))
                    .frame(width: 210, height: 210)
                    .blur(radius: 28)
                SoloraOnboardingGlassOrb(
                    size: 142,
                    color: SoloraTheme.lavender,
                    isAlive: !reduceMotion,
                    showsHalo: true
                )
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(SoloraTheme.cream)
            }
            .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text("Your memories are in Solora")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                Text("\(savedCount) reviewed career \(savedCount == 1 ? "memory is" : "memories are") now part of your private lore.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(SoloraTheme.ink.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .frame(maxWidth: 330)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var bottomAction: some View {
        VStack(spacing: 0) {
            switch stage {
            case .prompt:
                SoloraOnboardingPrimaryButton(
                    title: "Copy tailored prompt",
                    detail: "Then paste it into ChatGPT"
                ) {
                    UIPasteboard.general.string = ChatGPTCareerMemoryImport.prompt
                    advance(to: .paste)
                    responseIsFocused = false
                }
            case .paste:
                SoloraOnboardingPrimaryButton(
                    title: "Review memories",
                    detail: "Validate before anything is saved"
                ) {
                    parseResponse()
                }
                .disabled(pastedResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(pastedResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.46 : 1)
            case .review:
                SoloraOnboardingPrimaryButton(
                    title: "Save \(includedDrafts.count) \(includedDrafts.count == 1 ? "memory" : "memories")",
                    detail: reviewActionDetail
                ) {
                    saveReviewedMemories()
                }
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.46)
            case .complete:
                SoloraOnboardingPrimaryButton(title: "Continue onboarding") {
                    dismiss()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private var includedDrafts: [CareerMemoryDraft] {
        drafts.filter(\.isIncluded)
    }

    private var hasUnsavedValidMemories: Bool {
        !includedDrafts.isEmpty && includedDrafts.allSatisfy(\.isValid)
    }

    private var canSave: Bool {
        !includedDrafts.isEmpty && includedDrafts.allSatisfy(\.isValid)
    }

    private var reviewActionDetail: String {
        let invalidCount = includedDrafts.filter { !$0.isValid }.count
        if includedDrafts.isEmpty { return "Include at least one memory" }
        if invalidCount > 0 {
            return "Fix \(invalidCount) included \(invalidCount == 1 ? "memory" : "memories") first"
        }
        return "Write reviewed memories to your private archive"
    }

    private func parseResponse() {
        responseIsFocused = false
        errorMessage = nil

        do {
            let result = try ChatGPTCareerMemoryImport.parse(pastedResponse)
            drafts = result.drafts
            notices = result.notices
            advance(to: .review)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Solora could not read that response. Check the JSON and try again."
        }
    }

    private func saveReviewedMemories() {
        errorMessage = nil
        let moments = includedDrafts.compactMap { $0.makeMoment() }
        guard moments.count == includedDrafts.count else {
            errorMessage = "Fix each included memory before saving."
            return
        }

        do {
            try ChatGPTCareerMemoryImport.save(moments, userID: userID)
            savedCount = moments.count
            onImported(moments.count)
            advance(to: .complete)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Your memories could not be saved right now. Please try again."
        }
    }

    private func goBack() {
        switch stage {
        case .prompt, .complete:
            return
        case .paste:
            advance(to: .prompt)
        case .review:
            advance(to: .paste)
        }
    }

    private func advance(to newStage: Stage) {
        withAnimation(reduceMotion ? .easeOut(duration: 0.16) : SoloraMotion.reveal) {
            stage = newStage
        }
    }

    private func stageHeading(eyebrow: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SoloraOnboardingGlassOrb(size: 54, color: SoloraTheme.lavender, isAlive: stage == .prompt)
                    .accessibilityHidden(true)
                Spacer()
            }
            .padding(.bottom, 4)

            Text(eyebrow)
                .font(.caption.weight(.black))
                .tracking(1.4)
                .foregroundStyle(SoloraTheme.coral)
            Text(title)
                .font(.system(size: 31, weight: .black, design: .rounded))
                .tracking(-0.6)
            Text(detail)
                .font(.body.weight(.medium))
                .foregroundStyle(SoloraTheme.ink.opacity(0.62))
                .lineSpacing(3)
        }
    }

    private func instruction(_ number: Int, _ text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.black))
                .foregroundStyle(SoloraTheme.cream)
                .frame(width: 28, height: 28)
                .background(SoloraTheme.ink, in: Circle())
            Text(text)
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
    }

    private func importMessage(_ text: String, symbol: String, color: Color) -> some View {
        Label(text, systemImage: symbol)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(SoloraTheme.ink.opacity(0.68))
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct CareerMemoryReviewCard: View {
    @Binding var draft: CareerMemoryDraft
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Toggle(isOn: $draft.isIncluded) {
                    Text(draft.isIncluded ? "Included" : "Not included")
                        .font(.subheadline.weight(.bold))
                }
                .tint(SoloraTheme.moss)

                Spacer()

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .frame(width: 44, height: 44)
                }
                .foregroundStyle(SoloraTheme.coral)
                .accessibilityLabel("Remove memory")
            }

            Menu {
                ForEach(CareerMemoryKind.allCases) { kind in
                    Button(kind.title) { draft.kind = kind }
                }
            } label: {
                HStack {
                    Text(draft.kind.title)
                        .font(.subheadline.weight(.bold))
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(SoloraTheme.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 46)
                .background(SoloraTheme.lavender.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Title")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SoloraTheme.ink.opacity(0.52))
                TextField("What is worth remembering?", text: $draft.title, axis: .vertical)
                    .font(.body.weight(.semibold))
                    .lineLimit(1...3)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Career evidence")
                    Spacer()
                    Text("\(draft.summary.count)/2000")
                        .monospacedDigit()
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(SoloraTheme.ink.opacity(0.52))

                TextEditor(text: $draft.summary)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 112)
                    .padding(10)
                    .background(.white.opacity(0.46), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .soloraHairline(radius: 12)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("When it happened")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SoloraTheme.ink.opacity(0.52))
                TextField("YYYY-MM-DD", text: $draft.occurredOn)
                    .font(.body.monospaced().weight(.semibold))
                    .textInputAutocapitalization(.never)
                    .keyboardType(.numbersAndPunctuation)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 46)
                    .background(.white.opacity(0.46), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .soloraHairline(radius: 12)
            }

            if draft.isIncluded && !draft.validationMessages.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(draft.validationMessages, id: \.self) { message in
                        Label(message, systemImage: "exclamationmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SoloraTheme.coral)
                    }
                }
            }
        }
        .padding(18)
        .background(.white.opacity(draft.isIncluded ? 0.54 : 0.28), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .soloraHairline(
            draft.isIncluded && !draft.isValid ? SoloraTheme.coral.opacity(0.42) : SoloraTheme.ink.opacity(0.08),
            radius: 20
        )
        .opacity(draft.isIncluded ? 1 : 0.68)
    }
}
