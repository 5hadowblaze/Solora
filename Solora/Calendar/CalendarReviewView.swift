import SwiftUI

struct CalendarReviewSheet: View {
    @ObservedObject var store: CalendarSourceStore

    @Environment(\.dismiss) private var dismiss
    @State private var showsDisconnectConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                switch store.status {
                case .checking:
                    ProgressView("Checking Calendar connection…")
                case .notConnected:
                    disclosure
                case .needsAttention(let message):
                    attention(message)
                case .connected(let accountEmail):
                    connected(accountEmail: accountEmail)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SoloraTheme.cream.ignoresSafeArea())
            .foregroundStyle(SoloraTheme.ink)
            .navigationTitle("Google Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
            .navigationDestination(for: CalendarEventCandidate.self) { event in
                CalendarEventReviewView(event: event, store: store)
            }
            .alert("Calendar", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { store.errorMessage = nil }
            } message: {
                Text(store.errorMessage ?? "Please try again.")
            }
            .confirmationDialog(
                "Disconnect Google Calendar?",
                isPresented: $showsDisconnectConfirmation,
                titleVisibility: .visible
            ) {
                Button("Disconnect and revoke access", role: .destructive) {
                    Task { await store.disconnectAndRevoke() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears Calendar access granted to Solora. Memories you already reviewed and saved stay in your lore.")
            }
        }
        .presentationDetents([.large])
    }

    private var disclosure: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                sourceHero(symbol: "calendar.badge.clock", title: "Review moments worth keeping")
                Text("Solora asks Google for read-only access to your primary calendar. It checks only completed events from the previous 30 days.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(SoloraTheme.ink.opacity(0.66))
                VStack(alignment: .leading, spacing: 14) {
                    privacyLine("Nothing is imported automatically", symbol: "hand.raised.fill")
                    privacyLine("Every event is reviewed individually", symbol: "checkmark.circle.fill")
                    privacyLine("Descriptions, attendee identities and meeting links are not read", symbol: "lock.fill")
                }
                .padding(18)
                .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 18))
                .soloraHairline(radius: 18)

                Button {
                    Task { await store.connectAndReview() }
                } label: {
                    actionLabel(store.isLoadingEvents ? "Opening Google…" : "Continue to Google")
                }
                .buttonStyle(SoloraPressButtonStyle())
                .disabled(store.isLoadingEvents)
            }
            .padding(20)
        }
    }

    private func attention(_ message: String) -> some View {
        VStack(spacing: 18) {
            sourceHero(symbol: "exclamationmark.arrow.triangle.2.circlepath", title: "Calendar needs attention")
            Text(message)
                .font(.body.weight(.medium))
                .foregroundStyle(SoloraTheme.ink.opacity(0.64))
                .multilineTextAlignment(.center)
            Button {
                Task { await store.connectAndReview() }
            } label: {
                actionLabel(store.isLoadingEvents ? "Reconnecting…" : "Reconnect Calendar")
            }
            .buttonStyle(SoloraPressButtonStyle())
            .disabled(store.isLoadingEvents)
        }
        .padding(24)
    }

    private func connected(accountEmail: String) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Connected")
                            .font(.title2.weight(.bold))
                        Text(accountEmail)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(SoloraTheme.ink.opacity(0.54))
                    }
                    Spacer()
                    Button("Disconnect") { showsDisconnectConfirmation = true }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SoloraTheme.coral)
                }

                Label("Private review only · nothing is saved until you add a reflection", systemImage: "lock.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(SoloraTheme.ink.opacity(0.60))
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SoloraTheme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

                if store.isLoadingEvents {
                    ProgressView("Checking completed events…")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                } else if !store.hasLoadedEvents {
                    Button {
                        Task { await store.refreshEvents() }
                    } label: {
                        actionLabel("Review recent events")
                    }
                    .buttonStyle(SoloraPressButtonStyle())
                } else if store.events.isEmpty {
                    ContentUnavailableView(
                        "No events to review",
                        systemImage: "calendar.badge.checkmark",
                        description: Text("There are no eligible completed events in the last 30 days.")
                    )
                    .padding(.vertical, 40)
                } else {
                    HStack {
                        Text("Completed events")
                            .font(.headline)
                        Spacer()
                        Button("Refresh") { Task { await store.refreshEvents() } }
                            .font(.caption.weight(.bold))
                    }

                    ForEach(store.events) { event in
                        HStack(spacing: 12) {
                            NavigationLink(value: event) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(event.title)
                                        .font(.subheadline.weight(.bold))
                                        .lineLimit(2)
                                    Text(eventDate(event))
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(SoloraTheme.ink.opacity(0.54))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            Button("Skip") { store.skip(event) }
                                .font(.caption.weight(.bold))
                                .foregroundStyle(SoloraTheme.ink.opacity(0.48))
                        }
                        .padding(15)
                        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 15))
                        .soloraHairline(radius: 15)
                    }
                }
            }
            .padding(20)
        }
        .refreshable { await store.refreshEvents() }
    }

    private func eventDate(_ event: CalendarEventCandidate) -> String {
        if event.isAllDay {
            return event.startDate.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)) + " · all day"
        }
        return event.startDate.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
    }

    private func sourceHero(symbol: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(SoloraTheme.coral)
                .frame(width: 72, height: 72)
                .background(SoloraTheme.gold.opacity(0.18), in: Circle())
            Text(title)
                .font(.system(size: 32, weight: .black, design: .rounded))
        }
    }

    private func privacyLine(_ text: String, symbol: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(SoloraTheme.ink.opacity(0.72))
    }

    private func actionLabel(_ title: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: "arrow.right")
        }
        .font(.headline.weight(.bold))
        .foregroundStyle(SoloraTheme.cream)
        .padding(.horizontal, 18)
        .frame(height: 54)
        .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 13))
    }
}

private struct CalendarEventReviewView: View {
    let event: CalendarEventCandidate
    @ObservedObject var store: CalendarSourceStore

    @Environment(\.dismiss) private var dismiss
    @State private var reflection = ""
    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("REVIEW BEFORE SAVING")
                        .font(.caption.weight(.black))
                        .tracking(1.2)
                        .foregroundStyle(SoloraTheme.coral)
                    Text(event.title)
                        .font(.system(size: 31, weight: .black, design: .rounded))
                    Text(event.startDate.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SoloraTheme.ink.opacity(0.55))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("What changed?")
                        .font(.title3.weight(.bold))
                    Text("Add what you contributed, learned, decided or achieved. One thought is enough.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SoloraTheme.ink.opacity(0.58))
                    TextEditor(text: $reflection)
                        .frame(minHeight: 150)
                        .padding(10)
                        .scrollContentBackground(.hidden)
                        .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 14))
                        .soloraHairline(radius: 14)
                }

                Label("Only this title, date and your reflection will be saved to Solora.", systemImage: "lock.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(SoloraTheme.ink.opacity(0.58))

                Button(action: save) {
                    HStack {
                        Text(isSaving ? "Saving…" : "Keep in my lore")
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(SoloraTheme.cream)
                    .padding(.horizontal, 18)
                    .frame(height: 54)
                    .background(SoloraTheme.ink, in: RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(SoloraPressButtonStyle())
                .disabled(isSaving || reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            }
            .padding(20)
        }
        .background(SoloraTheme.cream.ignoresSafeArea())
        .navigationTitle("Review event")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Couldn't save", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "Please try again.")
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                _ = try await store.saveMemory(from: event, reflection: reflection)
                dismiss()
            } catch {
                saveError = error.localizedDescription
            }
            isSaving = false
        }
    }
}
