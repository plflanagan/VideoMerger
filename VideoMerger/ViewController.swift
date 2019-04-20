//
//  ViewController.swift
//  VideoMerger
//
//  Created by Patrick Flanagan on 4/19/19.
//  Copyright © 2019 ORG_NAME. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        overlapVideos()
    }

    func overlapVideos() {
        let startTime = DispatchTime.now()

        let composition = AVMutableComposition()

        // make main video instruction
        let mainInstruction = AVMutableVideoCompositionInstruction()

        guard let pathUrl = Bundle.main.url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4") else {
            assertionFailure()
            return
        }


        // make first video track and add to composition
        let firstAsset = AVAsset(url: pathUrl)

        // timeframe will match first video for this example
        mainInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: firstAsset.duration)


        guard let firstTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            assertionFailure()
            return
        }
        try! firstTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: firstAsset.duration), of: firstAsset.tracks(withMediaType: .video)[0], at: .zero)

        // add layer instruction for first video
        let firstVideoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: firstTrack)
        let firstMove = CGAffineTransform(translationX: 1000, y: 400)
        let firstScale = CGAffineTransform(scaleX: 0.2, y: 0.2)

        firstVideoLayerInstruction.setTransform(firstMove.concatenating(firstScale), at: .zero)

        mainInstruction.layerInstructions.append(firstVideoLayerInstruction)


        // make second video track and add to composition
        let secondAsset = AVAsset(url: pathUrl)

        guard let secondTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            assertionFailure()
            return
        }
        try! secondTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: secondAsset.duration), of: secondAsset.tracks(withMediaType: .video)[0], at: .zero)

        // add layer instruction for second video
        let secondVideoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: secondTrack)
        let secondMove = CGAffineTransform(translationX: -500, y: -500)
        let secondScale = CGAffineTransform(scaleX: 0.2, y: 0.2)

        secondVideoLayerInstruction.setTransform(secondMove.concatenating(secondScale), at: .zero)

        mainInstruction.layerInstructions.append(secondVideoLayerInstruction)


        // make third video track and add to composition
        let thirdAsset = AVAsset(url: pathUrl)

        guard let thirdTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            assertionFailure()
            return
        }
        try! thirdTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: thirdAsset.duration), of: thirdAsset.tracks(withMediaType: .video)[0], at: .zero)

        // add layer instruction for third video
        let thirdVideoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: thirdTrack)
        let thirdMove = CGAffineTransform(translationX: 0, y: 1000)
        let thirdScale = CGAffineTransform(scaleX: 0.2, y: 0.2)

        thirdVideoLayerInstruction.setTransform(thirdMove.concatenating(thirdScale), at: .zero)

        mainInstruction.layerInstructions.append(thirdVideoLayerInstruction)


        // make video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [mainInstruction]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderSize = CGSize(width: 640, height: 480)


        // export
        let searchPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentDirectory = searchPaths[0]
        let filePath = documentDirectory.appending("output.mov")
        let outputUrl = URL(fileURLWithPath: filePath)

        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: filePath) {
            try! fileManager.removeItem(at: outputUrl)
        }

        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            assertionFailure()
            return
        }
        exporter.videoComposition = videoComposition
        exporter.outputFileType = .mov
        exporter.outputURL = outputUrl

        exporter.exportAsynchronously {
            DispatchQueue.main.async { [weak self] in
                let endTime = DispatchTime.now()
                print("time required: \((endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000 )s")
                self?.didFinish(session: exporter)
            }
        }
    }

    func didFinish(session: AVAssetExportSession) {
        guard let url = session.outputURL else {
            assertionFailure()
            return
        }
        showVideo(videoUrl: url)
    }

    let player = AVPlayerViewController()

    func showVideo(videoUrl: URL) {

        let videoPlayer = AVPlayer(url: videoUrl)
        player.player = videoPlayer

        self.present(player, animated: true) {
            self.player.player?.play()
        }
    }
}

