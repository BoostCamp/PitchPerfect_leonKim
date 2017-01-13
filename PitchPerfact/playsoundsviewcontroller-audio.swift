//
//  PlaySoundsViewController+Audio.swift
//  PitchPerfect
//
//  Copyright © 2016 Udacity. All rights reserved.
//

import UIKit
import AVFoundation

// MARK: - PlaySoundsViewController: AVAudioPlayerDelegate

extension PlaySoundsViewController: AVAudioPlayerDelegate {
    
    // MARK: Alerts
    
    struct Alerts {
        static let DismissAlert = "Dismiss"
        static let RecordingDisabledTitle = "Recording Disabled"
        static let RecordingDisabledMessage = "You've disabled this app from recording your microphone. Check Settings."
        static let RecordingFailedTitle = "Recording Failed"
        static let RecordingFailedMessage = "Something went wrong with your recording."
        static let AudioRecorderError = "Audio Recorder Error"
        static let AudioSessionError = "Audio Session Error"
        static let AudioRecordingError = "Audio Recording Error"
        static let AudioFileError = "Audio File Error"
        static let AudioEngineError = "Audio Engine Error"
    }
    
    // MARK: PlayingState (raw values correspond to sender tags)
    
    enum PlayingState { case playing, notPlaying, pause }
    
    // MARK: Audio Functions
    
    func setupAudio() {
        // initialize (recording) audio file
        do {
            audioFile = try AVAudioFile(forReading: recordedAudioURL as URL)
        } catch {
            showAlert(Alerts.AudioFileError, message: String(describing: error))
        }        
    }
    
    func playSound(rate: Float? = nil, pitch: Float? = nil, echo: Bool = false, reverb: Bool = false) {
        
        // initialize audio engine components
        audioEngine = AVAudioEngine()
        
        // node for playing audio
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attach(audioPlayerNode)
        
        // node for adjusting rate/pitch
        let changeRatePitchNode = AVAudioUnitTimePitch()
        if let pitch = pitch {
            changeRatePitchNode.pitch = pitch
        }
        if let rate = rate {
            changeRatePitchNode.rate = rate
        }
        audioEngine.attach(changeRatePitchNode)
        
        // node for echo
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.multiEcho1)
        audioEngine.attach(echoNode)
        
        // node for reverb
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 50
        audioEngine.attach(reverbNode)
        
        // connect nodes
        if echo == true && reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, reverbNode, audioEngine.outputNode)
        } else if echo == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, audioEngine.outputNode)
        } else if reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, reverbNode, audioEngine.outputNode)
        } else {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, audioEngine.outputNode)
        }
        
        // schedule to play and start the engine!
        audioPlayerNode.stop()
        let afPos: AVAudioFramePosition = AVAudioFramePosition(Double(audioFile.processingFormat.sampleRate) * Double(slider.value))
        let length = Float(getTotalTime()) - slider.value
        let framestoplay: AVAudioFrameCount = AVAudioFrameCount(Float(audioFile.processingFormat.sampleRate) * length)
        
        if(framestoplay > 100) {
            audioPlayerNode.scheduleSegment(audioFile, startingFrame: afPos, frameCount: framestoplay, at: nil)
//            {
//                
//                var delayInSeconds: Double = 0
//                
//                if let lastRenderTime = self.audioPlayerNode.lastRenderTime, let playerTime = self.audioPlayerNode.playerTime(forNodeTime: lastRenderTime) {
//                    
//                    if let rate = rate {
//                        delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate) / Double(rate)
//                    } else {
//                        delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate)
//                    }
//                }
            
                // schedule a stop timer for when audio finishes playing
//                self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(PlaySoundsViewController.stopAudio), userInfo: nil, repeats: false)
//                            RunLoop.main.add(self.stopTimer!, forMode: RunLoopMode.defaultRunLoopMode)
//            }
            
            do {
                try audioEngine.start()
            } catch {
                showAlert(Alerts.AudioEngineError, message: String(describing: error))
                return
            }
            
            // play the recording!
            audioPlayerNode.play()
            
            updateTimer = Timer(timeInterval: 0.05, target: self, selector: #selector(PlaySoundsViewController.onUpdateTimer), userInfo: nil, repeats: true)
            RunLoop.main.add(self.updateTimer!, forMode: RunLoopMode.defaultRunLoopMode)
        }
    }
    
    func stopAudio() {
        
        if let audioPlayerNode = audioPlayerNode {
            audioPlayerNode.stop()
        }
        
        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }
        
        if let updateTimer = updateTimer {
            updateTimer.invalidate()
        }
        
        configureUI(.notPlaying)
                        
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }
    
    func pauseAudio() {
        
        if let audioPlayerNode = audioPlayerNode {
            audioPlayerNode.stop()
        }
        
        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }
        
        if let updateTimer = updateTimer {
            updateTimer.invalidate()
        }
        
        configureUI(.pause)
        
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }
    
    // MARK: Connect List of Audio Nodes
    
    func connectAudioNodes(_ nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1], format: audioFile.processingFormat)
        }
    }
    
    // MARK: UI Functions

    func configureUI(_ playState: PlayingState, rate: Float? = nil) {
        switch(playState) {
        case .playing:
            setPlayButtonsEnabled(false)
            stopButton.isEnabled = true
            pauseButton.isEnabled = true
            slider.isEnabled = false
            
            let totalTime = getTotalTime(rate: rate)
            totalTimeLabel.text = "\(totalTime)"
            slider.maximumValue = Float(totalTime)
            
        case .notPlaying:
            setPlayButtonsEnabled(true)
            stopButton.isEnabled = false
            pauseButton.isEnabled = false
            slider.isEnabled = true
            
            resumeTime = 0
            slider.value = 0.0
            currentTimeLabel.text = "0.0"
            
        case .pause:
            setPlayButtonsEnabled(false)
            stopButton.isEnabled = true
            pauseButton.isEnabled = true
            slider.isEnabled = true
        }
    }
    
    func setPlayButtonsEnabled(_ enabled: Bool) {
        snailButton.isEnabled = enabled
        chipmunkButton.isEnabled = enabled
        rabbitButton.isEnabled = enabled
        vaderButton.isEnabled = enabled
        echoButton.isEnabled = enabled
        reverbButton.isEnabled = enabled
    }

    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func getTotalTime(rate: Float? = nil) -> Double {
        if let rate = rate {
            return Double(self.audioFile.length) / Double(self.audioFile.processingFormat.sampleRate) / Double(rate)
        } else {
            return Double(self.audioFile.length) / Double(self.audioFile.processingFormat.sampleRate)
        }
    }
    
    private func getCurrentTime() -> TimeInterval {
        if let playerNode: AVAudioPlayerNode = audioPlayerNode, let nodeTime: AVAudioTime = playerNode.lastRenderTime, let playerTime: AVAudioTime = playerNode.playerTime(forNodeTime: nodeTime) {
            if let rate = self.rate {
                return Double(Double(playerTime.sampleTime) / playerTime.sampleRate) / Double(rate)
            } else {
                return Double(Double(playerTime.sampleTime) / playerTime.sampleRate)
            }
        }
        return 0
    }
    
    func onUpdateTimer() {
        let curTime = Double(self.resumeTime) + getCurrentTime()
        let totalTime = getTotalTime(rate: self.rate)
        
        if curTime >= totalTime {
            stopAudio()
        } else {
            slider.value = Float(curTime)
            currentTimeLabel.text = "\(curTime)"
        }
//        print("playing : \(audioPlayerNode.isPlaying), curTime: \(curTime), totalTime: \(totalTime)")
    }
}
