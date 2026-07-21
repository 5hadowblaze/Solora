import SwiftUI

struct MasterCVView: View {
    let moments: [SoloraMoment]
    let userID: String

    @StateObject private var cvStore: CVStore

    init(moments: [SoloraMoment], userID: String) {
        self.moments = moments
        self.userID = userID
        _cvStore = StateObject(wrappedValue: CVStore(userID: userID))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SoloraTheme.paper.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        cvCard
                        recentMoments
                        shareActions
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task(id: userID) {
                await cvStore.load()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR CAREER")
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(SoloraTheme.coral)
            Text("Master CV")
                .font(.system(size: 36, weight: .bold, design: .rounded))
            Text("A private, living record shaped by the moments you choose to keep.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SoloraTheme.ink.opacity(0.58))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(SoloraTheme.ink)
    }

    @ViewBuilder
    private var cvCard: some View {
        if cvStore.isLoading {
            ProgressView("Loading your master CV…")
                .frame(maxWidth: .infinity, minHeight: 176)
                .tint(SoloraTheme.coral)
                .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 20))
        } else if let master = cvStore.master {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(master.title)
                            .font(.title3.weight(.bold))
                        Text("Version \(master.version) · \(master.structuredEntryCount) entries")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SoloraTheme.ink.opacity(0.52))
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(SoloraTheme.moss)
                        .font(.title2)
                }

                Text(preview(of: master.contentMarkdown))
                    .font(.subheadline)
                    .foregroundStyle(SoloraTheme.ink.opacity(0.72))
                    .lineLimit(6)

                ShareLink(item: master.contentMarkdown) {
                    Label("Share master CV", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(SoloraTheme.cream)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(20)
            .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 20))
            .soloraHairline(radius: 20)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "doc.badge.plus")
                    .font(.title2)
                    .foregroundStyle(SoloraTheme.coral)
                Text("Your CV will live here")
                    .font(.title3.weight(.bold))
                Text("Keep capturing moments for now. When your master CV is ready, it will become the source for every shareable version.")
                    .font(.subheadline)
                    .foregroundStyle(SoloraTheme.ink.opacity(0.62))
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SoloraTheme.gold.opacity(0.13), in: RoundedRectangle(cornerRadius: 20))
            .soloraHairline(SoloraTheme.gold.opacity(0.34), radius: 20)
        }
    }

    private var recentMoments: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT EVIDENCE")
                .font(.caption.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(SoloraTheme.ink.opacity(0.48))

            if moments.isEmpty {
                Text("Capture a moment in Now and it will become evidence you can reuse here.")
                    .font(.subheadline)
                    .foregroundStyle(SoloraTheme.ink.opacity(0.60))
            } else {
                ForEach(Array(moments.prefix(3).enumerated()), id: \.element.id) { index, moment in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(SoloraTheme.orbColors[index % SoloraTheme.orbColors.count])
                            .frame(width: 12, height: 12)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(moment.title)
                                .font(.subheadline.weight(.semibold))
                            Text(moment.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(SoloraTheme.ink.opacity(0.48))
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(.white.opacity(0.46), in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private var shareActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MAKE SOMETHING SMALL")
                .font(.caption.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(SoloraTheme.ink.opacity(0.48))

            ShareLink(item: recentPost) {
                actionRow(
                    title: "Generate a post from recent moments",
                    detail: "A concise, editable reflection on what you have been doing.",
                    symbol: "text.quote"
                )
            }

            ShareLink(item: bubbleStory) {
                actionRow(
                    title: "Share your CV as memory bubbles",
                    detail: "A visual, personal summary rather than a formal document.",
                    symbol: "circle.hexagongrid.fill"
                )
            }
        }
    }

    private func actionRow(title: String, detail: String, symbol: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(SoloraTheme.coral)
                .frame(width: 44, height: 44)
                .background(SoloraTheme.coral.opacity(0.10), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(SoloraTheme.ink)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(SoloraTheme.ink.opacity(0.56))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Image(systemName: "square.and.arrow.up")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(SoloraTheme.ink.opacity(0.34))
        }
        .padding(16)
        .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 16))
        .soloraHairline(radius: 16)
    }

    private var recentPost: String {
        let highlights = moments.prefix(3).map { "• \($0.title): \($0.summary)" }.joined(separator: "\n")
        return highlights.isEmpty
            ? "I am building a more intentional record of the work that matters to me."
            : "A few moments I am taking forward from recent work:\n\n\(highlights)"
    }

    private var bubbleStory: String {
        let titles = moments.prefix(5).map(\.title).joined(separator: " · ")
        return titles.isEmpty
            ? "My career is a collection of the moments I chose to keep."
            : "My career, in moments: \(titles)."
    }

    private func preview(of markdown: String) -> String {
        let lines = markdown
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return lines.prefix(6).joined(separator: "\n")
    }
}
