import AVFoundation
import SwiftUI
import UIKit

struct SoloraOrbView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var size: CGFloat = 96
    var color: Color = SoloraTheme.gold
    var isAlive = false
    var showsHalo = false
    var mediaPath: String?
    var mediaPaths: [String] = []
    var visualAssets: [MomentVisualAsset] = []
    var playbackStyle: MemoryPlaybackStyle = .photoSequence
    var stickerPath: String?

    var body: some View {
        Group {
            if isAlive && !reduceMotion {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    orb(at: timeline.date.timeIntervalSinceReferenceDate)
                }
            } else {
                orb(at: 0)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("Glowing Solora orb")
        .accessibilityHint("A visual marker in your personal world")
    }

    private func orb(at time: TimeInterval) -> some View {
        let phase = time
        let breath = 1 + sin(phase * 0.72) * 0.014
        let driftX = cos(phase * 0.52) * size * 0.055
        let driftY = sin(phase * 0.43) * size * 0.045
        let rimWidth = max(1, size * 0.016)
        let availableMedia = visualAssets.isEmpty
            ? (mediaPaths.isEmpty ? [mediaPath].compactMap { $0 } : mediaPaths)
            : visualAssets.map(\.posterPath)
        let mediaIndex = availableMedia.isEmpty ? 0 : Int((phase / 3.4).rounded(.down)) % availableMedia.count
        let motionPath = playbackStyle == .livingSequence && visualAssets.indices.contains(mediaIndex)
            ? visualAssets[mediaIndex].motionPath
            : nil

        return ZStack {
            if showsHalo {
                Circle()
                    .trim(from: 0.08, to: 0.68)
                    .stroke(
                        AngularGradient(
                            colors: [
                                color.opacity(0),
                                color.opacity(0.42),
                                .white.opacity(0.74),
                                SoloraTheme.lavender.opacity(0.42),
                                color.opacity(0)
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: max(1.5, size * 0.014), lineCap: .round)
                    )
                    .padding(-size * 0.13)
                    .rotationEffect(.degrees(phase * 9))
                    .blur(radius: size * 0.004)
                    .opacity(0.68)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.96),
                            SoloraTheme.cream.opacity(0.82),
                            color.opacity(0.58),
                            SoloraTheme.lavender.opacity(0.36),
                            SoloraTheme.plum.opacity(0.18)
                        ],
                        center: UnitPoint(x: 0.28, y: 0.22),
                        startRadius: 1,
                        endRadius: size * 0.82
                    )
                )

            ZStack {
                Circle()
                    .fill(color.opacity(0.62))
                    .frame(width: size * 0.78, height: size * 0.78)
                    .blur(radius: size * 0.13)
                    .offset(x: size * 0.23 + driftX, y: size * 0.28 + driftY)

                Circle()
                    .fill(SoloraTheme.cream.opacity(0.82))
                    .frame(width: size * 0.66, height: size * 0.56)
                    .blur(radius: size * 0.11)
                    .offset(x: -size * 0.22 - driftX * 0.6, y: -size * 0.23)

                Capsule()
                    .fill(SoloraTheme.lavender.opacity(0.48))
                    .frame(width: size * 0.9, height: size * 0.28)
                    .rotationEffect(.degrees(-22 + sin(phase * 0.37) * 5))
                    .blur(radius: size * 0.09)
                    .offset(x: size * 0.05, y: size * 0.22 - driftY)

                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                .white.opacity(0.54),
                                .clear,
                                SoloraTheme.coral.opacity(0.26),
                                color.opacity(0.34),
                                .white.opacity(0.48)
                            ],
                            center: .center
                        )
                    )
                    .rotationEffect(.degrees(phase * -5))
                    .blendMode(.screen)
            }
            .clipShape(Circle().inset(by: size * 0.025))

            if let selectedMediaPath = availableMedia.indices.contains(mediaIndex) ? availableMedia[mediaIndex] : nil,
               !selectedMediaPath.isEmpty {
                Group {
                    if let motionPath, isAlive && !reduceMotion {
                        SoloraMomentMotionPlayer(path: motionPath)
                    } else {
                        SoloraMomentMediaImage(path: selectedMediaPath)
                    }
                }
                    .frame(width: size * 0.94, height: size * 0.94)
                    .clipShape(Circle())
                    .id(selectedMediaPath)
                    .transition(.opacity)
                    .overlay {
                        Circle().fill(
                            LinearGradient(
                                colors: [.white.opacity(0.22), .clear, color.opacity(0.14)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                    .animation(.easeInOut(duration: 0.8), value: selectedMediaPath)
            }

            if let stickerPath, !stickerPath.isEmpty {
                SoloraMomentMediaImage(path: stickerPath, scalesToFill: false)
                    .frame(width: size * 0.78, height: size * 0.78)
                    .rotationEffect(.degrees(-4 + sin(phase * 0.33) * 1.5))
                    .shadow(color: SoloraTheme.plum.opacity(0.22), radius: size * 0.05, y: size * 0.04)
                    .accessibilityLabel("Personal memory sticker")
            }

            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.48), .clear, SoloraTheme.plum.opacity(0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.screen)
                .opacity(0.8)

            Ellipse()
                .fill(.white.opacity(0.72))
                .frame(width: size * 0.44, height: size * 0.19)
                .blur(radius: max(1.5, size * 0.045))
                .rotationEffect(.degrees(-32))
                .offset(x: -size * 0.18 + driftX * 0.28, y: -size * 0.26 + driftY * 0.24)

            Ellipse()
                .stroke(SoloraTheme.lavender.opacity(0.36), lineWidth: size * 0.025)
                .frame(width: size * 0.7, height: size * 0.18)
                .blur(radius: size * 0.025)
                .offset(y: size * 0.34)

            Circle()
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.92), location: 0),
                            .init(color: .white.opacity(0.2), location: 0.38),
                            .init(color: SoloraTheme.lavender.opacity(0.58), location: 0.72),
                            .init(color: .white.opacity(0.7), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: rimWidth
                )

            Circle()
                .stroke(.white.opacity(0.35), lineWidth: max(0.7, size * 0.007))
                .padding(size * 0.035)
        }
        .scaleEffect(breath)
        .compositingGroup()
        .shadow(color: SoloraTheme.plum.opacity(0.16), radius: size * 0.05, y: size * 0.04)
        .shadow(color: color.opacity(0.3), radius: size * 0.18, y: size * 0.1)
    }
}

