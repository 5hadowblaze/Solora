import Foundation

struct AppContainer: Sendable {
    let moments: [SoloraMoment]
    let worldManifest: WorldManifest

    static let demo = AppContainer(
        moments: DemoFixtures.moments,
        worldManifest: DemoFixtures.memoryShelvesManifest
    )
}
