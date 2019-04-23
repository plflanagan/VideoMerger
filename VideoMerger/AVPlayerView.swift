//
//  AVPlayerLayer.swift
//  UNUMCanvas
//
//  Created by Patrick Flanagan on 4/2/19.
//

import Foundation
import AVKit
import Anchorage

public enum PlayerViewFactory {
    public static func makePlayerView(with avAsset: AVAsset) -> AVPlayerView {
        let avPlayerItem = AVPlayerItem(asset: avAsset)
        let avPlayer = AVPlayer(playerItem: avPlayerItem)

        let mediaView = AVPlayerView(player: avPlayer)

        if let videoLayer = mediaView.layer as? AVPlayerLayer {
            videoLayer.backgroundColor = UIColor.clear.cgColor
            videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        }

        return mediaView
    }
}

public class AVPlayerView: UIView {

    private var videoView: VideoView?

    public var videoPlayer: AVPlayer {
        guard let videoView = videoView else {
            assertionFailure("Player Layer should be set at init.")
            return AVPlayer(playerItem: nil)
        }
        return videoView.videoPlayer
    }

    public init(player: AVPlayer) {
        super.init(frame: .zero)

        let image = getImage(from: player)
        let imageView = UIImageView(image: image)
        addSubview(imageView)
        imageView.edgeAnchors == edgeAnchors

        let videoView = VideoView(player: player)
        addSubview(videoView)
        videoView.edgeAnchors == edgeAnchors
        self.videoView = videoView
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getImage(from player: AVPlayer) -> UIImage? {
        guard let asset = player.currentItem?.asset else {
            return nil
        }

        let assetIG = AVAssetImageGenerator(asset: asset)
        assetIG.appliesPreferredTrackTransform = true
        assetIG.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels

        let cmTime = CMTime(seconds: 0, preferredTimescale: 60)
        let thumbnailImageRef: CGImage
        do {
            thumbnailImageRef = try assetIG.copyCGImage(at: cmTime, actualTime: nil)
        } catch let error {
            print("Error: \(error)")
            return nil
        }

        return UIImage(cgImage: thumbnailImageRef)
    }
}

private class VideoView: UIView {
    public var videoPlayer: AVPlayer {
        guard
            let playerLayer = layer as? AVPlayerLayer,
            let player = playerLayer.player
            else {
                assertionFailure("Player Layer should be set at init.")
                return AVPlayer(playerItem: nil)
        }
        return player
    }

    override public class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    public init(player: AVPlayer) {
        super.init(frame: .zero)
        guard let castedLayer = layer as? AVPlayerLayer else {
            assertionFailure("Layer is not able to be cast properly")
            return
        }
        castedLayer.player = player
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