private struct SoloraMomentMotionPlayer: View {
    let path: String
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?

    var body: some View {
        PlayerLayerView(player: player)
            .task(id: path) {
                guard let url = try? await FirebaseMomentMediaRepository.downloadURL(for: path) else { return }
                let player = AVQueuePlayer()
                let item = AVPlayerItem(url: url)
                looper = AVPlayerLooper(player: player, templateItem: item)
                self.player = player
                player.isMuted = true
                player.play()
            }
            .onDisappear {
                player?.pause()
                looper = nil
                player = nil
            }
    }
}

private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer?

    func makeUIView(context: Context) -> PlayerView { PlayerView() }
    func updateUIView(_ view: PlayerView, context: Context) { view.playerLayer.player = player }

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        override init(frame: CGRect) {
            super.init(frame: frame)
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.backgroundColor = UIColor.clear.cgColor
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
}

private struct SoloraMomentMediaImage: View {
    let path: String
    var scalesToFill = true
    @State private var resolvedImage: Image?

    var body: some View {
        Group {
            if let resolvedImage {
                if scalesToFill {
                    resolvedImage.resizable().scaledToFill().transition(.opacity)
                } else {
                    resolvedImage.resizable().scaledToFit().transition(.opacity)
                }
            } else {
                Color.clear
            }
        }
        .animation(.easeOut(duration: 0.2), value: resolvedImage != nil)
        .task(id: path) {
            guard let data = try? await SoloraMomentMediaDataCache.shared.data(for: path),
                  let image = UIImage(data: data) else { return }
            resolvedImage = Image(uiImage: image)
        }
    }
}
