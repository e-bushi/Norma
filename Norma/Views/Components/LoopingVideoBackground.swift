//
//  LoopingVideoBackground.swift
//  Norma
//
//  Created by Claude on 3/12/26.
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - Video Cycling Manager

class VideoCycleManager: ObservableObject {
    @Published var activeIndex = 0

    let videoNames: [String]
    let videoDurations: [TimeInterval]
    private(set) var players: [AVPlayer] = []
    private var transitionTimer: Timer?
    private var observers: [Any] = []

    init(videoNames: [String], videoDurations: [TimeInterval]) {
        self.videoNames = videoNames
        self.videoDurations = videoDurations
    }

    func setup() {
        guard players.isEmpty else { return }

        players = videoNames.compactMap { name in
            guard let url = Bundle.main.url(forResource: name, withExtension: "mp4") else { return nil }
            let player = AVPlayer(url: url)
            player.isMuted = true
            player.actionAtItemEnd = .none

            // Loop each video so it keeps playing if transition hasn't fired yet
            let observer = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { _ in
                player.seek(to: .zero)
                player.play()
            }
            observers.append(observer)

            return player
        }

        // Start the first video
        players.first?.play()

        if players.count > 1 {
            scheduleTransition()
        }
    }

    func teardown() {
        transitionTimer?.invalidate()
        transitionTimer = nil
        players.forEach { $0.pause() }
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
    }

    private func scheduleTransition() {
        let duration = activeIndex < videoDurations.count
            ? videoDurations[activeIndex]
            : 8.0

        transitionTimer?.invalidate()
        transitionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.performTransition()
        }
    }

    private func performTransition() {
        guard players.count > 1 else { return }

        let previous = activeIndex
        let upcoming = (activeIndex + 1) % players.count

        // Start the next video from the beginning
        players[upcoming].seek(to: .zero)
        players[upcoming].play()

        // Crossfade
        withAnimation(.easeInOut(duration: 1.5)) {
            activeIndex = upcoming
        }

        // Pause the old video after crossfade
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            self?.players[previous].pause()
        }

        // Schedule the next transition after crossfade completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.scheduleTransition()
        }
    }

    deinit {
        teardown()
    }
}

// MARK: - View

struct LoopingVideoBackground: View {
    @StateObject private var manager: VideoCycleManager

    init(videoNames: [String], videoDurations: [TimeInterval]) {
        _manager = StateObject(wrappedValue: VideoCycleManager(
            videoNames: videoNames,
            videoDurations: videoDurations
        ))
    }

    var body: some View {
        ZStack {
            ForEach(Array(manager.players.enumerated()), id: \.offset) { index, player in
                VideoLayerView(player: player)
                    .opacity(index == manager.activeIndex ? 1 : 0)
                    .animation(.easeInOut(duration: 1.5), value: manager.activeIndex)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            manager.setup()
        }
        .onDisappear {
            manager.teardown()
        }
    }
}

// MARK: - AVPlayer UIViewRepresentable

struct VideoLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> VideoPlayerUIView {
        VideoPlayerUIView(player: player)
    }

    func updateUIView(_ uiView: VideoPlayerUIView, context: Context) {}
}

class VideoPlayerUIView: UIView {
    private var playerLayer: AVPlayerLayer

    init(player: AVPlayer) {
        playerLayer = AVPlayerLayer(player: player)
        super.init(frame: .zero)

        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
