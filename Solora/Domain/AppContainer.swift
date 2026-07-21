import Foundation

struct AppContainer: Sendable {
    let moments: [SoloraMoment]

    static let demo = AppContainer(
        moments: DemoFixtures.moments
    )
}
